import { MASTER_SYSTEM_PROMPT } from './systemPrompts.js';
import { SWARM_DEFINITIONS } from './swarmDefinitions.js';
import { TOOLS } from './tools.js';

const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;
const API_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';

export async function callNemotronOrchestrator(userPrompt) {
  if (!NVIDIA_API_KEY) {
    throw new Error('NVIDIA_API_KEY no está configurada en las variables de entorno.');
  }

  const payload = {
    model: "nvidia/nemotron-4-340b-instruct", // Ajusta al nombre exacto de Hermes Agent-Nemotron 3 550 Ultra en tu dashboard de NVIDIA
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
    temperature: 0.2, // Baja para precisión, código y tool calling
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
    return data.choices[0].message; // Devuelve el mensaje con tool_calls o content

  } catch (error) {
    console.error('Error al llamar a Nemotron Orchestrator:', error);
    throw error;
  }
}