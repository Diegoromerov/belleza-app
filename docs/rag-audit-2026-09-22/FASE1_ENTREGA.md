# FASE 1 — Filtros, citas y trazabilidad · entrega verificada

**Fecha**: 2026-09-23 · **Rama**: `fix/rag-filtros-citas-trazas` · **Plan**: `PLAN_MEJORA_RAG.md` Fase 1
**Objetivo**: que el RAG deje de devolver "0 resultados" en silencio por filtros que no existen, que
las citas digan la verdad y que la traza permita diagnosticar sin reproducir.

---

## 1. Qué cambió

| # | Archivo | Antes | Ahora |
|---|---|---|---|
| 1.1 | `config/knowledgeCategories.js` (nuevo) + `auraToolExecutor.js:117` | El tool ofrecía texto libre con la descripción *"Categoría cosmética (ej. piel, cabello, uñas)"*: valores que **no existen** en el corpus | `enum` con las **12 categorías reales** del corpus; `ragService` normaliza acentos/mayúsculas (`"Guías Uñas"` → `guias_unas`) |
| 1.2 | `ragService.buildMetadataFilters` | `category = $n` con cualquier valor → 0 filas | Si el valor no está en el vocabulario: **no filtra**, lo registra en `filters_dropped` (fail-open) |
| 1.3 | `ragService` `skin_type` | `skin_type ILIKE $n` sobre una columna que **la ingesta canónica nunca escribe** (NULL en todas las filas) → 0 filas | `EXISTS` sobre `metadata->'skin_types'`, incluyendo el contenido universal (`all`/`todas`/`todos` = 4.526 de 5.619 chunks que antes quedaban excluidos) |
| 1.4 | `ragService` `domain` | `metadata->>'domain' = $n` sobre una clave que existe en **0 de 5.619** chunks → 0 filas | Compara `category` y `metadata->'applicable_modules'` (campos reales) |
| 1.5 | `ragService` `ingredients` / `contraindications` | `ingredients::text ILIKE` / `contraindications::text ILIKE` sobre columnas que la ingesta no escribe | Mismo predicado de lista JSONB sobre `metadata` |
| 1.6 | `ragService` (red de seguridad) | Un filtro sin datos devolvía vacío como si no hubiera conocimiento | Reintento **único** sin filtros de *pista* (`category`, `skin_type`, `ingredients`, `contraindications`) + `filters_relaxed = true` en la traza. **Los filtros de alcance (`domain`, `jurisdiction`) NO se relajan** y el aislamiento de tenant jamás se relaja |
| 1.7 | `ragService` SELECT (vectorial y FTS) | `id, title, content, category, metadata, tenant_id, expires_at` | + `chunk_id, document_id, fuente, seccion` → se puede citar |
| 1.8 | `ragService` fallback FTS | `0.5 AS similarity` (constante inventada → "Similitud: 50%" siempre) | `NULL::double precision AS similarity` + `mode = 'fts'` |
| 1.9 | `ragService.formatKnowledgeContext` | "📚 Fuente:" tomaba `metadata.source \| legal_basis \| jurisdiction \| authority \| version`, claves que existen en **0 de 5.619** chunks → mostraba el slug de categoría o el literal `GlowApp Canon`; y siempre "(Similitud: N%)" | Cita `fuente`, `seccion` y `chunk_id` reales; la similitud sólo aparece si se midió |
| 1.10 | `ragLogger` | Insertaba **9 de 17** columnas: `category`, `threshold_used`, `filters_applied`, `all_scores`, `retrieval_mode`, `fallback_triggered`, `breaker_state_at_query` quedaban NULL para siempre | Las 16 columnas (sin `id`) con valores reales + `filters_dropped`, `filters_relaxed` en la traza JSON |
| 1.11 | `geminiService:304` | La traza registraba `threshold: 0.72` mientras la búsqueda usaba `0.45` | Una sola fuente: se registra el umbral realmente usado; también `retrieval_mode`, `fallback_triggered`, `all_scores`, y la latencia real del embedding (antes siempre `0`) |
| 1.12 | `geminiService.shouldSearchBeautyKnowledge` | `AHA` y `BHA` (2 de 103 disparadores) no podían coincidir: se comparaban en mayúsculas contra texto en minúsculas | Comparación normalizada |
| 1.13 | `scripts/verifyKnowledgeCategories.js` (nuevo) | — | Verifica que el vocabulario coincida con `SELECT DISTINCT category` y que cada categoría devuelva chunks (código de salida apto para CI) |

## 2. Evidencia (medida contra Postgres, código de `main` vs código nuevo, mismas 5 filas de prueba)

`probes/probe_fase1.js` — crea 5 filas con categorías/metadata reales (`document_id = 'zz-fase1-probe'`),
ejecuta el `ragService` de `main` y el nuevo, y borra lo que creó (verificado: 0 filas restantes).

| Filtro aplicado | ANTES (`main`) | DESPUÉS (Fase 1) | Traza |
|---|---|---|---|
| `category='Piel'` | **0 chunks** | 5 chunks | `filters_dropped: [{category, 'Piel', not_in_canonical_vocabulary}]` |
| `category='Uñas'` | **0 chunks** | 5 chunks | igual |
| `category='guias_unas'` | 2 chunks | 2 chunks | `filters_applied: {category: guias_unas}` |
| `category='Guías Uñas'` | **0 chunks** | 2 chunks | normalizado a `guias_unas` |
| `skin_type='seca'` | **0 chunks** | 4 chunks (`seca` + `all`) | filtro sobre `metadata->skin_types` |
| `skin_type='grasa'` | **0 chunks** | 3 chunks (`grasa` + `all`) | idem |
| `domain='diagnostico_capilar'` | **0 chunks** | 2 chunks | compara contra `category`/`applicable_modules` |
| `domain='BUSINESS'` | **0 chunks** | **0 chunks** (estricto, `relaxed=false`) | el corpus no tiene documentos regulatorios → no se devuelve contenido de otro dominio |
| sin filtros | 5 chunks | 5 chunks | — |

Cita generada (antes: `Fuente: guias_unas`; ahora):

```
[1] Esmaltado semipermanente (Similitud: 100%)
   📚 Fuente: canon/guias_unas [Sección: tecnicas] [Chunk: zz-fase1-chunk-0]
```

Trazabilidad (`probes/probe_traza.js`, fila real escrita y leída de `rag_query_logs`):

```
threshold_used: "0.450" | retrieval_mode: "hnsw" | fallback_triggered: false
category: "guias_unas"  | breaker_state_at_query: "CLOSED" | all_scores: [0.83, 0.71, 0.55]
filters_applied: {"category": "guias_unas"}
✅ 16/16 columnas con valores reales   (antes: 7 en NULL)
```

Tests: **50 verdes** en las suites RAG (`ragService` 17, `knowledgeCategories` 4, `embeddingService`,
`beautyKnowledge`, `businessRAG`), frente a 35 antes de la Fase 1.

## 3. Cómo reproducir

```bash
cd backend
npx jest --testPathPattern="(ragService|knowledgeCategories|embeddingService|beautyKnowledge|businessRAG)"
node ../../docs/rag-audit-2026-09-22/probes/probe_fase1.js    # filtros: antes vs después
node ../../docs/rag-audit-2026-09-22/probes/probe_traza.js    # 16/16 columnas de traza
node scripts/verifyKnowledgeCategories.js                     # vocabulario vs base de datos
```

## 4. Límites y pendientes declarados

- El embedding de las sondas es **sintético** (vector unitario de 1024 d): el modelo real de 1024 dims
  está retirado. Se verifica el comportamiento de los filtros y de las citas, **no** el ranking (Fase 0/2).
- El corpus canónico **no contiene documentos regulatorios** (0 chunks con `business`/`resolucion`/
  `formalizacion`; 2 con `invima`): `search_regulatory_knowledge_rag` devuelve vacío por **falta de
  datos**, no por el filtro. Cargar ese corpus es una decisión de datos (Fase 4).
- `metadata.skin_types` tiene datos sucios (95 valores distintos: `seca`/`seco`/`dry`/`muy_seca`/
  `con rosácea`…). El filtro ya no mira el JSON completo, pero normalizar ese vocabulario es trabajo de
  corpus (Fase 2).
- La tabla `rag_query_logs` **no tiene** columnas de latencia de embedding/retrieval: ese detalle sólo
  queda en el log JSON (`logs/rag_traces.log`). Añadirlas es una migración aparte.
- Cambios de umbral (rol de `threshold_used`) son Fase 0: aquí sólo se registra el valor real.
