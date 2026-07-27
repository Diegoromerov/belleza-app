// backend/src/services/ragService.js
const { pool } = require('../config/db');

/**
 * Diccionario estático de conocimiento de belleza y rutinas para fallback instantáneo RAG
 */
const BEAUTY_KNOWLEDGE_BASE = [
  {
    category: 'piel',
    keywords: ['piel grasa', 'brillo', 'poros', 'acne', 'sebo'],
    advice: 'Para piel grasa o seborreica: Limpia el rostro 2 veces al día con gel limpiador con ácido salicílico. Aplica suero de Niacinamida 10% para regular el sebo y usa gel hidratante oil-free con ácido hialurónico. No olvides protector solar toque seco.'
  },
  {
    category: 'piel',
    keywords: ['piel seca', 'desquamacion', 'tirantez', 'deshidratacion'],
    advice: 'Para piel seca o deshidratada: Usa limpiador cremoso sin sulfatos. Aplica crema hidratante con ceramidas, ácidos grasos y ácido hialurónico sobre la piel húmeda. Evita el agua muy caliente en el rostro.'
  },
  {
    category: 'cabello',
    keywords: ['frizz', 'cabello seco', 'puntas abiertas', 'dañado'],
    advice: 'Para combatir el frizz y la sequedad capilar: Aplica mascarilla nutritiva con aceite de argán o keratina 1 vez por semana. Usa termo-protector antes del secador/plancha y finaliza con óleo de medios a puntas.'
  },
  {
    category: 'cejas',
    keywords: ['visajismo', 'cejas', 'laminado', 'microblading', 'diseño'],
    advice: 'El visagismo de cejas analiza la estructura ósea del rostro (distancia interpupilar, arco de la frente) para definir el diseño óptimo. Se recomienda mantenimiento cada 15 a 21 días.'
  },
  {
    category: 'uñas',
    keywords: ['semipermanente', 'quebradizas', 'cuticula', 'manicura'],
    advice: 'Para uñas quebradizas o frágiles: Hidrata las cutículas diariamente con aceite de almendras o jojoba. Usa base fortalecedora con calcio y toma descansos entre retirados de gel semipermanente.'
  }
];

/**
 * Busca conocimiento técnico de belleza usando pgvector (si existe) o fallback semántico
 */
async function searchBeautyKnowledge(queryText, category) {
  try {
    // Intentar consulta pgvector si la tabla existe
    const pgRes = await pool.query(
      `SELECT title, category, content 
       FROM beauty_knowledge_embeddings 
       WHERE category = $1 OR LOWER(content) LIKE $2 
       LIMIT 3;`,
      [category || 'piel', `%${(queryText || '').toLowerCase()}%`]
    ).catch(() => null);

    if (pgRes && pgRes.rows.length > 0) {
      return pgRes.rows.map(r => r.content).join('\n---\n');
    }
  } catch (err) {
    console.warn('⚠️ pgvector query fallback:', err.message);
  }

  // Fallback a base de conocimiento estructurada
  const lowerQuery = (queryText || '').toLowerCase();
  const matched = BEAUTY_KNOWLEDGE_BASE.filter(item => 
    item.keywords.some(kw => lowerQuery.includes(kw)) || (category && item.category === category.toLowerCase())
  );

  if (matched.length > 0) {
    return matched.map(m => m.advice).join('\n');
  }

  return 'Mantén una rutina de limpieza diaria suave, hidratación constante según tu tipo de piel y protección solar FPS 50+ todos los días.';
}

module.exports = {
  searchBeautyKnowledge,
  BEAUTY_KNOWLEDGE_BASE
};
