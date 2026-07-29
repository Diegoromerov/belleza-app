const youcamClient = require('./youcam.client');
const geminiClient = require('./gemini.client');
const deepseekClient = require('./deepseek.client');
const profileService = require('./profile.service');
const openUV = require('../openUV');
const logger = require('../../config/logger');

class BiometricOrchestrator {
  /**
   * Orquesta el análisis completo: rostro + manos + recomendación
   * @param {string|number} userId - ID del usuario
   * @param {Buffer} faceImage - Imagen de rostro
   * @param {Buffer} handsImage - Imagen de manos
   * @param {string} entryPoint - 'ideas' (por defecto)
   * @param {number} [lat] - Latitud opcional
   * @param {number} [lng] - Longitud opcional
   * @returns {Promise<Object>} Resultado completo
   */
  async analyze(userId, faceImage, handsImage, entryPoint = 'ideas', lat, lng) {
    const parsedUserId = parseInt(userId, 10);
    logger.info('Iniciando análisis biométrico para el usuario', { userId: parsedUserId });

    // 1-3. Ejecutar análisis de rostro, manos y UV EN PARALELO
    let faceScores, handsDiagnosis, uvData = null;

    const [faceResult, handsResult, uvResult] = await Promise.allSettled([
      youcamClient.analyzeFace(faceImage),
      geminiClient.analyzeHands(handsImage),
      (lat && lng) ? openUV.getUV(lat, lng) : Promise.resolve(null),
    ]);

    // Procesar resultado de rostro (con fallback)
    if (faceResult.status === 'fulfilled') {
      faceScores = faceResult.value;
      logger.info('Análisis YouCam finalizado con éxito', { userId: parsedUserId });
    } else {
      logger.warn('YouCam falló, aplicando fallback local:', { userId: parsedUserId, error: faceResult.reason?.message });
      faceScores = {
        hydration: 60,
        wrinkles: 30,
        spots: 40,
        pores: 35,
        subtono: 'neutro',
        bioAge: 35,
      };
    }

    // Procesar resultado de manos (con fallback)
    if (handsResult.status === 'fulfilled') {
      handsDiagnosis = handsResult.value;
      logger.info('Análisis Gemini 3.1 Vision de manos finalizado con éxito', { userId: parsedUserId });
    } else {
      logger.warn('Gemini 3.1 Vision falló, aplicando fallback local:', { userId: parsedUserId, error: handsResult.reason?.message });
      handsDiagnosis = {
        manchasSolares: 'leve',
        sequedad: 'moderada',
        cuticulas: 'sanas',
        unas: 'sanas',
        edadAparente: 35,
      };
    }

    // Procesar resultado UV (opcional)
    if (uvResult.status === 'fulfilled' && uvResult.value) {
      uvData = uvResult.value;
      logger.info('OpenUV datos obtenidos', { userId: parsedUserId, uvData });
    } else if (uvResult.status === 'rejected') {
      logger.warn('OpenUV falló:', { userId: parsedUserId, error: uvResult.reason?.message });
    }

    // 4. Generar recomendación con DeepSeek V4 Flash (con fallback a Gemini 3.1)
    let recommendation;
    try {
      recommendation = await deepseekClient.generateRecommendation(faceScores, handsDiagnosis);
      logger.info('Recomendación de DeepSeek V4 Flash generada con éxito', { userId: parsedUserId });
    } catch (error) {
      logger.warn('DeepSeek V4 Flash falló, intentando Gemini 3.1:', { userId: parsedUserId, error: error.message });
      try {
        recommendation = await geminiClient.generateRecommendation(faceScores, handsDiagnosis);
      } catch (err) {
        recommendation = deepseekClient.getFallbackRecommendation();
      }
    }

    // 5. Obtener tonos VTO recomendados según subtono biométrico (DeepSeek V4 Flash)
    let vtoTones = null;
    try {
      vtoTones = await deepseekClient.getVtoToneMatching(faceScores.subtono);
    } catch (e) {
      vtoTones = deepseekClient.getFallbackVtoTones(faceScores.subtono);
    }

    if (uvData) {
      recommendation = `${recommendation}\n\n☀️ **Alerta FPS Activa:** ${uvData.recommendation} (Nivel de riesgo: ${uvData.riskLevel}, Índice UV: ${uvData.uv})`;
    }

    // 5. Extraer ingredientes activos sugeridos
    const keyIngredients = this.extractIngredients(recommendation);

    // 6. Guardar perfil final en base de datos e inyectar a Redis
    const profile = await profileService.saveProfile({
      userId: parsedUserId,
      faceScores,
      handsDiagnosis,
      recommendation,
      recommendedProducts: [], // Fase 4
      entryPoint,
      keyIngredients,
    });

    logger.info('Perfil biométrico guardado exitosamente', { userId: parsedUserId, profileId: profile.id });

    return {
      profileId: profile.id,
      face: faceScores,
      hands: handsDiagnosis,
      recommendation,
      keyIngredients,
      vtoTones,
      createdAt: profile.createdAt,
    };
  }

  /**
   * Extrae ingredientes sugeridos mediante escaneo por palabras clave
   */
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
    const lowerText = recommendation.toLowerCase();
    for (const ingredient of ingredientList) {
      if (lowerText.includes(ingredient)) {
        found.push(ingredient);
      }
    }
    return found.slice(0, 5);
  }
}

module.exports = new BiometricOrchestrator();
