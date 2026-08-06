/**
 * backend/src/services/chunkingService.js
 * Servicio de chunking semántico para documentos de belleza/skincare
 * Divide documentos en chunks de 500-800 tokens con overlap de 50 tokens
 * Respeta límites de oraciones y párrafos
 */

const crypto = require('crypto');

/**
 * Configuración por defecto del chunking
 */
const DEFAULT_OPTIONS = {
  maxTokens: 600,
  overlapTokens: 50,
  respectSentences: true,
  respectParagraphs: true,
};

/**
 * Estima el número de tokens en un texto (aproximación: 1 token ≈ 4 caracteres en español)
 * @param {string} text - Texto a estimar
 * @returns {number} Número estimado de tokens
 */
function estimateTokens(text) {
  return Math.ceil(text.length / 4);
}

/**
 * Calcula hash SHA-256 determinista del contenido
 * @param {string} content - Contenido a hashear
 * @returns {string} Hash SHA-256 en hex
 */
function computeContentHash(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

/**
 * Divide el texto en párrafos preservando saltos de línea
 * @param {string} text - Texto completo
 * @returns {string[]} Array de párrafos
 */
function splitIntoParagraphs(text) {
  return text.split(/\n\s*\n/).filter(p => p.trim().length > 0);
}

/**
 * Divide un párrafo en oraciones
 * @param {string} paragraph - Párrafo a dividir
 * @returns {string[]} Array de oraciones
 */
function splitIntoSentences(paragraph) {
  // Regex para español: punto seguido de espacio + mayúscula, o signos de interrogación/exclamación
  const sentenceRegex = /(?<=[.!?])\s+(?=[A-ZÁÉÍÓÚÑ¿¡])/;
  return paragraph.split(sentenceRegex).filter(s => s.trim().length > 0);
}

/**
 * Combina oraciones/parráfos en chunks respetando límites de tokens
 * @param {string[]} units - Unidades (oraciones o párrafos) a combinar
 * @param {Object} options - Opciones de chunking
 * @returns {string[]} Chunks combinados
 */
function combineIntoChunks(units, options) {
  const { maxTokens, overlapTokens, respectSentences } = options;
  const chunks = [];
  let currentChunk = '';
  let currentTokens = 0;
  let overlapBuffer = [];

  for (const unit of units) {
    const unitTokens = estimateTokens(unit);

    // Si la unidad sola excede maxTokens, dividirla más
    if (unitTokens > maxTokens && respectSentences) {
      // Dividir la unidad larga recursivamente
      const subUnits = splitIntoSentences(unit);
      const subChunks = combineIntoChunks(subUnits, options);
      // Añadir chunks de la subdivisión al buffer actual
      for (const subChunk of subChunks) {
        if (currentTokens + estimateTokens(subChunk) <= maxTokens) {
          currentChunk += (currentChunk ? ' ' : '') + subChunk;
          currentTokens += estimateTokens(subChunk);
        } else {
          if (currentChunk) {
            chunks.push(currentChunk.trim());
            overlapBuffer.push(currentChunk.trim());
          }
          currentChunk = subChunk;
          currentTokens = unitTokens;
        }
      }
      continue;
    }

    // Verificar si añadir esta unidad excede el límite
    if (currentTokens + unitTokens > maxTokens && currentChunk) {
      // Finalizar chunk actual
      chunks.push(currentChunk.trim());
      
      // Preparar overlap para el siguiente chunk
      overlapBuffer.push(currentChunk.trim());
      const overlapText = overlapBuffer.join(' ').slice(-overlapTokens * 4); // aprox chars
      currentChunk = overlapText + ' ' + unit;
      currentTokens = estimateTokens(overlapText) + unitTokens;
      overlapBuffer = [];
    } else {
      // Añadir unidad al chunk actual
      currentChunk += (currentChunk ? ' ' : '') + unit;
      currentTokens += unitTokens;
    }
  }

  // Añadir último chunk si existe
  if (currentChunk.trim()) {
    chunks.push(currentChunk.trim());
  }

  return chunks;
}

/**
 * Función principal: divide un documento en chunks semánticos
 * @param {string} content - Contenido del documento
 * @param {Object} options - Opciones de chunking
 * @returns {Array<Object>} Array de chunks con metadata
 */
function chunkDocument(content, options = {}) {
  const opts = { ...DEFAULT_OPTIONS, ...options };
  
  if (!content || typeof content !== 'string') {
    return [];
  }

  // Normalizar espacios en blanco
  const normalizedContent = content.replace(/\s+/g, ' ').trim();
  
  if (!normalizedContent) {
    return [];
  }

  // Estrategia: dividir por párrafos primero
  const paragraphs = splitIntoParagraphs(normalizedContent);
  
  let allChunks = [];

  if (opts.respectParagraphs) {
    // Procesar cada párrafo
    for (const paragraph of paragraphs) {
      const paraTokens = estimateTokens(paragraph);
      
      if (paraTokens <= opts.maxTokens) {
        // Párrafo cabe entero
        allChunks.push(paragraph.trim());
      } else {
        // Párrafo muy largo, dividir por oraciones
        const sentences = splitIntoSentences(paragraph);
        const sentenceChunks = combineIntoChunks(sentences, opts);
        allChunks.push(...sentenceChunks);
      }
    }
  } else {
    // Dividir todo por oraciones directamente
    const allSentences = paragraphs.flatMap(p => splitIntoSentences(p));
    allChunks = combineIntoChunks(allSentences, opts);
  }

  // Post-procesar: asegurar overlap entre chunks adyacentes
  const finalChunks = [];
  for (let i = 0; i < allChunks.length; i++) {
    let chunk = allChunks[i].trim();
    
    // Añadir overlap del chunk anterior si no es el primero
    if (i > 0 && opts.overlapTokens > 0) {
      const prevChunk = allChunks[i - 1].trim();
      const overlapText = prevChunk.slice(-opts.overlapTokens * 4); // chars aprox
      chunk = overlapText + ' ' + chunk;
    }
    
    // Calcular hash y tokens
    const contentHash = computeContentHash(chunk);
    const tokens = estimateTokens(chunk);
    
    finalChunks.push({
      content: chunk,
      contentHash,
      tokens,
      index: i,
      totalChunks: allChunks.length,
    });
  }

  return finalChunks;
}

/**
 * Chunking para documentos con estructura de secciones (markdown con headers)
 * @param {string} content - Contenido markdown
 * @param {Object} options - Opciones
 * @returns {Array<Object>} Chunks preservando jerarquía
 */
function chunkMarkdownDocument(content, options = {}) {
  const opts = { ...DEFAULT_OPTIONS, ...options };
  
  // Dividir por headers (# ## ###)
  const sectionRegex = /^(#{1,6})\s+(.+)$/gm;
  const sections = [];
  let lastIndex = 0;
  let match;

  while ((match = sectionRegex.exec(content)) !== null) {
    const headerLevel = match[1].length;
    const headerText = match[2];
    const startIndex = match.index;
    
    if (startIndex > lastIndex) {
      // Contenido antes de este header
      const prevContent = content.slice(lastIndex, startIndex).trim();
      if (prevContent) {
        sections.push({ level: 0, title: '', content: prevContent });
      }
    }
    
    sections.push({ level: headerLevel, title: headerText, content: '' });
    lastIndex = sectionRegex.lastIndex;
  }

  // Capturar contenido después del último header
  if (lastIndex < content.length) {
    const remaining = content.slice(lastIndex).trim();
    if (remaining) {
      sections.push({ level: 0, title: '', content: remaining });
    }
  }

  // Procesar cada sección
  const allChunks = [];
  let globalIndex = 0;

  for (const section of sections) {
    if (!section.content.trim()) continue;
    
    const sectionChunks = chunkDocument(section.content, options);
    
    for (const chunk of sectionChunks) {
      allChunks.push({
        ...chunk,
        index: globalIndex++,
        sectionTitle: section.title,
        sectionLevel: section.level,
      });
    }
  }

  // Actualizar totalChunks e índices
  return allChunks.map((chunk, i) => ({
    ...chunk,
    index: i,
    totalChunks: allChunks.length,
  }));
}

module.exports = {
  chunkDocument,
  chunkMarkdownDocument,
  estimateTokens,
  computeContentHash,
  splitIntoParagraphs,
  splitIntoSentences,
  DEFAULT_OPTIONS,
};