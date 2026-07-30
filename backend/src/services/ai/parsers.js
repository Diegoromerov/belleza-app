/**
 * Extrae el contenido dentro de una etiqueta XML específica.
 * Ejemplo: extractXmlContent(text, 'thinking')
 */
export function extractXmlContent(text, tag) {
  const regex = new RegExp(`<${tag}>([\\s\\S]*?)<\\/${tag}>`, 'i');
  const match = text.match(regex);
  return match ? match[1].trim() : null;
}

/**
 * Parsea un string JSON de forma segura, evitando crashes si el modelo alucina.
 */
export function parseJsonSafely(jsonString) {
  try {
    // A veces los modelos envuelven el JSON en bloques de código markdown
    const cleanString = jsonString.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    return JSON.parse(cleanString);
  } catch (error) {
    console.error('Error parseando JSON de Nemotron:', error);
    return null;
  }
}

/**
 * Formatea la respuesta final del orquestador para el usuario.
 */
export function formatOrchestratorResponse(message) {
  const thinking = extractXmlContent(message.content, 'thinking');
  const plan = extractXmlContent(message.content, 'plan');
  
  // Limpiamos el contenido de las etiquetas para mostrar solo el texto útil
  let cleanContent = message.content;
  if (thinking) cleanContent = cleanContent.replace(new RegExp(`<thinking>[\\s\\S]*?<\/thinking>`, 'i'), '');
  if (plan) cleanContent = cleanContent.replace(new RegExp(`<plan>[\\s\\S]*?<\/plan>`, 'i'), '');

  return {
    thinking: thinking || "Razonamiento interno no disponible.",
    plan: plan || "Plan no estructurado.",
    finalResponse: cleanContent.trim(),
    toolCalls: message.tool_calls || []
  };
}