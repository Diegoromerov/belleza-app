/**
 * ============================================================================
 *  INGESTOR DE CHUNKS A RAG (pgvector)
 *  Uso:  node scripts/ingest_json_chunks.js backend/data/corpus/visajismo_chunks.json
 * ============================================================================
 *  Este script:
 *   1. Lee un archivo JSON con chunks
 *   2. Genera el embedding de cada chunk con la API de NVIDIA (1024 dims)
 *   3. Los inserta en la tabla beauty_knowledge_embeddings (BD pgvector)
 * ============================================================================
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');

// Conectamos a la BD de RAG (pgvector), NO a la principal de PostGIS
const { ragPool } = require('../src/config/db');

// ---------- Configuración NVIDIA Embeddings ----------
const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;
const NVIDIA_API_URL = process.env.NVIDIA_API_URL || 'https://integrate.api.nvidia.com/v1/embeddings';
const NVIDIA_EMBEDDING_MODEL = process.env.NVIDIA_EMBEDDING_MODEL || 'nvidia/nv-embedqa-e5-v5';
const EXPECTED_DIMS = 1024;

// ---------- Generar embedding de un texto ----------
async function generateEmbedding(text) {
  const response = await fetch(NVIDIA_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${NVIDIA_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: NVIDIA_EMBEDDING_MODEL,
      input: [text],
      input_type: 'passage',
      encoding_format: 'float',
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`NVIDIA API ${response.status}: ${errText.substring(0, 200)}`);
  }

  const data = await response.json();
  const embedding = data.data && data.data[0] && data.data[0].embedding;

  if (!embedding || embedding.length !== EXPECTED_DIMS) {
    throw new Error(`Embedding con dimensiones incorrectas: se esperaban ${EXPECTED_DIMS}, llegaron ${embedding ? embedding.length : 0}`);
  }
  return embedding;
}

// ---------- Inspeccionar qué columnas tiene la tabla ----------
async function getTableSchema() {
  const res = await ragPool.query(`
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'beauty_knowledge_embeddings'
    ORDER BY ordinal_position;
  `);
  const schema = {};
  for (const row of res.rows) {
    schema[row.column_name] = row.data_type;
  }
  return schema;
}

// ---------- Extraer el valor del chunk según la columna de la BD ----------
function extractValue(chunk, columnName) {
  const md = chunk.metadata || {};
  const joinArray = (arr) => (Array.isArray(arr) && arr.length ? arr.join(', ') : null);

  switch (columnName) {
    case 'title': return chunk.title;
    case 'content': return chunk.content;
    case 'category': return chunk.category;
    case 'risk_level': return chunk.risk_level || md.risk_level || null;
    case 'skin_type': return joinArray(md.skin_types) || md.skin_type || null;
    case 'season_station': return joinArray(md.season) || md.season_station || null;
    case 'age_range': return joinArray(md.age_ranges) || md.age_range || null;
    case 'fototipos': return joinArray(md.fototipos) || null;
    case 'ingredients': return md.ingredients || null;
    case 'contraindications': return md.contraindications || null;
    case 'sources': return chunk.sources ? JSON.stringify(chunk.sources) : null;
    case 'metadata': return JSON.stringify(md);
    default: return md[columnName] !== undefined ? md[columnName] : null;
  }
}

// ---------- Formatear el valor según el tipo de dato de la columna ----------
function formatValue(value, dataType) {
  if (value === null || value === undefined) return null;

  // Columnas tipo ARRAY -> pasar como array literal de Postgres
  if (dataType === 'ARRAY') {
    const arr = Array.isArray(value) ? value : String(value).split(',').map(s => s.trim()).filter(Boolean);
    return `{${arr.map(v => `"${String(v).replace(/"/g, '\\"')}"`).join(',')}}`;
  }
  // Columnas JSONB/JSON -> pasar como string JSON
  if (dataType === 'jsonb' || dataType === 'json') {
    return typeof value === 'string' ? value : JSON.stringify(value);
  }
  return value;
}

// ---------- Ingesta principal ----------
async function ingestChunks(jsonPath) {
  // 1. Verificar que el archivo exista
  if (!fs.existsSync(jsonPath)) {
    console.error(`❌ No encuentro el archivo: ${jsonPath}`);
    process.exit(1);
  }

  // 2. Verificar API key de NVIDIA
  if (!NVIDIA_API_KEY) {
    console.error('❌ Falta la variable NVIDIA_API_KEY en Railway / .env');
    process.exit(1);
  }

    // 3. Leer el JSON (eliminando el carácter invisible BOM si existe)
  const raw = fs.readFileSync(jsonPath, 'utf8');
  const limpio = raw.charCodeAt(0) === 0xFEFF ? raw.slice(1) : raw;
  const parsed = JSON.parse(limpio);
  const chunks = Array.isArray(parsed) ? parsed : (parsed.chunks || []);

  // 4. Verificar conexión a la BD de RAG
  try {
    const before = await ragPool.query('SELECT COUNT(*)::int AS count FROM beauty_knowledge_embeddings');
    console.log(`✅ Conectado a la BD RAG (pgvector). Chunks existentes: ${before.rows[0].count}`);
  } catch (err) {
    console.error('❌ No pude conectar a la BD RAG:', err.message);
    console.error('   Revisa que la variable RAG_DATABASE_URL esté configurada en Railway.');
    process.exit(1);
  }

  // 5. Inspeccionar el esquema de la tabla
  const schema = await getTableSchema();
  console.log(`🔍 Columnas detectadas en la tabla: ${Object.keys(schema).join(', ')}\n`);

  if (!schema.embedding) {
    console.error('❌ La tabla no tiene la columna "embedding". Verifica el esquema.');
    process.exit(1);
  }

  // 6. Insertar cada chunk
  let inserted = 0, updated = 0, failed = 0;

  for (let i = 0; i < chunks.length; i++) {
    const chunk = chunks[i];
    const shortTitle = (chunk.title || 'Sin título').substring(0, 45);
    try {
      console.log(`[${i + 1}/${chunks.length}] ${shortTitle}...`);

      // Generar embedding a partir de título + contenido
      const embedding = await generateEmbedding(`${chunk.title}\n\n${chunk.content}`);
      const embeddingStr = `[${embedding.join(',')}]`;

      // Construir columnas y valores según el esquema real
      const columns = [];
      const values = [];
      const placeholders = [];
      let paramIndex = 1;

      for (const columnName of Object.keys(schema)) {
        if (columnName === 'embedding') continue; // se maneja aparte
        const dataType = schema[columnName];
        // Saltar columnas auto-generadas (id, created_at, etc.)
        if (['id', 'created_at', 'updated_at', 'chunk_id'].includes(columnName)) continue;

        const rawValue = extractValue(chunk, columnName);
        if (rawValue === null || rawValue === undefined) continue;

        columns.push(`"${columnName}"`);
        values.push(formatValue(rawValue, dataType));
        placeholders.push(`$${paramIndex}`);
        paramIndex++;
      }

      columns.push('embedding');
      placeholders.push(`$${paramIndex}::vector`);
      values.push(embeddingStr);

      const insertSql = `
        INSERT INTO beauty_knowledge_embeddings (${columns.join(', ')})
        VALUES (${placeholders.join(', ')})
        ON CONFLICT (title) DO UPDATE SET
          content = EXCLUDED.content,
          embedding = EXCLUDED.embedding
        RETURNING (xmax = 0) AS was_inserted;
      `;

      const result = await ragPool.query(insertSql, values);
      if (result.rows[0].was_inserted) { inserted++; console.log('   ✅ Insertado'); }
      else { updated++; console.log('   🔄 Actualizado (ya existía)'); }

      // Pausa breve para no saturar la API de NVIDIA
      await new Promise(r => setTimeout(r, 250));

    } catch (err) {
      failed++;
      console.error(`   ❌ Error: ${err.message}`);
    }
  }

  // 7. Resumen final
  console.log('\n' + '='.repeat(55));
  console.log('📊 RESUMEN DE LA INGESTA');
  console.log(`   ✅ Insertados nuevos : ${inserted}`);
  console.log(`   🔄 Actualizados      : ${updated}`);
  console.log(`   ❌ Con error         : ${failed}`);
  console.log(`   📦 Total procesados  : ${chunks.length}`);
  console.log('='.repeat(55));

  // 8. Verificación final por categoría
  if (chunks.length > 0 && chunks[0].category) {
    const cat = chunks[0].category;
    const finalRes = await ragPool.query(
      'SELECT COUNT(*)::int AS count FROM beauty_knowledge_embeddings WHERE category = $1',
      [cat]
    );
    console.log(`\n🎯 Chunks de "${cat}" ahora en la BD: ${finalRes.rows[0].count}`);
  }

  process.exit(0);
}

// ---------- Punto de entrada ----------
const jsonPath = process.argv[2];
if (!jsonPath) {
  console.error('❌ Falta la ruta del archivo JSON.');
  console.error('   Uso: node scripts/ingest_json_chunks.js backend/data/corpus/visajismo_chunks.json');
  process.exit(1);
}

ingestChunks(jsonPath).catch(err => {
  console.error('❌ Error fatal:', err);
  process.exit(1);
});