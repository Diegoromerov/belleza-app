// Al principio de seed_glowapp_kb.js
process.env.NVIDIA_API_KEY = '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'; // Pega tu clave real aquí
process.env.DB_HOST = '127.0.0.1';
process.env.DB_PORT = '5435';
// ... resto del código

console.log("CLAVE REAL LEIDA:", process.env.NVIDIA_API_KEY);
console.log("LONGITUD:", process.env.NVIDIA_API_KEY ? process.env.NVIDIA_API_KEY.length : 0);
const axios = require('axios');
const { Pool } = require('pg');
require('dotenv').config();

console.log('🔍 Verificando entorno local...');
console.log('DB_HOST:', process.env.DB_HOST);
console.log('DB_PORT:', process.env.DB_PORT);
console.log('NVIDIA_API_KEY:', process.env.NVIDIA_API_KEY ? '✅ Detectada' : '❌ Faltante');

// 1. Configuración directa de la conexión a tu Docker Local
const pool = new Pool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT, 10) || 5435,
  database: process.env.DB_NAME || 'beauty_db',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'admin123',
});

// Configuración NVIDIA NIM
const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;
const EMBEDDING_MODEL = process.env.EMBEDDING_MODEL || 'nvidia/nv-embedqa-e5-v5';
const EMBEDDING_URL = process.env.EMBEDDING_URL || 'https://integrate.api.nvidia.com/v1/embeddings';

// Datos extraídos de la Guía Estratégica v1.0
const kbEntries = [
  {
    id: "kb_skincare_niacinamide_001",
    title: "¿Qué es la Niacinamida y por qué debería usarla en mi rutina facial?",
    category: "Ingredientes > Actives Skincare",
    content: JSON.stringify({
      analogy: "Imagina la niacinamida como el 'manager' de tu barrera cutánea.",
      technical_explanation: "La niacinamida (vitamina B3) es un precursor de NAD+/NADP+, cofactores esenciales en la producción de energía celular y reparación del ADN.",
      practical_recommendations: [
        "Concentración ideal: 2–5% (más del 5% no aporta beneficio extra y puede irritar).",
        "Compatible con retinoides, vit C, AHAs, BHAs, péptidos.",
        "Aplicar AM y/o PM tras limpieza, antes de hidratante."
      ],
      evidence_summary: "Meta-análisis 2021 (J Cosmet Dermatol): 4–5% niacinamida reduce TEWL 20–30%, mejora barrera, reduce poros visibles.",
      safety_notes: "Raro: irritación leve inicio. Seguro embarazo/lactancia (tópico)."
    }),
    metadata: {
      skin_types: ["Oily", "Combination", "Sensitive", "Normal", "Dry"],
      concerns: ["Acne", "Pores", "Hyperpigmentation", "Barrier Repair", "Aging", "Rosacea"],
      evidence_level: "High",
      difficulty: "Beginner",
      regulatory_status: "Approved worldwide, max 5% EU/US cosmetic"
    }
  },
  {
    id: "kb_hair_porosity_high_001",
    title: "¿Por qué mi cabello absorbe el agua tan rápido y se siente áspero?",
    category: "Técnicas > Hair Treatments",
    content: JSON.stringify({
      analogy: "Imagina tu cabello como una esponja con 'agujeros' en la cutícula.",
      technical_explanation: "Alta porosidad indica daño en la capa externa del cabello, permitiendo que la humedad entre y salga rápidamente.",
      practical_recommendations: [
        "Necesita proteínas hidrolizadas (queratina, trigo) para reparar.",
        "Usa aceites penetrantes (coco, babasú) para sellar.",
        "Evita humectantes puros sin oclusivo porque causan efecto rebote."
      ],
      myth_buster: "Mito: 'Cabello baja porosidad no necesita proteínas'. Realidad: Proteínas hidrolizadas de bajo peso molecular reparan microdaños."
    }),
    metadata: {
      hair_porosity: "High",
      key_ingredients: ["Hydrolyzed Proteins", "Ceramides", "Coconut Oil"],
      difficulty: "Intermediate"
    }
  },
  {
    id: "kb_safety_ppd_001",
    title: "¿Es seguro el PPD en los tintes de pelo?",
    category: "Regulación > Ingredient Safety",
    content: JSON.stringify({
      technical_explanation: "El PPD (p-fenilendiamina) es el alérgeno #1 en tintes y puede causar dermatitis de contacto grave tipo IV.",
      practical_recommendations: [
        "Test de parche 48h obligatorio antes de CADA uso.",
        "Máximo permitido: 2% en producto final.",
        "Si tienes historial de alergias, busca alternativas con PTD o tintes vegetales puros."
      ],
      safety_notes: "Sensibilización de por vida. Reactividad cruzada con textiles y anestésicos locales."
    }),
    metadata: {
      allergen_risk: "High",
      regulatory_status: "Restricted (Max 2%)",
      region: "EU/Colombia/US"
    }
  }, // <--- AQUÍ FALTABA ESTA COMA
  {
    id: "kb_skincare_retinol_guide",
    title: "¿Cómo introducir el Retinol sin irritar mi piel?",
    category: "Ingredientes > Actives Skincare",
    content: JSON.stringify({
      analogy: "El retinol es como un entrenamiento intenso para la piel; hay que empezar suave para evitar lesiones.",
      technical_explanation: "Acelera la renovación celular y estimula colágeno tipo I y III. Puede comprometer la barrera cutánea al inicio aumentando la pérdida de agua transepidérmica (TEWL).",
      practical_recommendations: ["Método sándwich: hidratante + retinol + hidratante.", "Iniciar 1 vez por semana y aumentar gradualmente.", "Usar solo en PM y proteger con SPF 50+ en AM."],
      evidence_summary: "Gold standard anti-aging según AAD. Eficacia comprobada en fotoenvejecimiento y acné leve.",
      safety_notes: "Contraindicado en embarazo y lactancia. Evitar mezcla directa con AHAs/BHAs al inicio."
    }),
    metadata: { skin_types: ["Normal", "Oily", "Combination"], concerns: ["Aging", "Acne", "Texture"], evidence_level: "High", difficulty: "Intermediate" }
  },
  {
    id: "kb_makeup_seasonal_winter",
    title: "¿Qué tonos de maquillaje favorecen en la estación Invierno?",
    category: "Visagismo > Colorimetría Estacional",
    content: JSON.stringify({
      analogy: "Los inviernos son como joyas preciosas: necesitan contrastes nítidos y colores profundos para brillar.",
      technical_explanation: "Piel con subtono frío/rosado, cabello oscuro y ojos intensos. Requieren pigmentos azulados o puros, evitando tonos anaranjados o dorados que apagan el rostro.",
      practical_recommendations: ["Base con subtono rosado o neutro-frío.", "Labiales en rojo cereza, berry o fucsia.", "Evitar rubores naranja; preferir rosa helado o ciruela."],
      evidence_summary: "Teoría del color aplicada a la dermatología estética y armonía facial.",
      safety_notes: "Verificar siempre el subtono real bajo luz natural antes de comprar productos costosos."
    }),
    metadata: { season: "Winter", undertone: "Cool", difficulty: "Beginner" }
  },
  {
    id: "kb_hair_bonding_tech",
    title: "¿Realmente funcionan los tratamientos de reconstrucción de enlaces (Bonding)?",
    category: "Técnicas > Hair Treatments",
    content: JSON.stringify({
      analogy: "Son como el 'pegamento' molecular que vuelve a unir las escaleras rotas dentro de la fibra capilar.",
      technical_explanation: "Tecnologías como Olaplex o K18 reparan enlaces disulfuro (cistina) rotos por procesos químicos. No son acondicionadores, son reparadores estructurales.",
      practical_recommendations: ["Usar durante la decoloración para prevención.", "Aplicar en cabello limpio y sin acondicionador previo para máxima penetración.", "No enjuagar si la instrucción lo indica."],
      evidence_summary: "Estudios in-vitro muestran recuperación de hasta el 90% de la fuerza tensil en cabellos dañados.",
      safety_notes: "El exceso de proteína/reparador puede causar rigidez (hygral fatigue balance)."
    }),
    metadata: { hair_condition: "Chemically Damaged", key_ingredients: ["Bis-Aminopropyl Diglycol Dimaleate"], difficulty: "Professional" }
  },
  {
    id: "kb_lash_safety_glue",
    title: "¿Es seguro el cianoacrilato usado en extensiones de pestañas?",
    category: "Salud > Lash & Brow Services",
    content: JSON.stringify({
      technical_explanation: "El cianoacrilato médico es el estándar, pero libera vapores (formaldehído en trazas) que pueden sensibilizar la mucosa ocular con el tiempo.",
      practical_recommendations: ["Ventilación activa en el salón obligatoria.", "Uso de selladores de vapores (nano misters).", "Patch test 24h antes para clientes nuevos."],
      safety_notes: "Riesgo de blefaritis química si el adhesivo toca la piel del párpado. Nunca pegar sobre la piel."
    }),
    metadata: { allergen_risk: "Medium", regulatory_status: "Cosmetic Grade Only", region: "Colombia/INVIMA" }
  },
  {
    id: "kb_supplements_collagen",
    title: "¿El colágeno hidrolizado realmente mejora la piel o es marketing?",
    category: "Suplementos > Nutricosmética",
    content: JSON.stringify({
      analogy: "Es como enviar ladrillos pre-fabricados a una obra en lugar de materia prima bruta.",
      technical_explanation: "Los péptidos de colágeno (2-5 kDa) llegan a la dermis y estimulan a los fibroblastos para producir colágeno propio, elastina y ácido hialurónico.",
      practical_recommendations: ["Dosis clínica efectiva: 2.5g a 10g diarios.", "Buscar colágeno hidrolizado de pescado (tipo I) o bovino.", "Combinar con Vitamina C para síntesis óptima."],
      evidence_summary: "Meta-análisis 2021 confirma mejora en elasticidad e hidratación tras 8-12 semanas de uso continuo.",
      safety_notes: "Seguro en general. Precaución en personas con alergia a pescados o mariscos."
    }),
    metadata: { evidence_level: "Moderate-High", target: "Anti-aging", difficulty: "Beginner" }
  },
  {
    id: "kb_visagism_face_shapes",
    title: "¿Cómo identificar la forma de mi rostro para elegir cortes y cejas?",
    category: "Visagismo > Análisis Facial",
    content: JSON.stringify({
      technical_explanation: "Se basa en la proporción entre ancho de frente, pómulos y mandíbula, y la longitud total del rostro.",
      practical_recommendations: ["Óvalo: casi todo le favorece.", "Redondo: buscar ángulos y volumen en corona.", "Cuadrado: suavizar mandíbula con ondas o cejas arqueadas.", "Corazón: equilibrar frente ancha con volumen en la zona del mentón."],
      evidence_summary: "Principios de simetría y proporción áurea aplicados a la estética profesional.",
      safety_notes: "Ninguna. Es una herramienta de diagnóstico estético no invasiva."
    }),
    metadata: { category_hierarchy: ["Visagismo", "Análisis"], difficulty: "Intermediate" }
  },
  {
    id: "kb_regulation_invima_cosmetics",
    title: "¿Qué exige el INVIMA para registrar un producto cosmético en Colombia?",
    category: "Regulación > Normativa Colombiana",
    content: JSON.stringify({
      technical_explanation: "Resolución 2021/... exige notificación sanitaria obligatoria antes de la comercialización. Clasificación por riesgo (I, II, III).",
      practical_recommendations: ["Tener un Químico Farmacéutico responsable.", "Etiquetado en español con INCI correcto.", "Pruebas de estabilidad y desafío microbiológico."],
      evidence_summary: "Marco legal colombiano para protección de la salud pública.",
      safety_notes: "Sanciones graves por venta de productos sin notificación sanitaria vigente."
    }),
    metadata: { region: "Colombia", authority: "INVIMA", difficulty: "Professional" }
  },
  {
    id: "kb_skincare_barrier_ceramide",
    title: "¿Por qué las ceramidas son esenciales para pieles sensibles?",
    category: "Ingredientes > Barrier Repair",
    content: JSON.stringify({
      analogy: "Son el 'cemento' que mantiene unidos los 'ladrillos' (células) de tu piel.",
      technical_explanation: "Lípidos naturales que componen el 50% de la matriz extracelular. Su déficit causa dermatitis atópica, rosácea y sequedad extrema.",
      practical_recommendations: ["Buscar productos con ratio 3:1:1 (ceramidas, colesterol, ácidos grasos).", "Ideal para usar tras exfoliación ácida o retinoides."],
      evidence_summary: "Estándar de oro en reparación de barrera según Journal of Clinical Medicine.",
      safety_notes: "Altamente seguro y compatible con todos los activos."
    }),
    metadata: { skin_types: ["Sensitive", "Dry", "Atopic"], concerns: ["Barrier Repair", "Redness"], evidence_level: "High" }
  },
  {
    id: "kb_nails_health_fungus",
    title: "¿Cómo diferenciar una onicomicosis de un trauma en la uña?",
    category: "Salud > Nail Care",
    content: JSON.stringify({
      technical_explanation: "La onicomicosis es una infección por hongos (dermatofitos) que causa engrosamiento, decoloración amarillenta y desmoronamiento.",
      practical_recommendations: ["Derivar a dermatólogo para cultivo micológico.", "No realizar manicure tradicional sobre uñas infectadas.", "Desinfección rigurosa de herramientas (esterilización vs desinfección)."],
      evidence_summary: "Diagnóstico diferencial clave para evitar propagación en salones.",
      safety_notes: "Riesgo biológico alto. Uso de EPP obligatorio para la nail tech."
    }),
    metadata: { health_risk: "High", category_hierarchy: ["Salud", "Patologías"], difficulty: "Professional" }
  },
  {
    id: "kb_trends_clean_beauty_colombia",
    title: "¿Qué significa realmente 'Clean Beauty' en el mercado colombiano?",
    category: "Tendencias > Mercado",
    content: JSON.stringify({
      technical_explanation: "Movimiento que prioriza transparencia en ingredientes y elimina controversiales (parabenos, sulfatos, fragancias sintéticas), aunque no hay definición legal única.",
      practical_recommendations: ["Leer etiquetas INCI, no solo marketing frontal.", "Certificaciones útiles: COSMOS, Ecocert, EWG Verified.", "Enfocarse en la eficacia del activo natural (ej: Bakuchiol vs Retinol)."],
      evidence_summary: "Crecimiento del 15% anual en LatAm según ANDI.",
      safety_notes: "'Natural' no siempre significa seguro (ej: aceites esenciales alergénicos)."
    }),
    metadata: { market_trend: "High Growth", region: "LatAm", difficulty: "Beginner" }
  }
]; 

async function generateEmbedding(text) {
  if (!NVIDIA_API_KEY) {
    console.warn('⚠️ No hay NVIDIA_API_KEY configurada en el .env.');
    return null;
  }
  try {
    const response = await axios.post(
      EMBEDDING_URL,
      { model: EMBEDDING_MODEL, input: text,input_type: 'passage', encoding_format: "float" },
      { headers: { 'Authorization': `Bearer ${NVIDIA_API_KEY}`, 'Content-Type': 'application/json' } }
    );
    return response.data.data[0].embedding;
  } catch (error) {
    console.error(`❌ Error generando embedding:`, error.response?.data || error.message);
    return null;
  }
}

async function seedKnowledgeBase() {
  try {
    console.log('🌱 Iniciando siembra de Base de Conocimiento GlowApp (Guía v1.0)...');
    
    for (const entry of kbEntries) {
      console.log(`🔄 Procesando: ${entry.title}`);
      
      // Generar embedding del contenido completo (JSON stringificado)
      const embedding = await generateEmbedding(entry.content);
      const embeddingString = embedding ? `[${embedding.join(',')}]` : null;
      
      const query = `
        INSERT INTO beauty_knowledge_embeddings (title, category, content, metadata, embedding)
        VALUES ($1, $2, $3, $4, $5::vector)
        ON CONFLICT (title) DO UPDATE SET 
          content = EXCLUDED.content, 
          metadata = EXCLUDED.metadata, 
          embedding = COALESCE(EXCLUDED.embedding, beauty_knowledge_embeddings.embedding);
      `;
      
      await pool.query(query, [
        entry.title, 
        entry.category, 
        entry.content, 
        entry.metadata, 
        embeddingString
      ]);
      
      console.log(`✅ Guardado: ${entry.id}`);
    }
    
    console.log('\n🎉 Base de conocimientos sembrada exitosamente.');
  } catch (error) {
    console.error('❌ Error crítico:', error);
  } finally {
    await pool.end();
  }
}

seedKnowledgeBase();