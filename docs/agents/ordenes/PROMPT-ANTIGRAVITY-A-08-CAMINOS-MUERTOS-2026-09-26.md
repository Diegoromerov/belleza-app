# ORDEN A-08 — «Lo que no corre y lo que no se maneja» (para el Ejecutor)

> Pegá este documento en el otro chat, tal cual. **Ordená así:** si **A-07 sigue abierta, cerrá A-07 primero** (una tarea
> por vez, un worktree por agente). Cuando A-07 esté entregada, empezás con esta.

**Rama:** `fix/caminos-muertos` **nacida de** `fase-a/verdad-operativa @ b545ef22` (nunca de `main`).
**Un worktree = un agente:** worktree nuevo y propio; no toques `C:/beauty-app`, el de la KB ni el de otras órdenes.
**Autorización:** sos el Ejecutor; podés empujar tu rama. **No** mergeás.

---

## Por qué esta orden

El hito de Fase A es «**la app dice la verdad**». Estas tres cosas son mentiras del propio sistema sobre sí mismo: un rechazo
que nadie maneja, un test que **nunca corre**, y un mensaje que dice «migración aplicada exitosamente» **con la base caída**.
Ninguna toca dinero ni identidad, y ninguna necesita una decisión del Dueño para empezar.

---

## Cargo 1 — CI-21: el rechazo que nadie maneja

`backend/src/services/tenantRouting.js:170` (`runAsSystem` → `deps.pool.connect()`) deja un **`Unhandled Rejection`** cuando
la base no responde. Está atribuido y **no tocado**.

1. Test que **primero falle** demostrando el rechazo sin manejar (capturá `process.on('unhandledRejection')` en un proceso
   hijo, o el mecanismo equivalente: tiene que **verse** el rechazo, no describirse).
2. Fix: el rechazo se maneja y el estado queda **declarado** (error propagado o degradación explícita). Nada de silenciarlo.
3. **Mutación pegada**: revertí el manejo a propósito y verificá que el test cae. Restaurá con `sha256` verificado.

## Cargo 2 — CI-12: la suite que jest nunca colecciona

`backend/src/services/biometricCryptoService.test.js` **no lo colecciona jest** ⇒ esa suite **no corre nunca**.

1. Medí y **pegá la evidencia** de la causa (salida de `jest --listTests`, el patrón de `testMatch`/`testPathIgnorePatterns`
   que lo excluye, y qué cambió para que quedara fuera).
2. Hacé que **corra**.
3. Si al correr revela defectos: arreglalos (test-first) **o** documentá cada uno con su salida real y por qué queda abierto.
   **Prohibido** «arreglarlo» borrando o vaciando el test.

## Cargo 3 — TEC-72: el mensaje sin atribuir

`backend/scripts/migrationRunner.js` es **código muerto**, y el mensaje «**migración aplicada exitosamente**» se vio
**18 veces con la base caída**.

1. Atribuí **quién emite** ese mensaje: `grep` exhaustivo + una corrida que lo reproduzca, con el comando exacto y la salida real.
2. De ahí: si es código muerto, **retiralo con la evidencia** de que nadie lo alcanza; si es alcanzable, explicá por qué y qué
   está mintiendo (¿se imprime sin esperar el resultado?).

---

## Prohibiciones (una infracción invalida la entrega)

- No toques C-01/C-02/C-03 (OTP, cobro, wallet, disputas), migraciones, `backend/public` ni `index.js` fuera de lo pedido.
- **No borres ni saltes tests para poner nada verde.**
- Sin `--force` ni `--force-with-lease`. No mergees. No borres ramas del remoto.
- No inventes números: si no lo medíste, `NO MEDIDO`.

## Evidencia de entrega (walkthrough)

- Procedencia: rama + SHA + `git status --porcelain`.
- Por cada cargo: la **medición previa** (salida real), el RED, el fix, el GREEN y la **mutación** con su control.
- Si algo quedó fuera: la razón exacta y el comando que la muestra.
