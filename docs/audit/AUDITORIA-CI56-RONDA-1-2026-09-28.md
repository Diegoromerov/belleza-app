# Auditoría — CI-56 ronda 1 (2026-09-28)

**Rama**: `fix/ci56-rag-observable` @ `823f02a0b` · **base**: `origin/main` (al día: `main`-ahead 0,
rama-ahead 1) · **Un commit, un archivo**.

**Veredicto: ACEPTADA EN CÓDIGO.** El criterio de aceptación de la orden —un run cuya anotación
contenga el resumen de tests— **sigue PENDIENTE**: hace falta que el Dueño abra el PR, porque
`rag-evaluation.yml` no corre en pushes a ramas de trabajo (lección de CI-55).

## Lo que verifiqué, con mis instrumentos

| Qué | Cómo | Resultado |
|---|---|---|
| Alcance | `git show --stat 823f02a0` | 1 archivo: `.github/workflows/rag-evaluation.yml`, **23+/1-** |
| Sin desvíos | `git diff --stat origin/main origin/fix/...` | igual: 1 archivo, 23+/1- |
| El comando de jest | `grep -n "npx jest"` | **idéntico** al de `main` (mismos `testPathIgnorePatterns`, mismos flags) |
| Sin prótesis | `grep continue-on-error` | **0** ocurrencias; no hay `\|\| true` |
| Los 5 nombres de job | `diff` de los nombres entre `main` y la rama | **IDÉNTICOS** |
| Preserva el exit | línea 90 | `set -o pipefail` antes del `tee` ⇒ el rojo sigue siendo rojo |
| Sintaxis/esquema | `actionlint` (imagen oficial, **mi** corrida, sin pipe en el exit) | **exit 0**, sin salida |
| Control positivo del instrumento | mismo `actionlint` sobre un workflow con el defecto viejo de CI-55 | **exit 1** con el error exacto ⇒ **el instrumento discrimina** |

## El diseño, revisado

- `Run core tests`: `set -o pipefail` + `2>&1 | tee /tmp/jest-rag-core.log`. Correcto: sin
  `pipefail` el pipe devolvería el exit de `tee` y el job se vería verde con los tests rojos.
- Paso nuevo `Publicar salida de tests RAG core (anotacion)` con `if: failure()`:
  - emite **primero** el resumen (`Test Suites: … · Tests: …`) y recién después las 20 líneas ⇒
    el resumen sobrevive al tope de ~10 anotaciones por paso de GitHub.
  - distingue «suites fallaron al cargar» de una corrida normal.
  - si el log no existe (falló un paso previo), lo dice en vez de callarse.
- El archivo `/tmp/jest-rag-core.log` sobrevive entre pasos: cada `run:` es un shell distinto, pero
  el filesystem del runner es el mismo dentro del job.

## Dos observaciones (no bloquean)

1. **Las anotaciones son públicas** y el paso vuelca las últimas 20 líneas del log de jest como
   `::error::`. Si algún día ese log imprime una variable de entorno, quedaría publicada. Riesgo
   bajo hoy (es un log de tests), pero es la misma clase que venimos cerrando ⇒ vigilar.
2. El `if: failure()` no distingue *qué* paso falló: si falla `Install dependencies`, el paso corre
   y cae en la rama que informa «No se encontró el log». Es informativo, no un defecto.

## Error propio del Auditor (registrado, R-06)

Medí `actionlint exit=0` a través de un `| head`, así que el exit reportado era el de `head` y no
el del linter: **evidencia inválida**. Re-medido capturando el exit del proceso y con un control
positivo que falla a propósito. Es una trampa que ya estaba documentada en `TRAMPAS.md`; la volví
a pisar igual.

## Lo que falta para cerrar CI-56

1. **Dueño**: abrir el PR de `fix/ci56-rag-observable` (destino `main`).
2. Su run ejercita el paso nuevo y publica la salida real del job `Unit Tests (Core)`.
3. **Con esa salida**, la causa del rojo queda medida y recién ahí se arregla (la sospecha del
   `NODE_VERSION: '18'` deja de ser sospecha o se cae).
