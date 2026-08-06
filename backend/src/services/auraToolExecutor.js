// backend/src/services/auraToolExecutor.js
const atenaAgent = require('./agents/atenaAgent');
const hermesAgent = require('./agents/hermesAgent');
const chronosAgent = require('./agents/chronosAgent');
const hestiaAgent = require('./agents/hestiaAgent');
const valkyrieAgent = require('./agents/valkyrieAgent');
const { searchBeautyKnowledge } = require('./ragService');
const { checkConsent, logAccess } = require('./consentService');

/**
 * Definicón de JSON Schemas de las herramientas (Tool Definitions) para DeepSeek / Gemini Function Calling
 */
const AURA_TOOLS_DEFINITIONS = [
  {
    type: 'function',
    function: {
      name: 'query_user_biometric_profile',
      description: 'Invoca a ATENA para obtener el perfil biométrico del usuario (diagnóstico facial, manos, subtono de piel y paleta de colorimetría).',
      parameters: {
        type: 'object',
        properties: {
          userId: { type: 'number', description: 'ID numérico del usuario' }
        },
        required: ['userId']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'search_nearby_services',
      description: 'Invoca a HERMES para buscar servicios y prestadores de belleza cercanos a la ubicación geográfica usando PostGIS.',
      parameters: {
        type: 'object',
        properties: {
          latitude: { type: 'number', description: 'Latitud (ej. 4.6097 en Bogotá)' },
          longitude: { type: 'number', description: 'Longitud (ej. -74.0817 en Bogotá)' },
          category: { type: 'string', description: 'Categoría opcional (ej. Uñas, Cabello, Piel, Cejas)' },
          maxDistanceKm: { type: 'number', description: 'Radio máximo en kilómetros (por defecto 5)' }
        },
        required: ['latitude', 'longitude']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'check_provider_availability',
      description: 'Invoca a HERMES para verificar la disponibilidad de agenda de un prestador evitando colisiones.',
      parameters: {
        type: 'object',
        properties: {
          providerId: { type: 'number', description: 'ID del prestador' },
          serviceId: { type: 'string', description: 'ID o UUID del servicio' },
          date: { type: 'string', description: 'Fecha sugerida en formato YYYY-MM-DD' }
        },
        required: ['providerId']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'evaluate_user_rebooking',
      description: 'Invoca a CHRONOS para evaluar si el usuario tiene tratamientos que vencieron o requieren agendamiento de mantenimiento.',
      parameters: {
        type: 'object',
        properties: {
          userId: { type: 'number', description: 'ID numérico del usuario' }
        },
        required: ['userId']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'recommend_glowstore_products',
      description: 'Invoca a HESTIA para recomendar productos de la tienda GlowStore compatibles con la piel o necesidad del usuario.',
      parameters: {
        type: 'object',
        properties: {
          userId: { type: 'number', description: 'ID opcional del usuario para personalización' },
          queryText: { type: 'string', description: 'Término de búsqueda de producto' },
          category: { type: 'string', description: 'Categoría del producto (ej. Piel, Uñas, Cabello)' }
        }
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'get_provider_b2b_insights',
      description: 'Invoca a VALKYRIE para generar inteligencia de negocios, ocupación de horas muertas y descuentos dinámicos para un prestador.',
      parameters: {
        type: 'object',
        properties: {
          providerId: { type: 'number', description: 'ID numérico del prestador' }
        },
        required: ['providerId']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'search_beauty_knowledge_rag',
      description: 'Busca información técnica sobre rutinas cosméticas, ingredientes, compatibilidad de piel y cuidado en casa en la base de conocimiento.',
      parameters: {
        type: 'object',
        properties: {
          queryText: { type: 'string', description: 'Consulta del usuario sobre rutina o producto' },
          category: { type: 'string', description: 'Categoría cosmética (ej. piel, cabello, uñas)' }
        },
        required: ['queryText']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'trigger_ui_redirection',
      description: 'Genera una redirección visual en la aplicación Flutter al Módulo de Ideas o herramientas específicas de visajismo.',
      parameters: {
        type: 'object',
        properties: {
          moduleKey: {
            type: 'string',
            enum: ['nails-classic', 'skin-tone', 'hair-diagnostic', 'skin-texture', 'eyebrow-visagism', 'nails-style'],
            description: 'Clave del módulo gráfico al cual redirigir'
          }
        },
        required: ['moduleKey']
      }
    }
  }
];

/**
 * Orquesta y ejecuta las herramientas delegando en los Agentes Especializados (ATENA, HERMES, CHRONOS, HESTIA, VALKYRIE, RAG)
 */
async function executeAuraTool(toolName, args, userId) {
  console.log(`🛠️ [AURA Orchestration] Ejecutando herramienta: ${toolName}, Args:`, args);

  // Verificar consentimiento para herramientas que acceden a datos biométricos
  const BIOMETRIC_TOOLS = ['query_user_biometric_profile'];
  if (BIOMETRIC_TOOLS.includes(toolName)) {
    const targetUserId = args.userId || userId;
    const consent = await checkConsent(targetUserId, 'all_biometric');
    
    if (!consent.granted) {
      // Log intento sin consentimiento
      await logAccess({
        userId: targetUserId,
        accessedBy: 'ATENA',
        accessType: 'attempt_biometric_profile',
        ip: null,
        details: { toolName, requiredConsent: 'all_biometric' }
      });
      
      return { 
        error: 'consent_required', 
        message: 'No tienes consentimiento biométrico activo. Por favor otórgalo en Configuración > Privacidad > Datos Biométricos.' 
      };
    }

    // Log acceso autorizado
    await logAccess({
      userId: targetUserId,
      accessedBy: 'ATENA',
      accessType: 'read_biometric_profile',
      ip: null,
      details: { toolName }
    });
  }

  try {
    switch (toolName) {
      case 'query_user_biometric_profile': {
        const targetUserId = args.userId || userId;
        return await atenaAgent.getBiometricDiagnosis(targetUserId);
      }

      case 'search_nearby_services': {
        return await hermesAgent.findNearbyServices({
          latitude: args.latitude,
          longitude: args.longitude,
          category: args.category,
          maxDistanceKm: args.maxDistanceKm
        });
      }

      case 'check_provider_availability': {
        return await hermesAgent.checkAvailability({
          providerId: args.providerId,
          serviceId: args.serviceId,
          date: args.date
        });
      }

      case 'evaluate_user_rebooking': {
        const targetUserId = args.userId || userId;
        return await chronosAgent.evaluateUserRebooking(targetUserId);
      }

      case 'recommend_glowstore_products': {
        return await hestiaAgent.recommendProducts({
          userId: args.userId || userId,
          queryText: args.queryText,
          category: args.category
        });
      }

      case 'get_provider_b2b_insights': {
        return await valkyrieAgent.getProviderInsights({
          providerId: args.providerId
        });
      }

      case 'search_beauty_knowledge_rag': {
        const results = await searchBeautyKnowledge(args.queryText, args.category);
        return { status: 'success', knowledge: results };
      }

      case 'trigger_ui_redirection': {
        return {
          status: 'success',
          redirectionTag: `Redirección Módulo Ideas: ${args.moduleKey}`
        };
      }

      default:
        return { error: `Herramienta desconocida: ${toolName}` };
    }
  } catch (error) {
    console.error(`❌ Error ejecutando herramienta AURA (${toolName}):`, error.message);
    return { error: `Error interno al ejecutar la herramienta ${toolName}: ${error.message}` };
  }
}

module.exports = {
  AURA_TOOLS_DEFINITIONS,
  executeAuraTool
};
