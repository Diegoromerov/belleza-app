// backend/src/services/beautyKnowledgeService.js
const axios = require('axios');
const { pool } = require('../config/db');
require('dotenv').config();

// Configuración de proveedor de embeddings
const EMBEDDING_PROVIDER = process.env.EMBEDDING_PROVIDER || 'nvidia'; 
const ENABLE_BEAUTY_RAG = process.env.ENABLE_BEAUTY_RAG === 'true';

// Configuración NVIDIA NIM
// 1. Tomamos la variable de entorno o usamos el default
const RAW_NVIDIA_URL = process.env.NVIDIA_EMBED_URL || 'https://integrate.api.nvidia.com/v1';

// 2. TRUCO DE SEGURIDAD: Eliminamos '/embeddings' si ya viene al final, para evitar duplicados
const NVIDIA_BASE_URL = RAW_NVIDIA_URL.replace(/\/embeddings$/, '');

const NVIDIA_EMBEDDING_MODEL = process.env.NVIDIA_EMBEDDING_MODEL || 'nvidia/nv-embedqa-e5-v5';
const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;

/**
 * Genera embedding usando NVIDIA AI Foundation Models API (NIM)
 * Especificación oficial: https://integrate.api.nvidia.com/v1/embeddings
 */
async function generateNvidiaEmbedding(text) {
  if (!NVIDIA_API_KEY) {
    throw new Error('NVIDIA_API_KEY no configurada');
  }

  try {
    // Usamos la constante limpia definida arriba para evitar duplicar '/embeddings'
    const url = `${NVIDIA_BASE_URL}/embeddings`;
    
    const response = await axios.post(
      url,
      { 
        input: [text.slice(0, 8000)], // La API de NVIDIA exige un array de strings
        model: NVIDIA_EMBEDDING_MODEL, 
        encoding_format: 'float',
        input_type: 'query' // CRÍTICO para modelos asimétricos como E5
      },
      { 
        timeout: 15000,
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${NVIDIA_API_KEY}`
        }
      }
    );
    
    // Validar estructura de respuesta
    if (!response.data?.data?.[0]?.embedding) {
      throw new Error('Respuesta NVIDIA inválida: ' + JSON.stringify(response.data));
    }
    
    return response.data.data[0].embedding;
  } catch (error) {
    // Log detallado para debug inmediato en Railway
    if (error.response) {
      console.error('❌ NVIDIA Embedding HTTP Error:', {
        status: error.response.status,
        statusText: error.response.statusText,
        data: error.response.data,
        sentPayload: {
          model: NVIDIA_EMBEDDING_MODEL,
          input: text.slice(0, 100) + '...',
          encoding_format: 'float',
          input_type: 'query',
          url_used: url
        }
      });
    } else {
      console.error('❌ NVIDIA Embedding Network Error:', error.message);
    }
    throw error;
  }
}

/**
 * Embedding dummy determinístico para fallback
 */
function generateDummyEmbedding(text) {
  const hash = require('crypto').createHash('sha256').update(text).digest();
  const embedding = new Array(1024).fill(0).map((_, i) => {
    return (hash[i % 32] / 255 - 0.5) * 0.01;
  });
  const norm = Math.sqrt(embedding.reduce((sum, v) => sum + v * v, 0));
  return embedding.map(v => v / norm);
}

/**
 * Genera embedding según proveedor configurado con Circuit Breaker
 */
let nvidiaFailureCount = 0;
const MAX_NVIDIA_FAILURES = 3;

async function generateEmbedding(text) {
  if (nvidiaFailureCount < MAX_NVIDIA_FAILURES) {
    try {
      const embedding = await generateNvidiaEmbedding(text);
      nvidiaFailureCount = 0; // Reset en éxito
      return embedding;
    } catch (error) {
      nvidiaFailureCount++;
      console.warn(`⚠️ NVIDIA Embedding fallo #${nvidiaFailureCount}/${MAX_NVIDIA_FAILURES}.`);
      if (nvidiaFailureCount >= MAX_NVIDIA_FAILURES) {
        console.error('🔴 NVIDIA Circuit breaker OPEN.');
      }
      return generateDummyEmbedding(text);
    }
  }
  return generateDummyEmbedding(text);
}

/**
 * Busca chunks de conocimiento de belleza relevantes
 */
async function searchBeautyKnowledge(query, topK = 3, threshold = 0.7) {
  if (!ENABLE_BEAUTY_RAG) {
    return [];
  }
  
  try {
    const embedding = await generateEmbedding(query);
    const vector = `[${embedding.join(',')}]`;
    
    // FIX: Nombre de tabla correcto -> aura_knowledge_chunks
    const sql = `
      SELECT 
        content,
        source_type,
        source_id,
        title,
        metadata,
        1 - (embedding <=> $1::vector) as similarity
      FROM aura_knowledge_chunks
      WHERE 1 - (embedding <=> $1::vector) > $2
      ORDER BY embedding <=> $1::vector
      LIMIT $3
    `;
    
    const res = await pool.query(sql, [vector, threshold, topK]);
    
    console.log(`🔍 Beauty RAG: ${res.rows.length} chunks encontrados.`);
    
    return res.rows.map(row => ({
      content: row.content,
      sourceType: row.source_type,
      sourceId: row.source_id,
      title: row.title,
      metadata: row.metadata,
      similarity: parseFloat(row.similarity),
    }));
    
  } catch (error) {
    console.error('❌ Error en searchBeautyKnowledge:', error.message);
    return [];
  }
}

/**
 * Formatea chunks para inyección en system prompt
 */
function formatKnowledgeContext(chunks) {
  if (!chunks || chunks.length === 0) return '';
  
  return chunks.map((chunk, i) => {
    const source = chunk.title || chunk.sourceType || 'conocimiento';
    return `[Fuente ${i + 1}: ${source}] ${chunk.content}`;
  }).join('\n\n');
}

module.exports = {
  searchBeautyKnowledge,
  formatKnowledgeContext,
  ENABLE_BEAUTY_RAG,
};