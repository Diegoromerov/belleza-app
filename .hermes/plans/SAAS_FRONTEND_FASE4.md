# FASE 4 — Admin Dashboard SuperAdmin (frontend)

**Autorización:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — F7.006-FASE7-SAAS-FRONTEND-FASE4`
(concedida junto con RAG-FASE2; RAG-FASE2 ya cerrada y desplegada en `41c552f2`).

## Hallazgo que define el alcance

El backend **ya está completo**. `backend/src/routes/superAdminRoutes.js`, montado en
`/api/superadmin`, expone todo lo que las pantallas necesitan:

| Endpoint | Uso en la pantalla |
|---|---|
| `GET /dashboard` | KPIs de portada |
| `GET /tenants` · `GET /tenants/:id` | listado y detalle de tenants |
| `PATCH /tenants/:id/plan` | cambio de plan |
| `POST /tenants/:id/suspend` | suspender/reactivar |
| `GET /revenue` | facturación agregada |
| `GET /usage` | consumo por tenant |
| `GET /webhooks` | salud de integraciones |
| `GET /health` | estado de la plataforma |
| `GET /audit-logs` | trazabilidad de acciones |

En el frontend **no existe nada**: `find frontend/lib -iname "*admin*"` devuelve vacío.
Por tanto Fase 4 es **solo Flutter**, sin tocar backend ni migraciones.

## Trabajo

1. `frontend/lib/models/superadmin/superadmin_models.dart`
   - `TenantSummary`, `TenantDetail`, `RevenuePoint`, `UsageRow`, `AuditEntry`, `PlatformHealth`.
   - Parseo tolerante snake/camel, como en `saas_models.dart`.

2. `frontend/lib/services/superadmin_api_service.dart`
   - Cliente contra `/api/superadmin/*` reutilizando el patrón de `saas_api_service.dart`
     (token, manejo de 401/403, errores tipados).

3. `frontend/lib/providers/superadmin_providers.dart`
   - `TenantsNotifier` (lista + paginación + búsqueda), `RevenueNotifier`, `UsageNotifier`,
     `AuditNotifier`. Mutaciones (`changePlan`, `suspendTenant`) recargan la lista.

4. Pantallas en `frontend/lib/screens/superadmin/`
   - `tenants_screen.dart` — tabla con plan, estado, MRR, último acceso; acciones de plan y suspensión.
   - `superadmin_billing_screen.dart` — ingresos, distribución por plan, evolución.
   - `superadmin_usage_screen.dart` — consumo por tenant, tenants cerca del límite.
   - `superadmin_plans_screen.dart` — comparativa de planes y tenants por plan.

5. Acceso
   - Ruta protegida por rol `SUPER_ADMIN`; si el usuario no lo tiene, la entrada no aparece
     (no basta con ocultar el botón: el guard debe estar en el router).

6. Pruebas
   - `frontend/test/superadmin/superadmin_screens_smoke_test.dart` al estilo del de SaaS:
     providers falsos, viewport 1200x3200, `takeException() == null`.
   - `flutter analyze` sin errores nuevos (hoy: 0 errores, 96 issues preexistentes).

## Reglas que se mantienen

- **Sin mocks** en pantallas: todo dato viene de la API; errores y vacíos se muestran como tales.
- Moneda en COP.
- Nada de `notifyListeners()` dentro de `build`.

## Verificación de cierre

1. `flutter analyze` → 0 errores.
2. `flutter build web --release` → éxito.
3. Widget tests → verde (`takeException() == null` en las 4 pantallas).
4. `/api/superadmin/tenants` responde **401** sin token (no 500) en producción.
5. Login real como SuperAdmin y captura de cada pantalla con datos reales.

## Riesgo conocido

`superAdminRoutes.js` hace JOIN con `users` en algunos endpoints; en Fase 3 se detectó que
`memberships.user_id` referencia `usuarios`. Hay que comprobar en runtime que el listado de
tenants no salga vacío por ese desajuste antes de dar la fase por buena.
