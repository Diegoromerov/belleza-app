# PLAN DE MEJORA DEL RAG — Aura / Belleza App

**Fecha**: 2026-09-22 · **Base**: auditoría `AUDITORIA_RAG_2026-09-22.md` §7 + banco de pruebas
`benchmark/` · **Rama**: `docs/rag-eol-corrections-2026-09-22` · **Estado**: propuesto, sin ejecutar

> Toda cifra marcada **[MEDIDO]** se ejecutó en esta máquina y es reproducible con las sondas de
> `probes/` y el banco de `benchmark/`. Lo marcado **[ESPERADO]** es proyección con su número de
> partida para poder verificarla.

---

## 0. Punto de partida (línea base medida)

| Métrica | Valor hoy |
|---|---|
| Modelo de embeddings | `nvidia/nv-embedqa-e5-v5` → **[MEDIDO]** HTTP 410 Gone (EOL 25-ago-2026) |
| Key NVIDIA | **[MEDIDO]** válida (`GET /v1/models` → 200); único modelo de embedding habilitado: `nvidia/nemotron-3-embed-1b` (**2048 d**) |
| Chunks en el corpus canónico | 5.619 (100% en `clinical_review_status = pending_review`) |
| Chunks embebidos en BD local | **0** |
| Retrieval vectorial | **[MEDIDO]** 0 filas |
| Ranking (modelo vivo, índice 5.619, 18 queries) | **[MEDIDO]** vector: R@5 16,9% · R@10 38,2% · MRR 0,251 · 2 misses |
| Coste de ingesta | **[MEDIDO]** 1.053 ms/embedding (1 input por llamada) → ~98 min |
| Umbral de admisión | 0,45 — **[MEDIDO]** corta la mediana de los aciertos (0,427) y admite la del ruido (0,477) |
| Compuertas del proyecto (`qualityGates.js:10-14`) | P@5 ≥ 0,70 · R@5 ≥ 0,60 · MRR ≥ 0,65 → **ninguna alcanzada** |
| Cobertura funcional (rúbrica 17 compuertas) | 73,5% implementado · **búsqueda semántica 0%** |

**Conclusión de partida**: el RAG está bien construido en arquitectura y seguridad (tras PR #6), pero
**no recupera conocimiento**, y su instrumentación no lo delata.

---

## 1. Decisiones que el plan resuelve (con recomendación)

Cada decisión trae recomendación y alternativa. Si apruebas el plan tal cual, se ejecuta la
recomendación; si quieres cambiarla, indícalo por número.

| # | Decisión | Recomendación | Alternativa y por qué no |
|---|---|---|---|
| **D1** | Qué modelo de embeddings | **Medir 3 candidatos con el banco (`benchmark/`) antes de migrar el esquema**: `nvidia/nemotron-3-embed-1b` (2048 d, ya habilitado, coste cero de alta), un multilingüe de proveedor (tipo `text-embedding-3-large`, 3072 d) y un local (`bge-m3`). El banco es agnóstico del proveedor: cambiar una función | Adoptar nemotron sin medir: rápido, pero **fija dimensiones y re-ingesta** (la parte cara de revertir) sobre un modelo que no sabemos si discrimina en español |
| **D2** | Cómo migrar las dimensiones | **Columna nueva `embedding_next vector(N)` + doble escritura y conmutación por flag**; la vieja queda intacta hasta validar | `ALTER COLUMN TYPE` in-place: más simple, **sin vuelta atrás** y con el índice HNSW reconstruido a ciegas |
| **D3** | Rol del umbral 0,45 | **Piso de admisión calibrado y bajo (~0,30, por tenant) + el ranking decide**; el umbral deja de ser el filtro de calidad | Mantener 0,45: **[MEDIDO]** descarta más aciertos que ruido |
| **D4** | ¿Filtros/citas/trazas en PR aparte del de embeddings? | **Sí**: son independientes del modelo, arreglan una regresión viva y se verifican sobre el fallback FTS | Juntarlos: PR grande, imposible atribuir regresiones |
| **D5** | Set de evaluación canónico | **Adoptar GOLD-V5** (`evaluation_dataset_v5_candidate.json`: 37 core + 22 supporting, 100% alineados, anotación ciega). v1/v2 quedan congelados como históricos | Seguir con `evaluation_dataset.json`: **[MEDIDO]** 0/80 gold existen en el corpus |

---

## 2. Fases

### FASE 1 — Dejar de responder "0 resultados" en silencio *(tamaño M · riesgo bajo · sin dependencias)*

> ✅ **EJECUTADA** — PR #8 (`fix/rag-filtros-citas-trazas`, 2026-09-23). Evidencia y límites en
> `FASE1_ENTREGA.md`; 50 tests verdes en las suites RAG y mismos 73 rojos preexistentes (0 nuevos).

**Por qué primero**: arregla una **regresión introducida por PR #6** (el tool pasó a aplicar un
filtro con vocabulario que el LLM no puede acertar → 0 chunks garantizados) y no depende de la
decisión de modelo, así que se puede verificar ya sobre el fallback FTS.

| # | Cambio | Archivo:línea | Criterio de aceptación |
|---|---|---|---|
| 1.1 | Vocabulario de categorías: el enum del tool debe ofrecer **las 12 categorías reales** del corpus (o mapear etiqueta humana → categoría real) | `auraToolExecutor.js:277-282` (filtro) y el schema del tool `:42`, `:89`, `:117`; corpus: 12 categorías `guias_unas`, `diagnostico_capilar`, `colorimetria_capilar_tinte`, … | **[MEDIDO hoy: 0 chunks para 10/10 valores humanos]** → script que recorre los 12 valores y exige N>0 en todos |
| 1.2 | Filtro `domain`: lee `metadata->>'domain'` (clave inexistente en 5.619/5.619) → usar la clave real (`applicable_modules`) o retirarlo | `ragService.js:49-53` | Consulta con `domain` devuelve N>0 |
| 1.3 | Filtro `skin_type`: hoy `ILIKE` sobre todo el JSON de metadata (coincide por accidente) → predicado exacto | `ragService.js:37-41` | `metadata->'skin_types' ? $n` |
| 1.4 | **Valor fuera del vocabulario ⇒ no filtrar y registrarlo** (nunca devolver vacío con apariencia de "no hay información") | `ragService.js:32-75` | Test: valor desconocido → resultados + traza con `filters_applied` |
| 1.5 | Devolver identidad para **citar**: `chunk_id`, `document_id`, `fuente`, `seccion` en el SELECT vectorial y en el FTS | `ragService.js:132-141` y `:178-190` | La cita de Aura coincide con la fila en BD |
| 1.6 | Quitar la similitud inventada del fallback (`0.5` fijo) y marcar `retrieval_mode='fts'` | `ragService.js:185` | El prompt/usuario no muestra similitudes falsas |
| 1.7 | Cita real: hoy `formatKnowledgeContext` busca 5 claves que existen en **0/5.619** chunks → usar `fuente`/`seccion`/`_source_files` | `ragService.js:208-219` | "📚 Fuente:" muestra la fuente real, no el slug ni `GlowApp Canon` |
| 1.8 | Traza completa: 16 columnas de `rag_query_logs` + **el umbral realmente usado** (hoy se registra 0,72 con 0,45 en uso) | `ragLogger.js:129-145`, `geminiService.js:304` | Fila con `threshold_used`, `filters_applied`, `retrieval_mode`, `fallback_triggered`, `breaker_state_at_query` |
| 1.9 | Disparadores muertos `AHA`/`BHA` (se comparan contra texto en minúsculas) | `geminiService.js:87-112` | Los 103 disparadores coinciden cuando deben |

**Definición de hecho**: tests de `ragService` en verde + script de verificación de filtros en verde +
una consulta real que devuelve chunks **con cita verificable** y su fila de traza completa.
**Riesgo**: bajo. No toca esquema ni isolation multi-tenant (`appendTenantCondition` intacto).

### FASE 0 — Restaurar la ruta vectorial *(tamaño L · riesgo medio-alto · depende de D1 y D2)*

| # | Cambio | Detalle | Criterio de aceptación |
|---|---|---|---|
| 0.1 | Medir candidatos de modelo | Banco `benchmark/eval_live.js` con 2-3 modelos | Tabla comparativa R@5/R@10/MRR por modelo; se elige con dato, no por disponibilidad |
| 0.2 | Una sola fuente de dimensiones | Hoy 1024 en `embeddingService.js:8-25`, `ragService.js:16`, `verifyRagSchema.js:18`, `ingestCanonicalCorpus.js:19-20` | Un valor (`NVIDIA_EMBEDDING_DIMS`/migración) y validación derivada |
| 0.3 | Migración de dimensiones | Columna nueva `embedding_next vector(N)` + índice HNSW + doble escritura + flag de conmutación (D2) | `verifyRagSchema.js` en verde sin tocar la columna vieja |
| 0.4 | Re-ingesta por lotes | Lotes de 64-128 (`ingestCanonicalCorpus.js:41` hoy 1 input) | **[MEDIDO: 1.053 ms → 86 ms por chunk]** 5.619 chunks en ~8 min; 0 errores; `count(*)` = 5.619 |
| 0.5 | Umbral calibrado (D3) | Piso ~0,30 por tenant, derivado de la distribución de similitudes | **[MEDIDO: gold p50 0,427 vs ruido p50 0,477]** el piso no debe cortar aciertos |
| 0.6 | Verificación end-to-end | Consulta real de punta a punta contra Postgres | Aura responde con chunks recuperados y `retrieval_mode='hnsw'` |

**Definición de hecho**: consulta semántica devuelve el chunk correcto en top-5, traza completa y
benchmark publicado con el modelo elegido. **Riesgo**: esquema y re-ingesta; se mitiga con la
columna dual (rollback = apagar el flag) y re-ejecutando la ingesta idempotente
(`ON CONFLICT (document_id, chunk_id)`, ya implementado).

### FASE 2 — Subir la calidad del ranking *(tamaño M · depende de Fase 0)*

| # | Cambio | Evidencia / objetivo |
|---|---|---|
| 2.1 | **Híbrido RRF** (vector + léxico) en `ragService` | **[MEDIDO con modelo vivo]** R@5 16,9%→**28,3%**, R@50 61,9%→**75,3%**, MRR 0,251→**0,411**, misses 2→1 |
| 2.2 | Reemplazar el FTS actual (`plainto_tsquery` + `ILIKE '%query%'`) por **BM25/ts_rank sobre los mismos tokenizadores** | El fallback de producción hoy casi no responde a lenguaje natural |
| 2.3 | **Rerank** del top-50 al top-5 | **[ESPERADO]** más precisión en el contexto inyectado (los gates piden P@5 ≥ 0,70) |
| 2.4 | Filtros de vigencia/estado (`clinical_review_status`, `expires_at`) dentro del ranking, no como hachazo | Coherente con Fase 4 |
| 2.5 | Medir y decidir datos de corpus: 12 categorías con tamaños muy dispares (526 vs 399) y chunks casi duplicados | Ataca los `misses` residuales |

**Definición de hecho**: benchmark antes/después publicado; ninguna métrica por debajo de la línea base.

### FASE 3 — Cerrar el bucle de medición (CI) *(tamaño M · independiente de Fase 2)*

| # | Cambio | Archivo | Criterio |
|---|---|---|---|
| 3.1 | Dataset canónico GOLD-V5 (D5) | `.github/workflows/rag-evaluation.yml` (hoy `evaluation_dataset.json` → **[MEDIDO]** 0/80 gold existen) | El job mide contra ids reales |
| 3.2 | Ingesta **real** en el job (hoy `--dry-run`) | idem | El job evalúa una base con vectores |
| 3.3 | Coherencia de dimensiones en el chequeo de esquema | `verifyRagSchema.js:18` | Verde con las dims elegidas |
| 3.4 | Baseline versionado + gate de regresión | `src/data/eval/baseline_metrics.json` (hoy desactualizado) | PR que empeora MRR/R@5 falla el job |
| 3.5 | Disparar también cuando cambien servicios y corpus | `on.push.paths` (hoy no incluye `backend/src/services/**`) | El job corre en los PRs que tocan el RAG |

**Definición de hecho**: un PR de prueba que degrada el ranking hace fallar el job; un PR neutro pasa.

### FASE 4 — Gobernanza del conocimiento clínico *(tamaño S, decisión de producto)*

Hoy los 5.619 chunks están en `pending_review` y **ningún servicio lee `clinical_review_status`**:
Aura entrega contenido clínico sin revisión y sin trazabilidad de aprobación. Decisión: (a) disclaimer
explícito en las respuestas que citan el corpus, (b) gate de publicación por estado, o (c) ambas.
**Definición de hecho**: política escrita + consulta que demuestra que solo se sirve lo permitido.

---

## 3. Orden de ejecución propuesto

```
PR #7 (docs)          ← ✅ MERGEADO (main = 17815833)
   └── PR #8  FASE 1  (filtros, citas, trazas)   ← ✅ EJECUTADA, rebasada sobre main, pendiente de merge
   └── PR #9  FASE 0  (modelo, dims, re-ingesta) ← depende de D1/D2
         └── PR #10 FASE 2 (híbrido + rerank)
   └── PR #11 FASE 3  (CI: GOLD-V5 + gates)      ← paralelizable con Fase 0/2
   └── PR #12 FASE 4  (gobernanza clínica)
```

Reglas que respeta: rama por fase + PR (AGENTS.md), identidad de chunk `(document_id, chunk_id)`
intacta, aislamiento multi-tenant (`appendTenantCondition`) intacto, y **nada de reescribir la
evidencia histórica** (los ~120 archivos de evaluación de los ciclos R5/R6 se conservan como están).

## 4. Trampas ya descartadas con medición (no repetir)

| Idea tentadora | Por qué NO |
|---|---|
| Afinar HNSW (`ef_search`) | **[MEDIDO en r5c15]** `ef_search` 40/100/200/400 no cambia ningún rank: HNSW ≡ escaneo exacto |
| Subir `MAX_EMBED_CHARS` de 1.400 | **[MEDIDO]** solo 291 chunks (5,2%) lo exceden; p90 = 1.363 chars → coste sin beneficio |
| Subir el umbral para "más precisión" | **[MEDIDO]** con este modelo ningún umbral separa aciertos de ruido (separan 0,05) |
| Cambiar los defaults de código al modelo nuevo sin migrar | Rompe toda la ingesta (2048 ≠ 1024): el orden es migración → re-ingesta → flag |
| Cablear la caché semántica antes del retrieval | Hoy es Redis y `getRedisClient()` → null: **no cachea nada**; no es el cuello y puede enmascarar el EOL |

## 5. Protocolo de verificación (aplica a cada PR)

1. `node -c` de cada archivo tocado + `npx jest --testPathPattern="(rag|embedding|knowledge)"` en verde.
2. Comparación de la suite completa contra `main` (hoy: 574 tests / 92 rojos **preexistentes**) —
   no se aceptan rojos nuevos.
3. Script de verificación específico de la fase (filtros, citas, similitud, latencia).
4. Benchmark de ranking antes/después con el mismo set (GOLD-V5 tras D5).
5. `node scripts/verifyNoVersionedSecrets.js` antes de commitear (sin credenciales versionadas).
