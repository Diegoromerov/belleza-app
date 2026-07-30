// ✅ CommonJS Compatible
const { MASTER_SYSTEM_PROMPT } = require('./systemPrompts');
const { SWARM_DEFINITIONS } = require('./swarmDefinitions');
const { TOOLS } = require('./tools');

const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;
const API_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';

async function callNemotronOrchestrator(userPrompt) {
  if (!NVIDIA_API_KEY) {
    throw new Error('NVIDIA_API_KEY no está configurada en las variables de entorno.');
  }

  const payload = {
    model: "nvidia/nvidia/nemotron-3-ultra-550b-a55b", // ⚠️ REEMPLAZAR CON EL ID EXACTO DE HERMES AGENT-NEMOTRON 3 550 ULTRA EN TU DASHBOARD
    messages: [
      {
        role: "system",
        content: `
          ${MASTER_SYSTEM_PROMPT}
          
          <swarm_context>
            ${SWARM_DEFINITIONS}
          </swarm_context>
        `
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

  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${NVIDIA_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Error en API de NVIDIA: ${response.status} - ${JSON.stringify(errorData)}`);
    }

    const data = await response.json();
    return data.choices[0].message;

  } catch (error) {
    console.error('Error al llamar a Nemotron Orchestrator:', error);
    throw error;
  }
}

module.exports = { callNemotronOrchestrator };