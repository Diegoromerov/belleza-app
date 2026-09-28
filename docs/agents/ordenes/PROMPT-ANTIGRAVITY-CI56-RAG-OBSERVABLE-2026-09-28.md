# Orden — CI-56: hacer observable el workflow RAG, y recien despues medirlo

**Para**: Antigravity (Ejecutor) · **De**: Arquitecto/Auditor · **Fecha**: 2026-09-28
**Rama**: `fix/ci56-rag-observable` · **Base**: `main` @ `c98503b33` (o el tip que veas)
**Prohibido**: mergear. Vas a terminar con la rama empujada y un PR abierto SIN mergear.

## 0. Contexto (medido, no supuesto)

- CI-55 quedo CERRADA: el run `36457331586` (`workflow_dispatch` sobre `main` @ `ae3cb8198`)
  tiene **5 jobs**. La falla de arranque (`failure` con `jobs=0`) desaparecio.
- Pero el run queda en `failure` porque el job `Unit Tests (Core)` falla 27 s despues de
  empezar, en el paso **`Run core tests`**. Los pasos previos pasan todos.
- **La causa no se puede medir hoy**: ese workflow no publica la salida de sus pasos. Las
  anotaciones del job dicen solo `Process completed with exit code 1`.
- Sospecha NO medida: el workflow declara `NODE_VERSION: '18'`. En `ci.yml` el motor de Node
  fue exactamente lo que impedia que las suites cargaran (CI-54: con 22 paso de
  `Tests: 0 total` a `Tests: 592 total`). Pero el job se llama "core tests" y la RAG es un
  pipeline Python: **no asumas que la causa es Node**. No lo sabes todavia.

## 1. Lo unico que se pide en esta ronda

Hacer que el workflow **publique la salida de su paso de tests como anotacion**, igual que ya
hace `ci.yml` (mira ese archivo y copia el patron que ya funciona; no inventes otro).

- No cambies la condicion del job, ni sus exclusiones, ni agregues `continue-on-error`.
- No vacies el workflow para que "arranque": arrancar ya lo logramos, lo que falta es ver.
- Los 5 nombres de job deben quedar iguales.

## 2. Que NO hacer en esta ronda

- **No** cambies `NODE_VERSION`. Si el rojo es de Node, saldra en la salida que vas a publicar
  y lo arreglamos en la ronda siguiente con la causa a la vista.
- **No** arregles el test que falla. No sabes cual es.
- **No** toques `ci.yml`.

## 3. Entrega

1. La URL del run disparado (`workflow_dispatch` desde la UI, rama `main` del PR).
2. Las lineas literales que la anotacion nueva publique (el resumen de tests y, si aparece,
   el nombre del test que falla).
3. Si la salida NO alcanza para saber la causa, decilo con esas palabras: "no hay causa
   atribuible con este instrumento". Eso tambien es un resultado valido.

## 4. Criterio de aceptacion

Un run de `rag-evaluation.yml` cuya anotacion contenga el resumen de tests del job
`Unit Tests (Core)`. Nada mas.
