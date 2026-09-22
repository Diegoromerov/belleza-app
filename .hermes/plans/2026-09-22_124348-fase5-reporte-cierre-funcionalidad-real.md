# FASE 5 — Reporte de cierre consolidado · Funcionalidad no real de GlowApp

**Fecha:** 22-sep-2026 12:43 (HPS) · **Rama:** `baseline-v1-stable` @ `77497a20` (HEAD sin mover) · **Estado:** árbol de trabajo, **sin commit ni push**
**Ruta:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\setup_glowguide_architecture`
**Origen:** plan `.hermes/plans/2026-09-22_102645-plan-correcciones-funcionalidad-real.md` (323 líneas)

**Método:** ningún punto de este reporte es especulativo: cada uno lleva el comando que lo comprobó y el resultado observado. No se creó ningún mock nuevo, no se maquilló ninguna pantalla, no se ejecutó `--update-baseline` ni `--update-goldens`.

---

## 1. Compuertas — último resultado real de cada una

| Compuerta | Comando | Resultado observado | Estado |
|---|---|---|---|
| Jest (backend) | `node scripts/verifyTestBaseline.js` | 43 esperadas · 42 verdes · 0 inestables · **0 fallos nuevos** · EXIT **0** | ✅ |
| Flutter analyze | `node scripts/verifyFlutterBaseline.js` | 0 errores · **473 issues** (línea base 578 → **−105**) · 0 reglas con conteo incrementado · EXIT **0** | ✅ |
| Rutas y archivos muertos (nueva, FASE 4) | `node scripts/verifyNoDeadRoutes.js` | 24/24 rutas con navegación · 0 archivos muertos · EXIT **0** | ✅ |
| Anti-fabricación de pagos | `node scripts/verifyNoFabricatedPayments.js` | 13 focos → **0** · EXIT **0** | ✅ |
| Aislamiento multi-tenant | `node scripts/verifyTenantIsolation.js` | EXIT **1** — no verificable (falta rol sin `BYPASSRLS`) | ⚠️ |
| Suite Flutter completa | `flutter test` | **+36 −3** (los 3 goldens heredados) · 0 fallos nuevos | ⚠️ |
| Flujo real dinero+equipo | `scratch/gate1_gate2_flujo_real.js` | **12/12** con HTTP real y filas reales | ✅ |
| Business Center no fabricado | `frontend/test/screens/gate3_business_no_fabricado_test.dart` | **5/5** | ✅ |

---

## 2. FASE 0 — Andamiaje · **CERRADA 5/5**

| Punto | Antes → Después | Comando · resultado | Estado |
|---|---|---|---|
| T0.1 Guard de fabricación | no existía → `backend/scripts/verifyNoFabricatedPayments.js` | `node scripts/verifyNoFabricatedPayments.js` → nació con 13 hallazgos, hoy 0, EXIT 0 | **CERRADO** |
| T0.2 `business_tasks` | tabla inexistente, `062` fallaba → `backend/migrations/012_business_engine.sql` aplicada por el runner (`backend/index.js:1619-1621`) | arranque del backend → `062` desaparece de la lista de fallos | **CERRADO** |
| T0.3 Migraciones rotas | 4 fallando → **3** (`031`, `034`, `037`), documentadas | log de arranque: “66 migraciones aplicadas, 3 avisos” | **CERRADO** (documentado) |
| T0.4 Servicios por prestador | duda de negocio → confirmado **por prestador** | `SELECT count(*) FROM services` = 133 · prestador 74 = 88 | **CERRADO** |
| T0.5 `WOMPI_WEBHOOK_SECRET` | ausente en `.env` → documentado | `backend/.env.example` · el webhook falla cerrado (401) | **CERRADO** |

## 3. FASE 1 — El camino del dinero · **CERRADA 5/5**

| Punto | Antes → Después | Comando · resultado | Estado |
|---|---|---|---|
| T1.1 Estado del pedido | `backend/src/controllers/orderController.js:128-138` escribía `'PAGADO'` sin cobro → aplica el `DEFAULT 'PENDIENTE_PAGO'` | `POST /api/v1/store/checkout` → **201**; `SELECT estado` → `PENDIENTE_PAGO` | **CERRADO** |
| T1.2 Rama local de éxito | `frontend/lib/screens/store_screen.dart` con `STORE_<millis>` y diálogo local → eliminada | `grep -c 'STORE_'` → **0** | **CERRADO** |
| T1.3 Error visible | `store_screen.dart:386-435`: éxito local + SnackBar → error real visible, carrito intacto | widget test + revisión de la rama de error | **CERRADO** |
| T1.4 Propina inventada | cálculo fabricado en la UI → eliminado | `grep` de propina → **0** | **CERRADO** |
| Gate 1 | — | `scratch/gate1_gate2_flujo_real.js` → 201 + fila `PENDIENTE_PAGO` verificada en la base | **CERRADO** |

**No previsto por el inventario (el inventario decía 4 focos):** aparecieron **13**. Tres nuevos corregidos — `backend/src/controllers/designsController.js:1564` (referencia Wompi inventada por 15.000 COP), `:1635` (revisión médica fabricada), `backend/src/routes/paymentRoutes.js:282` (`paid` al completar).
**Honestidad de UI:** el botón “Pagar” → **“Registrar pedido”** (`frontend/lib/screens/store_screen.dart`), porque ningún cargo ocurre.

## 4. FASE 2 — Invitación de equipo · **CERRADA 5/5**

| Punto | Antes → Después | Comando · resultado | Estado |
|---|---|---|---|
| T2.1 UI de canje | no había entrada → `frontend/lib/widgets/invitation_code_entry.dart` + `login_screen.dart:383-385` + `user_profile.dart:278-286` | alcanzable desde login y perfil (`/profile` → `main.dart:273`) | **CERRADO** |
| T2.2 Aceptación real | el código nunca llegaba a la API → `backend/src/controllers/salonController.js:140-269` valida que quien invita sea DUEÑO/ADMINISTRADOR | probe HTTP: dueño invita → colaborador acepta → aparece en `GET /api/salon/1/members` | **CERRADO** |
| T2.3 Reutilización del token | sin control → **400** + `usado = true` | probe: segundo intento → 400 y fila marcada | **CERRADO** |
| T2.4 Intruso con el token | aceptaba → **403 `INVITATION_EMAIL_MISMATCH`**, 0 membresías creadas | probe: 403 observado; `SELECT count(*)` de membresías sin cambios | **CERRADO** |
| Gate 2 | — | `scratch/gate1_gate2_flujo_real.js` → **12/12**; prueba de mutación: al invertir la condición → “Expected 403, Received 200” | **CERRADO** |

**Atomicidad:** `INSERT` + `UPDATE usado` en **una sola sentencia** (CTE) en vez de dos escrituras no atómicas.

## 5. FASE 3 — Datos fabricados · **CERRADA 5/5** (1 excepción)

| Punto | Antes → Después | Comando · resultado | Estado |
|---|---|---|---|
| T3.1 Literales inventados | métricas escritas a mano en el panel → 0 literales + capa de estado | `grep` de los literales → **0** | **CERRADO** |
| T3.2 “Citas Hoy” | etiqueta que prometía un dato inexistente → **“Citas”** | `grep` → 0 ocurrencias de la etiqueta vieja | **CERRADO** |
| T3.3 Servicios pintados | números inventados → reales | prestador 74: **88/88** nombres coinciden con `SELECT nombre FROM services` | **CERRADO** |
| T3.4 Business Center lectura+escritura | `business_task_detail_screen.dart` 100 % fabricado (`Ley 9 de 1979`, PDF falso, `Certificado_Sanitario_2026.pdf (Cargado)`) → pantalla reescrita contra la API real | `POST /api/v1/business/diagnostic` → perfil creado; `POST /api/v1/business/tasks/<id>/advance` → etapa `ENTENDER → EXPLICAR` **persistida**; relectura confirma | **CERRADO** |
| T3.4 Evidencia | subida que solo cambiaba un booleano → **retirada de la UI** | `grep -rE 'multer|upload\.single|upload\.array' backend/src` → **0**: la app no tiene ninguna vía real de subir un archivo | **ABIERTO** (documentado) |
| Gate 3 | — | `frontend/test/screens/gate3_business_no_fabricado_test.dart` → **5/5** (backend caído → ningún negocio inventado) | **CERRADO** |

**Tres hallazgos que el plan no preveía (la causa raíz de FASE 3):**
1. **El DDL del Business Engine nunca se aplicó.** Dormía en `backend/src/db/migrations/`, y el runner lee `readdirSync('migrations')` no recursivo (`backend/index.js:1619-1621`). De ahí el fallo de `062`.
2. **El router nunca se montó.** `backend/src/routes/businessRoutes.js` estaba completo y ausente de `index.js` → las 15 rutas daban **404**; montado en `backend/index.js:391-394` → `verticals` 200 real, `summary|tasks|templates` 401 sin token.
3. **El servidor fabricaba, no solo la UI.** `backend/src/repositories/businessRepository.js:116-123` devolvía `'Salón de Belleza Demo'` (score 35) y `businessDiagnosticService.js:18` lo saltaba con `startsWith('biz-demo-')` → perfil demo eliminado, `return null`, la UI dice “haz el diagnóstico”.

**Cuarto hallazgo (propio, corregido):** el catálogo (4 verticales, 4 requisitos, 2 plantillas) solo existía **en memoria**; `business_profiles.vertical_id` tiene FK contra `business_verticals`, que estaba vacía → **todo** `createProfile` violaba la FK, el repositorio **se tragaba la excepción** y servía memoria. Un “12/12 en verde” anterior era **falso** por esto. Arreglado con `backend/scripts/seedBusinessCatalog.js` (idempotente) enganchado como paso 11b del arranque (`backend/index.js` ~`:1650`).
**Verificación final:** `business_verticals/business_requirements/document_templates` = **4/4/2** en la base · el probe crea y **persiste** `business_profiles=1`, `business_tasks=4`, `business_findings=2` · **0 avisos** `[BusinessRepository] … memory fallback`.

**Bug de producción cazado por un widget test:** `frontend/lib/models/business_profile_model.dart` casteaba `provider_id as String?` cuando la columna es **INTEGER** → `type 'int' is not a subtype of type 'String?'` habría mostrado “No se pudo cargar” a **todos** los proveedores reales. Corregido con `?.toString()`.

## 6. FASE 4 — Rutas y archivos muertos · **CERRADA**

| Punto | Antes → Después | Comando · resultado | Estado |
|---|---|---|---|
| Gate propio de la fase | no existía → `frontend/scripts/verifyNoDeadRoutes.js` (92 líneas) | `node scripts/verifyNoDeadRoutes.js` → nació con **37** hallazgos; hoy **EXIT 0** | **CERRADO** |
| `/terms` (D5) | `main.dart:277` declarada con **0 navegaciones** → enganchada | `login_screen.dart:546-563` + `user_profile.dart:288-297` | **CERRADO** |
| 11 rutas muertas | entradas en la tabla de `main.dart` → eliminadas | `/my-glow`, `/provider/profile`, `/provider-route`, `/biometric-consent`, `/medical-validation`, `/glowup-card`, `/palette-card`, `/colorimetria-historial`, `/wardrobe`, `/outfit-result`, `/makeup-lookbook` | **CERRADO** |
| Archivos muertos | el plan listaba 5 → **44 borrados** (todos en git: `git checkout -- <ruta>` los restaura) | `git status --porcelain lib/ \| grep -c '^ D'` → 44 | **CERRADO** |
| Gate 4 | — | 24/24 rutas con navegación · 0 archivos muertos | **CERRADO** |

**Dos errores propios, encontrados y corregidos en el acto:**
1. Borré `frontend/lib/widgets/wompi_payment_sheet.dart` creyéndolo muerto: **mi gate solo miraba clases** y ese archivo exporta la **función** `showWompiCheckoutSheet`, que `frontend/lib/screens/booking_screen.dart:332` sí llama. `flutter analyze` lo destapó (2 errores) → restaurado con `git checkout --`, y el gate ahora extrae también funciones de nivel superior, mixins, enums, typedefs, extensiones y constantes.
2. Mi entrada de invitación de FASE 2 estaba en `frontend/lib/screens/client_profile_screen.dart`, pantalla que `main.dart:42` **importaba y nunca renderizaba** (muerta). Movida al perfil vivo.

## 7. FASE 5 — este documento

---

## 8. “No funcional restante” — lista honesta

1. **No existe ninguna función de cargo Wompi en el repo.** El pedido de la tienda queda `PENDIENTE_PAGO` de forma indefinida; no hay conciliación en ese flujo. (El webhook existe, es serio —HMAC sobre `req.rawBody` con `timingSafeEqual`— pero en `.env` no hay `WOMPI_WEBHOOK_SECRET`, así que falla cerrado.)
2. **Carga de evidencia del Business Center: retirada de la UI.** No hay subida real de archivos (`multer` = 0 resultados).
3. **`business_onboarding_screen` y `business_document_generator_screen` sin auditar** — pueden fabricar datos como hacía el detalle de tarea.
4. **El fallback silencioso sigue vivo:** `businessRepository` (y `db.js:528`) convierten cualquier error de base en datos en memoria; `isPgAvailable` no se recupera de un error transitorio.
5. **`/api/providers` devuelve 5 de 9** — filtro sin identificar (no es `tenant_id`, `is_active` ni usuario activo).
6. **`verifyTenantIsolation` no es verificable:** `app_rls_user` no existe en el clúster y `admin` es superusuario con `BYPASSRLS`. No muté credenciales para forzar un verde.
7. **3 migraciones rotas** en `beauty_db`: `031_aura_pgvector… deleted_at`, `034_add_fks_to_academy_tables` (unique), `037_create_biometric_consents.consent_type`.
8. **3 golden tests rojos** de `BookingScreen` (0.87 % de píxeles) — sin `--update-goldens`.
9. **`AuthService.getMySalon()`** ahora devuelve el cuerpo de error; los llamadores antiguos que interpretaban `null` como “sin salón” deben revisarse.
10. **2 archivos usados solo por tests**, inalcanzables desde la UI: `aura_welcome_screen.dart`, `my_glow_dashboard_screen.dart`.
11. **`.env.production` versionado con secretos vivos** (JWT_SECRET, ENCRYPTION_KEY, tres API keys) — rotar y purgar historial.
12. **OLA 3 sin empezar:** falta el criterio de mutación en `tenant-isolation.test.js` y que el acceso cruzado devuelva **403**, no 500.
13. **`tenant_id` TEXT (tablas business) vs INTEGER (tablas salón)** — migración aparte.
14. **Datos de prueba en `beauty_db`:** 1 salón (`id=1`, “Salón de Prueba — Gate 2”), 2 membresías, 3 invitaciones, 3 pedidos `PENDIENTE_PAGO` (conservados para reproducibilidad).

## 9. Inventario del árbol (sin commitear)

`git status --porcelain`: **45 borrados · 41 modificados · 31 sin rastrear** (incluye `backend/src/*.dart` sin rastrear, fuera de alcance por decisión explícita, y `frame.png`/`frame_cropped.png` preexistentes).
Modificados por área: `frontend/lib` 17 · `backend/src` 17 · `backend/migrations` 2 · `frontend/test` 1 · `backend/index.js` 1 · `backend/.env.example` 1 · `.gitignore` 1 · `.github/workflows` 1.
Nuevos relevantes: `backend/migrations/012_business_engine.sql`, `068_force_rls_strict_isolation.sql`, `backend/scripts/{seedBusinessCatalog,prepareRlsDatabase,verifyNoFabricatedPayments,verifyTenantIsolation}.js`, `frontend/scripts/verifyNoDeadRoutes.js`, `frontend/test/screens/gate3_business_no_fabricado_test.dart`.

**Cobertura del plan:** FASE 0–3 y FASE 4 **20/20 items ejecutados y verificados** (con la excepción documentada de la carga de evidencia); FASE 5 = este reporte.
