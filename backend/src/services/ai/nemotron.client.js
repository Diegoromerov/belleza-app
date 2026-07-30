// ✅ CommonJS Compatible
const { MASTER_SYSTEM_PROMPT } = require('./systemPrompts');
const { SWARM_DEFINITIONS } = require('./swarmDefinitions');
const { TOOLS } = require('./tools');

const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;
const API_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';

// Timeout por defecto para la llamada a la API (en ms)
const REQUEST_TIMEOUT_MS = 30000;

/**
 * Normaliza SWARM_DEFINITIONS a string, sin importar si viene como
 * objeto/array (JSON) o ya como texto plano.
 */
function serializeSwarmContext(swarmDefinitions) {
  if (typeof swarmDefinitions === 'string') {
    return swarmDefinitions;
  }
  try {
    return JSON.stringify(swarmDefinitions, null, 2);
  } catch (err) {
    console.error('No se pudo serializar SWARM_DEFINITIONS:', err);
    return '';
  }
}

async function callNemotronOrchestrator(userPrompt) {
  if (!NVIDIA_API_KEY) {
    throw new Error('NVIDIA_API_KEY no está configurada en las variables de entorno.');
  }

  const swarmContext = serializeSwarmContext(SWARM_DEFINITIONS);

  const payload = {
    // ⚠️ REEMPLAZAR con el ID EXACTO del modelo tal como aparece en tu dashboard de NVIDIA
    model: "nvidia/nemotron-3-ultra-550b-a55b",
    messages: [
      {
        role: "system",
        content: `${MASTER_SYSTEM_PROMPT}

<swarm_context>
${swarmContext}
</swarm_context>`
      },
      {
        role: "user",
        content: `<user_prompt>${userPrompt}</user_prompt>`
      }
    ],
    tools: TOOLS,
    temperature: 0.2,
    max_tokens: 4096,
    stream: false
  };

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${NVIDIA_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload),
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    const responseText = await response.text();

    if (!response.ok) {
      throw new Error(`Error en API de NVIDIA: ${response.status} - ${responseText.substring(0, 500)}`);
    }

    let data;
    try {
      data = JSON.parse(responseText);
    } catch (parseError) {
      console.error('Respuesta no es JSON válido:', responseText.substring(0, 200));
      throw new Error(`La API de NVIDIA devolvió una respuesta inválida: ${responseText.substring(0, 100)}`);
    }

    if (!data.choices || !data.choices[0] || !data.choices[0].message) {
      throw new Error(`Respuesta inesperada de NVIDIA (sin choices/message): ${JSON.stringify(data).substring(0, 300)}`);
    }

    return data.choices[0].message;

  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      console.error('Timeout al llamar a Nemotron Orchestrator (30s excedidos).');
      throw new Error('Timeout: la API de NVIDIA no respondió a tiempo.');
    }
    console.error('Error al llamar a Nemotron Orchestrator:', error);
    throw error;
  }
}

module.exports = { callNemotronOrchestrator };