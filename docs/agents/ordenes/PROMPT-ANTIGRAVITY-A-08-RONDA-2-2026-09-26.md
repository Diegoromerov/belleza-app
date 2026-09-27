# ORDEN A-08 — RONDA 2 · «Que el test muerda»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-26
**Rama:** seguí en **`fix/caminos-muertos`** (una orden = una rama). No abras rama nueva, no mergees, no borres ramas del remoto, no uses `--force` ni `--force-with-lease`.
**Base auditada:** `ad4f94f8` (tu entrega) contra `b545ef22`. Auditoría completa: `docs/audit/AUDITORIA-ENTREGA-A-08-2026-09-26.md`.

## Lo que ya está aceptado (no lo toques)

- **Cargo 2, la parte de colección:** medí `jest --listTests` y tu `testMatch` agrega **exactamente 1 suite** (la de biometría), sin arrastrar ninguna otra ⇒ quirúrgico. 3 suites / 36 tests ✓.
- **Cargo 3 completo:** contrafactual medido — sin tu guarda, arrancar con la bd caída imprime **78** «Migración … aplicada exitosamente»; con tu guarda, **0**, y aparece el mensaje honesto. `migrationRunner.js` sin importadores ✓.

## Cargo nuevo 1 — Que el test de CI-21 pueda fallar

**Por qué:** el test que entregaste **no discrimina**. Medí dos cosas:
1. **Mutación**: devolví `const client = await deps.pool.connect();` **fuera** del `try` (el defecto original, `node --check` OK, restauración por `sha256` idéntica) ⇒ tu test **siguió verde**.
2. **Sonda por el camino de producción**: invoqué `runAsSystem({ pool: deadPool }, fn)` **sin** `.catch()`, que es como lo invoca el repo (`setInterval(comoSistema(...))`, nadie espera la promesa) ⇒ **1 rechazo sin manejar con tu fix y 1 sin tu fix**. Tu cambio mueve el `connect` dentro del `try` y agrega guardas en `catch`/`finally`: endurece, pero no cambia el comportamiento observable.
3. **Causa:** tu proceso hijo hace `runAsSystem(...).catch(err => …)` ⇒ adjunta el manejador **por construcción** ⇒ `unhandledRejection` no puede dispararse nunca. Es una tautología.

**Qué tenés que hacer:**
- Reescribí el test para que dispare el rechazo **por el mismo camino que producción**, sin adjuntar manejador: invocá dentro de un `setInterval`/`setImmediate` (o llamá al wrapper `comoSistema` del job) y dejá que el proceso hijo escuche `unhandledRejection`.
- Dejá claro **dónde está la cura**: si sostenés que es `tenantRouting.js`, tenés que mostrar un test que **voltee al revertir ese cambio**. Si la cura real es el wrapper de `paymentJobs.js` (que es lo que yo medí), el test tiene que morder **ahí**: con el wrapper ⇒ el hijo termina sin rechazo sin manejar y con el fallo registrado; sin el wrapper ⇒ el hijo reporta el rechazo.
- Corré vos las dos mutaciones (aplicar ⇒ rojo; restaurar ⇒ verde) y pegá la salida cruda, con `sha256` del archivo antes y después. Sin eso no hay evidencia.

## Cargo nuevo 2 — Declarar (y probar) el cambio de producción de cripto

**Por qué:** en `biometricCryptoService.js` cambiaste el comportamiento de **producción**: con `BIOMETRIC_ENCRYPTION_KEY` distinta de 32 bytes ahora **lanza**, donde antes derivaba `sha256(env)` y seguía operando. Eso es ruta de **identidad/datos biométricos**, no te lo pedí, y **puede romper producción** si la clave desplegada no mide 32 bytes (se cruza con TEC-53/D-003). No lo reviertas por ahora.

**Qué tenés que hacer:**
- Agregá el test que falta: **ida y vuelta** (`encrypt` → `decrypt`) con una clave válida de 32 bytes **en modo producción**, para probar que el camino feliz sigue funcionando. Hoy sólo probás los caminos que lanzan.
- En tu entrega, declaralo en una línea propia y explícita: «cambio de comportamiento en producción — requiere decisión del Dueño», con lo que pasa si la clave real no mide 32 bytes.
- Si en el camino te enterás de que hay datos cifrados con la derivación vieja (`sha256(env)`), **no los toques**: decilo y pará.

## Prohibiciones (recordatorio)

No toques C-01/C-02/C-03 (OTP, cobro, wallet, disputas) más allá del wrapper de error que ya tocaste; no toques migraciones; no toques `backend/public`; no rebuildés el bundle; no mergees; no empujes a `main`; no borres ramas del remoto.

## Compuertas mecánicas antes de empujar

1. `git status --porcelain` y `git log -1 --format='%h %s'` (declaralos en la entrega).
2. Las 3 suites verdes **con tu `testMatch`** (sin él la biometría no entra): esperado `3 passed / 36 tests` (o más si agregaste tests).
3. Las dos mutaciones nuevas ejecutadas y restauradas, con `sha256` demostrablemente idéntico antes y después.
4. `node --check` de todo archivo que toques.

## Evidencia que debe traer la entrega

Salida cruda (no resúmenes) de: el test nuevo en rojo y en verde, las dos mutaciones, el `--listTests` con y sin tu línea, y el `sha256` de restauración. Todo lo que no puedas medir, decilo como «no medido» y por qué.
