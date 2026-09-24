# INFORME DE REMEDIACIÓN — Auditoría 360 (A360-2026-09-22)

**Fecha:** 2026-09-22 · **Rama:** `fix/audit-360-remediation` · **Base:** `origin/main` = `d018587d`
**Commits:** `dc8c570c` (núcleo), `451e538b` (C-04 clientes + tipos del panel), `+` beauty-scan 4xx
**Nada escrito en el worktree de Antigravity.** Informe previo de auditoría: `AUDITORIA-360-CONSOLIDADA-2026-09-22.md`

---

## 1. Verificación ejecutada (medida, no reportada por terceros)

| Comprobación | Comando | Resultado |
|---|---|---|
| Suite backend (patrón CI) | `npm test -- --testPathIgnorePatterns="geminiService\|…"` | **359 passed / 37 failed** en 5 suites → línea base idéntica, **0 regresiones** |
| Tests nuevos de remediación | `npx jest src/tests/audit360-remediation.test.js` | **21/21 en verde** |
| Contrato del worker IA | `python ai_worker/tests/test_beauty_scan_contract.py` | **7/7 OK** |
| Escáner de credenciales | `node backend/scripts/verifyNoVersionedSecrets.js` | ✅ limpio, exit 0 |
| Tipos del panel admin | `npx tsc --noEmit` (admin-dashboard) | **exit 0** (antes exit 2, 3 errores) |
| Flutter | `flutter analyze --no-pub lib` | **2 errores / 52 warnings / 533 info** — los 2 errores son preexistentes (`widgets/provider/inventory_alert_dialog.dart:33,77`, archivo no tocado); idéntico tras mis arreglos de WS |
| Sintaxis | `node --check` ×24 · `py_compile` ×5 | OK |

Los 37 fallos restantes son preexistentes: 4 suites `business*.integration` (fixtures: `req.user.id` string vs `user_id` INTEGER, sin crear perfil/membresía) y `sprint4_agents` (espera 8 herramientas de Aura, hay 11).

## 2. Hallazgos cerrados

| ID | Hallazgo | Evidencia del cierre |
|---|---|---|
| C-01 | El runner ejecutaba los rollbacks (el de 035 hacía `DROP COLUMN embedding`) | `backend/migrations/rollback/` + filtro `.down.sql` en `backend/index.js` (versionado). Los `check_*.js`/`run_*.js` están en `.gitignore`: su filtro es local |
| C-02 | Secretos versionados | `.env.production` fuera del índice; clave NVIDIA y logs eliminados; contraseñas reales redactadas; step **bloqueante** en `ci.yml` |
| C-03 | Fail-open a datos fabricados | `db.js`: sin cortocircuito a `handleMemoryQuery`, `isPgAvailable` recuperable, `testConnection` no miente, `ALLOW_MEMORY_FALLBACK`, `getDbStatus()`; `/api/health` ya no escribe |
| C-04 | WebSocket sin auth | **Servidor:** token obligatorio, pertenencia a la reserva verificada, `providerId` desde el token. **Clientes:** `chat_screen.dart:176` y `booking_tracking_screen.dart:67` envían token (registro antes de `join_booking_room`) |
| C-05 | Cobros fabricados | `payBooking`, `disbursePayout`/`crearPayout`, `payMedicalValidation` → 501/rechazo sin `ALLOW_PAYMENT_SIMULATOR`; sheet Flutter sin `APPROVED` inventado; propina removida del flujo |
| C-06 | Password/OTP en logs | `authController`, `paymentRoutes` (+ `EXPOSE_DEV_OTP`), `seed_glowapp_kb` |
| C-07/C-08 | Contrato IA y métricas falsas | Worker: 4 archivos multipart requeridos, métricas reales por imagen (75.0 vs 89.0), 422/400/413 en vez de 200 sintético; proxy `beautyScanRoutes.js` propaga el 4xx |
| C-10 | Nota clínica aleatoria firmada | Eliminada de `designsController` |
| C-11 | Clave biométrica de JWT_SECRET | Fail-closed + `decryptWithLegacyKey()` + `scripts/reencryptBiometricData.js` (dry-run por defecto) |
| C-12 | Caché semántico sin tenant | Identidad en clave y en índice de candidatos (`semanticCache.js`) |
| C-14 | Login admin por email | Rol desde el token + `allowedRoles={['ADMIN']}` |
| A-01 | `req.user.rol` inexistente | `auth.js` |
| A-17 | `/orchestrate` abierto, guard decorativo | auth+admin y guard que acota al repo |
| H-01 | Wrapper de Gradle (532 MB, 22.043 archivos) | Fuera del índice + `.gitignore` |

## 3. Lo que NO está cerrado

1. **Pasarela real (decisión de negocio).** Nadie cobra: GlowShop ya no simula éxito, pero no está cableado a `POST /api/store/checkout` (existe, `productRoutes.js:38`); falta el helper en `ApiService`. Propina: no existe endpoint (verificado). `POST /bookings/:id/pay` sigue siendo simulador interno.
2. **Ventana de BD:** `backend/migrations/manual/069_force_rls_strict_isolation.sql` (FORCE RLS) y `070_reassign_tenant_id_by_owner.sql`. Deliberadamente manuales: `backend/migrations/` se ejecuta en cada arranque y activar FORCE RLS sin contexto de tenant en **todas** las rutas de datos (incluido el pool propio de Sequelize) devuelve 0 filas globalmente. Runbook con conteos previos en `backend/migrations/manual/README.md`.
3. **Rotación de secretos + purga de historial.** Los valores siguen en el historial de git: hay que rotar `JWT_SECRET`, `ENCRYPTION_KEY`, la contraseña de `DATABASE_URL` y la clave NVIDIA. Antes de tocar `JWT_SECRET`: `reencryptBiometricData.js --dry-run`.
4. **Restos de RLS:** `auth.js` con `set_config(…, false)` sobre conexión arbitraria del pool; `tenantContext.js` con un segundo `Pool` sin montar.
5. **Panel admin:** 98 errores de lint pendientes (47 `no-unused-vars`, 47 `no-explicit-any`), `@ts-nocheck` sin quitar en `academia/[id]/page.tsx` (1.425 líneas), `error` de `useBookings` sin consumir en 4 páginas. `next.config.ts` se dejó con `ignoreDuringBuilds: true` **a propósito**: quitarlo hoy rompería `next build`. `eslint.config.mjs` ya usa FlatCompat, así que el lint es ejecutable y esa limpieza es posible.
6. **Flutter residual:** 49 warnings de código muerto (`unused_import/field/element`) — verificado que **ninguna** declaración está en las líneas agregadas por la remediación (son preexistentes); 2 errores de `inventory_alert_dialog.dart` (llama a `ApiService.fetchConsignmentInventory`/`consumeInventoryItem`, que no existen).
7. **`migrationRunner.js` es código muerto** (nadie lo requiere): el filtro efectivo de C-01 es `index.js`.
8. **Trabajo de otro agente en el mismo árbol, NO commiteado:** academia (`academyService.js`, `academyAdminRoutes.js`, `academyRoutes.js`, `xpLog*`, `expressAsync.js`, borrado de `learningPath*`, migraciones 066/067) y los `.pkl` de la raíz. También aparecen modificaciones nuevas en `admin-dashboard/src/**` posteriores a mi commit. No las borré ni me las atribuyo.
9. **`backend/src/startup/app.js:28` requiere `routes/userRoutes` que no existe** (el endpoint real está en `index.js:1037/1138`) — ese árbol de arranque es código muerto con un require roto.

## 4. Próximos pasos

1. `chat_screen`/`booking_tracking` en dispositivo (no hay test widget para el WS).
2. `npm ci && npm run build` en admin-dashboard para cerrar el `next build` con el árbol actual.
3. Limpieza de lint del panel → luego quitar `ignoreDuringBuilds`.
4. Ventana para 069/070 con medición antes/después.
5. Rotación de secretos y `reencryptBiometricData.js --dry-run`.
6. Integrar pasarela real (o dejar GlowShop deshabilitado de forma explícita en producto).
