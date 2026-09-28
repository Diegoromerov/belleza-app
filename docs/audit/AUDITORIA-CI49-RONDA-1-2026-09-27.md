# Auditoría — CI-49 ronda 1 (rama `fix/ci49-credencial-no-publicada`)

**Auditor:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
**Procedencia:** `origin/fix/ci49-credencial-no-publicada` tip **`b264108f7`**, merge-base con `origin/main` = **`8ad61234a`** (sin commits ajenos), medido en worktrees propios (`scratch/ci49/wt`, `scratch/ci49/wtmain`) sin tocar el banco ni la rama del Ejecutor.
**Veredicto:** **ACEPTADA PARCIALMENTE** — lo entregado funciona y está medido; queda abierta **una forma que el propio objetivo nombra**, y la causa es compartida con mi orden.

---

## 1. Lo que medí (y cómo)

| # | Medición | Resultado |
|---|---|---|
| 1 | Compuerta sobre el árbol de la rama | `✅ Sin credenciales versionadas en archivos trackeados.` · **exit 0** |
| 2 | `backend/seed.sql` de la rama, barrido por formas | `password123` ⇒ **0** · hash bcrypt literal ⇒ **0** · queda el marcador `__SEED_PASSWORD_HASH__` |
| 3 | `src/tests/seedRunner.test.js` aislado | **2/2 passed** — «Sin SEED_PASSWORD: falla cerrado sin insertar filas» y «Con SEED_PASSWORD: ninguna cuenta autentica con password123» (aserción `bcrypt.compare`, no texto) |
| 4 | `src/tests/verifyNoVersionedSecrets.test.js` aislado | **7/7 passed** — los 4 casos previos intactos (C2, C3, C4, Coexistencia legacy) + 3 nuevos |
| 5 | Sonda directa de las reglas nuevas contra el **defecto real** | prosa con `contraseña` ⇒ 1 hallazgo ✅ · línea `INSERT` con el hash de `password123` ⇒ 1 hallazgo ✅ · hash bcrypt de contraseña fuerte ⇒ 0 ✅ |
| 6 | Gate completo (comando del CI) | rama: `4 failed, 74 passed, 78 total` · `23 failed, 1 skipped, 573 passed, 597 total` — **idéntico a lo que declaró el Ejecutor** |
| 7 | Diff del PR | 8 archivos: `seed.sql` 8+/9−, `index.js` 5+/10−, `verifyNoVersionedSecrets.js` **47+/0−**, `seedRunner.js` (nuevo, 31), `seedRunner.test.js` (nuevo, 43), el test del escáner 43+/3− (**sólo se borraron 3 líneas de comentario**), y las dos evidencias |
| 8 | `EXENTAS`/`VENDOR` antes/después | **9 / 9** — no se ampliaron ✅ |
| 9 | Tests borrados o salteados | ninguno nuevo; los `skip` que aparecen son preexistentes (`geminiFallback`, `ownerMultiSalonDashboard` gated) ✅ |

`index.js`: el guardián de producción **se muda** a `seedRunner.js` y pasa de `console.warn` a `throw` — pero la llamada está dentro del `try/catch` de `initDatabase`, así que en producción (donde `needsSeed` es `false` porque `provider@beautyapp.com` existe) no cambia nada observable. Se deja constancia, no es defecto.

## 2. Lo que queda abierto (el residuo)

**La forma «valor por defecto literal en variable sensible» sigue siendo invisible para la compuerta.** Sonda directa, cuatro formas:

| forma | hallazgos |
|---|---|
| `process.env.DB_PASSWORD \|\| 'Literal123!'` | **0** |
| `process.env.JWT_SECRET \|\| 'devsecret123'` | **0** |
| `process.env.API_KEY ?? 'live_key_1234567890'` | **0** |
| `DB_PASSWORD=Literal123!` (estilo `.env`) | **0** |
| `const ADMIN_SECRET = 'SuperSecret123!'` (ya cubierta) | 1 ✅ |

Y esa forma aparece **12 veces en el árbol**: `runMigrations.js:93`, `prepareRlsDatabase.js:42`, `publishAcademyContent.js:101`, `purgeAcademyEvidence.js:53`, `config/database.js:40`, `config/db.js:32`, `admin-glow/admin.controller.js:267`, `seed_glowapp_kb.js:27`, `frontend/backend/src/controllers/authController.js:4`, `frontend/backend/src/middleware/auth.js:2`, `auditoria-belleza-app.md:25` y `:28`.

**Segunda brecha, menor:** la regla de prosa exige la `ñ` — `contrasena` (sin acento) ⇒ **0 hallazgos**; `contraseña` ⇒ 1. Un repo que escribe en español y a veces sin acentos tiene que aceptar las dos grafías.

**Causa compartida (R-06):** mi orden de ronda 1 afirmó que esa forma «ya está cubierta» y **no la medí**. El residuo es de la orden además de la entrega. Se registra, no se borra.

## 3. Hallazgo colateral: CI-51

`admin.controller.js:267` = `process.env.KYC_WEBHOOK_SECRET || 'glowapp_secure_kyc_webhook_secret_2026'`, y `KYC_WEBHOOK_SECRET` está **AUSENTE** entre las 42 variables de producción (medido, sólo nombres). Severidad **medida, no supuesta**: el router `glow-admin` **no está montado** — `/api/glow-admin/dashboard/financial-summary` ⇒ **404**, con `/api/health` ⇒ 200 y `/api/admin/dashboard` ⇒ 401 como controles ⇒ **hoy no es explotable**. Riesgo latente si alguien monta el router sin definir la variable. No envié ninguna petición de escritura a producción.

## 4. Trampa medida de esta ronda (para TRAMPAS)

**Mi primera corrida del gate sobre la rama dio `5 failed / 24 failed` con `tests/ownerMultiSalonDashboard.test.js`**, y estuve a un paso de cobrárselo al Ejecutor. La suite aislada da **verde en `main` y en la rama** (`1 skipped, 5 passed, 6 total` en las dos), y la segunda corrida completa sobre la rama dio **`4 / 23`**, idéntico a su informe. Regla: **ante una suite gated que aparece roja sólo en la corrida completa, medirla aislada en las dos revisiones antes de atribuirla** — y el baseline del gate se mide **en la misma sesión y el mismo entorno**, no se hereda.

## 5. Evidencia cruda

`scratch/ci49/`: `aud1.sh`, `aud2.sh`, `aud3.sh` (worktree + compuerta + sonda + tests aislados), `probe.js`, `probe2.js` (sondas de reglas), `gate.sh` / `gate.txt` (1ª corrida, 5/24 flaky), `gate2.sh` / `gate2.txt` (2ª corrida, 4/23), `gate_main.sh` / `gate_main.txt` (baseline de `main`: `4 failed, 73 passed, 77 total` · `23 failed, 1 skipped, 568 passed, 592 total`), `attr.sh` (atribución), `vars.js` (auditoría de variables de producción, sólo nombres).
