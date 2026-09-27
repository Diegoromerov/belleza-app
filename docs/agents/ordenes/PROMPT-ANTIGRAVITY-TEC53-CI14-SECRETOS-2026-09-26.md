# ORDEN TEC-53 / CI-14 — «Ningún respaldo literal para una variable sensible»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-26
**Rama:** nueva, **`fix/secretos-sin-respaldo-literal`**, nacida de `fase-a/verdad-operativa` (`b545ef22`). Un worktree = un agente. Sin `--force`, sin `--force-with-lease`, sin merge, sin borrar ramas del remoto.
**Decisión del Dueño:** CI-14 autorizada (redactar las líneas de prosa) y TEC-53 autorizada (quitar los respaldos literales del código).

## Lo que hay que arreglar (medido por el Arquitecto, escáner nuevo, exit 1)

Los 8 hallazgos son **una sola clase**: *«valor por defecto literal para variable sensible»*.

| # | Archivo:línea | Qué es |
|---|---|---|
| 1 | `AUDITORIA_PREPRODUCCION_MASTER.md:84` | prosa: cita un valor por defecto |
| 2 | `BLOQUE_TRABAJO_1_BASELINE.md:144` | prosa |
| 3 | `auditoria-belleza-app.md:232` | prosa |
| 4 | `auditoria-belleza-app.md:233` | prosa |
| 5 | `scripts/COMO_EJECUTAR.md:35` | prosa |
| 6 | `backend/src/config/jwt.js:1` | `TEST_SECRET = '…'` — literal real |
| 7 | `backend/src/config/jwt.js:2` | `DEFAULT_PROD_SECRET = '…'` — literal real **y en repo público** |
| 8 | `backend/src/services/biometricCryptoService.js:18` | `CLAVE_LEGADA` deriva de `process.env.JWT_SECRET \|\| '…'` — literal real |

**Verificado por el Arquitecto contra producción** (Railway `grateful-harmony` / production / servicio `belleza-app`, sin imprimir valores): `JWT_SECRET` **presente, 32 bytes utf8**; `BIOMETRIC_ENCRYPTION_KEY` y `ENCRYPTION_KEY` **64 caracteres hex** (el código los decodifica a 32 bytes).
⇒ **Quitar los respaldos literales NO rompe producción**: las tres variables están provisionadas y en formato válido.

## Cargo 1 — `jwt.js` sin literales (hallazgos 6 y 7)

`getJwtSecret()` debe quedar así, en este orden de decisión:

1. `process.env.JWT_SECRET` presente **y** con longitud ≥32 ⇒ se usa.
2. Si falta o es corta ⇒ si el entorno es **producción** ⇒ **lanzar** (fallo rápido al arrancar, con mensaje que diga que hay que provisionar `JWT_SECRET`). **Nada de respaldo silencioso.**
3. Fuera de producción (test/dev) ⇒ un secreto **efímero y memoizado** (`crypto.randomBytes` una sola vez por proceso, guardado en una variable de módulo). **Sin literal en el código**: es lo que mantiene la suite hermética — y **tiene que estar memoizado**, porque el mismo proceso firma y verifica (`adminPreciosRoutes.test.js` importa `getJwtSecret` desde A-07 r4: si cada llamada devolviera algo distinto, los tokens no validarían).

Borrá también `TEST_SECRET` si queda sin uso.

## Cargo 2 — `biometricCryptoService.js:18` sin literal (hallazgo 8)

`CLAVE_LEGADA` existe para **descifrar y re-cifrar** los datos que ya están cifrados con la clave vieja: **no se puede cambiar la fórmula de derivación**, sólo quitar el respaldo.

- Si falta `JWT_SECRET` ⇒ **lanzar** (esa función hoy no tiene de dónde derivar sin el literal).
- **Verificá que sigue derivando lo mismo** con el `JWT_SECRET` puesto: el mismo ciphertext viejo tiene que seguir descifrándose. Si tenés acceso a un ciphertext legado (el script `backend/scripts/reencryptBiometricData.js` lo sugiere), usalo como prueba; si no, decilo como «no medido» y explicá con qué lo reemplazaste.

## Cargo 3 — las 5 líneas de prosa (hallazgos 1-5)

Sustituí **sólo el valor** por `***`, dejando la frase intacta, y agregá al pie de cada documento: `> Valor redactado el 2026-09-26 (CI-14). El original queda en el historial de Git; se conserva como registro, no se borra la línea.`

**Prohibido:** borrar líneas, reescribir los informes, o «limpiar» más de lo pedido.

## Cargo 4 — la prueba (esto es la entrega)

Con el **entorno completo del CI** (`NODE_ENV`, `JWT_SECRET`, `DATABASE_URL`, `TEST_DATABASE_URL`, `RLS_ROLE_PASSWORD`), checkout **LF**, base limpia, pegá las salidas crudas:

1. `node scripts/verifyNoVersionedSecrets.js < /dev/null` ⇒ **esperado `exit 0`, 0 hallazgos** (hoy: exit 1, 8).
2. `npx jest src/tests/audit360-remediation.test.js --runInBand` ⇒ **verde** (hoy rojo: es la misma causa).
3. Las suites que firman y verifican tokens ⇒ verdes **con** y **sin** `JWT_SECRET` exportado (el mismo resultado en las dos).
4. **Mutación (obligatoria):** con `NODE_ENV=production` y `JWT_SECRET` **sin poner**, el arranque debe **fallar** con el error del Cargo 1 — pegá la salida cruda. Sin esto, «fallo rápido» es una hipótesis.

## Nota de la ronda del 2026-09-27 (medido por el Arquitecto)

- **La CI-30 (el control de 32 bytes de la clave biométrica) NO se toca: se queda.** `initializeKey()` corre en el **cargado del módulo** (`biometricCryptoService.js:63`) ⇒ un formato inválido hace **fallar el arranque**, no un 500 en caliente. Medido hoy en producción (42 variables, sin imprimir valores): `BIOMETRIC_ENCRYPTION_KEY` **64 chars hex** ⇒ la rama hex lo decodifica a **32 bytes** ⇒ **aceptado, no lanza**; `ENCRYPTION_KEY` igual. ⇒ Es un **no-op** sobre los valores de hoy.
- **Formato válido para cualquier rotación**: **64 chars hex** o **32 bytes utf8**, nada más. Y las claves biométricas **no se rotan sin correr `scripts/reencryptBiometricData.js`** (los datos guardados están cifrados con la clave actual).
- **A-08 no quitó este literal**: `biometricCryptoService.js:18` (`CLAVE_LEGADA` con el respaldo literal) **sigue ahí** en el tren y en `fix/caminos-muertos` (verificado: el escáner lo señala en las dos) ⇒ **esta orden sigue siendo la única que lo quita**; aterrizar A-08 no limpia el paso 7.
- **No dupliques trabajo con `origin/fix/jwt-sin-respaldo`** (ya escrito, sin aterrizar): hace lo mismo en `jwt.js` y en el biométrico y trae **dos tests aprovechables** — `backend/src/tests/jwtNoFallback.test.js` y `backend/src/tests/biometricNoFallback.test.js`. **Usalos como referencia del test que primero falla** y podés traerlos a tu rama; lo que **no** hay que hacer es aterrizar esa rama: está **vieja** (nació de un `main` anterior: su árbol hoy da **104 hallazgos**, con `ci.yml` y prosa que ya están arreglados en el tren) y **choca** con la reescritura del biométrico de A-08.

## Compuertas antes de empujar

1. `git status --porcelain` + `git log -1 --format='%h %s'` + `git rev-list --count b545ef22..HEAD`.
2. Las 4 salidas crudas del Cargo 4.
3. `node --check` de cada archivo tocado.
4. `git diff --stat` sin archivos fuera de los 8 listados.
5. Lo que no se pueda medir: **«no medido»** con el motivo.
