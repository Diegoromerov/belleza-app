const { GoogleGenerativeAI } = require('@google/generative-ai');
const path = require('path');
require('dotenv').config();
const { pool } = require('../config/db');

const saveAnalysisToDb = async (userId, toolType, resultData) => {
  if (!userId) return;
  try {
    const query = `
      INSERT INTO ai_diagnostics (user_id, tool_type, result_data)
      VALUES ($1, $2, $3);
    `;
    await pool.query(query, [userId, toolType, JSON.stringify(resultData)]);
    console.log(`💾 [DB] Guardado historial de IA (${toolType}) para usuario ${userId}`);
  } catch (err) {
    console.error('⚠️ [DB ERROR] Error guardando historial de IA:', err.message);
  }
};

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
      if (req.user && req.user.id) {
        await saveAnalysisToDb(req.user.id, 'eyebrow-visagism', MOCK_FACE_ANALYSIS);
      }
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
      // Garantizar purga incluso si falla el parseo
      if (req.file && req.file.buffer) req.file.buffer.fill(0);
      throw new Error('La IA no retornó un formato JSON válido.');
    }

    // Purga criptográfica inmediata de la imagen del buffer en memoria RAM
    if (req.file && req.file.buffer) {
      req.file.buffer.fill(0);
    }

    if (req.user && req.user.id) {
      await saveAnalysisToDb(req.user.id, 'eyebrow-visagism', analysisJson);
    }

    return res.status(200).json({
      success: true,
      source: 'gemini',
      analysis: analysisJson
    });

  } catch (error) {
    // Garantizar purga en caso de excepciones
    if (req.file && req.file.buffer) {
      try { req.file.buffer.fill(0); } catch (e) {}
    }
    console.error('❌ ERROR ANALIZANDO ROSTRO:', error.message);
    res.status(500).json({ 
      error: 'Error al analizar la forma del rostro con IA',
      details: error.message 
    });
  }
};

exports.analyzeDesign = async (req, res) => {
  try {
    const { type } = req.body;
    if (!req.file) {
      return res.status(400).json({ error: 'Es obligatorio subir una imagen para el análisis.' });
    }
    if (!type) {
      return res.status(400).json({ error: 'El campo "type" es obligatorio para identificar el análisis.' });
    }

    // Mock responses in case Gemini API is not configured
    if (!ai) {
      console.warn(`⚠️ GEMINI_API_KEY no configurada. Retornando análisis simulado para "${type}".`);
      let mockResult = {};
      if (type === 'skin-tone') {
        mockResult = {
          undertone: "Frío",
          skin_tone: "Medio Claro",
          explanation: "Tu subtono de piel es frío, lo que significa que los colores con base azul o rosa resaltan tu luminosidad natural de forma espectacular.",
          recommended_colors: ["Rosa Pastel", "Azul Marino", "Gris Perla", "Rojo Cereza"],
          pinterest_query: "paleta de colores invierno frio ropa maquillaje"
        };
      } else if (type === 'hair-diagnostic') {
        mockResult = {
          damage_level: "Medio",
          scalp_status: "Seco",
          explanation: "Se observa cierta deshidratación en la hebra capilar con puntas abiertas leves, lo que sugiere una pérdida moderada de humedad y lípidos naturales.",
          recommended_treatments: ["Mascarilla ultra-hidratante de argán", "Cauterización capilar con queratina", "Uso de sérum reparador de puntas"],
          pinterest_query: "tratamiento hidratacion cabello antes y despues"
        };
      } else if (type === 'skin-texture') {
        mockResult = {
          skin_type: "Mixta",
          pore_status: "Dilatado en zona T",
          explanation: "Tu piel muestra una ligera acumulación de sebo en la frente y nariz (Zona T) con poros algo más visibles, mientras que las mejillas tienden a estar normales o secas.",
          recommended_routine: ["Limpiador facial espumoso con ácido salicílico", "Tónico equilibrante sin alcohol", "Sérum con Niacinamida para control de poros"],
          pinterest_query: "rutina skincare poros dilatados zona t"
        };
      } else if (type === 'eyebrow-visagism') {
        mockResult = {
          face_proportions: "Rostro Ovalado / Equilibrado",
          eyebrow_shape: "Arqueada Suave",
          explanation: "Dadas las proporciones equilibradas de tu rostro, una ceja con arco suave y grosor natural ayuda a enmarcar tus ojos sin endurecer tu mirada.",
          recommended_designs: ["Depilación con hilo para definición limpia", "Sombreado temporal con Henna", "Laminado de cejas orgánicas"],
          pinterest_query: "diseno cejas naturales rostro ovalado"
        };
      } else if (type === 'nails-style') {
        mockResult = {
          finger_proportion: "Dedos alargados y estilizados",
          skin_undertone: "Cálido",
          recommended_shapes: ["Almendra", "Ovalada", "Semi-cuadrada"],
          recommended_colors: ["Nude beige", "Rojo terracota", "Glitter dorado"],
          pinterest_query: "unas almendradas color nude beige"
        };
      } else {
        return res.status(400).json({ error: `Tipo de análisis "${type}" no reconocido.` });
      }

      if (req.user && req.user.id) {
        await saveAnalysisToDb(req.user.id, type, mockResult);
      }

      return res.status(200).json({
        success: true,
        source: 'mock',
        analysis: mockResult
      });
    }

    const fileBuffer = req.file.buffer;
    let mimeType = req.file.mimetype;

    if (!mimeType || mimeType === 'application/octet-stream') {
      const ext = path.extname(req.file.originalname || '').toLowerCase();
      if (ext === '.png') mimeType = 'image/png';
      else if (ext === '.webp') mimeType = 'image/webp';
      else if (ext === '.gif') mimeType = 'image/gif';
      else mimeType = 'image/jpeg';
    }

    const imagePart = {
      inlineData: {
        data: fileBuffer.toString('base64'),
        mimeType
      }
    };

    let prompt = '';
    let jsonTemplate = '';

    if (type === 'skin-tone') {
      prompt = `Analiza detalladamente la colorimetría de la piel en esta foto de rostro.
Identifica el subtono de piel (Cálido, Frío o Neutro) y el tono general (Claro, Medio, Oscuro).
Proporciona una explicación detallada sobre qué colores de cabello, prendas y maquillaje le favorecen según su estación de color.
Sugiere una lista de 4 colores específicos recomendados.
Genera una consulta corta (máximo 6 palabras) en español para buscar paletas de color inspiracionales en Pinterest.`;
      jsonTemplate = `{
  "undertone": "Subtono de piel",
  "skin_tone": "Tono general",
  "explanation": "Explicación detallada de colorimetría facial...",
  "recommended_colors": ["Color 1", "Color 2", "Color 3", "Color 4"],
  "pinterest_query": "consulta corta de pinterest"
}`;
    } else if (type === 'hair-diagnostic') {
      prompt = `Analiza la condición de la hebra capilar o cuero cabelludo que se observa de cerca en esta foto.
Evalúa el nivel de daño (Bajo, Medio, Alto) y la condición general (Seco, Graso, Mixto o Saludable).
Proporciona una explicación diagnóstica sobre el frizz, porosidad aparente, puntas y brillo.
Recomienda una lista de 3 tratamientos específicos o mascarillas reparadoras.
Genera una consulta corta (máximo 6 palabras) en español para buscar tratamientos o resultados en Pinterest.`;
      jsonTemplate = `{
  "damage_level": "Nivel de daño",
  "scalp_status": "Condición general",
  "explanation": "Explicación detallada del diagnóstico...",
  "recommended_treatments": ["Tratamiento 1", "Tratamiento 2", "Tratamiento 3"],
  "pinterest_query": "consulta corta de pinterest"
}`;
    } else if (type === 'skin-texture') {
      prompt = `Analiza el estado de la textura de la piel del rostro en esta foto de primer plano.
Determina el tipo de piel observado (Grasa, Seca, Mixta, Normal o Sensible) y el estado de los poros/imperfecciones (Dilatados, Congestionados, Obstruidos o Normales).
Explica la presencia de brillo, puntos negros, resequedad o texturas irregulares en zonas como la T o las mejillas.
Sugiere una rutina de cuidado facial corta (3 pasos específicos).
Genera una consulta corta (máximo 6 palabras) en español para buscar rutinas de skincare de inspiración en Pinterest.`;
      jsonTemplate = `{
  "skin_type": "Tipo de piel",
  "pore_status": "Estado de poros",
  "explanation": "Explicación de textura de la piel...",
  "recommended_routine": ["Paso 1: Limpiador...", "Paso 2: Tónico...", "Paso 3: Hidratación/Sérum..."],
  "pinterest_query": "consulta corta de pinterest"
}`;
    } else if (type === 'eyebrow-visagism') {
      prompt = `Realiza un estudio de visagismo de cejas a partir de la estructura del rostro en esta foto.
Identifica las proporciones del rostro (ej. Rostro Redondo, Ovalado, Cuadrado) y la forma recomendada de cejas (ej. Arqueada, Angular, Recta, Sutil).
Explica detalladamente cómo el arco, la longitud y el grosor ideal de la ceja pueden armonizar sus rasgos faciales.
Recomienda 3 diseños de cejas o técnicas profesionales aplicables (ej. Depilación con hilo, Laminado, Henna).
Genera una consulta corta (máximo 6 palabras) en español para buscar diseños de cejas óptimos en Pinterest.`;
      jsonTemplate = `{
  "face_proportions": "Proporción facial detectada",
  "eyebrow_shape": "Forma recomendada",
  "explanation": "Explicación de visagismo geométrico...",
  "recommended_designs": ["Técnica/Diseño 1", "Técnica/Diseño 2", "Técnica/Diseño 3"],
  "pinterest_query": "consulta corta de pinterest"
}`;
    } else if (type === 'nails-style') {
      prompt = `Analiza la estructura de la mano, la longitud de los dedos y el tono de piel en esta foto.
Determina la proporción de los dedos (ej. Dedos cortos, Dedos alargados) y el subtono cromático de la mano (Cálido o Frío).
Sugiere las 3 formas de uñas que más estilizan la mano (ej. Almendra, Ovalada, Coffin) y una lista de 4 colores de esmalte favorecedores.
Genera una consulta corta (máximo 6 palabras) en español para buscar estilos de manicure ideales en Pinterest.`;
      jsonTemplate = `{
  "finger_proportion": "Proporción de los dedos",
  "skin_undertone": "Subtono cromático de mano",
  "recommended_shapes": ["Forma 1", "Forma 2", "Forma 3"],
  "recommended_colors": ["Color 1", "Color 2", "Color 3", "Color 4"],
  "pinterest_query": "consulta corta de pinterest"
}`;
    } else {
      return res.status(400).json({ error: `Tipo de análisis "${type}" no es válido.` });
    }

    const fullPrompt = `${prompt}
Responde de manera obligatoria únicamente con un objeto JSON válido, sin formato markdown (sin bloques de código \`\`\`json) y sin caracteres adicionales, usando este formato exacto:
${jsonTemplate}`;

    const model = ai.getGenerativeModel({ model: 'gemini-2.5-flash' });
    const result = await model.generateContent({
      contents: [
        {
          role: 'user',
          parts: [
            { text: fullPrompt },
            imagePart
          ]
        }
      ]
    });
    const response = await result.response;
    
    let text = response.text().trim();
    if (text.startsWith('```json')) {
      text = text.substring(7, text.length - 3).trim();
    } else if (text.startsWith('```')) {
      text = text.substring(3, text.length - 3).trim();
    }

    let analysisJson;
    try {
      analysisJson = JSON.parse(text);
    } catch (parseErr) {
      console.error('Error al parsear respuesta JSON de Gemini para análisis:', text);
      if (req.file && req.file.buffer) req.file.buffer.fill(0);
      throw new Error('La IA no retornó un formato JSON válido.');
    }

    // Purga de RAM
    if (req.file && req.file.buffer) {
      req.file.buffer.fill(0);
    }

    if (req.user && req.user.id) {
      await saveAnalysisToDb(req.user.id, type, analysisJson);
    }

    return res.status(200).json({
      success: true,
      source: 'gemini',
      analysis: analysisJson
    });

  } catch (error) {
    if (req.file && req.file.buffer) {
      try { req.file.buffer.fill(0); } catch (e) {}
    }
    console.error('❌ ERROR REALIZANDO ANÁLISIS DE DISEÑO:', error.message);
    res.status(500).json({ 
      error: 'Error al analizar la imagen con IA',
      details: error.message 
    });
  }
};
