/**
 * backend/src/config/knowledgeCategories.js
 * Vocabulario canónico de categorías de la base de conocimiento de Aura.
 *
 * Fuente: `SELECT DISTINCT category FROM beauty_knowledge_embeddings` sobre el corpus
 * canónico (5.619 chunks, 12 dominios). Es la ÚNICA lista válida para `filters.category`:
 * el corpus NO usa etiquetas humanas ("Piel", "Cabello", "Uñas") sino estos slugs.
 *
 * Se usa en dos puntos:
 *   1. `auraToolExecutor` — enum del tool, para que el LLM elija un valor válido.
 *   2. `ragService` — validación defensiva: un valor fuera de este vocabulario NO se
 *      aplica como filtro (fail-open) en vez de devolver 0 filas en silencio.
 *
 * Si el corpus cambia, actualizar aquí: el test `knowledgeCategories.test.js` compara
 * esta lista contra la base de datos cuando hay conexión disponible.
 */

const KNOWLEDGE_CATEGORIES = Object.freeze([
  'colorimetria_capilar_tinte',
  'colorimetria_piel_undertone',
  'cuidado_corporal_y_spa',
  'diagnostico_capilar',
  'guias_unas',
  'ingredientes_activos_contraindicaciones',
  'maquillaje_tecnicas_por_ocasion',
  'skincare_rutinas_por_tipo_piel',
  'tendencias_belleza_virales',
  'textura_poros',
  'tratamientos_esteticos_faciales',
  'visajismo_cejas_microblading',
]);

const KNOWLEDGE_CATEGORY_SET = new Set(KNOWLEDGE_CATEGORIES);

/**
 * Normaliza una etiqueta para compararla con el vocabulario canónico.
 * Acepta variantes con mayúsculas, acentos o espacios ("Guías Uñas" → "guias_unas").
 * NO traduce etiquetas humanas a categorías (no existe un mapeo 1:1: "Cabello" puede ser
 * `diagnostico_capilar`, `colorimetria_capilar_tinte` o `tendencias_belleza_virales`).
 *
 * @param {string} value
 * @returns {string} valor normalizado
 */
function normalizeCategory(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '_');
}

/**
 * Devuelve la categoría canónica si el valor es reconocible, o null si no pertenece
 * al vocabulario (en ese caso el llamador NO debe filtrar).
 *
 * @param {string} value
 * @returns {string|null}
 */
function resolveCategory(value) {
  if (!value) return null;
  const normalized = normalizeCategory(value);
  return KNOWLEDGE_CATEGORY_SET.has(normalized) ? normalized : null;
}

/**
 * Diccionario de sinónimos dialectales colombianos y jerga técnica de estética.
 * Mapea términos populares a su equivalente técnico/clínico para enriquecer las consultas RAG.
 */
const COLOMBIAN_BEAUTY_SYNONYMS = Object.freeze({
  repolarizacion: 'tratamiento lipidico capilar restaurador reestructurante',
  repolarizado: 'tratamiento lipidico capilar restaurador reestructurante',
  repolarizador: 'tratamiento lipidico capilar restaurador reestructurante',
  'retoque de raiz': 'mantenimiento pigmentario colorimetria capilar',
  'repitiendo tinte': 'mantenimiento pigmentario colorimetria capilar',
  keratina: 'alisado queratina formaldehido bioseguridad capilar',
  queratina: 'alisado queratina formaldehido bioseguridad capilar',
  'alisado progresivo': 'alisado queratina formaldehido bioseguridad capilar',
  barboterapia: 'barberia protocolo higienico barboterapia dermo-facial',
  'perfilado de cejas': 'visajismo cejas microblading micropigmentacion',
  microblading: 'visajismo cejas microblading micropigmentacion',
  despigmentacion: 'melasma hiperpigmentacion despigmentante hidroquinona acido kojico',
  manchas: 'hiperpigmentacion melasma fotodano acido tranexamico',
  paño: 'melasma hiperpigmentacion cloasma',
  boticario: 'cosmetovigilancia formula magistral bioseguridad',
  cepillado: 'termo-proteccion capilar cepillado secador',
  blower: 'termo-proteccion capilar cepillado secador',
  espinillas: 'comedones acne papulopustuloso acido salicilico',
  barritos: 'acne comedoniano papulopustuloso',
  'talones agrietados': 'podologia hiperqueratosis plantar exfoliacion urea',
  'pies resecos': 'podologia hiperqueratosis plantar hidratacion urea',
});

/**
 * Enriquece la consulta del usuario agregando términos técnicos si detecta modismos colombianos.
 * @param {string} queryText
 * @returns {string} Consulta enriquecida
 */
function expandColombianBeautySynonyms(queryText) {
  if (!queryText || typeof queryText !== 'string') return queryText || '';
  const lower = queryText.toLowerCase();
  const additions = [];

  for (const [key, expansion] of Object.entries(COLOMBIAN_BEAUTY_SYNONYMS)) {
    if (lower.includes(key) && !lower.includes(expansion)) {
      additions.push(expansion);
    }
  }

  if (additions.length === 0) return queryText;
  return `${queryText} ${additions.join(' ')}`;
}

/**
 * Devuelve un umbral de similitud adaptativo según la categoría o severidad del dominio.
 * - Dominios de seguridad/clínica requieren mayor precisión (0.35).
 * - Dominios creativos/virales usan mayor cobertura (0.25).
 * @param {string} category
 * @returns {number} Threshold (0.25 - 0.35)
 */
function getAdaptiveThreshold(category) {
  const cat = resolveCategory(category);
  if (!cat) return 0.30;

  const STRICT_CATEGORIES = new Set([
    'ingredientes_activos_contraindicaciones',
    'diagnostico_capilar',
    'visajismo_cejas_microblading',
  ]);

  const RELAXED_CATEGORIES = new Set([
    'tendencias_belleza_virales',
    'maquillaje_tecnicas_por_ocasion',
  ]);

  if (STRICT_CATEGORIES.has(cat)) return 0.35;
  if (RELAXED_CATEGORIES.has(cat)) return 0.25;
  return 0.30;
}

module.exports = {
  KNOWLEDGE_CATEGORIES,
  COLOMBIAN_BEAUTY_SYNONYMS,
  normalizeCategory,
  resolveCategory,
  expandColombianBeautySynonyms,
  getAdaptiveThreshold,
};

