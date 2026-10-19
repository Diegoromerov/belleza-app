const youcamClient = require('./youcam.client');
const geminiClient = require('./gemini.client');
const deepseekClient = require('./deepseek.client');
const profileService = require('./profile.service');
const scanSessionService = require('./scanSession.service');
const captureQuality = require('./captureQuality.service');
const undertoneService = require('./undertone.service');
const deltaService = require('./delta.service');
const scanComparisonService = require('./scanComparison.service');
const openUV = require('../openUV');
const logger = require('../../config/logger');
const { BIOMETRIC_CONSENT_VERSION } = require('../../config/consentConfig');
const { breakers } = require('../circuitBreakerService');

class BiometricOrchestrator {
  /**
   * Orquesta el análisis completo con resiliencia y Circuit-Breakers (Sprint 2.3 ADR-001)
   */
  async analyze(userId, faceImage, handsImage, entryPoint = 'ideas', lat, lng, traceId = null) {
    const parsedUserId = parseInt(userId, 10);
    logger.info('Iniciando análisis biométrico resilietne para el usuario', { userId: parsedUserId, traceId });

    // Y-F2: puerta de calidad antes de gastar unidades del proveedor. Una foto
    // oscura, borrosa o de menos de 640 px no se envía: se responde 422 con el motivo.
    const prepared = await captureQuality.prepareFace(faceImage);
    if (prepared.rejected) {
      const error = new Error('La foto no cumple los requisitos mínimos para medir piel.');
      error.code = 'CAPTURE_REJECTED';
      error.statusCode = 422;
      error.details = prepared.quality;
      throw error;
    }
    const normalizedFace = prepared.image.buffer;

    // 1-3. Ejecutar análisis de rostro, manos y UV con Circuit Breakers
    let faceScores, handsDiagnosis, uvData = null;

    const [faceResult, handsResult, uvResult] = await Promise.allSettled([
      breakers.youcam.execute(() => youcamClient.analyzeFace(normalizedFace, traceId)),
      breakers.gemini.execute(() => geminiClient.analyzeHands(handsImage, traceId)),
      (lat && lng) ? openUV.getUV(lat, lng) : Promise.resolve(null),
    ]);

    if (faceResult.status === 'rejected' || handsResult.status === 'rejected') {
      const error = new Error('El análisis biométrico no está disponible; no se generó ni guardó un diagnóstico.');
      error.code = 'BIOMETRIC_ANALYSIS_UNAVAILABLE';
      error.statusCode = 503;
      throw error;
    }

    faceScores = faceResult.value;
    handsDiagnosis = handsResult.value;

    // Y-F2: el subtono se mide sobre la foto normalizada, no se hereda del tipo de piel.
    // Si no hay píxeles de piel suficientes queda en null con fuente 'no_medido'.
    const undertone = await undertoneService.measureUndertone(normalizedFace);
    faceScores.subtonoMedicion = undertone;
    faceScores.subtono = undertone.measured ? undertone.subtono : null;
    faceScores.subtonoFuente = undertone.measured ? 'ita_hue_propio' : 'no_medido';
    normalizedFace.fill(0); // la imagen ya se midió: no se conserva en memoria

    if (uvResult.status === 'fulfilled' && uvResult.value) {
      uvData = uvResult.value;
    }

    // 4. Generar recomendación con DeepSeek (con fallback a Gemini envuelto en Circuit Breaker)
    let recommendation;
    try {
      recommendation = await breakers.deepseek.execute(
      () => deepseekClient.generateRecommendation(faceScores, handsDiagnosis),
      () => breakers.gemini.execute(() => geminiClient.generateRecommendation(faceScores, handsDiagnosis, traceId))
      );
    } catch (cause) {
      const error = new Error('Las recomendaciones biométricas no están disponibles; no se guardó un diagnóstico incompleto.');
      error.code = 'BIOMETRIC_ANALYSIS_UNAVAILABLE';
      error.statusCode = 503;
      error.cause = cause;
      throw error;
    }

    // 5. Obtener tonos VTO recomendados según subtono biométrico
    let vtoTones;
    try {
      vtoTones = await breakers.deepseek.execute(() => deepseekClient.getVtoToneMatching(faceScores.subtono));
    } catch (cause) {
      const error = new Error('La personalización de tonos no está disponible; no se guardó un diagnóstico incompleto.');
      error.code = 'BIOMETRIC_ANALYSIS_UNAVAILABLE';
      error.statusCode = 503;
      error.cause = cause;
      throw error;
    }

    if (uvData) {
      recommendation = `${recommendation}\n\n☀️ **Alerta FPS Activa:** ${uvData.recommendation} (Nivel de riesgo: ${uvData.riskLevel}, Índice UV: ${uvData.uv})`;
    }

    // 6. Extraer ingredientes activos sugeridos
    const keyIngredients = this.extractIngredients(recommendation);

    // 7. Calcular GlowScore (0-100) y Familias Clínicas (Evimetra + Bioderma)
    const glowScore = this.calculateGlowScore(faceScores);
    const dermoFamilies = this.getDermatologicalFamilies(faceScores);

    // 8. Guardar perfil final en base de datos
    const profile = await profileService.saveProfile({
      userId: parsedUserId,
      faceScores,
      handsDiagnosis,
      recommendation,
      recommendedProducts: [],
      entryPoint,
      keyIngredients,
    });

    logger.info('Perfil biométrico guardado exitosamente con resiliencia', { userId: parsedUserId, profileId: profile.id });

    // Y-F1: persistir la llamada completa (16 acciones HD, raw_score, máscaras) en su
    // propia serie temporal. Si la escritura falla no se rompe la respuesta: el análisis
    // ya se pagó y el perfil quedó guardado; se devuelve `scanSession.persisted = false`
    // para que quede rastro en logs y en la respuesta interna.
    const scanSession = await scanSessionService.saveScan({
      userId: parsedUserId,
      faceScores,
      geometry: prepared.geometry, // Y-F2: origen, normalización y EXIF de la captura
      quality: { ...prepared.quality, undertone }, // Y-F2: veredicto, score y motivos
      tolerante: true,
    });

    if (!scanSession.persisted) {
      logger.warn('Sesión de escaneo no persistida', {
        userId: parsedUserId,
        reason: scanSession.reason,
        metricsCount: scanSession.metricsCount,
      });
    }

    // Y-F3: comparación contra el escaneo anterior del mismo usuario. Si es el primero,
    // no hay baseline y se dice; no se fabrica una mejora del 100%.
    let delta = null;
    if (scanSession.persisted && scanSession.id) {
      try {
        const previous = await scanSessionService.getPrevious(parsedUserId, scanSession.id);
        if (previous) {
          const comparacion = deltaService.compareScans({
            previous: previous.payload,
            current: { metrics: faceScores.metrics, capturedAt: scanSession.capturedAt },
            glowScoreBefore: this.calculateGlowScore(previous.payload?.legacy || {}),
            glowScoreAfter: glowScore,
          });

          const saved = await scanComparisonService.save({
            userId: parsedUserId,
            baselineScanId: previous.id,
            currentScanId: scanSession.id,
            result: comparacion,
          });

          delta = {
            ...comparacion,
            baselineScanId: previous.id,
            comparisonId: saved.id || null,
            persisted: saved.persisted,
          };
        } else {
          delta = {
            verdict: 'SIN_BASELINE',
            threshold: deltaService.DEFAULT_THRESHOLD,
            compared: 0,
            significant: 0,
            notes: ['Primer escaneo con métricas completas: todavía no hay con qué comparar.'],
          };
        }
      } catch (error) {
        logger.warn('No se pudo calcular la comparación con el baseline', {
          userId: parsedUserId,
          scanSessionId: scanSession.id,
          error: error.message,
        });
        delta = { verdict: 'NO_DISPONIBLE', notes: [error.message] };
      }
    }

    return {
      profileId: profile.id,
      scanSessionId: scanSession.id || null,
      metricsCount: scanSession.metricsCount,
      delta,
      // Y-F1b: el cliente necesita saber si autorizó con el texto vigente o con uno viejo.
      consent: {
        version: scanSession.consentVersion || null,
        currentVersion: BIOMETRIC_CONSENT_VERSION,
        outdated: scanSession.consentOutdated === true,
      },
      face: faceScores,
      glowScore,
      dermoFamilies,
      hands: handsDiagnosis,
      recommendation,
      keyIngredients,
      vtoTones,
      createdAt: profile.createdAt,
    };
  }

  calculateGlowScore(faceScores) {
    // Un 0 medido es un dato, no un valor ausente: `|| 60` lo convertía en 60 y
    // falseaba el GlowScore (y con Y-F3, el Δ contra el baseline).
    const num = (value, fallback) => (Number.isFinite(value) ? value : fallback);
    const hydration = num(faceScores.hydration, 60);
    const wrinkles = num(faceScores.wrinkles, 30);
    const spots = num(faceScores.spots, 20);
    const pores = num(faceScores.pores, 35);

    const hydrationWeight = 0.35;
    const clarityWeight = 0.25;   // (100 - spots)
    const textureWeight = 0.25;   // (100 - pores)
    const firmnessWeight = 0.15;  // (100 - wrinkles)

    const score = (
      (hydration * hydrationWeight) +
      ((100 - spots) * clarityWeight) +
      ((100 - pores) * textureWeight) +
      ((100 - wrinkles) * firmnessWeight)
    );

    return Math.round(Math.min(100, Math.max(0, score)));
  }

  getDermatologicalFamilies(faceScores) {
    const num = (value, fallback) => (Number.isFinite(value) ? value : fallback);
    const pores = num(faceScores.pores, 35);
    const spots = num(faceScores.spots, 20);
    const wrinkles = num(faceScores.wrinkles, 30);
    const hydration = num(faceScores.hydration, 60);

    return {
      sebumPores: {
        score: Math.min(100, Math.round(pores * 1.2)),
        level: pores > 50 ? 'Atención Requerida' : 'Equilibrado',
        recommendedTreatment: 'Limpieza Facial Profunda con Ultrasonido',
        activeTarget: 'Niacinamida + Ácido Salicílico',
      },
      pigmentationClarity: {
        score: Math.min(100, Math.round(spots * 1.3)),
        level: spots > 45 ? 'Hiperpigmentación Leve' : 'Tono Uniforme',
        recommendedTreatment: 'Peeling Suave con Ácido Glicólico / Vitamina C',
        activeTarget: 'Vitamina C pura + Ácido Azelaico',
      },
      firmnessLines: {
        score: Math.min(100, Math.round(wrinkles * 1.2)),
        level: wrinkles > 45 ? 'Pérdida de Elasticidad' : 'Firmeza Óptima',
        recommendedTreatment: 'Radiofrecuencia Facial y Masaje Miofascial',
        activeTarget: 'Péptidos de Cobre + Ácido Hialurónico',
      },
      barrierHydration: {
        score: Math.min(100, Math.round(hydration)),
        level: hydration < 55 ? 'Deshidratación Notoria' : 'Barrera Saludable',
        recommendedTreatment: 'Protocolo Hidrafacial y Velo de Colágeno',
        activeTarget: 'Ceramidas + Ácido Hialurónico Multimolecular',
      },
    };
  }

  extractIngredients(recommendation) {
    const ingredientList = [
      'ácido hialurónico',
      'retinol',
      'vitamina c',
      'niacinamida',
      'ácido salicílico',
      'ácido glicólico',
      'ácido láctico',
      'coenzima q10',
      'péptidos',
      'ceramidas',
    ];

    const found = [];
    const lowerText = (recommendation || '').toLowerCase();
    for (const ingredient of ingredientList) {
      if (lowerText.includes(ingredient)) {
        found.push(ingredient);
      }
    }
    return found.slice(0, 5);
  }
}

module.exports = new BiometricOrchestrator();

