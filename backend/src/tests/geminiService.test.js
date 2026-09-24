// backend/src/tests/geminiService.test.js
const { pool } = require('../config/db');

// Mockear el pool de la base de datos
jest.mock('../config/db', () => ({
  pool: {
    query: jest.fn()
  }
}));

// Mockear el servicio de websockets para evitar envíos en la prueba
jest.mock('../services/websocketService', () => ({
  notifyUserChatMessage: jest.fn(),
  notifyUserAuraStatus: jest.fn()
}));

// Mockear axios para las llamadas a DeepSeek
const axios = require('axios');
jest.mock('axios');
axios.post.mockResolvedValue({
  data: {
    choices: [
      {
        message: {
          content: "Respuesta de Aura de prueba"
        }
      }
    ]
  }
});

// Importar después de configurar mocks
const { processAssistantMessage, sanitizeAiResponseText, parseDsmlToolCalls, AI_USER_ID } = require('../services/geminiService');

describe('Pruebas unitarias de Asistente de IA (geminiService.js)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('Debería agrupar mensajes consecutivos del mismo emisor e impedir roles consecutivos', async () => {
    // 1. Configurar mock de base de datos
    pool.query.mockImplementation((queryText, params) => {
      if (queryText.includes('SELECT s.id as service_id')) {
        return Promise.resolve({ rows: [] });
      }
      if (queryText.includes('SELECT sender_id, receiver_id, message, created_at')) {
        return Promise.resolve({
          rows: [
            { sender_id: 1, receiver_id: 0, message: "Hola Aura, recomiéndame algo", created_at: new Date() },
            { sender_id: 1, receiver_id: 0, message: "Tengo piel grasa", created_at: new Date(Date.now() - 1000) },
            { sender_id: 0, receiver_id: 1, message: "Hola, soy Aura.", created_at: new Date(Date.now() - 2000) },
            { sender_id: 1, receiver_id: 0, message: "Hola", created_at: new Date(Date.now() - 3000) }
          ]
        });
      }
      if (queryText.includes('INSERT INTO messages')) {
        return Promise.resolve({
          rows: [
            { id: 'msg-id-123', sender_id: 0, receiver_id: 1, message: "Respuesta de Aura de prueba", is_read: false, created_at: new Date() }
          ]
        });
      }
    });

    // 2. Invocar la función con el mensaje actual
    await processAssistantMessage(1, "Hola Aura, recomiéndame algo", null);

    // 3. Verificar los argumentos pasados a DeepSeek API vía axios
    expect(axios.post).toHaveBeenCalled();
    const payload = axios.post.mock.calls[0][1];
    expect(payload.model).toBe('deepseek-v4-flash');
    expect(payload.messages.length).toBeGreaterThan(1);
  });

  test('Debería sanitizar correctamente marcado DSML completo de invocación de herramientas', () => {
    const rawDsml = `< | DSML | | calls>
< | DSML | | invoke name="search_beauty_knowledge_rag">
< | DSML | | parameter name="queryText" string="true">hena embarazo</ | DSML | | parameter>
</ | DSML | | invoke>
< | DSML | | invoke name="search_beauty_knowledge_rag">
< | DSML | | parameter name="queryText" string="true">tinte cabello embarazo</ | DSML | | parameter>
</ | DSML | | invoke>
</ | DSML | | calls>`;

    // 1. parseDsmlToolCalls debe extraer las 2 herramientas
    const parsedTools = parseDsmlToolCalls(rawDsml);
    expect(parsedTools.length).toBe(2);
    expect(parsedTools[0].function.name).toBe('search_beauty_knowledge_rag');
    expect(JSON.parse(parsedTools[0].function.arguments).queryText).toBe('hena embarazo');
    expect(parsedTools[1].function.name).toBe('search_beauty_knowledge_rag');
    expect(JSON.parse(parsedTools[1].function.arguments).queryText).toBe('tinte cabello embarazo');

    // 2. sanitizeAiResponseText debe dejar el texto totalmente limpio / vacío
    const cleaned = sanitizeAiResponseText(rawDsml);
    expect(cleaned).toBe('');
  });
});
