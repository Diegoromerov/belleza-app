// backend/src/controllers/designsController.js
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

exports.searchPinterestDesigns = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.status(400).json({ error: 'El parámetro de búsqueda "q" es obligatorio' });
    }

    const apiKey = process.env.GOOGLE_SEARCH_API_KEY;
    const cx = process.env.GOOGLE_SEARCH_CX;

    // Si no están configuradas las variables de entorno de Google Search, usamos Mock Fallback
    if (!apiKey || !cx) {
      console.log('⚠️ GOOGLE_SEARCH_API_KEY o GOOGLE_SEARCH_CX no configurados. Usando datos de prueba.');
      // Filtramos un poco los mocks según el query básico solo para simular dinamismo
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

    // Aseguramos que la búsqueda esté bien enfocada agregando términos clave y limitando a Pinterest
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
      image_url: item.link, // URL de la imagen directa
      link: item.image?.contextLink || 'https://pinterest.com' // Link del pin
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
