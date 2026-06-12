// backend/src/controllers/designsController.js
const { GoogleGenerativeAI } = require('@google/generative-ai');
const path = require('path');
require('dotenv').config();

const MOCK_NAIL_IMAGES = [
  {
    title: 'Uñas Rojas Elegantes',
    image_url: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=600&auto=format&fit=crop',
    link: 'https://pinterest.com/pin/mock_red_nails'
  },
  {
    title: 'Diseño Rosa Pastel con Brillos',
    image_url: 'https://images.unsplash.com/photo-1632345031435-8797b2d58045?q=80&w=600&auto=format&fit=crop',
    link: 'https://pinterest.com/pin/mock_pink_nails'
  },
  {
    title: 'Manicura Nude Minimalista',
    image_url: 'https://images.unsplash.com/photo-1607779097040-26e80aa78e66?q=80&w=600&auto=format&fit=crop',
    link: 'https://pinterest.com/pin/mock_nude_nails'
  },
  {
    title: 'Uñas Esculpidas Glamour',
    image_url: 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=600&auto=format&fit=crop',
    link: 'https://pinterest.com/pin/mock_glam_nails'
  },
  {
    title: 'Uñas Decoradas Tendencia',
    image_url: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=600&auto=format&fit=crop',
    link: 'https://pinterest.com/pin/mock_decorated_nails'
  },
  {
    title: 'Nail Art Francés Moderno',
    image_url: 'https://images.unsplash.com/photo-1629732047847-50b7ef46c3bb?q=80&w=600&auto=format&fit=crop',
    link: 'https://pinterest.com/pin/mock_french_nails'
  }
];

const MOCK_FACE_ANALYSIS = {
  face_shape: 'Ovalado',
  explanation: 'El rostro ovalado es considerado la forma más simétrica y versátil. Le beneficia casi cualquier tipo de corte, especialmente los que despejan las facciones y añaden movimiento lateral.',
  recommended_cuts: [
    { name: 'Corte Shag Capas Suaves', reason: 'Añade textura y volumen natural sin alterar la simetría.' },
    { name: 'Bob Clásico Desfilado', reason: 'Enmarca perfectamente la mandíbula y define los pómulos.' },
    { name: 'Flequillo Abierto (Curtain Bangs)', reason: 'Aporta frescura y resalta la mirada de forma sofisticada.' }
  ],
  pinterest_query: 'cortes de cabello rostro ovalado mujer'
};

// Inicializar el cliente de la API de Gemini
const apiKey = process.env.GEMINI_API_KEY;
const ai = apiKey ? new GoogleGenerativeAI(apiKey) : null;

// Función helper para buscar imágenes reales de Pinterest usando DuckDuckGo sin llaves
const searchRealPinterestImages = async (query) => {
  const oldTlsConfig = process.env.NODE_TLS_REJECT_UNAUTHORIZED;
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
  
  try {
    const searchQuery = `${query} uñas manicure site:pinterest.com`;
    const url = `https://duckduckgo.com/?q=${encodeURIComponent(searchQuery)}`;
    
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    
    if (!response.ok) return null;
    
    const html = await response.text();
    const vqdRegex = /vqd=([^&'"]+)/;
    const match = html.match(vqdRegex);
    
    let vqd = null;
    if (match) {
      vqd = match[1];
    } else {
      const vqdRegex2 = /vqd\s*=\s*['"]([^'"]+)['"]/;
      const match2 = html.match(vqdRegex2);
      if (match2) vqd = match2[1];
    }

    if (!vqd) return null;

    const searchUrl = `https://duckduckgo.com/i.js?q=${encodeURIComponent(searchQuery)}&o=json&vqd=${vqd}&f=,,,`;
    const imageResponse = await fetch(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://duckduckgo.com/'
      }
    });

    if (!imageResponse.ok) return null;

    const data = await imageResponse.json();
    if (!data.results || data.results.length === 0) return [];

    return data.results.slice(0, 6).map(item => ({
      title: item.title || 'Diseño de uñas',
      image_url: item.image,
      link: item.url || 'https://pinterest.com'
    }));

  } catch (err) {
    console.error('⚠️ Error buscando en DuckDuckGo:', err.message);
    return null;
  } finally {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = oldTlsConfig;
  }
};

exports.searchPinterestDesigns = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.status(400).json({ error: 'El parámetro de búsqueda "q" es obligatorio' });
    }

    const apiKey = process.env.GOOGLE_SEARCH_API_KEY;
    const cx = process.env.GOOGLE_SEARCH_CX;

    if (!apiKey || !cx) {
      console.log('🔍 Buscando imágenes reales de Pinterest mediante motor alternativo...');
      const realImages = await searchRealPinterestImages(q);
      
      if (realImages && realImages.length > 0) {
        return res.status(200).json({
          success: true,
          source: 'ddg-pinterest',
          data: realImages
        });
      }

      console.log('⚠️ Búsqueda alternativa falló o fue bloqueada. Usando datos de prueba.');
      const queryLower = q.toLowerCase();
      let filteredMocks = MOCK_NAIL_IMAGES;
      
      if (queryLower.includes('rojo') || queryLower.includes('roja')) {
        filteredMocks = [
          MOCK_NAIL_IMAGES[0],
          ...MOCK_NAIL_IMAGES.slice(1, 6)
        ];
      } else if (queryLower.includes('rosa') || queryLower.includes('past')) {
        filteredMocks = [
          MOCK_NAIL_IMAGES[1],
          ...MOCK_NAIL_IMAGES.slice(0, 1),
          ...MOCK_NAIL_IMAGES.slice(2, 6)
        ];
      }
      
      return res.status(200).json({
        success: true,
        source: 'mock',
        data: filteredMocks.slice(0, 6)
      });
    }

    const searchQuery = `${q} uñas manicure site:pinterest.com`;
    const searchUrl = `https://www.googleapis.com/customsearch/v1?key=${apiKey}&cx=${cx}&q=${encodeURIComponent(searchQuery)}&searchType=image&num=6`;

    const response = await fetch(searchUrl);
    if (!response.ok) {
      throw new Error(`Google Search API responded with status: ${response.status}`);
    }

    const searchData = await response.json();
    
    if (!searchData.items || searchData.items.length === 0) {
      return res.status(200).json({
        success: true,
        source: 'google',
        data: []
      });
    }

    const formattedResults = searchData.items.map(item => ({
      title: item.title || 'Diseño de uñas',
      image_url: item.link, 
      link: item.image?.contextLink || 'https://pinterest.com'
    }));

    return res.status(200).json({
      success: true,
      source: 'google',
      data: formattedResults
    });

  } catch (error) {
    console.error('❌ ERROR AL BUSCAR DISEÑOS:', error.message);
    res.status(500).json({ error: 'Error al buscar ideas de diseños' });
  }
};

exports.analyzeFaceShape = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Es obligatorio subir una foto de rostro en el campo "image".' });
    }

    // Si no hay API Key de Gemini, devolvemos el Mock inmediato
    if (!ai) {
      console.warn('⚠️ GEMINI_API_KEY no configurada. Retornando análisis de rostro simulado.');
      return res.status(200).json({
        success: true,
        source: 'mock',
        analysis: MOCK_FACE_ANALYSIS
      });
    }

    const fileBuffer = req.file.buffer;
    let mimeType = req.file.mimetype;

    // Detectar mimetype si es genérico
    if (!mimeType || mimeType === 'application/octet-stream') {
      const ext = path.extname(req.file.originalname || '').toLowerCase();
      if (ext === '.png') {
        mimeType = 'image/png';
      } else if (ext === '.webp') {
        mimeType = 'image/webp';
      } else if (ext === '.gif') {
        mimeType = 'image/gif';
      } else {
        mimeType = 'image/jpeg';
      }
    }

    const imagePart = {
      inlineData: {
        data: fileBuffer.toString('base64'),
        mimeType
      }
    };

    const prompt = `Analiza detenidamente la forma del rostro de la persona en esta imagen.
Dime qué tipo de rostro tiene (Ovalado, Redondo, Cuadrado, Corazón, Diamante, Alargado).
Recomienda 3 cortes de cabello específicos para este tipo de rostro.
Genera una consulta de búsqueda en español óptima de no más de 6 palabras para buscar ideas visuales de estos cortes de cabello en Pinterest (por ejemplo, "cortes de cabello para rostro redondo").
Responde de manera obligatoria únicamente con un objeto JSON válido, sin formato markdown (sin bloques de código \`\`\`json) y sin caracteres adicionales, usando este formato exacto:
{
  "face_shape": "Tipo de rostro",
  "explanation": "Breve explicación de por qué y qué le beneficia",
  "recommended_cuts": [
    { "name": "Nombre del corte", "reason": "Razón corta de la recomendación" },
    { "name": "Nombre del corte 2", "reason": "Razón corta de la recomendación" },
    { "name": "Nombre del corte 3", "reason": "Razón corta de la recomendación" }
  ],
  "pinterest_query": "consulta de búsqueda para pinterest"
}`;

    const model = ai.getGenerativeModel({ model: 'gemini-2.5-flash' });
    const result = await model.generateContent({
      contents: [
        {
          role: 'user',
          parts: [
            { text: prompt },
            imagePart
          ]
        }
      ]
    });
    const response = await result.response;
    
    let text = response.text().trim();
    
    // Limpieza de formato markdown de bloques de código en caso de que Gemini los retorne
    if (text.startsWith('```json')) {
      text = text.substring(7, text.length - 3).trim();
    } else if (text.startsWith('```')) {
      text = text.substring(3, text.length - 3).trim();
    }

    let analysisJson;
    try {
      analysisJson = JSON.parse(text);
    } catch (parseErr) {
      console.error('Error al parsear respuesta JSON de Gemini:', text);
      throw new Error('La IA no retornó un formato JSON válido.');
    }

    return res.status(200).json({
      success: true,
      source: 'gemini',
      analysis: analysisJson
    });

  } catch (error) {
    console.error('❌ ERROR ANALIZANDO ROSTRO:', error.message);
    res.status(500).json({ 
      error: 'Error al analizar la forma del rostro con IA',
      details: error.message 
    });
  }
};
