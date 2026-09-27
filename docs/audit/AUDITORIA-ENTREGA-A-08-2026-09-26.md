# Auditoría independiente — Entrega A-08 «Lo que no corre y lo que no se maneja»

**Fecha:** 2026-09-26 · **Auditor:** Hermes (Arquitecto/Verificador) · **Rama auditada:** `fix/caminos-muertos`
**Procedencia verificada por mí:** remoto `fix/caminos-muertos` = local = `ad4f94f840cd1052ec5209a9a45e7d6ee24624e0`, `b545ef22` es ancestro ✓ · worktree del Ejecutor en `ad4f94f8`
**Método:** lectura del diff + **mutaciones** + reproducción de comportamiento **con contrafactual** en worktree propio (`scratch/a08/wt`), sin tocar el del Ejecutor.
**Veredicto global:** **ACEPTADA PARCIALMENTE** — el código de los tres cargos está, y dos de los tres quedaron probados por mí; **la evidencia del Cargo 1 es inválida** y hay **un cambio de producción no pedido** que requiere al Dueño.

## 1. Cargo 1 — CI-21 (rechazo sin manejar en `tenantRouting.js`) — **evidencia INVÁLIDA**

Lo que declaró: test con ciclo «RED → GREEN» (`CHILD EXIT 101` → `0`).

Lo que medí yo:
1. **Mutación** (devolver `const client = await deps.pool.connect();` fuera del `try`, es decir el defecto original; `node --check` OK; restauración por `sha256` idéntica) ⇒ **su test sigue VERDE**. Una mutación que no voltea el test no es evidencia.
2. **Sonda fiel** — invocar `runAsSystem({ pool: deadPool }, fn)` **sin** `.catch()`, que es exactamente la forma en que los jobs se invocan en el repo (`setInterval(comoSistema(...))`, nadie espera la promesa):
   - con el código de A-08: **1 rechazo sin manejar**
   - con el defecto original: **1 rechazo sin manejar**
   ⇒ **el cambio de `tenantRouting.js` no cambia el comportamiento observable del rechazo.** Es endurecimiento (guarda `if (began && client)` en `catch`/`finally`), no cura.
3. **Por qué su test no puede discriminar:** su propio proceso hijo hace `runAsSystem(...).catch(err => ...)` ⇒ adjunta el manejador por construcción ⇒ `unhandledRejection` no puede dispararse nunca, con fix o sin fix. El test es una tautología.
4. **Dónde está la cura de verdad:** el wrapper de `paymentJobs.js` (`comoSistema`) que captura y registra. Y ahí su decisión es **correcta por el contexto que verifiqué**: los jobs se invocan dentro de `setInterval` (`:268`, `:271-273`, `:277-279`), nadie espera la promesa ⇒ un `rethrow` reintroduciría el mismo rechazo sin manejar. **Residual (no bloqueante):** captura y resuelve; no hay contador ni estado consultable ⇒ un job de pagos que falla sólo se distingue por una línea de log.

**Veredicto Cargo 1:** el fix se acepta como código; **la evidencia se rechaza**. Hace falta un test que invoque **sin** `.catch()` (o a través del wrapper del job) para que discrimine.

## 2. Cargo 2 — CI-12 (la suite de biometría nunca se coleccionaba) — **✓, con excedente no pedido**

Medido:
- `jest --listTests`: con su `testMatch` **83** suites; sin la línea **82** ⇒ el cambio agrega **exactamente 1** suite y **ninguna otra aparece ni desaparece**. Quirúrgico: no altera la composición del gate.
- Las 3 suites que él declara: **3 passed / 36 tests** ✓ (biometría 16/16, `tenantRoutingUnhandled` 1/1, `audit360-remediation` 19/19). El control pasa **sólo con el `testMatch` de A-08** (sin él, la biometría no entra: 2 suites).
- Las validaciones nuevas **sí** están probadas: `toThrow(/32 bytes long/)` ×3, `Invalid ciphertext format` ×3, hex inválido en `iv` y en `authTag` ⇒ no es un throw suelto.
- El test huérfano estaba **roto además de no coleccionado**: asumía export de clase donde el módulo exporta **instancia** ⇒ exposición del constructor: legítima.

**Pero:** mete un cambio de comportamiento de **producción** (`biometricCryptoService.js`): con `BIOMETRIC_ENCRYPTION_KEY` distinta de 32 bytes, en producción (o test) ahora **lanza**, donde antes derivaba `sha256(env)` y seguía operando. Es la ruta de **identidad/datos biométricos**, y **no se lo pedí**. Se cruza con **TEC-53 / D-003** (los secretos reales desplegados no están confirmados): si en Railway la clave no mide 32 bytes, este cambio **rompe** la función en producción.

**Veredicto Cargo 2:** ✓ por lo técnico; el cambio de producción queda **para decisión del Dueño**, no se mergea por mi auditoría.

## 3. Cargo 3 — TEC-72 (log falso de migración) — **✓ verificado por comportamiento**

- **Contrafactual medido** (bd caída, `DB_PORT=5499`, arranque real de `index.js`):
  - `index.js` de la **base**: **78** líneas `✅ … Migración NNN_*.sql aplicada exitosamente.`
  - `index.js` de **A-08**: **0** líneas falsas y aparece `⚠️ [initDatabase] PostgreSQL no disponible; omitiendo migración e inicialización de BD.`
- La atribución que hizo (el log salía de `index.js`, no de `migrationRunner.js`) queda **consistente** con esto: el mismo arranque sin su guarda produce los falsos éxitos.
- `migrationRunner.js`: **4 referencias, todas dentro de su propio archivo** (comentarios `:1`, `:81` y compañía) ⇒ **código muerto confirmado**, no hay importador.

**Veredicto Cargo 3:** ✓ aceptado. Y arregla algo que Fase A considera central: la app deja de decir «éxito» cuando no hubo éxito.

## 4. Gobernanza

- Archivos tocados: `backend/index.js` (+6), `backend/jest.config.js` (+1), `tenantRouting.js` (15), **`backend/src/jobs/paymentJobs.js` (8)**, `biometricCryptoService.js` (9), su test (65), y `tenantRoutingUnhandled.test.js` (nuevo, 50).
- **`paymentJobs.js` es área de dinero**: lo toca, pero **no altera lógica de pago ni de saldos** — sólo el manejo de error del wrapper. **No viola C-01/C-02/C-03**, pero debía declararlo como área sensible: lo declaro yo.
- No tocó migraciones, ni `backend/public`, ni ramas ajenas. No hay force-push. Rama empujada, base correcta ✓.

## 5. Falla mía (declarada)

Al mutar `tenantRouting.js` restauré con `fs.writeFileSync('/tmp/tr.orig')` desde `node` y luego `cp /tmp/tr.orig`: en este host un programa nativo escribe en `C:\tmp`, que **no es** el `/tmp` de MSYS ⇒ la restauración no ocurrió y mi worktree quedó mutado. Lo detecté en la misma corrida (`grep -c "let x;"` ≠ 0) y restauré con `git checkout --`; estado final limpio. Regla añadida a TRAMPAS.

## 6. Lo que queda para el Dueño

1. **Cripto (Cargo 2):** ¿se acepta que en producción una clave de largo ≠ 32 **lance** en lugar de derivar? (implica confirmar el valor real de `BIOMETRIC_ENCRYPTION_KEY`).
2. **Cargo 1:** ¿el fallo de un job de pagos puede quedar sólo en log, o querés contador/estado consultable?

## 7. Reglas nuevas para el registro

- **Un test cuyo propio arnés adjunta el manejador (`.catch`, `try/catch`) no puede probar un rechazo sin manejar.** El test tiene que invocar por el mismo camino que el código de producción (aquí: dentro de `setInterval`, sin esperar la promesa).
- **Mutación sobre el fix declarado**: si revertir el fix no voltea el test, el cargo **no está probado**, aunque el test pase y el log diga «RED → GREEN».
- **Un fix que no cambia el comportamiento observable (aquí: mover el `connect` dentro del `try`) no es la cura: hay que buscar dónde está la cura real** (el wrapper que captura) y decirlo.
