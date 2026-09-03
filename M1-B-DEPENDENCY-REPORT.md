# M1-B — Referencing & Dependency Verification Report

## 1. OBJETIVO
Verificar si alguno de los candidatos a limpieza está referenciado en `package.json`, workflows de GitHub Actions, scripts de ejecución, importaciones de código fuente o infraestructura de runtime.

## 2. RESULTADOS DE LA BÚSQUEDA DE REFERENCIAS (E0)
* **Scripts de GitHub Actions (`.github/workflows/*.yml`):**
  - No hacen referencia a ningún script `.py` en la raíz ni en `frontend/lib/screens/`.
  - No hacen referencia a archivos `.backup*` ni a `test-*.js` de la raíz.
* **`package.json` (Raíz y Backend):**
  - Solo referencia: `index.js`, `run_seed.js`, `scripts/ingestBeautyKnowledge.js`, `scripts/purgeRagKnowledge.js`, `scripts/evaluateRag.js`, `scripts/ciRagEvaluation.sh`.
* **Código Fuente Flutter (`frontend/lib/**/*.dart`):**
  - No importa ni ejecuta ningún script Python ni archivo `.backup`.
* **Código Fuente Backend (`backend/src/**/*.js`):**
  - No importa archivos `.backup` ni `.broken`.

## 3. TABLA DE CLASIFICACIÓN

| Grupo de Archivos | Cantidad | Clasificación | Acción Autorizada |
|---|:---:|:---:|:---:|
| Scripts Python en raíz (`C:\beauty-app\*.py`) | 50 | ORPHAN | Candidato a eliminación |
| Scripts Python en frontend (`frontend/lib/screens/*.py`) | 55 | ORPHAN | Candidato a eliminación |
| Archivos `.backup*` / `.original` / `.broken` | 16 | DUPLICATE / ORPHAN | Candidato a eliminación |
| Archivos de texto diagnóstico (`test_*.txt`, etc.) | 5 | ORPHAN | Candidato a eliminación |
| Scripts JS de testeo manual en raíz (`test-*.js`) | 5 | ORPHAN | Candidato a eliminación |
| Scripts PowerShell de dev (`scripts/*.ps1`) | 3 | REQUIRED TOOLING | **PRESERVAR** |
| Scripts Node RAG (`backend/scripts/*.js`, `run_seed.js`) | 8 | ACTIVE / CI DEPENDENCY | **PRESERVAR** |

## 4. ESTADO DEL GATE
🟢 **PASS**
