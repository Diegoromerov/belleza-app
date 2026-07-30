// ✅ CommonJS Compatible - Parser defensivo para Nemotron 3 Ultra

/**
 * Extrae contenido XML de forma segura (maneja null/undefined)
 */
function extractXmlContent(text, tag) {
  if (!text || typeof text !== 'string') return null;
  const regex = new RegExp(`<${tag}>([\\s\\S]*?)<\\/${tag}>`, 'i');
  const match = text.match(regex);
  return match ? match[1].trim() : null;
}

/**
 * Parsea JSON de forma segura
 */
function parseJsonSafely(jsonString) {
  if (!jsonString || typeof jsonString !== 'string') return null;
  try {
    const cleanString = jsonString.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    return JSON.parse(cleanString);
  } catch (error) {
    console.error('Error parseando JSON de Nemotron:', error.message);
    return null;
  }
}

/**
 * Formatea respuesta del orquestador (defensivo contra formatos variables)
 */
function formatOrchestratorResponse(message) {
  // Protección contra message.content nulo
  const content = (message && message.content) || '';
  
  const thinking = extractXmlContent(content, 'thinking');
  const plan = extractXmlContent(content, 'plan');
  
  let cleanContent = content;
  if (thinking) cleanContent = cleanContent.replace(new RegExp(`<thinking>[\\s\\S]*?<\/thinking>`, 'i'), '');
  if (plan) cleanContent = cleanContent.replace(new RegExp(`<plan>[\\s\\S]*?<\/plan>`, 'i'), '');

  return {
    thinking: thinking || "Razonamiento interno no disponible.",
    plan: plan || "Plan no estructurado.",
    finalResponse: cleanContent.trim() || "Sin respuesta generada.",
    toolCalls: (message && message.tool_calls) || []
  };
}

module.exports = { extractXmlContent, parseJsonSafely, formatOrchestratorResponse };