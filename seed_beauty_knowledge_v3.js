const axios = require('axios');
require('dotenv').config();

// Configuración para NVIDIA NIM
const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY; // Obténla en build.nvidia.com
const EMBEDDING_MODEL = 'nvidia/nv-embedqa-e5-v5'; // Modelo de embedding de alta calidad
const EMBEDDING_URL = 'https://integrate.api.nvidia.com/v1/embeddings';

async function generateEmbedding(text) {
  try {
    const response = await axios.post(
      EMBEDDING_URL,
      { 
        model: EMBEDDING_MODEL, 
        input: text,
        encoding_format: "float" 
      },
      { 
        headers: { 
          'Authorization': `Bearer ${NVIDIA_API_KEY}`, 
          'Content-Type': 'application/json' 
        } 
      }
    );
    // NVIDIA devuelve el vector en data[0].embedding
    return response.data.data[0].embedding;
  } catch (error) {
    console.error(`❌ Error generando embedding con NVIDIA:`, error.response?.data || error.message);
    return null;
  }
}