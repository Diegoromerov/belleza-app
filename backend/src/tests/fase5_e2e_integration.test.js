// backend/src/tests/fase5_e2e_integration.test.js
const { pool } = require('../config/db');
const { processAssistantMessage, AI_USER_ID } = require('../services/geminiService');
const { executeAuraTool } = require('../services/auraToolExecutor');

jest.mock('../config/db', () => ({
  pool: {
    query: jest.fn()
  }
}));

jest.mock('../config/redis', () => ({
  isOpen: false,
  get: jest.fn(),
  set: jest.fn()
}));

jest.mock('../services/websocketService', () => ({
  notifyUserChatMessage: jest.fn(),
  notifyUserAuraStatus: jest.fn()
}));

const axios = require('axios');
jest.mock('axios');

describe('Pruebas E2E de Fase 5 - Integración Completa del Ecosistema Multi-Agente', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('Debería orquestar correctamente el flujo completo: Mensaje del usuario → DeepSeek Tool Call → Ejecución de Agente → Notificación WebSocket', async () => {
    // Mock 1: Base de datos SELECT servicios, SELECT mensajes e INSERT respuesta
    pool.query.mockImplementation((queryText) => {
      if (queryText.includes('SELECT s.id as service_id')) {
        return Promise.resolve({ rows: [] });
      }
      if (queryText.includes('SELECT sender_id, receiver_id, message')) {
        return Promise.resolve({ rows: [] });
      }
      if (queryText.includes('INSERT INTO messages')) {
        return Promise.resolve({
          rows: [
            {
              id: 999,
              sender_id: 0,
              receiver_id: 1,
              message: '¡Hola! Noto que buscas un corte de cabello cerca de ti. Salón Ana Beauty está disponible a 0.8 km.',
              is_read: false,
              created_at: new Date()
            }
          ]
        });
      }
      return Promise.resolve({ rows: [] });
    });

    // Mock 2: Respuesta de DeepSeek solicitando Tool Call de HERMES (search_nearby_services)
    axios.post.mockResolvedValueOnce({
      data: {
        choices: [
          {
            message: {
              role: 'assistant',
              tool_calls: [
                {
                  id: 'call_hermes_001',
                  type: 'function',
                  function: {
                    name: 'search_nearby_services',
                    arguments: JSON.stringify({ latitude: 4.6097, longitude: -74.0817, category: 'Cabello' })
                  }
                }
              ]
            }
          }
        ]
      }
    });

    // Mock 3: Segunda respuesta de DeepSeek tras recibir los resultados de HERMES
    axios.post.mockResolvedValueOnce({
      data: {
        choices: [
          {
            message: {
              content: '¡Hola! Noto que buscas un corte de cabello cerca de ti. Salón Ana Beauty está disponible a 0.8 km.'
            }
          }
        ]
      }
    });

    // Ejecutar el procesamiento asíncrono
    await processAssistantMessage(1, "Busco corte de cabello cerca de mí", null);

    // Verificaciones
    expect(axios.post).toHaveBeenCalledTimes(2);
    expect(pool.query).toHaveBeenCalled();
  });
});
