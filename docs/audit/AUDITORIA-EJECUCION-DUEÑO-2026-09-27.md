# Auditoría de la ejecución del 2026-09-27 (tareas 2, 4, 5, 6, 10, 11)

**Auditor:** Hermes (Arquitecto) · **Fecha:** 2026-09-27 (noche) · **Procedencia:** `git ls-remote`, `git fetch`, `git log --graph`, compuertas y suites corridas por mí sobre un worktree detachado en `origin/main`.

**Veredicto: las seis tareas están hechas en el repositorio.** Dos afirmaciones del informe **no se sostienen** y una de mis citas era falsa: van abajo, con la medición.

---

## 1. Lo que verifiqué y está bien

| Comprobación | Medición |
|---|---|
| Remoto | `origin/main` = **`4c46344f0`** (coincide con lo declarado) |
| Los 4 merges son merges de verdad | `380af0b4b` padres `e8243432f`+`917c0a65d` · `1008d94b8` `380af0b4b`+`42a6f1e43` · `eaf289e64` `1008d94b8`+`3337aadb6` · `15d81b863` `eaf289e64`+`18a04262b` ⇒ **cero squash** |
| **CI-16** en `main` | Allowlist exactamente **3** rutas (`/api/health`, `/api/providers`, `/api/test-db`) · prueba de contrato presente · el contrato nombra dinero/identidad (3 menciones) |
| **D-004** en `main` | `docs/knowledge` **12** archivos · `docs/agents` **55** · `docs/audit` **86** · mi informe de hoy y la COLA incluidos ⇒ la KB y el sistema viven en `main` |
| **D-005** (#10 y #12) | `docs/glowshop-2026-09-24/restore_catalogo_a0.sql`: **296 `INSERT INTO productos` + 296 `INSERT INTO precios_producto`** ⇒ la base acordada (296/296) verificada |
| Los archivos que el merge de #12 resolvió a mano | `adminPreciosController.js`, `adminPreciosRoutes.js`, `verifyImportCsvPrecios.js`: **sintaxis OK, 0 marcadores**, y `adminPreciosRoutes.test.js` **5/5 corrida por mí** |
| Compuertas (desde la raíz) | anti-marcadores **exit 0** · escaneo de credenciales **exit 0** |
| **A-04** | El `.gitignore` deja de ignorar `backend/public` y documenta que el versionado es intencional; los globs de media (`.webm`/`.mp4`) siguen ignorados; los **192** archivos intactos; `git status --porcelain` limpio y los dos scratch des-ignorados **no existen** ⇒ sin efectos colaterales |
| **Tarea 11 (planes)** | Los 2 planes están trackeados en `main` (5 archivos en `.hermes/plans/`) |
| **Tarea 10 (poda)** | 15 ramas remotas borradas: quedan `main` + 4; de ellas, `docs/sistema-agentes`, `feat/glowshop-niveles-a0` y `feat/glowshop-precios-csv` tienen **0 commits fuera de `main`** ⇒ ya podables |

**Con A-04 cerrada por decisión tuya, la Fase A pasa de 92,5 % a 97,5 %** (entregables 79,2 → 95,8 %; sin A-04: 97,2 %).

## 2. Lo que el informe dice y la medición no sostiene

**(a) «El entorno local `C:\beauty-app` fue actualizado al commit de `main`» — no está en `main`.** El banco está en la rama **`feat/glowshop-niveles-a0` @ `15d81b863`**, un commit que *es ancestro* de `main` pero está **3 commits atrás** (le faltan el commit de planes y el de `.gitignore`). Estar en un ancestro no es estar en `main`: cualquier medición que se haga ahí mide un árbol viejo. Además quedó parado en la rama de GlowShop, que además ya no existe en el remoto.

**(b) Tarea 10 — «12 ramas integradas con 0 commits pendientes»: eran 12, pero la lista de poda era mía y estaba bien; el problema es la vecina.** La poda en sí está completa y correcta. Lo que aparece ahora es que **`chore/guardian-en-el-repo` sigue con 3 commits fuera de `main`** — es decir, **la poda no lo tocó porque no era podable**, y ahí vive el guardián versionado (O-014) que **no está en `main`**: `git ls-files | grep guardian` sólo encuentra el documento de la orden.

## 3. Corrección de una cita mía (R-06: se registra, no se borra)

En la lista de pendientes que publiqué hoy escribí: *«D-004 — mergear `docs/sistema-agentes` (106 commits fuera de `main`; **arrastra `chore/guardian-en-el-repo`, 40**)»*. **Era falso.** Verificado hoy: el merge de la KB **no** trajo esa rama; son ramas distintas y `chore/guardian-en-el-repo` conserva **3** commits fuera de `main` (el «40» era la distancia respecto del `main` viejo, no un contenido arrastrado). El único camino para que el guardián versionado llegue a `main` es mergear esa rama.

## 4. Lo que NO pude cerrar

- **El gate completo sobre el `main` nuevo** quedó corriendo (el conteo de suites rojas/verdes después de los merges). Primera corrida mía abortó por error mío (el worktree de medición no tenía `node_modules/.bin` en `PATH`); relanzada. **Nada de esta auditoría depende de ese número**: los tres archivos resueltos a mano ya pasaron su suite 5/5 y las compuertas dan 0.
- **D-017 sigue sin firmar.** CI-16 está mergeado, pero su firma (la aceptación de la consecuencia de negocio) es tuya y no está.

## 5. Pendientes tuyos después de esta entrega

1. **Firmar D-017** (alcance del candado).
2. **Mergear `chore/guardian-en-el-repo`** (3 commits fuera de `main`: el guardián versionado, O-014).
3. **Decidir si A-07 entra al denominador** (0,95). Ojo: con A-04 cerrada, incorporarla **baja** el total 0,04 pp (97,50 → 97,46 %), porque 0,95 queda por debajo del promedio nuevo de entregables (95,8 %).
4. **Las 2 líneas del log de CI-46** (o permiso para leerlo con un login guardado).
5. **D-003 — revocar** lo del historial (la rotación ya está hecha).
6. **Podar las 3 ramas que ya quedaron dentro de `main`**: `docs/sistema-agentes`, `feat/glowshop-niveles-a0`, `feat/glowshop-precios-csv`.
7. **D-002** (`delete_branch_on_merge`): sigue sin verificar desde acá.
8. **Poner el banco en `main`** (hoy: `feat/glowshop-niveles-a0` @ `15d81b863`).
9. **¿Hay ADMIN en producción?** (API de precios).
