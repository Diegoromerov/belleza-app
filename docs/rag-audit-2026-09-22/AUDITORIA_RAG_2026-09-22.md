# AUDITORÍA RAG — Belleza App / GlowApp
**Fecha:** 2026-09-22 · **Auditor:** Hermes (independiente) · **Alcance:** pipeline RAG de Aura (retrieval + embeddings + ingesta + trazabilidad)
**Clon auditado:** `C:\beauty-app` (branch `main`, HEAD `f036b8f2`) — **idéntico a `origin/main`** (`git rev-list --left-right --count main...origin/main` → `0 0`).
**No se tocó Railway/producción.** Toda validación se hizo contra la BD local `beauty-postgres` (5435) en modo lectura.

> El clon del cwd (`C:\Users\Compu casa\belleza-app`, HEAD `4f803a0b`) está congelado y **divergió**: `git merge-base --is-ancestor 4f803a0b origin/main` → **NO**. Su RAG es otro (más viejo). Todo lo de abajo aplica al código desplegado.

---

## 1. Cadena real de ejecución

```
geminiService.processAssistantMessage()
  ├─ shouldSearchBeautyKnowledge(text)   geminiService.js:175  (gate por keywords, RAG_TRIGGER_KEYWORDS:87)
  ├─ searchBeautyKnowledge(q,{topK:5,threshold:0.45})   geminiService.js:297
  │     └─ ragService.searchBeautyKnowledge   ragService.js:85
  │           ├─ generateEmbedding (ragService.js:16) → embeddingService.generateNvidiaEmbedding (sin breaker)
  │           ├─ SQL vectorial `<=>` sobre beauty_knowledge_embeddings   ragService.js:114-129
  │           ├─ catch → FTS español (plainto_tsquery)   ragService.js:141-183
  │           └─ pool = ragPool || pool   ragService.js:132
  ├─ formatKnowledgeContext → systemInstruction   geminiService.js:313-321
  ├─ cache semántico (SIMILARITY_THRESHOLD 0.92, identidad por usuario)   semanticCache.js:11
  └─ logRagQuery → rag_query_logs   geminiService.js:930 / ragLogger.js:130
Tool path: executeAuraTool('search_beauty_knowledge_rag'|'search_regulatory_knowledge_rag') → ragService   auraToolExecutor.js:277, :305
```

---

## 1b. Conteo de chunks (respuesta directa)

| Fuente | Chunks | Evidencia |
|---|---|---|
| **Corpus canónico (`corpus_canonico.json` v1.0.0)** | **5.619** | `total_chunks: 5619`, 12 dominios, 14 MB, generado 2026-09-03 |
| Ídem, según el baseline oficial R5B | 5.619 | `data/eval/baseline_real_r5b.json` → `corpus.chunks = 5619` |
| **Filas en BD durante R5B/R6** (`beauty_knowledge_embeddings`) | **5.663** (5.619 + 44 históricos), 0 NULLs de embedding, HNSW operativo | `r6c10_corpus_forensics_a.json` → `database_integrity: {total: 5663, nulls: 0, nonnulls: 5663, hnsw_operational: true, status: PASS}` |
| **Filas en BD local HOY (2026-09-22)** | **0** | `SELECT count(*) FROM beauty_knowledge_embeddings` → 0 |
| Seed legacy | 17 chunks en `seed_beauty_knowledge.js` | escribe en `knowledge_chunks` (tabla inexistente en la BD) |
| Dataset de evaluación | 30 queries / 65 expected_chunks (63 únicos) | `dataset_manifest_v2.json`; sólo 15-18 soportadas por el corpus actual |
| GOLD-V5 (último set de calidad) | 15 queries / 58 gold chunks | `r6_final_closure_report.json` → `baseline.gold_v5` |

Composición del corpus: 12 documentos de ~400-530 chunks cada uno (`tratamientos_esteticos_faciales` 497, `cuidado_corporal_y_spa` 526, `guias_unas` 504, `tendencias_belleza_virales` 501, `colorimetria_piel_undertone` 485, …), todos con `clinical_review_status = pending_review` (5.619/5.619), riesgo `alto` 806 / `medio` 1.937 / `bajo` 2.876, y 1.279 chunk_ids > 64 chars (máx 125) — el motivo de la migración 048.

Último estado de calidad medido (R6, cierre 2026-08-17): MRR **0.7222**, R@5 0.6156, R@10 0.6545, R@50 0.8011, latencia p50 500 ms, veredicto **REPRESENTATION-BOUND** (8 conceptos ultraespecializados irrecuperables con `nv-embedqa-e5-v5`).

---

## 1c. Verificación DIRECTA sobre GitHub (repo remoto, no el clon local)

**Repo:** `github.com/Diegoromerov/belleza-app` — **público** (`private: false`), default branch `main`.
**HEAD de `main` en GitHub:** `7f461caf69682a3ccd6c9cf25e461ed902ad5219` (2026-09-22 22:44 −05, `pushed_at` 2026-09-23T03:44Z), confirmado por API (`/commits/main`).
**El clon local estaba 4 commits por detrás** (`git rev-list --left-right --count HEAD...origin/main` → `0 4`). Los 4 commits nuevos (`526faaf5`, `018ae175`, `549f46…`, `7f461caf`) tocan **solo OAuth/frontend** (`oauthController.js`, `frontend/Dockerfile`, `login_screen.dart`, `web/index.html`) — **ningún archivo de RAG**. La auditoría sigue válida en el HEAD remoto.

### Integridad archivo por archivo (blob SHA local vs `origin/main`)
Los 13 archivos auditados son **byte-idénticos** entre el clon local y GitHub: `ragService.js`, `embeddingService.js`, `circuitBreakerService.js`, `beautyKnowledgeService.js`, `ragLogger.js`, `geminiService.js`, `auraToolExecutor.js`, `ingestCanonicalCorpus.js`, `ingestBeautyKnowledge.js`, migraciones `031`, `046`, `048` y `RAG_ARCHITECTURE.md`.

### Hallazgos re-verificados sobre el contenido remoto (`git grep … origin/main`)
| Hallazgo | Línea en GitHub |
|---|---|
| Dummy como fallback del breaker | `embeddingService.js:138` |
| Dummy devuelto tras 3 fallos / en rama local | `embeddingService.js:160`, `:165` |
| `breakers` sin `nvidiaEmbeddings` | `circuitBreakerService.js:72-76` (solo youcam, gemini, deepseek) |
| `tenantId` interpolado (2 rutas) | `ragService.js:103`, `:152` |
| `executeAuraTool` sin tenantId | `geminiService.js:534`, `:831` |
| `category` descartado | `auraToolExecutor.js:277` |
| Logger inserta 9 de 16 columnas | `ragLogger.js:131-133` |
| `ON CONFLICT (title)` en ingesta legacy | `ingestBeautyKnowledge.js:297` |
| Test que valida el dummy | `tests/embeddingService.test.js:110-136` |

### Ejecución del código de GitHub (extraído con `git archive origin/main` y ejecutado)
```
[G1] breakers registrados en GitHub/main: youcam, gemini, deepseek
[G2] ¿existe breakers.nvidiaEmbeddings? -> false
[G3] embeddingService exporta generateDummyEmbedding -> function
[G4] dummy dims=1024 primeros3=0.02117,-0.00706,-0.04257
⚠️ NVIDIA Embedding fallo local #1/3: NVIDIA_API_KEY no configurada en variables de entorno
[G5] generateEmbedding sin API key -> NO lanzó error, devolvió vector de 1024 dims (dummy silencioso)
```

### Causa raíz de la contradicción doc ↔ código (encontrada)
- El fix real del MVP RAG (**dummy eliminado, breaker, `category` en `filters`, `beautyKnowledgeService` como fachada deprecated**) existe en el commit **`68ce4b4e feat(rag): consolidate Aura RAG MVP R1-R4`** (2026-08-13)…
- …y ese commit **NO es ancestro de `origin/main`**: vive únicamente en la rama **local, nunca pusheada**, `codex/rag-aura-r1-r4` (`git ls-remote --heads origin codex/rag-aura-r1-r4` → vacío; `git branch -a --contains 68ce4b4e` → solo esa rama). La rama está **524 commits por detrás** de `main`, así que no es mergeable tal cual; hay que portar los 4 archivos.
- La **documentación** de ese fix sí llegó a GitHub: `RAG_ARCHITECTURE.md` entró a `main` vía `dc8c570c fix(audit360): …` / `805c64b6 docs: consolidacion…`. Se subió el informe, no el código.
- Ningún commit en todo el historial de la rama `main` añadió `nvidiaEmbeddings` al registry (`git log --all -S"nvidiaEmbeddings"` solo aparece en commits de ramas/PR ajenas a main).

### Otros hechos verificados en el remoto
- El corpus canónico **sí está versionado en GitHub**: `corpus_canonico.json` = 13.806.217 bytes (los 5.619 chunks), `corpus_manifest.json` 238.712 bytes, y los artefactos de evidencia (`baseline_real_r5b.json`, `r6_final_closure_report.json`, `r6c10_corpus_forensics_a.json`, `evaluation_dataset.json`) también.
- **No hay secretos commiteados**: el único archivo `.env*` en `origin/main` es `backend/.env.example` y no contiene claves. (El repo es **público**: el corpus, la evaluación y los docs son visibles para cualquiera.)
- **Parche recuperable** (contenido de `68ce4b4e`): `generateEmbedding()` pasa a ser `return generateNvidiaEmbedding(...)` con el comentario de que la ingesta debe fallar el chunk antes que guardar un vector falso; `ragService` usa `generateNvidiaEmbedding` y lanza en vez de fabricar vector; `beautyKnowledgeService` queda como fachada `@deprecated` de 7 líneas; `auraToolExecutor.js:277` pasa `filters: { category }`. Es exactamente la corrección de H3 y H4.

---

## 2. Hallazgos

| ID | Sev | Hallazgo | Evidencia |
|----|-----|----------|-----------|
| **H1** | **Crítico** | `tenantId` se **interpola** en el SQL (no parametrizado) en las dos rutas (vectorial y FTS) → multi-tenant roto por payload | `ragService.js:103`, `ragService.js:152` |
| **H2** | Alto | El camino Aura **nunca pasa `tenantId`** → el filtro queda en `tenant_id IS NULL` y el conocimiento por tenant jamás se recupera | `geminiService.js:534`, `:831` vs firma `auraToolExecutor.js:188` |
| **H3** | Alto | **Dummy embedding sigue en el camino productivo** (contradice R2) y el `circuit breaker nvidiaEmbeddings` **no existe** | `embeddingService.js:138`, `:145-165`; registry `circuitBreakerService.js:72-76`; `ragService.js:16-31`; test `embeddingService.test.js:110-131` |
| **H4** | Medio-Alto | El parámetro `category` de la tool RAG **se descarta**: se pasa en la raíz y ragService sólo lee `options.filters.category` | `auraToolExecutor.js:277` vs `ragService.js:86`, `:45-49` |
| **H5** | Medio | Trazabilidad incoherente: se consulta con `threshold 0.45` pero se registra `0.72`; y **nadie escribe las columnas de 047** — `saveToPostgres` inserta sólo 9 columnas, así que `retrieval_mode` queda siempre en su DEFAULT `'hnsw'` y `fallback_triggered` en `false`, incluso cuando el retrieval devolvió 0 chunks | `geminiService.js:297` vs `:304`,`:362`,`:937`; `ragLogger.js:129-145`; filas reales: `threshold_used=NULL, retrieval_mode=hnsw, fallback_triggered=f` con `chunks_retrieved=0` |
| **H6** | Medio | Fail-open silencioso: si el vector devuelve 0 chunks **no** se activa FTS (el fallback sólo ocurre con excepción) y el score FTS es fijo `0.5` | `ragService.js:141` (catch), `:170` |
| **H7** | Medio | Corpus canónico (**5.619 chunks**) no está ingestado en la BD local (**0 filas**) → retrieval real = 0 resultados | `corpus_canonico/corpus_canonico.json` (14 MB, 5.619 ítems); `count(*)` = 0 |
| **H8** | Medio | `RAG_ARCHITECTURE.md` afirma cosas que el código desmiente (doc != código) | ver §4 |
| **H9** | Bajo | `.env.local` (con `RAG_DATABASE_URL` local) **no lo carga nadie** (`git grep env.local` = 0 hits) → `ragPool` es `null` en local y todo cae al `pool` principal; el procedimiento R4 del doc no funciona como está escrito | `db.js:683`; `.env.local`; sin `dotenv.config({path:'.env.local'})` |
| **H10** | Bajo | Legacy `beautyKnowledgeService.js` sigue con `aura_knowledge_chunks` (tabla inexistente), dummy y `pool` principal — **0 callers** (dead code), no es el "wrapper" documentado | `beautyKnowledgeService.js:135` |
| **H11** | Bajo | Eval real (R5B, 18 queries) muy por debajo de gates: P@5 0.156 · R@5 0.167 · MRR 0.222 · faithfulness 0 · p95 3.640 ms | `data/eval/evaluation_real_r5b_runB_20260814T002252.json` |

### H1 — Prueba reproducible (ejecutada)
Réplica exacta del generador de SQL (`ragService.js:92-131`) sobre una tabla TEMP con 1 fila global, 1 de otro tenant y 1 borrada:

```
tenantId=null                     -> 0 filas
tenantId=10                       -> 1 filas: GLOBAL
tenantId="10') OR TRUE --"        -> 3 filas: GLOBAL | TENANT_AJENO_99 | BORRADO_99
```
El payload **cierra el paréntesis** y neutraliza el filtro de tenant **y** el de soft-delete. Explotabilidad actual: baja (hoy `tenantId` es `null` en el camino Aura), pero la superficie existe y crecerá en cuanto se pase el tenant real (H2). RLS no salva: `relrowsecurity=t` pero `relforcerowsecurity=f` y el pool conecta como dueño → RLS inerte.

### H3 — Verificación de runtime
`node` con el `.env` real (sin `NVIDIA_API_KEY`): `ragService.generateEmbedding('niacinamida...')` → `dims=1024 primeros3=0.02492,0.01768,-0.03984` = **vector dummy determinístico, sin excepción y sin FTS**. Con la tabla vacía el retrieval devolvió `0 chunks` en 4 variantes (topK/threshold/filtros).

---

## 3. Lo que SÍ está bien
- Esquema canónico sólido: `vector(1024)`, índice **HNSW** (`m=16, ef_construction=64`), UK `(document_id, chunk_id)`, columnas de trazabilidad, FK a `tenants`, índices GIN de metadata — todo verificado en `\d beauty_knowledge_embeddings`.
- Migración 048 resolvió el techo real de `chunk_id` (IDs canónicos hasta 125 chars) sin reescribir 046 aplicada — criterio correcto.
- Sanitización PII antes de LLM (`sanitizeContextForLLM`, `geminiService.js:453`) y cache semántico con identidad de usuario (`semanticCache.js:76`, fix A360 C-12).
- Fail-safe en embeddings: sin el try/catch, un fallo de NVIDIA tumbaría el chat.
- Suite RAG: **7 suites / 83 tests PASS** (`npx jest --testPathPattern="(rag|RAG|embedding|knowledge)"`).

---

## 4. Doc vs código (`RAG_ARCHITECTURE.md`)
| Afirmación del doc | Realidad |
|---|---|
| `:115` "NO dummy fallback!" | `embeddingService.js:138` pasa `generateDummyEmbedding` como fallback del breaker; `:160` lo devuelve tras 3 fallos; `ragService.js:26-31` lo genera si falta la key |
| `:86,:270` "breaker `nvidiaEmbeddings` (3/30s)" | No existe en `breakers` (`circuitBreakerService.js:72-76`); la rama `if (breakers?.nvidiaEmbeddings)` nunca se ejecuta |
| `:123` "`beautyKnowledgeService` convertido a wrapper" | Sigue siendo el legacy con `aura_knowledge_chunks` (`:135`) |
| `:242` "036/047 aplazadas porque el logger tiene fallback silencioso" | Ambas están **aplicadas** en la BD local (columnas de 047 presentes y con defaults), pero **ningún código las puebla** → observabilidad nominal, no real |
| `:272` "R4 PASS, 44 filas, 31 hashes" | Hoy la BD local tiene **0 filas**; el corpus canónico (5.619 chunks / 5.663 en BD durante R6) no está ingestado |
| `:283` "69/69 tests" | 83 tests ahora, pero `embeddingService.test.js:110` **valida el dummy** como comportamiento esperado |

---

## 5. Plan de corrección (P0 → P2)
**P0 · Aislamiento y semántica**
1. Parametrizar `tenantId` en `ragService.js:103` y `:152` (`tenant_id::text = $n`, nunca interpolado) + test de inyección con payload.
2. Pasar `tenantId` (y `userRole`) desde `geminiService.js:534/:831` → `executeAuraTool(...)`, y activar `ALTER TABLE ... FORCE ROW LEVEL SECURITY` o conectar con rol no-dueño.
3. Eliminar el fallback dummy de la ruta de producción: `embeddingService.generateEmbedding` debe lanzar; añadir `nvidiaEmbeddings` al registry; `ragService.generateEmbedding` debe fallar → FTS; actualizar `embeddingService.test.js` para afirmar el `throw` (hoy afirma lo contrario). **Ya existe código para esto**: portar (no mergear) los 4 archivos de `68ce4b4e` — `embeddingService.js` (`return generateNvidiaEmbedding(...)`), `ragService.js` (sin vector fabricado), `beautyKnowledgeService.js` (fachada `@deprecated`), `auraToolExecutor.js` (`filters: { category }`).
4. `auraToolExecutor.js:277` → `filters: { category }`. **Pushear la rama `codex/rag-aura-r1-r4` o el parche a `origin`**: hoy el fix solo existe en el clon local `C:\beauty-app`; si ese clon se pierde, se pierde el trabajo.

**P1 · Observabilidad e integridad**
5. Aplicar 036/047 en el entorno que corresponda y quitar el silencio de `ragLogger.js:149` (métrica + alerta).
6. `geminiService.js:304` → registrar el threshold real (0.45) y la latencia de embedding (hoy `0` en `:359`).
7. Cargar `.env.local` explícitamente o documentar el `export` obligatorio de `RAG_DATABASE_URL` (H9); abortar el arranque si falta en un entorno que declare RAG habilitado.
8. Ingestar el corpus canónico (`scripts/ingestCanonicalCorpus.js`, ya upserta por `(document_id, chunk_id)` y aborta si la URL no es local) y reejecutar la eval real.

**P2 · Calidad de recuperación**
9. Umbral efectivo: hoy `>= 0.45` con embeddings E5 y query corto deja fuera casi todo; el fallback FTS con score fijo `0.5` mezcla escalas — unificar (normalizar o marcar `retrieval_mode`).
10. Gate de degradación: si el vector devuelve 0 chunks → intentar FTS y registrar `fallback_triggered`.
11. Los experimentos `r5c12…r5c29` deben cerrarse contra HNSW real con corpus ingestado (P@5 0.156 / MRR 0.222 no supera gates).

**Fuera de alcance / no tocar sin decisión:** `beautyKnowledgeService.js` (dead code — borrar o dejar documentado, pero no "arreglar" la tabla inexistente) y `aura_knowledge_chunks` (no existe en ninguna migración).

---

## 6. Veredicto
**RAG desplegado: PARCIAL.**
Arquitectura y esquema correctos y bien instrumentados en papel; **runtime degradado**: embeddings dummy alcanzables, breaker de embeddings inexistente, aislamiento por tenant ausente + interpolación SQL explotable, trazas RAG no persistidas y base de conocimiento vacía en el entorno validado. Con el estado actual, Aura responde **sin conocimiento recuperado** y sin señal de que lo está haciendo.

---

## 7. Actualización 2026-09-22 — causa raíz encontrada y estado tras el merge

> Añadido después de la auditoría inicial. No modifica el veredicto: lo explica y lo acota.

### 7.1 La causa raíz de fondo: el modelo de embeddings está retirado

| Prueba (ejecutada con la key del proyecto) | Resultado |
|---|---|
| `GET https://integrate.api.nvidia.com/v1/models` | **HTTP 200** → key **válida** |
| `POST /v1/embeddings` con `nvidia/nv-embedqa-e5-v5` | **HTTP 410 Gone** |

```json
{"type":"about:blank","title":"Gone","status":410,
 "detail":"The model 'nvidia/nv-embedqa-e5-v5' has reached its end of life on 2026-08-25T09:00:00Z and is no longer available."}
```

De los **7** modelos de embedding que lista la API, con esta cuenta responde **solo uno**:
`nvidia/nemotron-3-embed-1b` → **2048 dimensiones**. Los otros 6 devuelven
`404 Not found for account` (catálogo global ≠ entitlement de la cuenta).

Bloqueos derivados, medidos: el código valida 1024 dims (`embeddingService` `expectedDimension`,
`ragService` `EXPECTED_DIMS`) y la columna es `vector(1024)`; y el umbral `0.45` descarta la
respuesta correcta con el modelo vivo (el documento correcto puntuó **0.4156** vs 0.1988 del 2º).

### 7.2 Matriz antes/después (código extraído del propio repo con `git show`, key real, BD local)

| Escenario | Antes (`43170150`) | Después (PR #6) |
|---|---|---|
| Ingesta con key (modelo EOL) | **dummy fabricado, sin error** | lanza `410` → chunk fallido, no se guarda vector falso |
| Ingesta sin key | dummy fabricado, sin error | lanza error |
| Retrieval con key | FTS (`similarity=0.5`) | FTS (`similarity=0.5`) |
| Retrieval sin key | **0 filas, sin fallback** | FTS (1 fila) |

### 7.3 Cobertura funcional (rúbrica de 17 compuertas, evidencia por compuerta)

| Columna | Resultado |
|---|---|
| Implementación en el repo | 73,5% (12,5/17) |
| Operativo con el código previo | 58,8% (10/17) |
| Operativo tras PR #6 | 73,5% (12,5/17) |
| Búsqueda semántica | **0%** (modelo retirado) |

### 7.4 Corrección de un punto de la §1 inicial

La afirmación "el fallback full-text no se activa porque el dummy no lanza" es cierta **solo** en el
retrieval **sin** `NVIDIA_API_KEY`. Con la key presente, el `410` del modelo EOL **sí** disparaba el
FTS en el código anterior. El dummy silencioso mordía en (a) retrieval sin key y (b) **la ingesta**,
que indexaba vectores sin valor semántico sin reportar error.
