import { callNemotronOrchestrator } from './nemotron.client.js';
import { formatOrchestratorResponse, parseJsonSafely } from './parsers.js';
import fs from 'fs/promises';
import path from 'path';

// Mapeo de herramientas disponibles (Solo lectura/consultivas)
const AVAILABLE_TOOLS = {
  read_repository_code: async (args) => {
    try {
      // Aseguramos que solo lea archivos dentro del proyecto (seguridad)
      const basePath = path.resolve(process.cwd(), '../../'); 
      const filePath = path.join(basePath, args.file_path);
      const content = await fs.readFile(filePath, 'utf-8');
      return { success: true, file: args.file_path, content };
    } catch (error) {
      return { success: false, error: error.message };
    }
  },
  
  search_luxury_benchmarks: async (args) => {
    // Simulación de búsqueda (aquí podrías integrar una API real como Tavily o Serper)
    return { 
      success: true, 
      query: args.query, 
      results: "Simulación: Se encontraron patrones de diseño de La Mer (minimalismo dorado), SK-II (datos clínicos visuales) y ModiFace (AR fluido)." 
    };
  },

  query_postgres_schema: async (args) => {
    // Simulación de consulta a DB (aquí conectarías con tu servicio de DB real)
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
export async function handleOrchestration(userPrompt) {
  try {
    // 1. Llamada inicial al modelo
    let message = await callNemotronOrchestrator(userPrompt);
    let finalOutput = [];

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

      // 3. Segunda llamada al modelo con los resultados de las herramientas
      // (En un flujo real de Nemotron, se envía el historial completo de mensajes)
      // Para simplificar, aquí simulamos que el modelo procesa los resultados y da la respuesta final.
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