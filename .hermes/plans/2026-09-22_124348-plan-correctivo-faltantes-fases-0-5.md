# Plan correctivo — Faltantes de las fases 0-5 · GlowApp

> **Base:** `baseline-v1-stable` @ `77497a20`, worktree `setup_glowguide_architecture`. Árbol sin commitear.
> **Antecedente:** `.hermes/plans/2026-09-22_124348-fase5-reporte-cierre-funcionalidad-real.md`
> **Reglas vigentes:** cero mocks nuevos · causa raíz, no parche · migraciones numeradas e idempotentes · nada de `--update-baseline` ni `--update-goldens` sin decisión explícita · sin commit ni push · nada de `success: true` local ni `Future.delayed` que sustituya una llamada real · todo cambio con `npm test` y `flutter analyze` en verde.

**Objetivo:** cerrar lo que quedó abierto en las fases 0-5, en orden de riesgo: primero el riesgo externo (secretos), después la garantía de aislamiento multi-tenant, y luego el residual funcional.

**Estado de partida (verificado hoy):** Jest 43/42/0 EXIT 0 · Flutter analyze 473 issues / 0 errores / EXIT 0 · Gate 4 EXIT 0 · anti-fabricación EXIT 0 · `verifyTenantIsolation` EXIT 1 (no verificable) · `flutter test` +36 −3 · flujo real 12/12 · Gate 3 5/5.

---

## Decisiones que se piden antes de ejecutar

| # | Decisión | Opciones | Recomendación |
|---|---|---|---|
| **D7** | Los 3 goldens de `BookingScreen` (0.87 % de píxeles) | (a) regenerar con `--update-goldens` tras revisar el diff · (b) tratar como regresión y corregir el layout | **(a)**, con el diff inspeccionado antes: `booking_screen.dart` se modificó en la fase UI previa (21-sep) y el cambio es de antialias, no de layout |
| **D8** | Rol RLS para poder verificar el aislamiento | (a) crear `app_rls_user` sin `BYPASSRLS` en el clúster local con contraseña en `.env.test` **no versionado** · (b) dejarlo no verificable y documentarlo | **(a)** — sin esto, OLA 3 no se puede probar |
| **D9** | Datos de prueba en `beauty_db` | (a) script de limpieza idempotente · (b) dejarlos y documentarlos | **(a)** al cerrar C4 |
| **D10** | Fallback silencioso del repositorio | (a) propagar el error (500) y quitar el fallback a memoria · (b) mantenerlo y solo registrar | **(a)** para el Business Center; es el patrón que ya produjo un “verde falso” |
| **D11** | Carga de evidencia del Business Center | (a) implementar subida real (multer + endpoint + UI) · (b) retirarla formalmente del alcance de producto | **(a)** si el módulo sigue vivo; si no, **(b)** y quitarlo del plan de producto |
| **D12** | Purgar `.env.production` del historial de git | (a) `git filter-repo` + force-push coordinado · (b) rotar las claves y dejar el historial | **(b) primero** (rotar ya); **(a)** solo con ventana acordada: reescribe historia |
| **D13** | Los 6 módulos visuales borrados en FASE 4 | (a) restaurarlos como módulos dormidos con su ruta y su enganche · (b) mantenerlos fuera | **(b)** salvo que tengan dueño de producto; se restauran en un comando |

---

## C1 · Secretos versionados — riesgo externo (sin decisión bloqueante)

**Motivo:** `.env.production` está versionado con credenciales vivas. Es el riesgo más alto del proyecto y no depende de código.

**Tarea C1.1 — Medir la exposición**
- Comando: `git log --all --oneline -- .env.production` y `git ls-files | grep -E '\.env'`
- Esperado: confirmar cuántos commits lo contienen y si sigue en el índice.

**Tarea C1.2 — Rotar (D12b)**
- Rotar en cada proveedor: `JWT_SECRET`, `ENCRYPTION_KEY` y las tres API keys. Las nuevas solo en el gestor de secretos / variables del despliegue (EKS), **nunca** en el repo.
- Verificación: el backend arranca y `/api/health` responde 200 con los valores nuevos; ninguna credencial vieja aparece en `git ls-files`.

**Tarea C1.3 — Guard nuevo**
- Crear: `backend/scripts/verifyNoVersionedSecrets.js` — falla si un `.env*` que no sea `.env.example` está en el índice o si un `.env*` contiene valores no vacíos para claves sensibles.
- Regla de nacimiento: **debe nacer ROJO** sobre el estado actual; si nace verde, el guard no sirve.
- Verificación: `node scripts/verifyNoVersionedSecrets.js` → rojo antes, verde después de C1.2/C1.4.

**Tarea C1.4 — Purgar del historial (D12a, opcional)**
- Solo con ventana acordada: `git filter-repo --path .env.production --invert-paths` y force-push coordinado con el equipo.
- Verificación: `git log --all -- .env.production` → vacío.

**Gate C1:** `git ls-files | grep -E '\.env'` → solo `.env.example`; guard EXIT 0.

---

## C2 · OLA 3 — aislamiento multi-tenant verificable (D8)

**Evidencia del hueco:** `backend/scripts/verifyTenantIsolation.js:121` exige un rol **sin** `BYPASSRLS`; `app_rls_user` no existe (`app_runtime_user`/`app_user` sí) y `admin` es superusuario, así que la prueba no puede fallar nunca. **Un gate que no puede ponerse rojo no es un gate.**

**Tarea C2.1 — Rol de verificación** (requiere D8a)
- Usar `backend/scripts/setupRlsRole.sql` + `backend/scripts/prepareRlsDatabase.js`; contraseña en `.env.test` local no versionado.
- Verificación: `psql -c "SELECT rolname, rolbypassrls FROM pg_roles WHERE rolname LIKE 'app%'"` → `app_rls_user` con `rolbypassrls = f`.

**Tarea C2.2 — Que el gate sea ejecutable**
- Ajustar `verifyTenantIsolation.js` para tomar la conexión de `TEST_DATABASE_URL` (hoy el `.env` no la define: usa `DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD`).
- Verificación: `node scripts/verifyTenantIsolation.js` → sale de EXIT 1 (conecta y evalúa de verdad).

**Tarea C2.3 — Criterio de mutación (el corazón de OLA 3)**
- Reescribir `backend/src/tests/tenant-isolation.test.js`: quitar el `WHERE tenant_id` de un controlador **debe** poner la suite roja.
- Prueba de mutación (dos veces, en dos controladores distintos): quitar la cláusula → suite ROJA; restaurarla → suite VERDE.
- Verificación: dejar constancia del rojo observado (el plan exige que el gate nazca rojo).

**Tarea C2.4 — Acceso cruzado = 403, no 500**
- Evidencia: hoy un tenant pidiendo datos de otro no recibe una respuesta limpia.
- Verificación: probe con dos tenants → **403** y cuerpo sin datos del otro tenant.

**Gate C2:** mutación → rojo · código correcto → verde · cross-tenant 403.

---

## C3 · Goldens de BookingScreen (D7)

**Tarea C3.1 — Decidir con la imagen delante**
- Comando: `flutter test test/golden/phase5_goldens_test.dart` → 3 fallos.
- Inspeccionar `test/golden/failures/*.png` contra `test/golden/goldens/*.png` (el diff ya medido es 0.87 % de píxeles).
- Decisión: si el cambio es intencional → C3.2a; si es regresión → C3.2b.

**Tarea C3.2a — Regenerar (solo con D7a)**
- Comando: `flutter test test/golden/phase5_goldens_test.dart --update-goldens`
- Verificación: `git diff --stat test/golden/` y **leer el diff de píxeles** antes de aceptarlo; después `flutter test` completo → 0 fallos.

**Tarea C3.2b — Corregir (si D7b)**
- Localizar el widget que cambió en `frontend/lib/screens/booking_screen.dart` (modificado el 21-sep) y devolverlo al layout del golden.

**Gate C3:** `flutter test` → **0 fallos** (hoy +36 −3).

---

## C4 · Residual funcional de FASE 3

**Tarea C4.1 — Subida real de evidencia (D11a) o retiro formal (D11b)**
- Si (a): `multer` en el backend + endpoint `POST /api/v1/business/tasks/:id/evidence` + botón real en `frontend/lib/screens/provider/business/business_task_detail_screen.dart` (hoy la carga se retiró deliberadamente).
- Si (b): documentar en el plan de producto y dejar la pantalla como está.
- Verificación (a): subir un archivo real y comprobar la fila y el almacenamiento; (b) `grep -rE 'upload' frontend/lib` sin botones falsos.

**Tarea C4.2 — Auditar las 2 pantallas Business restantes**
- `frontend/lib/screens/provider/business/business_onboarding_screen.dart`, `business_document_generator_screen.dart`.
- Método (el mismo que destapó el detalle de tarea): ¿de dónde sale cada dato que pinta? `grep` por literales, `success: true`, `Future.delayed`, y comparar contra los endpoints reales de `backend/src/routes/businessRoutes.js`.
- Verificación: cada dato pintado trazado a un endpoint o literal eliminado.

**Tarea C4.3 — Matar el fallback silencioso (D10a)**
- `backend/src/repositories/businessRepository.js` (todos los `catch` que devuelven memoria) y `backend/src/config/db.js:528`.
- Regla: el error se propaga (500) y el flag `isPgAvailable` se recupera al volver la base.
- Verificación: apagar Postgres → la API responde **500 con error**, no datos en memoria; encenderlo → vuelve a servir real (hoy se queda en memoria).
- ⚠️ Cambia comportamiento: revisar qué llamadores dependen del fallback antes de tocarlo.

**Tarea C4.4 — `/api/providers` devuelve 5 de 9**
- Encontrar el filtro: no es `tenant_id`, ni `is_active`, ni usuario activo (`perfiles_prestador` = 9).
- Verificación: `SELECT count(*)` vs las 9 filas devueltas o el filtro documentado.

**Tarea C4.5 — `AuthService.getMySalon()`**
- `frontend/lib/services/auth_service.dart`: devuelve el cuerpo de error; revisar llamadores que tratan `null` como “sin salón”.

**Gate C4:** los 4 puntos verificados uno a uno; gate 3 (5/5) y el probe del Business Center siguen verdes.

---

## C5 · Deuda del plan y del entorno

**Tarea C5.1 — 3 migraciones rotas**
- `031_aura_pgvector… (deleted_at)`, `034_add_fks_to_academy_tables` (unique), `037_create_biometric_consents.consent_type`.
- Cada una: script **numerado e idempotente** (la regla del proyecto), nunca mutación a ciegas.
- Verificación: el arranque reporta **0 avisos** de migración (hoy 3).

**Tarea C5.2 — Datos de prueba (D9a)**
- Script de limpieza idempotente para el salón `id=1`, 2 membresías, 3 invitaciones y 3 pedidos `PENDIENTE_PAGO`.

**Tarea C5.3 — 2 archivos solo-test**
- `frontend/lib/screens/ideas/aura_welcome_screen.dart`, `frontend/lib/screens/profile/my_glow_dashboard_screen.dart`: decidir borrarlos con su test o darles ruta.

**Tarea C5.4 — `tenant_id` TEXT vs INTEGER**
- Migración aparte que unifique el tipo entre las tablas `business_*` y las de salón. Requiere revisar `062:72` (`tenant_id = current_setting(...)` sin cast).

**Tarea C5.5 — Módulos visuales (D13)**
- Los 6 borrados en FASE 4: restaurar con `git checkout -- <ruta>` y engancharlos, o dejarlos fuera.

**Tarea C5.6 — `backend/src/*.dart` sin rastrear**
- Fuera de alcance por decisión explícita. Solo documentar que siguen ahí.

---

## Orden de ejecución sugerido

1. **C1** (riesgo externo) → 2. **C2** (garantía de aislamiento) → 3. **C3** (una decisión, 5 minutos) → 4. **C4.3** (el patrón que produce verdes falsos) → 5. **C4.1/C4.2/C4.4/C4.5** → 6. **C5**.

## Riesgos

- **C4.3** cambia comportamiento en producción: si algún camino depende del fallback, pasará de “datos en memoria” a 500. Mitigación: inventariar llamadores antes.
- **C2** toca credenciales de base de datos: se hace sobre el clúster local, con contraseña en un archivo no versionado.
- **C1.4/D12a** reescribe historia compartida: no se ejecuta sin ventana acordada con el equipo.
- **C3.2a** (`--update-goldens`) puede blanquear una regresión real: por eso el diff se revisa a ojo antes.

## Verificación global al cierre

`node scripts/verifyTestBaseline.js` → EXIT 0 · `node scripts/verifyFlutterBaseline.js` → EXIT 0 · `node scripts/verifyNoDeadRoutes.js` → EXIT 0 · `node scripts/verifyNoFabricatedPayments.js` → EXIT 0 · `node scripts/verifyNoVersionedSecrets.js` → EXIT 0 (nuevo) · `node scripts/verifyTenantIsolation.js` → ejecutable y con mutación roja · `flutter test` → 0 fallos.
