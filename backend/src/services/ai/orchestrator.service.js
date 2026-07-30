// ✅ CommonJS Compatible - Orquestador blindado contra crashes
const { callNemotronOrchestrator } = require('./nemotron.client');
const { formatOrchestratorResponse, parseJsonSafely } = require('./parsers');
const fs = require('fs/promises');
const path = require('path');

// Mapeo de herramientas disponibles (con validación robusta)
const AVAILABLE_TOOLS = {
  read_repository_code: async (args) => {
    try {
      if (!args || !args.file_path) {
        return { success: false, error: 'Falta el parámetro file_path' };
      }
      
      const basePath = path.resolve(process.cwd(), '../../'); 
      const filePath = path.join(basePath, args.file_path);
      
      // Seguridad: evitar traversal fuera del proyecto
      if (!filePath.startsWith(basePath)) {
        return { success: false, error: 'Acceso denegado: ruta fuera del proyecto' };
      }
      
      // Validar que sea archivo, no carpeta
      const stats = await fs.stat(filePath);
      if (!stats.isFile()) {
        return { success: false, error: `'${args.file_path}' es una carpeta. Usa rutas de archivo específicas (.js)` };
      }
      
      const content = await fs.readFile(filePath, 'utf-8');
      return { success: true, file: args.file_path, contentLength: content.length };
    } catch (error) {
      return { success: false, error: `No se pudo leer '${args.file_path}': ${error.message}` };
    }
  },
  
  search_luxury_benchmarks: async (args) => {
    return { 
      success: true, 
      query: args?.query || '', 
      results: "Benchmark simulado: Dior usa minimalismo dorado + serif; La Mer prioriza datos clínicos visuales; Perfect Corp destaca AR fluido con overlays elegantes." 
    };
  },

  query_postgres_schema: async (args) => {
    return { 
      success: true, 
      table: args?.table_name || '', 
      schema: "Esquema simulado disponible bajo demanda." 
    };
  }
};

/**
 * Función principal con manejo de errores completo
 */
async function handleOrchestration(userPrompt) {
  try {
    // 1. Primera llamada al modelo
    let message = await callNemotronOrchestrator(userPrompt);
    
    // 2. Procesar tool calls si existen
    if (message && message.tool_calls && message.tool_calls.length > 0) {
      const toolResults = [];
      
      for (const toolCall of message.tool_calls) {
        try {
          const toolName = toolCall.function?.name;
          const toolArgs = parseJsonSafely(toolCall.function?.arguments || '{}');

          if (toolName && AVAILABLE_TOOLS[toolName]) {
            const result = await AVAILABLE_TOOLS[toolName](toolArgs);
            toolResults.push({
              role: "tool",
              tool_call_id: toolCall.id,
              content: JSON.stringify(result)
            });
          } else {
            toolResults.push({
              role: "tool",
              tool_call_id: toolCall.id,
              content: JSON.stringify({ success: false, error: `Herramienta '${toolName}' no disponible` })
            });
          }
        } catch (toolError) {
          console.error(`Error ejecutando herramienta ${toolCall.function?.name}:`, toolError);
          toolResults.push({
            role: "tool",
            tool_call_id: toolCall.id,
            content: JSON.stringify({ success: false, error: 'Error interno en herramienta' })
          });
        }
      }

      // 3. Segunda llamada con resultados de herramientas
      if (toolResults.length > 0) {
        message = await callNemotronOrchestrator(
          `${userPrompt}\n\n<tool_results>${JSON.stringify(toolResults)}</tool_results>\n\nAnaliza los resultados y genera tu respuesta final consolidada.`
        );
      }
    }

    // 4. Formatear respuesta segura
    return formatOrchestratorResponse(message);

  } catch (error) {
    console.error('❌ Error crítico en orquestador:', error);
    throw new Error(`Fallo en procesamiento: ${error.message}`);
  }
}

module.exports = { handleOrchestration };