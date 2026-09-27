# Orden de ronda 2 — CI-49: la forma que quedó invisible (valor por defecto literal)

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Ronda 1: aceptada parcialmente.** Lo que hiciste está medido y se queda. Esta orden cierra **una** cosa: la forma que el objetivo nombra y la compuerta todavía no ve. **Debe quedar cero:** `tests/ownerMultiSalonDashboard.test.js` y las cuatro suites de `business*` son deuda heredada; no las toques.

---

## 1. LO QUE YA ESTÁ BIEN Y NO SE TOCA

Medido por el Auditor sobre tu rama `fix/ci49-credencial-no-publicada` @ `b264108f7` (base `8ad61234a`), en un worktree propio:

- `backend/seed.sql` ya no publica la contraseña ni el hash; el placeholder `__SEED_PASSWORD_HASH__` y el hash en runtime funcionan.
- La siembra sin `SEED_PASSWORD` **falla cerrado**; el test de comportamiento pasa **2/2** y la aserción es la correcta (`bcrypt.compare('password123', hash) === false`, no comparación de texto contra el fuente).
- La compuerta sobre tu árbol sale **exit 0**.
- Tus dos reglas nuevas **sí** funcionan sobre el defecto real (sonda directa: prosa con `contraseña` ⇒ 1 hallazgo; el `INSERT` con el hash bcrypt de `password123` ⇒ 1 hallazgo; un hash bcrypt de contraseña fuerte ⇒ 0, que es el diseño pedido).
- No borraste ni saltaste tests, y `EXENTAS`/`VENDOR` siguen con 9 líneas como en `main`.

**No reescribas nada de esto.** Los cambios de esta ronda van **encima**, en la misma rama, sin `--force`.

## 2. EL AGUJERO (medido, y en parte es culpa de mi orden)

Mi orden anterior declaró que la forma `process.env.X_PASSWORD || 'literal'` «ya está cubierta» por la regla `:74-98`. **Era falso y no lo medí.** Sonda directa contra tu compuerta, cuatro formas:

| forma | hallazgos |
|---|---|
| `const DB_PASSWORD = process.env.DB_PASSWORD \|\| 'Literal123!';` | **0** |
| `const JWT_SECRET = process.env.JWT_SECRET \|\| 'devsecret123';` | **0** |
| `const API_KEY = process.env.API_KEY ?? 'live_key_1234567890';` | **0** |
| `DB_PASSWORD=Literal123!` (estilo `.env`) | **0** |
| `const ADMIN_SECRET = 'SuperSecret123!';` (control positivo, ya cubierto) | 1 ✅ |

Y esa forma **existe 12 veces en el árbol**, es decir: la compuerta dice «✅ Sin credenciales versionadas» mientras el árbol las tiene. Las ocurrencias (verificalas vos, el grep está abajo):

`backend/runMigrations.js:93` · `backend/scripts/prepareRlsDatabase.js:42` (`RLS_ROLE_PASSWORD \|\| 'ci_only_password'`) · `backend/scripts/publishAcademyContent.js:101` · `backend/scripts/purgeAcademyEvidence.js:53` · `backend/src/config/database.js:40` · `backend/src/config/db.js:32` · `backend/src/modules/admin-glow/admin.controller.js:267` · `backend/seed_glowapp_kb.js:27` (`DB_PASSWORD \|\| 'admin123'`) · `frontend/backend/src/controllers/authController.js:4` · `frontend/backend/src/middleware/auth.js:2` · `auditoria-belleza-app.md:25` y `:28` (raíz del repo, **no** está bajo `docs/`, así que no cae en la exención).

Grep exacto (desde la raíz del repo):

```
git grep -nE "(PASSWORD|SECRET|TOKEN|API_KEY|CLAVE|PWD|PASS)[A-Z_]*[[:space:]]*(\|\||\?\?)[[:space:]]*['\"]"
```

**La peor es `admin.controller.js:267`** (`KYC_WEBHOOK_SECRET || 'glowapp_secure_kyc_webhook_secret_2026'`) porque la variable está **AUSENTE en producción** (medido, sólo nombres): el literal publicado *sería* el secreto vivo. Severidad real, medida y no supuesta: el router `glow-admin` **no está montado** — `/api/glow-admin/dashboard/financial-summary` ⇒ **404** con `/api/health` ⇒ 200 y `/api/admin/dashboard` ⇒ 401 como controles ⇒ hoy **no es explotable**. Eso no cambia lo tuyo: el default es un secreto publicado y la compuerta no lo ve.

## 3. ALCANCE DE ESTA RONDA

| Acción | Dónde |
|---|---|
| **Editar** | `backend/scripts/verifyNoVersionedSecrets.js` — reglas nuevas para los defaults literales; y la regla de prosa debe aceptar la grafía **sin acento** |
| **Editar** | las 12 ocurrencias del §2 (salvo las de `docs/`, ver abajo) — **quitando el literal**, no escondiéndolo |
| **Editar** | `backend/src/tests/verifyNoVersionedSecrets.test.js` — un caso por forma nueva, y el caso de `contrasena` sin acento |
| **Editar (declarado)** | `.github/workflows/ci.yml` **sólo** el paso de preparación de base, y **sólo si** al quitar el default de `prepareRlsDatabase.js:42` el paso necesita que `RLS_ROLE_PASSWORD` venga del `env:` — declaralo en el PR con la línea |
| **Editar (declarado)** | `backend/.env.example`, si algún valor de ejemplo es un literal usable ⇒ reemplazalo por marcador |
| **NO TOCAR** | `backend/src/routes/paymentRoutes.js` (tiene su arreglo propio, ya aprobado) · los `testPathIgnorePatterns` y el paso de tests de `ci.yml` · `backend/seed.sql` y `seedRunner.js` (ya están bien) · `backend/public/**` · migraciones · `EXENTAS`/`VENDOR` · datos de producción |

**Los docs que citan el defecto** (`auditoria-belleza-app.md:25,28`, `docs/audit/*.md`, `docs/agents/ordenes/*.md`): en `docs/` la compuerta no mira, así que no las toques por la compuerta. Pero `auditoria-belleza-app.md` está en la **raíz**, sí cae, y la salida correcta **no** es eximirla: es reemplazar el literal por un marcador (`REDACTED`) — un documento que explica la vulnerabilidad no necesita el literal de la clave.

## 4. CÓMO, SIN DECIDIR POR EL DUEÑO

- El literal **desaparece**: el valor tiene que venir del entorno. Si al quitarlo algo no arranca en desarrollo, eso es el comportamiento correcto (fail-closed) y **lo reportás**, no lo compensás con otro default.
- No cambies el **comportamiento** de conexión cuando la variable **sí** está: sólo desaparece el fallback. `db.js:32` y `database.js:40` son el camino de conexión real ⇒ tratalos con cuidado y medí después.
- Si te encontrás queriendo agregar un archivo a `EXENTAS` para que tu propio cambio pase la compuerta: **eso es una pregunta abierta en el PR**, no una edición.

## 5. VERIFICACIÓN (números medidos en esta sesión; si no coinciden, PARÁ y reportá)

**Gate con el comando del CI** (`ci.yml:99`), desde `backend/`:

```
npm test -- --coverage --testPathIgnorePatterns="geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|api.cors"
```

**Línea base medida hoy en `main` (`8ad61234a`), misma máquina y mismo entorno, en la misma sesión:**
`Test Suites: 4 failed, 73 passed, 77 total` · `Tests: 23 failed, 1 skipped, 568 passed, 592 total`
Rojas (por nombre): `business.integration`, `businessAdminDocs.integration`, `businessHardening.integration`, `businessSystem.integration` ⇒ deuda heredada, ficha CI-43.

**Tu criterio es el delta:** tu rama sale de `main`, así que el resultado tiene que ser **esas 4 suites rojas y ninguna más**, más tus tests nuevos. Compará **nombres de suites**, no el conteo: un worker distinto cambia el conteo.

*Aviso de arnés, medido:* en mi corrida completa sobre tu rama apareció una 5ª roja, `tests/ownerMultiSalonDashboard.test.js` (el test gated «Prueba de Integración SQL Real contra PostgreSQL»). Corrida **aislada**, esa suite da verde en `main` **y** en tu rama (`1 skipped, 5 passed, 6 total` en las dos) ⇒ no la pude atribuir a tu diff y **no te la cobro**. Si en tu corrida aparece roja, corréla aislada, pegá las dos salidas y decilo; no la "arregles".

**La compuerta, con el árbol real:**
- despues del cambio: `node backend/scripts/verifyNoVersionedSecrets.js` ⇒ **exit 0** (pegá la salida);
- **RED obligatorio:** plantá en un archivo **versionado** una línea con la forma nueva —por ejemplo `const X_SECRET = process.env.X_SECRET || 'Literal123!';`— y corré la compuerta ⇒ **exit ≠ 0** con `archivo:línea` y sin imprimir el valor. Pegá la salida. Después borralo **del árbol y del índice** y verificá las dos cosas: `git diff --cached -- <archivo>` vacío **y** `git show :<archivo> | grep -c 'Literal123'` = `0`.
- **Mutación por regla:** quitá una regla nueva, corré su test, pegá el fallo, restaurá (y verificá que restauraste con `git diff --stat`).

**Prueba del camino de conexión (esto es lo que puede romper el CI):** `prepareRlsDatabase.js:42` alimenta el paso de preparación de base del workflow. Después de quitar su default, corré ese script contra una base fresca local, con la variable puesta, y pegá la salida (exit + el «✅ Base preparada» si aplica). Un script que ya no corre con la variable puesta es un CI roto que llegaría a `main`.

**Prohibido cerrar esto con un test que lee el código como texto** (`TRAMPAS.md` R-07): las aserciones van contra `analizarSalida` con entradas construidas, como ya hacés.

## 6. ENTREGA

- **Misma rama** `fix/ci49-credencial-no-publicada`, commit **encima** (sin `--force`, sin rebase), PR que ya tenés.
- Cuerpo del PR: la tabla del §2 con las cuatro formas medidas antes/después, la lista de las 12 ocurrencias con **una línea por archivo** diciendo si la variable está definida donde el default se usaba (y si no lo está, quién la define: `ci.yml`, `.env`, el entorno local), el RED y el GREEN de la compuerta, el resultado del gate con su línea base, y la corrida del script de preparación de base.
- Si algo no lo pudiste medir: **«no pude medirlo»** y el motivo. Eso cierra; inventarlo, no.

## 7. PROHIBICIONES (idénticas a la ronda 1)

1. No toques datos de producción (el censo y las desactivaciones ya están hechos, y hay una ficha nueva **CI-50** con 14 cuentas demo activas que decide el Dueño).
2. Nada de `NODE_TLS_REJECT_UNAUTHORIZED=0`, `-SkipCertificateCheck` ni `curl -k`.
3. Nada de `--force`/`--force-with-lease`, no borres ramas del remoto, no `gc`, no reescribas historial.
4. No push directo a `main`: rama + PR.
5. No imprimas contraseñas, hashes, tokens ni cadenas de conexión — tampoco los que ya son públicos.
6. No amplíes `EXENTAS`/`VENDOR`/`testPathIgnorePatterns`, no saltes tests para bajar conteos, no marques tus propios hallazgos como falsos positivos.

## 8. DEFINICIÓN DE TERMINADO

1. La sonda del §2, repetida contra el árbol de tu rama, da **hallazgo en las cuatro formas** (pegá la salida de las cuatro).
2. Las 12 ocurrencias del §2 ya no tienen literal; por cada una, el PR dice de dónde sale el valor ahora.
3. La regla de prosa detecta `contrasena` sin acento **y** `contraseña` con acento (dos casos en el test).
4. Cada regla nueva tiene su caso y su mutación pegada.
5. Compuerta sobre el árbol: **exit 0** después, **exit ≠ 0** con el patrón plantado, y el patrón restaurado también en el índice.
6. `prepareRlsDatabase.js` corrido contra base fresca con la variable puesta ⇒ exit 0 pegado.
7. Gate: **4 suites rojas y ninguna más** (o el número distinto, pegado crudo y explicado).
8. Commit encima en la misma rama, sin `--force`, y PR actualizado.

---

**Preguntas abiertas que NO son tuyas** (van al PR, no a tu criterio): rotar o no el `KYC_WEBHOOK_SECRET` y definirlo en producción (CI-51), qué hacer con las 14 cuentas demo activas (CI-50), y cómo quiere el Dueño que el equipo siembre en desarrollo.
