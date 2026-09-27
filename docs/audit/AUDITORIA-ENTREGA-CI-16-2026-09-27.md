# Auditoría independiente — Entrega CI-16 (declarar el alcance del candado)

**Fecha:** 2026-09-27 · **Auditor:** Hermes · **Rama:** `fix/candado-declara-alcance` @ **`917c0a65d`**
**Procedencia verificada por mí:** `git ls-remote` = `917c0a65df41…` · **1** commit desde `main` (`e8243432f`) · ancestro confirmado.

**Veredicto: ACEPTADA.** Todo lo pedido está hecho y **la prueba es real** — la muté yo y falla.

## 1. El cambio del middleware es sólo comentarios (verificado)

| Comprobación | Medición |
|---|---|
| Líneas cambiadas en `degradedLock.js` | **5**, y **0** que no sean comentario |
| Allowlist antes vs después | `'/api/health'` `'/api/providers'` `'/api/test-db'` — **idénticas** |
| Código ejecutable | sin cambios |

⇒ El comportamiento no puede haber cambiado: no cambió una sola línea ejecutable.

## 2. La prueba es un contrato de verdad (mutada por el Auditor)

| Comprobación | Medición |
|---|---|
| Suite tal como está | **6 passed / 6** |
| **Mutación mía**: agregar `'/api/auth/login'` a `DEGRADED_ALLOWLIST` | **4 failed / 2 passed** ⇒ la prueba **detecta** la erosión |
| Sintaxis tras mutar / restaurar | OK en los dos estados |
| Archivo restaurado | **idéntico** al original (`diff -q` limpio) y árbol del worktree **limpio** |

⇒ Y su propia mutación **quedó revertida antes de empujar**: la allowlist del head tiene 3 entradas exactas.

Las tres cláusulas del contrato están fijadas: (1) la allowlist no puede tener rutas de dinero/identidad ni comodines; (2) las 3 exentas siguen exentas y `size === 3`; (3) las rutas sensibles responden `503` + `X-GlowApp-Degraded: memory-fallback` en los dos estados degradados, y **no** se bloquean en `UNCHECKED`.

## 3. Cobertura contra mi medición en vivo

La lista de rutas sensibles trae **exactamente las 7 mínimas** que pedía la orden (login, register, verify-otp, wompi-webhook, bookings, wallet/balance, disputes). Quedan **sin fijar** dos que yo medí en vivo y funcionan: `/api/tickets` y `/api/admin/metrics` ⇒ mejora opcional, no defecto.

## 4. Residuo declarado (no bloquea)

La prueba fija el **middleware**, no su **montaje**. Si alguien quitara o estrechara `app.use('/api', degradedLockMiddleware)` (`index.js:228`), la prueba seguiría verde mientras el alcance real se encoge.

No se cierra leyendo `index.js` como texto: eso es exactamente el antipatrón que prohíbe **R-07** («un test que lee el código como texto no prueba comportamiento»). El cierre honesto es una comprobación de integración (una ruta real, app real, estado degradado ⇒ `503`), que es lo que hice a mano el 2026-09-27 con las 12 rutas. Queda como residuo, con la evidencia de hoy en `D-017`.

## 5. Qué falta para cerrar CI-16

1. **La firma del Dueño** (D-017): la aceptación del alcance — dinero e identidad bloqueados a propósito durante la degradación.
2. **El merge** de `fix/candado-declara-alcance` (rama nacida de `main`, 1 commit, cambio de comentarios + prueba).
