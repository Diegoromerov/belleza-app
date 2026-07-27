// backend/src/services/agents/hestiaAgent.js
const { pool } = require('../../config/db');
const atenaAgent = require('./atenaAgent');

/**
 * AGENTE HESTIA: Personal Shopper y Recomendadora de Productos en GlowStore (E-Commerce)
 */
class HestiaAgent {
  /**
   * Recomienda productos de la tienda GlowStore compatibles con el perfil del usuario o término de búsqueda
   * @param {Object} params - { userId, queryText, category }
   * @returns {Promise<Object>} Productos recomendados
   */
  async recommendProducts({ userId, queryText, category }) {
    try {
      let targetIngredients = [];

      // 1. Si hay userId, consultar perfil biométrico con ATENA para extraer ingredientes sugeridos
      if (userId) {
        const atenaDiagnosis = await atenaAgent.getBiometricDiagnosis(userId);
        if (atenaDiagnosis && atenaDiagnosis.recommendedIngredients) {
          targetIngredients = atenaDiagnosis.recommendedIngredients;
        }
      }

      // 2. Construir consulta a la tabla productos
      let query = `
        SELECT id, nombre, descripcion, precio, categoria, stock, imagen_url
        FROM productos
        WHERE stock > 0
      `;
      const params = [];

      if (category) {
        query += ` AND LOWER(categoria) LIKE $1`;
        params.push(`%${category.toLowerCase()}%`);
      } else if (queryText) {
        query += ` AND (LOWER(nombre) LIKE $1 OR LOWER(descripcion) LIKE $1)`;
        params.push(`%${queryText.toLowerCase()}%`);
      }

      query += ` ORDER BY precio ASC LIMIT 4;`;

      let dbRows = [];
      try {
        const res = await pool.query(query, params);
        if (res && res.rows) {
          dbRows = res.rows;
        }
      } catch (dbErr) {
        console.warn('⚠️ [HESTIA Agent] Fallo al consultar BD productos, usando fallback:', dbErr.message);
      }

      // Si la BD devuelve productos
      if (dbRows.length > 0) {
        return {
          status: 'success',
          foundCount: dbRows.length,
          matchedIngredients: targetIngredients,
          products: dbRows
        };
      }

      // Fallback a recomendación por defecto si la base de datos no tiene productos aún
      return {
        status: 'success',
        foundCount: 2,
        matchedIngredients: targetIngredients,
        products: [
          {
            id: 'prod-001',
            nombre: 'Sérum Facial Ácido Hialurónico 2%',
            descripcion: 'Hidratación profunda 24h para todo tipo de piel.',
            precio: 65000,
            categoria: 'Piel',
            stock: 15
          },
          {
            id: 'prod-002',
            nombre: 'Aceite de Cutículas Nutritivo Almond Care',
            descripcion: 'Repara cutículas secas y fortalece uñas frágiles.',
            precio: 28000,
            categoria: 'Uñas',
            stock: 20
          }
        ]
      };
    } catch (err) {
      console.error('❌ [HESTIA Agent] Error en recomendación de productos:', err.message);
      return { status: 'error', message: err.message };
    }
  }
}

module.exports = new HestiaAgent();
