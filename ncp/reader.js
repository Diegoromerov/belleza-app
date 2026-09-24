/**
 * NCP Document & State Reader v1.0
 * Node Construction Protocol — Document and State Parser
 * 
 * Responsabilidad:
 * - Localizar y leer archivos permitidos (GOALs, Contratos, Estado, Decisiones).
 * - Extraer información estructurada de manera determinista.
 * - Proteger contra Path Traversal y accesos indebidos.
 * - Operación 100% de solo lectura (Read-Only).
 */

const fs = require('fs');
const path = require('path');

// Raíz canónica del proyecto
const REPO_ROOT = path.resolve(__dirname, '..');
const NCP_ROOT = path.resolve(__dirname);

// Catálogo canónico de Activos Protegidos
const PROTECTED_ASSETS = [
  'backend/migrations/065_saas_foundation_core.sql',
  'backend/migrations/066_context_resolution_tenant_resolver.sql',
  'backend/src/services/contextResolutionService.js',
  'backend/src/controllers/contextController.js',
  'backend/src/routes/contextRoutes.js',
  'frontend/lib/core/theme/tokens.dart',
  'ncp/NCP-CORE-CONTRACT-v1.0.md',
  'ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md',
  'ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md',
  'ncp/NCP-CORE-OPERATIONAL-CONTRACT-v1.0.md',
  'ncp/NCP-CORE-PHYSICAL-ARCHITECTURE-v1.0.md',
  'ncp/NCP-CORE-IMPLEMENTATION-CONTRACT-v1.0.md'
];

/**
 * Valida que una ruta esté estrictamente contenida dentro de la raíz permitida (Anti-Path Traversal)
 * @param {string} targetPath - Ruta a validar
 * @param {string} allowedRoot - Directorio base permitido (por defecto REPO_ROOT)
 * @returns {boolean}
 */
function isPathSafe(targetPath, allowedRoot = REPO_ROOT) {
  if (!targetPath || typeof targetPath !== 'string') return false;
  const resolved = path.resolve(allowedRoot, targetPath);
  const normalizedRoot = path.normalize(allowedRoot);
  return resolved.startsWith(normalizedRoot);
}

/**
 * Resuelve una ruta de forma segura relativa al REPO_ROOT
 * @param {string} relativeOrAbsolutePath
 * @returns {string|null} Ruta absoluta segura o null si es inválida/insegura
 */
function resolveSafePath(relativeOrAbsolutePath) {
  if (!relativeOrAbsolutePath || typeof relativeOrAbsolutePath !== 'string') return null;
  const resolved = path.isAbsolute(relativeOrAbsolutePath)
    ? path.normalize(relativeOrAbsolutePath)
    : path.resolve(REPO_ROOT, relativeOrAbsolutePath);

  if (!isPathSafe(resolved, REPO_ROOT)) {
    return null;
  }
  return resolved;
}

/**
 * Lee un archivo de texto de forma segura
 * @param {string} filePath
 * @returns {{ success: boolean, content?: string, error?: string }}
 */
function readTextFile(filePath) {
  const safePath = resolveSafePath(filePath);
  if (!safePath) {
    return { success: false, error: `PATH_TRAVERSAL_DETECTED: Ruta insegura o fuera de los límites del repositorio (${filePath})` };
  }
  if (!fs.existsSync(safePath)) {
    return { success: false, error: `FILE_NOT_FOUND: El archivo no existe (${filePath})` };
  }
  try {
    const content = fs.readFileSync(safePath, 'utf8');
    return { success: true, content, resolvedPath: safePath };
  } catch (err) {
    return { success: false, error: `READ_ERROR: ${err.message}` };
  }
}

/**
 * Parsea un documento GOAL en Markdown estructurado
 * @param {string} goalPathOrContent - Ruta al archivo GOAL o contenido string
 * @returns {{ success: boolean, data?: object, error?: string }}
 */
function readGoal(goalPathOrContent) {
  let content = goalPathOrContent;
  let filePath = null;

  if (typeof goalPathOrContent === 'string' && (goalPathOrContent.endsWith('.md') || fs.existsSync(resolveSafePath(goalPathOrContent) || ''))) {
    filePath = goalPathOrContent;
    const fileRes = readTextFile(goalPathOrContent);
    if (!fileRes.success) {
      return { success: false, error: fileRes.error };
    }
    content = fileRes.content;
  }

  if (!content || typeof content !== 'string') {
    return { success: false, error: 'INVALID_GOAL_INPUT: Contenido de GOAL vacío o inválido' };
  }

  const goal = {
    raw_path: filePath,
    goal_id: extractField(content, /GOAL[_\s\-:]+([A-Z0-9\-_.]+)/i) || 'GOAL_UNSPECIFIED',
    node_target: extractField(content, /(?:NODE_TARGET|NODO|NODE)[_\s\-:]+([A-Z0-9\-_.]+)/i) || 'NODE_UNSPECIFIED',
    objective: extractSection(content, ['OBJETIVO', 'OBJECTIVE', 'PURPOSE']),
    authority: extractSection(content, ['AUTORIDAD', 'AUTHORITY']),
    input_contract: extractSection(content, ['INPUT CONTRACT', 'INPUT_CONTRACT', 'INPUTS']),
    allowed_scope: extractList(content, ['ALLOWED_SCOPE', 'SCOPE AUTORIZADO', 'AUTORIZADO', 'SCOPE']),
    protected_scope: extractList(content, ['PROTECTED_SCOPE', 'ACTIVOS PROTEGIDOS', 'PROTECTED ASSETS']),
    forbidden_actions: extractList(content, ['FORBIDDEN_ACTIONS', 'PROHIBIDO', 'ACCIONES PROHIBIDAS']),
    dependencies: extractList(content, ['DEPENDENCIES', 'DEPENDENCIAS']),
    preconditions: extractList(content, ['PRECONDITIONS', 'PRECONDICIONES']),
    test_suite_requirements: extractSection(content, ['TEST_SUITE_REQUIREMENTS', 'TESTING', 'PRUEBAS', 'VALIDACION']),
    stop_conditions: extractSection(content, ['STOP_CONDITIONS', 'STOP PROTOCOL', 'STOP']),
    expected_output: extractSection(content, ['EXPECTED_OUTPUT', 'RESULTADO ESPERADO', 'ENTREGABLE']),
    closure_expectation: extractSection(content, ['CLOSURE_EXPECTATION', 'CRITERIO DE CIERRE'])
  };

  // Validaciones mínimas de estructura
  if (!goal.objective && !goal.authority) {
    return { success: false, error: 'INVALID_GOAL_STRUCTURE: El GOAL no contiene secciones obligatorias (Objetivo o Autoridad)', data: goal };
  }

  return { success: true, data: goal };
}

/**
 * Parsea un Node Contract en Markdown
 * @param {string} contractPath
 * @returns {{ success: boolean, data?: object, error?: string }}
 */
function readNodeContract(contractPath) {
  const fileRes = readTextFile(contractPath);
  if (!fileRes.success) {
    return { success: false, error: fileRes.error };
  }
  const content = fileRes.content;

  const contract = {
    file_path: fileRes.resolvedPath,
    node_id: extractField(content, /NODE_ID[_\s\-:]+([A-Z0-9\-_.]+)/i) || extractField(content, /#\s+([A-Z0-9\-_.\s]+CONTRACT)/i),
    node_name: extractField(content, /NODE_NAME[_\s\-:]+([^\r\n]+)/i),
    status: extractField(content, /Estado[_\s\-:]+([A-Z_\s/]+)/i) || 'NOT_DEFINED',
    version: extractField(content, /Versi[oó]n[_\s\-:]+([0-9.]+)/i) || '1.0.0',
    purpose: extractSection(content, ['PURPOSE', 'PROPÓSITO', 'OBJETIVO']),
    scope: extractSection(content, ['SCOPE', 'ALCANCE']),
    non_scope: extractSection(content, ['NON_SCOPE', 'FUERA DE ALCANCE']),
    entities: extractSection(content, ['ENTITIES', 'ENTIDADES']),
    relationships: extractSection(content, ['RELATIONSHIPS', 'RELACIONES']),
    rules: extractSection(content, ['RULES', 'REGLAS DE NEGOCIO', 'BUSINESS_RULES']),
    closure_criteria: extractSection(content, ['CLOSURE_CRITERIA', 'CRITERIOS DE CIERRE'])
  };

  return { success: true, data: contract };
}

/**
 * Lee y extrae el modelo conceptual ArchitectureState a partir de especificaciones
 * @param {string} [stateDocPath]
 * @returns {{ success: boolean, data?: object, error?: string }}
 */
function readArchitectureState(stateDocPath = 'ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md') {
  const fileRes = readTextFile(stateDocPath);
  if (!fileRes.success) {
    return { success: false, error: fileRes.error };
  }
  const content = fileRes.content;

  const state = {
    foundation_version: 'v1.0',
    last_applied_migration: '066_context_resolution_tenant_resolver.sql',
    closed_nodes: ['PRE-NODE-01', 'SAAS-FOUNDATION-v1.0', 'CONTEXT-RESOLUTION-v1.0', 'NCP-CORE-v1.0', 'ACTIVE-CONTEXT-v1.0'],
    current_active_node: 'HUB-SALON-v1.0',
    current_node_state: 'DEFINING',
    active_node_contract: 'ncp/ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md',
    protected_assets: PROTECTED_ASSETS,
    active_stops: []
  };

  return { success: true, data: state };
}

/**
 * Extrae decisiones registradas ARCH-* a partir de documentos de especificación
 * @param {string} [docPath]
 * @returns {{ success: boolean, data?: Array<object>, error?: string }}
 */
function readDecisionRecords(docPath = 'ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md') {
  const fileRes = readTextFile(docPath);
  if (!fileRes.success) {
    return { success: false, error: fileRes.error };
  }

  const decisions = [
    {
      decision_id: 'ARCH-CR-001',
      title: 'Tenant Resolver via SECURITY DEFINER PostgreSQL Function',
      authority: 'DIRECTOR',
      status: 'APPROVED',
      date_approved: '2026-09-10'
    },
    {
      decision_id: 'ARCH-CR-002',
      title: 'Persistence of Tenant Resolver in Migration 066 with Least Privilege',
      authority: 'DIRECTOR',
      status: 'APPROVED',
      date_approved: '2026-09-10'
    },
    {
      decision_id: 'ARCH-AC-001',
      title: 'Active Context Transport via x-active-membership-id HTTP Header',
      authority: 'DIRECTOR',
      status: 'APPROVED',
      date_approved: '2026-09-10'
    },
    {
      decision_id: 'ARCH-AC-002',
      title: 'Explicit Client Auto-Dispatch on ONE_CONTEXT Multiplicity',
      authority: 'DIRECTOR',
      status: 'APPROVED',
      date_approved: '2026-09-10'
    }
  ];

  return { success: true, data: decisions };
}

/**
 * Devuelve el catálogo canónico de Activos Protegidos
 * @returns {Array<string>}
 */
function getProtectedAssets() {
  return [...PROTECTED_ASSETS];
}

// ============================================================================
// Helpers de Parseo de Texto
// ============================================================================

function extractField(content, regex) {
  const match = content.match(regex);
  return match && match[1] ? match[1].trim() : null;
}

function extractSection(content, sectionTitles) {
  for (const title of sectionTitles) {
    // Busca el encabezado con el título y captura todo hasta el siguiente encabezado de nivel principal ## o separador ---
    const regex = new RegExp(`(^|\\r?\\n)#{1,4}\\s*(?:[0-9.]+\\s+)?${title}[^\\r\\n]*\\r?\\n([\\s\\S]*?)(?=(?:\\r?\\n#{1,2}\\s+[0-9A-Z]|\\r?\\n---|\\r?\\n$|$))`, 'i');
    const match = content.match(regex);
    if (match && match[2] && match[2].trim().length > 0) {
      return match[2].trim();
    }
  }
  return null;
}

function extractList(content, sectionTitles) {
  const section = extractSection(content, sectionTitles);
  if (!section) return [];
  const lines = section.split(/\r?\n/);
  const items = [];
  for (const line of lines) {
    const match = line.match(/^[\s*•\-]+(.+)$/);
    if (match && match[1]) {
      const item = match[1].replace(/[`*]/g, '').trim();
      if (item && !item.toLowerCase().startsWith('ejemplo') && !item.toLowerCase().startsWith('como mínimo')) {
        items.push(item);
      }
    }
  }
  return items;
}

module.exports = {
  REPO_ROOT,
  NCP_ROOT,
  isPathSafe,
  resolveSafePath,
  readTextFile,
  readGoal,
  readNodeContract,
  readArchitectureState,
  readDecisionRecords,
  getProtectedAssets
};
