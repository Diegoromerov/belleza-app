# Handoff — panel admin de Belleza App: estado de `main` y reglas para continuar

Fecha: 2026-10-08 · `origin/main` = `e23ae4483`

Para el agente que continúa el trabajo. Dice lo que YA está hecho y desplegado, el estado exacto
del repositorio, las operaciones que destruirían trabajo, y las trampas del entorno que ya
costaron rondas. No hace falta redescubrir nada de esto.

## 1. Lo que ya está hecho en `main` — no rehacer

| Commit | Qué cerró |
|---|---|
| `def5cb58d` | **PQRSF F2** — cinco endpoints `/api/admin/tickets` (bandeja con filtros y paginación, métricas, detalle con hilo, cambio de estado/prioridad, respuesta del operador), todos bajo `requireRol('admin')`, con las dos escrituras auditadas. Cerró huecos de F1: escritores de `resuelto_en`/`cerrado_en`, consumo de `ticketSla.js`, validación de `tipo`/`categoria` al crear (antes 500) y prioridad al crear. |
| `a9b42413d` | **PQRSF F4** — pantalla `/admin/pqrsf` (bandeja, filtros, hilo, cambio de estado/prioridad, respuesta) más lo que la UI exigió del backend: el conteo de la bandeja se renombró a `mensajes_total` (en el detalle `mensajes` es el array del hilo) y se añadió `GET /api/admin/tickets/esquema` para que los desplegables no lleven listas escritas en la pantalla. |
| `4d8c4f397` | Plan PQRSF corregido: F4 marcada HECHA, el SHA de F2 arreglado, y F3 con el alcance real del defecto del correo. |
| `dcd53d62f` | **Seguridad en el portero del panel** — `src/middleware.ts` daba por público cualquier camino con extensión (`/admin/pqrsf.json`, `/prestador/datos.json`…). La decisión pasó a `src/lib/portero.ts` y lo público es una lista explícita. Verificado en producción: esos caminos pasaron de 404 a 307. |
| `e23ae4483` | El guardián de ese atajo estaba sobre-escapeado y no podía fallar; reescrito y probado por mutación. |

## 2. Estado verificado del repositorio

- `origin/main` = `e23ae4483`; cadena `def5cb58d` → `a9b42413d` → `4d8c4f397` → `dcd53d62f` → `e23ae4483`.
- El árbol compartido (`C:/beauty-app`) está en `main` y **limpio**: `git status` vacío, sin trabajo sin commitear que un barrido pueda llevarse.
- Producción: backend y panel desplegados; el arreglo del portero comprobado en vivo.
- Suites: panel `npm test` 89/89 (0 fallos); backend `adminTickets.test.js` 29/29, `pqrsfSla.test.js` 19/19, guardián de numeración 7/7; integración contra PostgreSQL real 25/25.
- Respaldo fuera del repositorio: `C:/Users/Compu casa/beauty-app-archive/belleza-app-main.bundle` (autocontenido y verificado).

## 3. Lo que NO hay que hacer

1. **Nunca `git push --force` a `main`**, ni `rebase`/`amend` de commits ya publicados, ni borrar la rama remota. Es la única forma real de destruir lo hecho; todo lo demás lo rechaza git solo.
2. **No `git add -A` sin leer antes `git status`.** El árbol es compartido: un barrido se lleva trabajo ajeno a un commit con tu mensaje.
3. **No mergear las ramas `agent/*`** (hay ~336, a ~335 commits por detrás de `main`): rebase, no merge. Un merge no pierde commits, pero puede reintroducir versiones viejas de archivos.
4. **No reintroducir el atajo por extensión** en el portero ni volver a decidir "lo público" por la extensión del camino. Lo público es LISTA explícita: si hay que servir un archivo nuevo de `public/`, se declara en `ASSETS_PUBLICOS` (hay un test que compara la lista con el directorio real).
5. **No cambiar el vínculo** middleware → `clasificarCamino`: `tests/middleware.test.mjs` lo fija por texto y `tests/middleware-behavior.test.mjs` ejerce la decisión.
6. **No usar credenciales de producción** para reproducir nada.
7. Antes de tocar `src/lib/portero.ts`, `src/middleware.ts` o sus tests: `git fetch` y rebase sobre `origin/main`.
8. **No dejar worktrees registrados** apuntando a directorios temporales: retirarlos con `git worktree remove`; si no, quedan visibles en `git worktree list` para todos los agentes.

## 4. Trampas del entorno ya pagadas

- **Backticks en bash/MSYS son sustitución de comandos**: nunca dentro de `git commit -m` (usar `-F archivo`), ni al escribir código con template literals (cierran la cadena). Verificar con `node --check`.
- **La suite del panel se corre con `npm test`**, que es `node --test "tests/*.test.mjs"`. `node --test tests/` NO corre la suite.
- **No se puede importar `src/middleware.ts` desde una prueba**: importa `next/server` sin extensión y el resolutor de Node no lo carga (el empaquetador de Next sí). Por eso la decisión vive en `src/lib/portero.ts`, sin dependencias.
- **`taskkill //F` no funciona** en este MSYS: usar `taskkill /F /PID <pid>`.
- **`git bundle create f base..tip` y `f tip --not base`** fallan con "Refusing to create empty bundle" aunque el rango no esté vacío; funcionan `^base tip` o un solo ref.
- **No reportar números que no se puedan reproducir.** Un "66/66" circuló y no se pudo reproducir después: exigir 0 fallos y decir con qué orden se corre.

## 5. Qué queda pendiente

- **F3 — correo.** Bloqueado por un dato que solo se ve fuera del repositorio: hay que comprobar si el servicio `belleza-app` tiene proveedor de correo en su entorno. Sin proveedor, `email.service.js` simula y devuelve `success:true` — y eso afecta también la **recuperación de contraseña**, no solo PQRSF, así que el arreglo puede no pertenecer a la fase de PQRSF.
- **D3 — festivos.** La fecha límite de ARCO se calcula en días hábiles **sin festivos colombianos** y ya se muestra en la bandeja.
- **F5** — métricas de PQRSF en el dashboard raíz. **F6** — costura para el agente.
- **`/api/categorias` no existe** y `admin/productos/page.tsx` la llama; `categoria_id` es un fantasma en cinco sitios y la taxonomía real es `tag_especialidad`.
- Documentados y sin arreglar: `sanitizeText` hace doble escape en `business/page.tsx` y `cliente/page.tsx`; falta pgvector en la base de producción (las migraciones 035 y 076 no aplican).

## 6. La regla de verificación que se exige aquí

Cada cambio se entrega con el defecto **reproducido antes** de tocar nada, el arreglo, la
comprobación **en vivo** (no solo en local) y una **mutación** que pruebe que el guardián lo caza:
volver a introducir el defecto y exigir rojo. Todo con evidencia `archivo:línea` o salida de
comando. Un verde no prueba nada si el guardián no puede fallar.
