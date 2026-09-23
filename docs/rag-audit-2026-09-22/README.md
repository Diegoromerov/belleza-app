# Auditoría RAG — evidencia reproducible (2026-09-22)

Este directorio conserva la **evidencia ejecutable** de la auditoría del pipeline RAG de Aura.
Se versiona aquí para que no dependa de ningún disco local ni de directorios temporales, y para
que cualquiera pueda reproducir las mediciones.

## Contenido

| Archivo | Qué mide |
|---|---|
| `AUDITORIA_RAG_2026-09-22.md` | Informe completo: hallazgos, severidades, prompt de corrección P0 y §7 con la causa raíz (modelo EOL) |
| `PLAN_MEJORA_RAG.md` | **Plan de mejora por fases** con decisiones (D1-D5), criterios de aceptación por cambio, orden de PRs y trampas ya descartadas con medición |
| `probes/rag_e2e_after.js` | Aislamiento multi-tenant end-to-end contra Postgres real: 4 filas de prueba (GLOBAL / propio / ajeno / borrado) y el mismo payload de inyección contra el SQL viejo y el nuevo |
| `probes/matriz.js` | Matriz antes/después ejecutando el **código extraído del propio repo** (`git show <sha>:…`), con y sin `NVIDIA_API_KEY` |
| `probes/rag_modelo_vivo.js` | ¿Funciona el resto del pipeline con un modelo vivo? Embeddings reales + ranking por similitud coseno en una tabla de scratch |
| `probes/maincode_runner.js` | Ejecuta el código de `origin/main` fuera del repo (require a `services/*` extraídos) |
| `probes/jestfail.js` | Extrae de un JSON de Jest los tests que fallan (nombre + primer renglón), para comparar dos revisiones sin ruido |
| `probes/stub-config-db.js` | Stub de `config/db` necesario para correr los servicios extraídos fuera del repo |

## Requisitos

- Docker con el contenedor `beauty-postgres` (pgvector, puerto 5435) y `RAG_DATABASE_URL` en
  `backend/.env.local`.
- `NVIDIA_API_KEY` para las pruebas contra la API (las que no la necesitan están marcadas).
- Dependencias del backend instaladas (`backend/node_modules`).

## Cómo reproducir

```bash
# 1. Extraer el código de la revisión que se quiere medir (antes / después), fuera del repo
SCR=/tmp/rag-audit && mkdir -p $SCR/code/services $SCR/code/config
for f in embeddingService ragService circuitBreakerService; do
  git show 43170150:backend/src/services/$f.js > $SCR/code/services/$f.js   # 43170150 = antes; usar el SHA a medir
done
cp probes/stub-config-db.js $SCR/code/config/db.js

# 2. Matriz antes/después (con y sin key)
cd backend
NODE_PATH="$PWD/node_modules" node $SCR/../matriz.js $SCR/code
NODE_PATH="$PWD/node_modules" node $SCR/../matriz.js $SCR/code --sin-key

# 3. Aislamiento multi-tenant contra la BD real (crea y borra sus propias filas de prueba)
node probes/rag_e2e_after.js

# 4. ¿Responde el modelo vivo? (embeddings reales + ranking coseno)
node probes/rag_modelo_vivo.js
```

Salidas esperadas (medidas el 2026-09-22) documentadas en `AUDITORIA_RAG_2026-09-22.md` §7 y en
`RAG_ARCHITECTURE.md` §9.

## Notas de fidelidad

- Las sondas conservan las **rutas absolutas** de la máquina donde se ejecutaron
  (`C:/beauty-app/backend`, `C:/Users/…/scratch`). Es intencional: son el registro de lo que
  realmente corrió. Ajustar la constante `B` / `SCR` al reutilizarlas.
- No incluyen credenciales: leen `NVIDIA_API_KEY` y `RAG_DATABASE_URL` del entorno y nunca las
  imprimen (solo se reporta presencia y longitud).
- Las sondas que tocan la BD **crean y borran sus propias filas** (identificadas por
  `document_id = 'zz-probe-*'`) y usan tablas de scratch; no modifican datos existentes.
