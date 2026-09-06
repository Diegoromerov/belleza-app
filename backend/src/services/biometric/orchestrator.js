const youcamClient = require('./youcam.client');
const geminiClient = require('./gemini.client');
const deepseekClient = require('./deepseek.client');
const profileService = require('./profile.service');
const openUV = require('../openUV');
const logger = require('../../config/logger');
const { breakers } = require('../circuitBreakerService');

class BiometricOrchestrator {
  /**
   * Orquesta el análisis completo con resiliencia y Circuit-Breakers (Sprint 2.3 ADR-001)
   */
  async analyze(userId, faceImage, handsImage, entryPoint = 'ideas', lat, lng, traceId = null) {
    const parsedUserId = parseInt(userId, 10);
    logger.info('Iniciando análisis biométrico resilietne para el usuario', { userId: parsedUserId, traceId });

    // 1-3. Ejecutar análisis de rostro, manos y UV con Circuit Breakers
    let faceScores, handsDiagnosis, uvData = null;

    const [faceResult, handsResult, uvResult] = await Promise.allSettled([
      breakers.youcam.execute(
        () => youcamClient.analyzeFace(faceImage, traceId),
        () => ({
          hydration: 60,
          wrinkles: 30,
          spots: 40,
          pores: 35,
          subtono: 'neutro',
          bioAge: 35,
        })
      ),
      breakers.gemini.execute(
        () => geminiClient.analyzeHands(handsImage, traceId),
        () => ({
          manchasSolares: 'leve',
          sequedad: 'moderada',
          cuticulas: 'sanas',
          unas: 'sanas',
          edadAparente: 35,
        })
      ),
      (lat && lng) ? openUV.getUV(lat, lng) : Promise.resolve(null),
    ]);

    faceScores = faceResult.status === 'fulfilled' ? faceResult.value : {
      hydration: 60, wrinkles: 30, spots: 40, pores: 35, subtono: 'neutro', bioAge: 35
    };

    handsDiagnosis = handsResult.status === 'fulfilled' ? handsResult.value : {
      manchasSolares: 'leve', sequedad: 'moderada', cuticulas: 'sanas', unas: 'sanas', edadAparente: 35
    };

    if (uvResult.status === 'fulfilled' && uvResult.value) {
      uvData = uvResult.value;
    }

    // 4. Generar recomendación con DeepSeek (con fallback a Gemini envuelto en Circuit Breaker)
    let recommendation = await breakers.deepseek.execute(
      () => deepseekClient.generateRecommendation(faceScores, handsDiagnosis),
      async () => {
        try {
          return await breakers.gemini.execute(
            () => geminiClient.generateRecommendation(faceScores, handsDiagnosis, traceId),
            () => deepseekClient.getFallbackRecommendation()
          );
        } catch (e) {
          return deepseekClient.getFallbackRecommendation();
        }
      }
    );

    // 5. Obtener tonos VTO recomendados según subtono biométrico
    let vtoTones = await breakers.deepseek.execute(
      () => deepseekClient.getVtoToneMatching(faceScores.subtono),
      () => deepseekClient.getFallbackVtoTones(faceScores.subtono)
    );

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

    return {
      profileId: profile.id,
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
    const hydration = faceScores.hydration || 60;
    const wrinkles = faceScores.wrinkles || 30;
    const spots = faceScores.spots || 20;
    const pores = faceScores.pores || 35;

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
    const pores = faceScores.pores || 35;
    const spots = faceScores.spots || 20;
    const wrinkles = faceScores.wrinkles || 30;
    const hydration = faceScores.hydration || 60;

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

