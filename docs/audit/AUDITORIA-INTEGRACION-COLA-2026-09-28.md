# Auditoría — Integración de la cola de merges a `main` (2026-09-28, noche)

**Tip auditado**: `origin/main` = `38a1defa4` · **Ejecutor**: Antigravity, por caminos directos
con constancia · **Veredicto**: **ACEPTADA en sustancia, con dos reparos.**

## 1. Los cuatro merges (ACEPTADOS)

| Commit | Rama integrada | Padres | Constancia D-019 |
|---|---|---|---|
| `6e496a953` | `fix/ci48-sin-email-en-admin` | `c98503b33` + `83a936d78` | ✓ |
| `06a4e111f` | `fix/ci49-credencial-no-publicada` | `6e496a953` + `9d52aed1b` | ✓ |
| `9e464b37a` | `fix/ci72-visible-y-cifras-faseA` | `06a4e111f` + `4ca516878` | ✓ |
| `cb0dc0e94` | `chore/guardian-en-el-repo` | `9e464b37a` + `b919d45ad` | ✓ |

Son **merges reales** (dos padres cada uno, encadenados sin saltos), no squash, y **cada mensaje
lleva la constancia**. La convención que acordamos en D-019 funcionó por primera vez de punta a
punta. La KB quedó en `main` (`avanceFaseA.js` con `id: 'S3', nota: 1.00`; `COLA.md` con 67 filas).

## 2. El conflicto de `setupRlsRole.sql` (RESUELTO BIEN)

El merge de la KB tocó ese archivo y hubo que resolverlo a mano — el punto más peligroso de la
noche, porque es el archivo cuya causa rompió el CI durante días (CI-46). Verificado en `main`:

- `CREATE ROLE app_rls_user` (34) · `CREATE ROLE app_system NOLOGIN` (66) · `GRANT app_system TO
  app_rls_user` (74 y 105) ⇒ **el orden correcto se conservó** (el `GRANT` va después del `CREATE`).
- El comentario que dejaron en 72-73 («Va DESPUÉS del CREATE ROLE de arriba: es la corrección del
  orden que rompía la base vacía») prueba que resolvieron **entendiendo**, no adivinando.
- **Reparo menor**: quedó un `GRANT app_system TO app_rls_user;` **duplicado** (74 y 105). Es
  idempotente y no tiene efecto, pero conviene deduplicar cuando se toque el archivo.

## 3. El seed de CI-49 ahora vive en `main` — verificado que NO toca producción

Riesgo real planteado por el merge: `seed.sql` ya no lleva la contraseña ni el hash y el runner
**falla cerrado** sin `SEED_PASSWORD`. Producción tiene `SEED_DATABASE=true` (medido, 42 variables)
y **no** tiene `SEED_PASSWORD`. Consecuencia medida:

1. `seedRunner.js` **lanza** si `NODE_ENV === 'production'` («la siembra automática está prohibida
   en producción») ⇒ la guarda de producción gana antes de mirar `SEED_DATABASE`.
2. Además `index.js` sólo llama al seed si **falta** `provider@beautyapp.com`, y esa cuenta existe
   ⇒ `needsSeed = false`.
3. Y si aun así fallara, el llamador está envuelto en `try/catch`: `console.warn` + entrada en
   `dbErrors`. **No rompe el arranque.**

⇒ **Cero riesgo operativo**, por dos guardas independientes. Dato derivado: por esa misma guarda,
**CI-50 no se puede remediar con el seed en producción** — necesita una intervención explícita como
la de CI-48. El CI tampoco siembra (no define `SEED_DATABASE`).

## 4. Item 14 — RETRACTADO: el Dueño autorizó

El commit `38a1defa4` versiona **13 archivos, ~40 MB de video** (`step_01_welcome.mp4` …
`step_08_despedida.mp4`, ~4 MB cada uno, más un `.webm` de 2,2 MB) en un repositorio público.

**El Dueño declaró el 2026-09-28 que lo autorizó él.** ⇒ No hay reparo de proceso: la constancia del
mensaje era legítima y el sello no se aplicó de más. Esta auditoría había leído la lista («decidir») como
una decisión delegada; con la declaración del Dueño, el punto se cierra **sin cargo**.

Queda como dato de contexto, sin acción:

- esos ~40 MB viven en el historial de un repo público de forma permanente: sacarlos exigiría reescribir
  el historial, que está prohibido;
- el mismo `aura_canonical.webp` (228 KB) quedó **dos veces** (`glowguide/` y `glowguide/videos/`) y el
  `.gitkeep` quedó con 4 líneas: limpieza de una línea si algún día se toca esa ruta.

## 5. Pendiente medible de esta ronda

El CI de `main` sobre el tip `38a1defa4`: si el gate sigue en `4 suites / 23 rojos / 592` después de
cuatro merges, el baseline está intacto; cualquier otro número es un rojo nuevo con atribución.
