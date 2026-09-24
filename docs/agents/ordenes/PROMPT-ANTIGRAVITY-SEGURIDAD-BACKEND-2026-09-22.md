# PROMPT PARA ANTIGRAVITY — Remediación de seguridad del backend (versión verificada del informe 360°)

> Contexto: Diego recibió un "INFORME DE AUDITORÍA 360°" externo con 23 hallazgos. Ese informe fue
> **verificado hallazgo por hallazgo contra `C:\beauty-app`** (commit `362b590c`). Resultado: 9 ciertos,
> 3 parciales, **7 falsos positivos o ya corregidos**, 1 no verificable, y uno (el más grave) **mal
> clasificado**. El detalle completo, con el comando o el `archivo:línea` de cada veredicto, está en
> `C:/Users/Compu casa/auditorias/belleza-app/VERIFICACION-INFORME-23-HALLAZGOS-2026-09-22.md`.
>
> Este prompt trabaja **solo lo verificado**. No agregues items del informe original que aquí no
> aparezcan: son falsos positivos y arreglarlos es regresión.

## 0. Reglas

- **Una rama para todo esto**: `fix/backend-security-remediation-2026-09-22`, creada desde `main`
  **después** de que se mergee `fix/academia-glow-auditoria-2026-09-22` (ese merge ya está en curso).
  Al mergear esta, se borra. No acumules ramas.
- **Nunca** push directo a `main`, **nunca** `--force`.
- Cada fase termina con **evidencia ejecutada**: comando + salida, no descripción.
- Si una fase revela que un hallazgo no aplica, **dilo y detente en esa fase**; no inventes un arreglo.
- Prohibido "arreglar" lo ya resuelto: derivación de clave biométrica, circuit breakers, índices,
  helmet/headers, pooling, CORS del entry real, `EXPOSE_DEV_OTP`. Ver sección final.

---

## FASE 1 — Que una excepción async no mate el proceso (el hallazgo mejor sustentado)

Medido: **94 handlers `async` en `backend/src/routes/*.js`, solo 2 con wrapper**. Express 4 no captura
rechazos async ⇒ `unhandledRejection` ⇒ el proceso cae (Node ≥15). No es "inconsistencia de estilo":
es una caída de servicio a un request.

1. Ya existe el util correcto, creado para las rutas de academia: **`backend/src/utils/expressAsync.js`**
   (`wrapRouterAsync`). Úsalo, no crees otro.
2. Envuélvelos en **orden de exposición**: primero las rutas sin autenticación o con input externo
   (`auth`, `payment`, `booking`, `salon`, `academy` público), después el resto.
3. Revisa además `backend/index.js`: los `app.use(...)` con handler async también necesitan cobertura.
4. Añade una **guarda de proceso** con criterio: `process.on('unhandledRejection')` y
   `process.on('uncaughtException')` que registren, marquen el servicio como degradado y **no** dejen
   el proceso en estado zombie.
5. Test obligatorio: una suite que monte un router con un handler async que lanza y compruebe
   **500 y proceso vivo** (no caída). Sin ese test, el arreglo no está probado.

Evidencia: número de handlers envueltos antes/después (`grep -c`) + salida del test nuevo.

---

## FASE 2 — El blacklist de tokens es FAIL-OPEN (sesiones revocadas siguen válidas)

`backend/src/middleware/auth.js:16`: `if (redisClient && redisClient.isReady)` + `catch` que solo
loguea ⇒ **si Redis está caído o no configurado, un token revocado sigue autenticando**. El propio
comentario del código dice "FAIL-SAFE", que describe lo contrario de lo que hace.

1. Define la política explícita y escríbela: **solo puede ser fail-closed en producción** (sin Redis
   ⇒ 503, no "dejar pasar"), y fail-open únicamente en desarrollo/test con log de advertencia.
2. Corrige el comentario para que describa el comportamiento real.
3. Endurece `backend/src/config/redis.js`: hoy la reconexión corta a los 3 intentos
   (`if (retries >= 3) return new Error(...)`) y el error se loguea **una sola vez** (`loggedError`).
   Que el agotamiento de reintentos produzca una **señal visible** (log de nivel error repetido con
   backoff, o alerta) y que el estado "Redis muerto" sea consultable.
4. Test: con un cliente Redis que lanza en `get`, un token presente en el blacklist debe dar 401 en
   producción (fail-closed) y 401 con advertencia en desarrollo.

---

## FASE 3 — El backdoor real: modo memoria + usuarios demo en producción

El informe separó dos cosas que son **una sola**:

- `backend/src/config/db.js:695`: `memoryFallbackAllowed()` devuelve `true` si
  `ALLOW_MEMORY_FALLBACK === 'true'` **sin ninguna guarda de `NODE_ENV`** ⇒ una variable mal puesta en
  Railway pone toda la API a servir datos de memoria.
- `backend/src/config/db.js:39-63`: `initDefaultUsers()` crea usuarios demo con contraseñas
  **conocidas** (`password123`, `Password123!`) en `memoryUsers`. Verificado: **no** inserta en Postgres
  (el dump de producción no tiene ninguno de esos correos), pero en modo memoria **son los usuarios
  que autentican**.
- Y `initDefaultUsers()` se ejecuta al importar el módulo (`db.js:126`, sin `await`, sin guarda).

Trabajo:
1. Prohibir el modo memoria en producción a nivel de arranque: si `NODE_ENV === 'production'` y
   `ALLOW_MEMORY_FALLBACK === 'true'`, **no arrancar** (o ignorar el flag con log de error explícito).
   Decisión que debes tomar y reportar: ¿ignorar con log o abortar el boot? Se prefiere **abortar**:
   un backend que sirve memoria en producción es peor que un backend caído.
2. `initDefaultUsers()` solo debe ejecutarse cuando el modo memoria esté permitido, y con contraseñas
   aleatorias registradas en el log —no conocidas— o con autenticación deshabilitada para esos usuarios.
3. Verificar que `getDbStatus()` (`db.js:687`) expone `servingFabricatedData` y que **algo lo consulta**:
   un healthcheck que devuelva degradado cuando `servingFabricatedData === true`, para que Railway no
   reporte "healthy" sobre datos inventados.
4. Test: en `NODE_ENV=production` con `ALLOW_MEMORY_FALLBACK=true`, el arranque falla (o el flag es
   ignorado y el estado queda visible). En `test`, sigue funcionando.

---

## FASE 4 — TLS a la base de datos (verificar de verdad los certificados)

Instancias **vivas** con `rejectUnauthorized: false`:
- `backend/src/config/db.js:23` → se activa **siempre** que exista `DATABASE_URL` (o en prod/staging).
- `backend/src/config/db.js:667` → pool RAG.
- `backend/src/config/database.js:30` → **vivo** (31 archivos requieren ese módulo).

Regla a implementar: **`rejectUnauthorized: true` salvo host interno** (`*.railway.internal`), donde
TLS ni se usa. `db.js:668` ya hace esa distinción para el pool RAG: replica ese criterio en los tres
puntos y **unifica la configuración** — hoy `db.js` y `database.js` son dos fuentes de verdad para la
misma conexión; deja una sola (o que `database.js` importe la de `db.js`).

Ojo: `backend/index.js:278` (`httpsTileAgent` para teselas de OpenStreetMap) es tráfico a un servicio
público de mapas; si lo endureces, verifica que las teselas sigan cargando. No es prioridad.

Evidencia: conexión real funcionando contra la base de Railway con verificación activa, y el error
explícito si el certificado no valida. Si no puedes probarlo contra producción, dilo: **no** declares
el arreglo verificado sin haber conectado.

---

## FASE 5 — Rate limiting en autenticación y pago

Hoy: existe un limitador global (`app.use('/api', globalGeneralLimiter)`, `index.js:347`) pero con
**1000 peticiones / 15 min por IP**, y solo **2 de 39** archivos de rutas montan limitador propio.
`login`, OTP, registro y recuperación quedan protegidos solo por ese techo ⇒ fuerza bruta viable.

1. Limitadores específicos y más estrictos en: `login`, `register`, `refresh`, envío/validación de OTP,
   recuperación de contraseña, y creación de reservas/pagos.
2. Que la respuesta al límite sea 429 con `Retry-After` y **sin** filtrar si el usuario existe.
3. No rompas el flujo de la SPA: el techo global está alto a propósito por analítica; mantenlo, agrega
   los específicos encima.

Evidencia: salida real de superar el límite (429 y cabeceras) por endpoint.

---

## FASE 6 — Borrar el código muerto que el informe confundió con código vivo

1. **`backend/src/startup/app.js`**: 0 archivos lo requieren (el entry es `index.js`). Es donde el
   informe ubicó dos hallazgos. Además contiene una debilidad propia:
   `origin.endsWith('.up.railway.app')` (`app.js:120`). Bórralo **después** de confirmar con
   `grep -rn "startup/app" backend --include=*.js` que no queda ninguna referencia.
2. **8 archivos `.dart` dentro de `backend/`** (3 en `services`/`controllers` + 5 en `models`): no
   pueden ejecutarse en Node. Bórralos.
3. **5 `.backup`/`.bak`** (`geminiService.js.backup`, `biometric/youcam.client.js.backup`,
   `runMigrations.js.backup`, `migrations/056….sql.bak`, `migrations/057….sql.backup`). Ya están
   ignorados por git; bórralos del disco para que no confundan auditorías futuras.
   `backend/.env.backup` **no está versionado** (verificado) pero también debe irse.
4. **`backend/migrations/manual/069_force_rls_strict_isolation.sql`** (80 líneas) duplica el nombre de
   `068_force_rls_strict_isolation.sql` (251 líneas, la que sí se aplica) y **nunca se ejecuta**.
   Decide: si es un borrador viejo, bórralo; si aporta algo que 068 no tiene, intégralo en una
   migración nueva numerada en `backend/migrations/`. Lo que no puede quedar es un archivo que parece
   una migración y no lo es.

---

## FASE 7 — Configuración por entorno

1. **3 URLs de producción hardcodeadas en rutas vivas**: `authController.js:468` (link de referidos),
   `salonController.js:180` (link de invitación), `emailService.js:7` (checkout en correo) →
   leerlas de `FRONTEND_URL` (con fallback explícito y validado al arrancar).
2. **`JWT_SECRET`**: hoy lanza si falta o tiene <32 chars ✓, pero el fallback de test existe cuando
   `NODE_ENV === 'test'`. Añade una guarda explícita: si `NODE_ENV === 'production'` y el secreto
   coincide con el valor de test, **abortar el arranque**.
3. Deja constancia en un `.env.example` de cuáles variables son **prohibidas en producción**:
   `ALLOW_MEMORY_FALLBACK`, `ALLOW_PAYMENT_SIMULATOR`, `EXPOSE_DEV_OTP`.

---

## FASE 8 — Logs (última, y sin inflarla)

283 `console.log` medidos (el informe decía 689: cifra falsa). No conviertas esto en un refactor
grande: reemplaza por niveles (`logger.info/warn/error`) **solo en rutas de producción** y **elimina**
los que imprimen datos sensibles (tokens, teléfonos, cuerpos de request con PII). Los de `tests/` y
scripts de siembra pueden quedarse.

---

## FASE 9 — Verificación post-deploy (no es código, es comprobación)

Con el deploy de `fix/academia-glow-auditoria-2026-09-22` mergeado, la migración
**`068_force_rls_strict_isolation.sql` se aplica en el primer arranque**. Verifícalo en producción:

```sql
-- las 10 tablas deben quedar con FORCE
SELECT relname, relrowsecurity, relforcerowsecurity
  FROM pg_class WHERE relname IN (<las 10 tablas del aislamiento>);
-- y que el rol de la app NO sea superusuario ni tenga BYPASSRLS
SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user;
```

Si `relforcerowsecurity` sigue en `false`, el aislamiento multi-tenant **no** está activo: ese es el
hallazgo real de RLS, no el que declaró el informe.

---

## Evidencia que debes devolver (por fase, etiquetada)

1. [V] Handlers async envueltos: antes/después (`grep -c`) + test que prueba que el proceso sobrevive.
2. [V] Test de fail-closed del blacklist con Redis caído.
3. [V] Salida del arranque con `NODE_ENV=production` + `ALLOW_MEMORY_FALLBACK=true` (debe abortar) y
   estado del healthcheck cuando `servingFabricatedData` es verdadero.
4. [V] Conexión real a la base con verificación TLS activa.
5. [V] 429 + `Retry-After` por endpoint de autenticación.
6. [V] `grep -rn "startup/app"` vacío y listado de archivos borrados (`.dart`, `.backup`).
7. [V] URLs de los 3 puntos viniendo de `FRONTEND_URL` (y que los enlaces sigan funcionando).
8. [V] Las dos consultas SQL de la Fase 9 en producción.
9. Cualquier hallazgo del informe original que, al intentar arreglarlo, resulte no aplicable: con el
   error textual, sin maquillarlo.

**Prohibido re-tocar** (ya resuelto; si lo "arreglas" generas regresión): derivación de clave
biométrica (`biometricCryptoService.js` ya lanza si se usa `JWT_SECRET`), circuit breakers
(`circuitBreakerService.js` en uso), índices (`idx_usuarios_email` y 27 migraciones más), helmet/CSP
(`index.js:218`), pools (`db.js` es el único que crea pools), CORS del entry real
(`index.js:181-195`), `EXPOSE_DEV_OTP` (ya exige `NODE_ENV !== 'production'`).
