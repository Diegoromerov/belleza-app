// ✅ CommonJS Compatible
const { callNemotronOrchestrator } = require('./nemotron.client');
const { formatOrchestratorResponse, parseJsonSafely } = require('./parsers');
const fs = require('fs/promises');
const path = require('path');

// Mapeo de herramientas disponibles (Solo lectura/consultivas)
const AVAILABLE_TOOLS = {
  read_repository_code: async (args) => {
    try {
      const basePath = path.resolve(process.cwd(), '../../');
      const filePath = path.resolve(basePath, args.file_path);

      // Verificar que no salga del directorio base (seguridad contra path traversal)
      // Se usa path.sep al final de basePath para evitar falsos positivos con
      // directorios "hermanos" que comparten el mismo prefijo de texto
      // (ej: basePath = /home/user/project, ruta maliciosa = /home/user/project-evil)
      if (filePath !== basePath && !filePath.startsWith(basePath + path.sep)) {
        return { success: false, error: 'Acceso denegado: ruta fuera del proyecto' };
      }

      // Verificar que sea un archivo, no carpeta
      const stats = await fs.stat(filePath);
      if (!stats.isFile()) {
        return { success: false, error: `La ruta '${args.file_path}' es una carpeta, no un archivo. Usa rutas de archivo específicas.` };
      }

      const content = await fs.readFile(filePath, 'utf-8');
      return { success: true, file: args.file_path, content };
    } catch (error) {
      return { success: false, error: `Archivo no encontrado o inaccesible: ${args.file_path}` };
    }
  },

  search_luxury_benchmarks: async (args) => {
    return {
      success: true,
      query: args.query,
      results: "Simulación: Se encontraron patrones de diseño de La Mer (minimalismo dorado), SK-II (datos clínicos visuales) y ModiFace (AR fluido)."
    };
  },

  query_postgres_schema: async (args) => {
    return {
      success: true,
      table: args.table_name,
      schema: "Simulación: Tabla encontrada con campos id, user_id, hidratacion, sebo, subtono, created_at."
    };
  }
};

/**
 * Función principal que maneja la interacción con el Agente Líder.
 */
async function handleOrchestration(userPrompt) {
  try {
    // 1. Llamada inicial al modelo
    let message = await callNemotronOrchestrator(userPrompt);

    // 2. Si el modelo pide usar herramientas (Tool Calling)
    if (message.tool_calls && message.tool_calls.length > 0) {
      const toolResults = [];

      for (const toolCall of message.tool_calls) {
        const toolName = toolCall.function.name;
        const toolArgs = parseJsonSafely(toolCall.function.arguments);
        if (AVAILABLE_TOOLS[toolName]) {
          const result = await AVAILABLE_TOOLS[toolName](toolArgs);
          toolResults.push({
            role: "tool",
            tool_call_id: toolCall.id,
            content: JSON.stringify(result)
          });
        }
      }
      // 3. Segunda llamada con los resultados de las herramientas
      message = await callNemotronOrchestrator(
        `${userPrompt}\n\n<tool_results>${JSON.stringify(toolResults)}</tool_results>\n\nProcede con tu análisis y propuesta final.`
      );
    }
    // 4. Formatear y devolver la respuesta consultiva
    return formatOrchestratorResponse(message);
  } catch (error) {
    console.error('Error en el orquestador:', error);
    throw new Error('El Agente Líder encontró un error procesando tu solicitud.');
  }
}

module.exports = { handleOrchestration };