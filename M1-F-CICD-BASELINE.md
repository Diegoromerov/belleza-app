# M1-F — CI/CD Baseline Report

## 1. REVISIÓN DE CONFIGURACIÓN DE CI/CD

* **Workflows de GitHub Actions (`.github/workflows/`):**
  1. `ci.yml`: Ejecuta pipeline en `ubuntu-latest` con Node 18, `npm ci`, `npm test` y Flutter analyze (`flutter pub get`, `flutter analyze`).
  2. `rag-evaluation.yml`: Pipeline diario y por commit para evaluar calidad de recuperación y generación de RAG contra `baseline_metrics.json`.
* **Scripts npm en `backend/package.json`:**
  - `dev`: `nodemon index.js`
  - `start`: `node index.js`
  - `test`: `jest`
  - `ingest:rag`: `node scripts/ingestBeautyKnowledge.js`
  - `eval:rag`: `node scripts/evaluateRag.js`
  - `ci:eval`: `bash scripts/ciRagEvaluation.sh`
* **Scripts en package raíz:**
  - `seed`: `node run_seed.js`
  - `test`: `cd frontend && flutter test`

## 2. RECOMENDACIONES DE BASELINE
* Los comandos de CI están estandarizados y operan sobre entornos limpios con Node 18 y Flutter stable.
* El repositorio está listo para ejecutar pipelines continuos en GitHub Actions sin scripts residuales.

## 3. ESTADO DEL GATE
🟢 **PASS**
