const { GoogleGenerativeAI } = require('@google/generative-ai');
const path = require('path');
require('dotenv').config();
const { pool } = require('../config/db');

const saveAnalysisToDb = async (userId, toolType, resultData, track = 'piel') => {
  if (!userId) return;
  try {
    const scores = resultData.scores || {};
    const hidratacion = scores.hidratacion !== undefined ? parseInt(scores.hidratacion) : null;
    const impurezas = scores.impurezas !== undefined ? parseInt(scores.impurezas) : null;
    const luminosidad = scores.luminosidad !== undefined ? parseInt(scores.luminosidad) : null;

    const query = `
      INSERT INTO ai_diagnostics (user_id, tool_type, result_data, score_hidratacion, score_impurezas, score_luminosidad, track)
      VALUES ($1, $2, $3, $4, $5, $6, $7);
    `;
    await pool.query(query, [userId, toolType, JSON.stringify(resultData), hidratacion, impurezas, luminosidad, track]);
    console.log(`💾 [DB] Guardado historial de IA (${toolType}) para usuario ${userId}`);

    if (toolType === 'care-routine') {
      await updateSkinProfile(userId, resultData.skin_type || 'Piel Mixta');
    }
  } catch (err) {
    console.error('⚠️ [DB ERROR] Error guardando historial de IA:', err.message);
  }
};

const updateSkinProfile = async (userId, tipoPiel) => {
  try {
    const lastDiagQuery = `
      SELECT score_hidratacion, score_impurezas, score_luminosidad
      FROM ai_diagnostics
      WHERE user_id = $1 AND tool_type = 'care-routine'
      ORDER BY creado_en DESC
      LIMIT 5;
    `;
    const diags = await pool.query(lastDiagQuery, [userId]);
    
    if (diags.rows.length === 0) return;

    let totalHidra = 0, totalAcne = 0, totalSens = 0;
    let countH = 0, countI = 0;
    
    diags.rows.forEach(r => {
      if (r.score_hidratacion !== null) {
        totalHidra += r.score_hidratacion;
        countH++;
      }
      if (r.score_impurezas !== null) {
        totalAcne += r.score_impurezas;
        countI++;
      }
    });

    const avgHidra = countH > 0 ? Math.round(totalHidra / countH) : 50;
    const avgAcne = countI > 0 ? Math.round(totalAcne / countI) : 30;
    const avgSens = 15;

    const upsertQuery = `
      INSERT INTO skin_profiles (user_id, tipo_piel, hidratacion_promedio, tendencia_acne, sensibilidad_score, diagnosticos_count, ultimo_diagnostico_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, 1, NOW(), NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        tipo_piel = EXCLUDED.tipo_piel,
        hidratacion_promedio = EXCLUDED.hidratacion_promedio,
        tendencia_acne = EXCLUDED.tendencia_acne,
        sensibilidad_score = EXCLUDED.sensibilidad_score,
        diagnosticos_count = skin_profiles.diagnosticos_count + 1,
        ultimo_diagnostico_at = NOW(),
        updated_at = NOW();
    `;
    await pool.query(upsertQuery, [userId, tipoPiel, avgHidra, avgAcne, avgSens]);
    console.log(`💾 [DB] Perfil de piel actualizado para usuario ${userId}`);
  } catch (err) {
    console.error('⚠️ [DB ERROR] Error actualizando perfil de piel:', err.message);
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
      image_url: `/api/designs/proxy?url=${encodeURIComponent(item.image)}`,
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

    let optimizedQuery = q;
    if (ai) {
      try {
        const model = ai.getGenerativeModel({ model: 'gemini-2.5-flash' });
        const prompt = `Actúa como un experto en SEO y tendencias de belleza. Recibes un término de búsqueda para buscar ideas en Pinterest: "${q}".
Optimiza y expande este término a una consulta de búsqueda corta en inglés y español que consiga los mejores y más estéticos resultados de diseño de uñas o belleza en Pinterest.
Ejemplo: "uñas rosas" -> "elegant pink nails design aesthetic".
Devuelve ÚNICAMENTE la consulta de búsqueda optimizada final de 3 a 6 palabras, sin comillas ni texto adicional.`;
        const response = await model.generateContent(prompt);
        const text = response.response.text().trim();
        if (text && text.length > 2 && text.length < 100) {
          optimizedQuery = text;
          console.log(`🤖 Consulta de búsqueda optimizada con Gemini: "${q}" -> "${optimizedQuery}"`);
        }
      } catch (geminiErr) {
        console.error('⚠️ Error optimizando query con Gemini:', geminiErr.message);
      }
    }

    const apiKey = process.env.GOOGLE_SEARCH_API_KEY;
    const cx = process.env.GOOGLE_SEARCH_CX;

    if (!apiKey || !cx) {
      console.log(`🔍 Buscando imágenes reales de Pinterest mediante motor alternativo para: "${optimizedQuery}"...`);
      const realImages = await searchRealPinterestImages(optimizedQuery);
      
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

    const searchQuery = `${optimizedQuery} uñas manicure site:pinterest.com`;
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
      image_url: `/api/designs/proxy?url=${encodeURIComponent(item.link)}`, 
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
  let weatherInfo = null;
  try {
    const { type, concern, track } = req.body;
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
      } else if (type === 'care-routine') {
        const concernLabel = concern ? ` (Enfocado en ${concern})` : '';
        mockResult = {
          skin_type: "Mixta con tendencia a deshidratación",
          scalp_status: "Normal",
          explanation: `Tu piel muestra brillo leve en la zona T con mejillas deshidratadas. Requiere una rutina que equilibre la producción de grasa e hidrate a profundidad${concernLabel}.`,
          recommended_routine: [
            `Paso 1: Limpiador suave hidratante${concern ? ' especializado para ' + concern : ''}`,
            `Paso 2: Sérum activo${concern ? ' enfocado en ' + concern : ' de Ácido Hialurónico'}`,
            "Paso 3: Crema gel ligera selladora con FPS"
          ],
          pinterest_query: "rutina skincare semanal piel mixta"
        };
      } else if (type === 'hair-color') {
        mockResult = {
          skin_undertone: "Cálido (Otoño Suave)",
          face_shape: "Ovalado",
          recommended_shades: ["Castaño Miel / Avellana", "Balayage Cobrizo sutil", "Chocolate dorado"],
          explanation: "Los tonos cálidos con reflejos cobrizos o dorados aportan luz a tu piel y suavizan los rasgos de tu rostro ovalado de forma excepcional.",
          recommended_colors: ["Miel", "Avellana", "Cobrizo", "Chocolate Dorado"],
          pinterest_query: "tinte de cabello balayage miel castano"
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
    let profileContext = '';

    if (req.user && req.user.id && type === 'care-routine') {
      const profRes = await pool.query('SELECT tipo_piel, hidratacion_promedio, tendencia_acne, sensibilidad_score, diagnosticos_count FROM skin_profiles WHERE user_id = $1', [req.user.id]);
      if (profRes.rows.length > 0) {
        const prof = profRes.rows[0];
        profileContext = `
[PERFIL HISTÓRICO DEL USUARIO]
Tipo de piel inferido: ${prof.tipo_piel}
Hidratación promedio histórica: ${prof.hidratacion_promedio}/100
Tendencia de acné: ${prof.tendencia_acne}/100
Sensibilidad histórica: ${prof.sensibilidad_score}/100
Diagnósticos anteriores: ${prof.diagnosticos_count}
Usa este contexto para personalizar la rutina sin pedirle al usuario que lo explique de nuevo.
`;
      }
    }

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
    } else if (type === 'care-routine') {
      weatherInfo = { temp: 14, humidity: 80, description: 'Llovizna/Nublado' };
      try {
        const weatherApiKey = process.env.OPENWEATHER_API_KEY;
        if (weatherApiKey) {
          const resW = await fetch(`https://api.openweathermap.org/data/2.5/weather?q=Bogota,CO&appid=${weatherApiKey}&units=metric`);
          if (resW.ok) {
            const dataW = await resW.json();
            weatherInfo = {
              temp: dataW.main.temp,
              humidity: dataW.main.humidity,
              description: dataW.weather[0].description
            };
          }
        }
      } catch (wErr) {
        console.warn('⚠️ No se pudo obtener clima en tiempo real, usando clima promedio de Bogotá:', wErr.message);
      }

      const concernStr = concern ? `La preocupación u objetivo principal del usuario es: "${concern}". Asegúrate de orientar los pasos de la rutina y las explicaciones para mitigar este problema específicamente.` : '';
      const weatherPrompt = `
[CONTEXTO CLIMÁTICO ACTUAL - BOGOTÁ]
Temperatura: ${weatherInfo.temp}°C | Humedad: ${weatherInfo.humidity}% | Condición: ${weatherInfo.description}
Ajusta las recomendaciones considerando cómo este clima afecta el tipo de piel del usuario.
`;

      const isCapilar = track === 'capilar';
      if (isCapilar) {
        prompt = `Analiza detalladamente la hebra capilar o el cuero cabelludo que se observa en esta foto.
Determina el tipo de cabello (ej. Seco, Graso, Mixto) y el estado general (frizz, puntas abiertas, caspa).
Proporciona una explicación detallada del diagnóstico y genera una rutina semanal paso a paso en casa (3 pasos específicos).
${concernStr}
${weatherPrompt}
Genera una consulta corta (máximo 6 palabras) en español para buscar tratamientos capilares en Pinterest.`;
        jsonTemplate = `{
  "skin_type": "Tipo de cabello/cuero cabelludo",
  "scalp_status": "Estado del cuero cabelludo",
  "explanation": "Explicación de hebra y porosidad...",
  "recommended_routine": ["Paso 1...", "Paso 2...", "Paso 3..."],
  "scores": {
    "hidratacion": 70,
    "impurezas": 10,
    "luminosidad": 80
  },
  "pinterest_query": "consulta corta de pinterest"
}`;
      } else {
        prompt = `Analiza detalladamente la piel del rostro o la textura de cabello que se observa en esta foto.
Determina el tipo de piel o cabello (ej. Piel Mixta, Cabello Seco/Fino) y el estado general observando el brillo, resequedad o texturas.
Proporciona una explicación detallada del diagnóstico y genera una rutina semanal paso a paso en casa (3 pasos específicos).
${concernStr}
${profileContext}
${weatherPrompt}
Genera una consulta corta (máximo 6 palabras) en español para buscar rutinas de skincare o haircare recomendadas en Pinterest.`;
        jsonTemplate = `{
  "skin_type": "Tipo de piel o cabello detectado",
  "scalp_status": "Estado/Condición general",
  "explanation": "Explicación detallada del cuidado recomendado...",
  "recommended_routine": ["Paso 1...", "Paso 2...", "Paso 3..."],
  "scores": {
    "hidratacion": 80,
    "impurezas": 20,
    "luminosidad": 75
  },
  "pinterest_query": "consulta corta de pinterest"
}`;
      }
    } else if (type === 'hair-color') {
      prompt = `Analiza el rostro de la persona en esta foto, enfocándose en el subtono cromático de su piel (Cálido, Frío o Neutro) y la forma del rostro.
Determina el subtono cromático detectado y el tipo de rostro (Ovalado, Redondo, Cuadrado, etc.).
Recomienda los 3 tonos o reflejos de tinte de cabello que más le favorecen para enmarcar su cara y aportar luminosidad a su piel.
Explica detalladamente por qué estos colores armonizan con sus rasgos.
Genera una consulta corta (máximo 6 palabras) en español para buscar ideas visuales de coloración capilar recomendada en Pinterest.`;
      jsonTemplate = `{
  "skin_undertone": "Subtono de piel detectado",
  "face_shape": "Forma del rostro detectada",
  "recommended_shades": ["Tono 1", "Tono 2", "Tono 3"],
  "explanation": "Explicación detallada de colorimetría capilar...",
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
      if (weatherInfo) {
        analysisJson.weather_snapshot = weatherInfo;
      }
    } catch (parseErr) {
      console.error('Error al parsear respuesta JSON de Gemini para análisis:', text);
      if (req.file && req.file.buffer) req.file.buffer.fill(0);
      throw new Error('La IA no retornó un formato JSON válido.');
    }

    // Purga de RAM
    if (req.file && req.file.buffer) {
      req.file.buffer.fill(0);
    }

    if (type === 'care-routine') {
      const targetConcern = concern || 'Hidratación';
      try {
        const prodRes = await pool.query(
          `SELECT nombre, marca, url_afiliado as url, comision_pct 
           FROM affiliate_products 
           WHERE objetivo = $1 AND activo = TRUE 
           LIMIT 1;`,
          [targetConcern]
        );
        if (prodRes.rows.length > 0) {
          analysisJson.recommended_product = prodRes.rows[0];
        }

        const sponsorRes = await pool.query(
          `SELECT marca, nombre_rutina, descripcion, producto_destacado, logo_url 
           FROM brand_sponsorships 
           WHERE objetivo_target = $1 AND activo = TRUE 
           LIMIT 1;`,
          [targetConcern]
        );
        if (sponsorRes.rows.length > 0) {
          analysisJson.brand_sponsorship = sponsorRes.rows[0];
        }
      } catch (prodErr) {
        console.warn('⚠️ No se pudo cargar recomendación de afiliado o patrocinio:', prodErr.message);
      }
    }

    if (req.user && req.user.id) {
      await saveAnalysisToDb(req.user.id, type, analysisJson, track);
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

exports.proxyImage = async (req, res) => {
  try {
    const { url } = req.query;
    if (!url) {
      return res.status(400).json({ error: 'Falta el parámetro url' });
    }

    const response = await fetch(url);
    if (!response.ok) {
      return res.status(response.status).json({ error: 'Error al obtener la imagen' });
    }

    const contentType = response.headers.get('content-type');
    if (contentType) {
      res.setHeader('Content-Type', contentType);
    }
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('Access-Control-Allow-Origin', '*');

    const buffer = await response.arrayBuffer();
    res.send(Buffer.from(buffer));
  } catch (error) {
    console.error('Error en proxy de imagen:', error.message);
    res.status(500).json({ error: 'Error interno del proxy de imagen' });
  }
};

exports.getAIHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { tool_type } = req.query;

    let query = `
      SELECT id, tool_type, result_data, created_at 
      FROM ai_diagnostics 
      WHERE user_id = $1
    `;
    const params = [userId];

    if (tool_type) {
      query += ` AND tool_type = $2`;
      params.push(tool_type);
    }

    query += ` ORDER BY created_at DESC;`;

    const result = await pool.query(query, params);

    res.json({
      success: true,
      data: result.rows.map(row => ({
        id: row.id,
        tool_type: row.tool_type,
        result_data: typeof row.result_data === 'string' ? JSON.parse(row.result_data) : row.result_data,
        created_at: row.created_at
      }))
    });
  } catch (error) {
    console.error('❌ ERROR AL OBTENER HISTORIAL DE IA:', error);
    res.status(500).json({ error: 'Error al obtener el historial de diagnósticos' });
  }
};

exports.compareDesigns = async (req, res) => {
  try {
    const { diagnostic_id } = req.body;

    if (!req.files || !req.files.imageBefore || !req.files.imageAfter) {
      return res.status(400).json({ error: 'Es obligatorio subir ambas imágenes (Antes y Después) para realizar la comparación.' });
    }

    const fileBefore = req.files.imageBefore[0];
    const fileAfter = req.files.imageAfter[0];

    const imageBeforePart = {
      inlineData: {
        data: fileBefore.buffer.toString('base64'),
        mimeType: fileBefore.mimetype || 'image/jpeg'
      }
    };

    const imageAfterPart = {
      inlineData: {
        data: fileAfter.buffer.toString('base64'),
        mimeType: fileAfter.mimetype || 'image/jpeg'
      }
    };

    let comparisonResult = {};

    if (!ai) {
      console.warn('⚠️ GEMINI_API_KEY no configurada. Retornando comparación simulada.');
      comparisonResult = {
        delta_hidratacion: 15,
        delta_impurezas: -10,
        delta_luminosidad: 20,
        resumen: "Se observa una notable mejora en la textura y el brillo general de la piel. Las zonas deshidratadas lucen más uniformes.",
        recomendacion: "Mantener la rutina actual y considerar un sellador ligero adicional por las noches."
      };
    } else {
      const prompt = `Eres un especialista en análisis de piel. Se te proporcionan DOS fotografías del mismo usuario tomadas en momentos diferentes (foto A = antes, foto B = después). Analiza ambas y genera un JSON con esta estructura exacta:
{
  "delta_hidratacion": número entre -100 y 100 (positivo = mejoró),
  "delta_impurezas": número entre -100 y 100 (negativo = disminuyeron las impurezas, positivo = aumentaron),
  "delta_luminosidad": número entre -100 y 100,
  "resumen": "texto de máximo 2 oraciones en español describiendo el cambio observable",
  "recomendacion": "texto de máximo 2 oraciones con ajuste a la rutina si aplica"
}
Responde SOLO con el JSON. Sin texto adicional, sin backticks, sin explicación.`;

      const model = ai.getGenerativeModel({ model: 'gemini-2.5-flash' });
      const result = await model.generateContent({
        contents: [
          {
            role: 'user',
            parts: [
              { text: prompt },
              imageBeforePart,
              imageAfterPart
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

      try {
        comparisonResult = JSON.parse(text);
      } catch (parseErr) {
        console.error('Error al parsear JSON de comparación:', text);
        throw new Error('La IA no retornó un formato de comparación JSON válido.');
      }
    }

    // Purga de RAM
    if (fileBefore.buffer) fileBefore.buffer.fill(0);
    if (fileAfter.buffer) fileAfter.buffer.fill(0);

    if (diagnostic_id) {
      const updateQuery = `
        UPDATE ai_diagnostics
        SET comparison_photo_url = $1, comparison_delta = $2
        WHERE id = $3;
      `;
      await pool.query(updateQuery, ['http://dummy-url.com/comparison.jpg', JSON.stringify(comparisonResult), diagnostic_id]);
    }

    res.json({
      success: true,
      comparison: comparisonResult
    });

  } catch (error) {
    console.error('❌ ERROR EN DIAGNÓSTICO SECUENCIAL DE DOBLE CAPA:', error);
    res.status(500).json({ error: 'Error al realizar el análisis comparativo' });
  }
};

exports.getSkinProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const query = `
      SELECT id, tipo_piel, hidratacion_promedio, tendencia_acne, sensibilidad_score, diagnosticos_count, ultimo_diagnostico_at
      FROM skin_profiles
      WHERE user_id = $1;
    `;
    const result = await pool.query(query, [userId]);
    if (result.rows.length === 0) {
      return res.json({
        success: true,
        data: null
      });
    }
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ ERROR AL OBTENER PERFIL DE PIEL:', error);
    res.status(500).json({ error: 'Error al obtener el perfil de piel' });
  }
};

exports.checkGlowAIQuota = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const userQuery = `
      SELECT glowai_plan, glowai_diagnosticos_mes, glowai_ciclo_reset_at
      FROM usuarios
      WHERE id = $1;
    `;
    const result = await pool.query(userQuery, [userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado.' });
    }

    let { glowai_plan, glowai_diagnosticos_mes, glowai_ciclo_reset_at } = result.rows[0];
    const ahora = new Date();
    const resetDate = new Date(glowai_ciclo_reset_at || ahora);

    const diffTime = Math.abs(ahora - resetDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays >= 30) {
      await pool.query(
        `UPDATE usuarios 
         SET glowai_diagnosticos_mes = 0, glowai_ciclo_reset_at = NOW() 
         WHERE id = $1;`,
        [userId]
      );
      glowai_diagnosticos_mes = 0;
    }

    if (glowai_plan === 'free' && glowai_diagnosticos_mes >= 2) {
      return res.status(402).json({
        error: 'quota_exceeded',
        message: 'Has alcanzado el límite mensual de diagnósticos gratuitos.',
        upgrade_url: '/glowaipremium'
      });
    }

    await pool.query(
      `UPDATE usuarios SET glowai_diagnosticos_mes = COALESCE(glowai_diagnosticos_mes, 0) + 1 WHERE id = $1;`,
      [userId]
    );
    
    next();

  } catch (error) {
    console.error('❌ ERROR EN MIDDLEWARE DE CUOTA GLOWAI:', error);
    res.status(500).json({ error: 'Error al verificar la cuota de diagnósticos' });
  }
};

exports.subscribePremium = async (req, res) => {
  try {
    const userId = req.user.id;
    await pool.query(
      `UPDATE usuarios 
       SET glowai_plan = 'premium', glowai_ciclo_reset_at = NOW() 
       WHERE id = $1;`,
      [userId]
    );
    res.json({
      success: true,
      message: 'Suscripción a GlowAI Premium activada con éxito.'
    });
  } catch (error) {
    console.error('❌ ERROR AL SUSCRIBIR A PREMIUM:', error);
    res.status(500).json({ error: 'Error al procesar el pago de la suscripción' });
  }
};

exports.checkInStreak = async (req, res) => {
  try {
    const userId = req.user.id;
    const userQuery = `
      SELECT streak_actual, streak_maximo, streak_ultimo_registro
      FROM usuarios
      WHERE id = $1;
    `;
    const userRes = await pool.query(userQuery, [userId]);
    if (userRes.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    let { streak_actual, streak_maximo, streak_ultimo_registro } = userRes.rows[0];
    const hoy = new Date().toISOString().split('T')[0];
    
    // Si la fecha coincide con la del último registro (teniendo en cuenta la zona horaria)
    // Para simplificar, convertimos ambas fechas a strings YYYY-MM-DD
    let lastDateStr = null;
    if (streak_ultimo_registro) {
      const dbDate = new Date(streak_ultimo_registro);
      lastDateStr = dbDate.toISOString().split('T')[0];
    }

    if (lastDateStr === hoy) {
      return res.status(400).json({
        error: 'already_checked_in',
        message: 'Ya has registrado tu rutina de hoy. ¡Vuelve mañana!',
        streak_actual,
        streak_maximo
      });
    }

    let nuevoStreak = 1;
    if (lastDateStr) {
      const ayer = new Date();
      ayer.setDate(ayer.getDate() - 1);
      const ayerStr = ayer.toISOString().split('T')[0];
      
      if (lastDateStr === ayerStr) {
        nuevoStreak = (streak_actual || 0) + 1;
      }
    }

    const nuevoMaximo = Math.max(streak_maximo || 0, nuevoStreak);
    
    let rewardUnlocked = false;
    let updatePlanQuery = '';
    if (nuevoStreak >= 7) {
      updatePlanQuery = `, glowai_plan = 'premium'`;
      rewardUnlocked = true;
    }

    const updateQuery = `
      UPDATE usuarios
      SET streak_actual = $1, streak_maximo = $2, streak_ultimo_registro = $3 ${updatePlanQuery}
      WHERE id = $4;
    `;
    await pool.query(updateQuery, [nuevoStreak, nuevoMaximo, hoy, userId]);

    res.json({
      success: true,
      message: rewardUnlocked 
        ? '¡Racha registrada! Has completado 7 días seguidos y desbloqueado GlowAI Premium Gratis por esta semana. 🎉' 
        : '¡Rutina diaria registrada con éxito! Sigue así.',
      streak_actual: nuevoStreak,
      streak_maximo: nuevoMaximo,
      reward_unlocked: rewardUnlocked
    });

  } catch (error) {
    console.error('❌ ERROR AL REGISTRAR RACHA DE RUTINA:', error);
    res.status(500).json({ error: 'Error al registrar la racha de la rutina' });
  }
};

exports.getShareCode = async (req, res) => {
  try {
    const userId = req.user.id;
    const checkQuery = `SELECT codigo FROM referidos WHERE referidor_user_id = $1;`;
    const checkRes = await pool.query(checkQuery, [userId]);
    
    if (checkRes.rows.length > 0) {
      return res.json({
        success: true,
        code: checkRes.rows[0].codigo
      });
    }

    const code = 'GLOW' + Math.random().toString(36).substring(2, 8).toUpperCase();
    const insertQuery = `
      INSERT INTO referidos (referidor_user_id, codigo)
      VALUES ($1, $2)
      RETURNING codigo;
    `;
    const insertRes = await pool.query(insertQuery, [userId, code]);
    
    res.json({
      success: true,
      code: insertRes.rows[0].codigo
    });

  } catch (error) {
    console.error('❌ ERROR AL OBTENER CÓDIGO DE REFERIDO:', error);
    res.status(500).json({ error: 'Error al generar código de referido' });
  }
};

exports.redirectReferral = async (req, res) => {
  try {
    const { code } = req.params;
    
    await pool.query(
      `UPDATE referidos SET clicks = clicks + 1 WHERE codigo = $1;`,
      [code]
    );

    res.redirect('/');
  } catch (error) {
    console.error('❌ ERROR EN REDIRECCIÓN DE REFERIDO:', error);
    res.status(500).send('Error al procesar el enlace de referido');
  }
};

exports.getRecommendedDoctors = async (req, res) => {
  try {
    const query = `
      SELECT id, nombre, especialidad, registro_medico, telefono, email, ciudad, foto_url, condiciones_tratadas
      FROM profesionales_medicos
      WHERE membresia_activa = TRUE;
    `;
    const result = await pool.query(query);
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ ERROR AL OBTENER DERMATÓLOGOS RECOMENDADOS:', error);
    res.status(500).json({ error: 'Error al obtener dermatólogos' });
  }
};
