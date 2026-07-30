// ✅ CommonJS Compatible
const TOOLS = [
  {
    type: "function",
    function: {
      name: "read_repository_code",
      description: "Lee y analiza archivos específicos del repositorio 'belleza-app' para entender la base técnica existente. (Solo lectura).",
      parameters: {
        type: "object",
        properties: {
          file_path: {
            type: "string",
            description: "Ruta relativa del archivo, ej: 'backend/src/routes/niaBeautyRoutes.js'"
          }
        },
        required: ["file_path"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "search_luxury_benchmarks",
      description: "Simula la búsqueda de información sobre diseños, flujos y estéticas de aplicaciones de belleza premium y lujo.",
      parameters: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "Términos de búsqueda, ej: 'luxury beauty app UI UX trends 2026'"
          }
        },
        required: ["query"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "query_postgres_schema",
      description: "Consulta el esquema de la base de datos PostgreSQL para verificar tablas biométricas y de usuarios.",
      parameters: {
        type: "object",
        properties: {
          table_name: {
            type: "string",
            description: "Nombre de la tabla, ej: 'user_biometrics', 'beauty_profiles'"
          }
        },
        required: ["table_name"]
      }
    }
  }
];

module.exports = { TOOLS };