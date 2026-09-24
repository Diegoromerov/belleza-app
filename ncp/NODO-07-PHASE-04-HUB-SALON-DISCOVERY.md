# NODO-07 — FASE 4 — HUB SALÓN DISCOVERY
## Operational Cockpit Contract & Physical Architecture Discovery

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto  
NODE IDENTIFIER: NODO-07  
PHASE: FASE 4 — Hub Salón (Contract & Physical Discovery)  
DOCUMENT VERSION: v1.0.0  
CLASSIFICATION: FORMAL DISCOVERY & PHYSICAL SPECIFICATION — ZERO CODE IMPLEMENTED  
BASELINE CONTRACT: ncp/NODO-07-SAAS-SCREEN-FLOW-CONTRACT-v1.0.md (CLOSED / IMMUTABLE)  
PHYSICAL ARCHITECTURE BASE: ncp/NODO-07-PHYSICAL-ARCHITECTURE-v1.0.md (APPROVED)  
INFRASTRUCTURE BASE: NODO-07 FASE 1 (CLOSED / IMMUTABLE)  
AVAILABLE CONTEXT: NODO-07 FASE 2 & FASE 3 (CLOSED / IMMUTABLE)  
STATUS: DISCOVERY COMPLETE / AWAITING DIRECTOR REVIEW & DECISION 🟡  
================================================================================

---

## 1. EXECUTIVE SUMMARY

El presente documento formaliza el **Discovery Contractual y Físico** para el **Hub Salón** (`HubSalonScreen`), el cockpit operacional de la sede física activa en GlowApp SaaS.

### Conclusiones Principales:
1. **Endpoints Backend Verificados y Cerrados:** El backend dispone de dos endpoints operativos en [`backend/src/routes/hubSalonRoutes.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/routes/hubSalonRoutes.js):
   - `GET /api/v1/saas/hub/summary`: Resumen de establecimiento, organización, rol del usuario activo y conteo de staff.
   - `GET /api/v1/saas/hub/staff`: Listado detallado de miembros del equipo activos con roles y correos.
2. **Dependencia Transaccional de Active Context:** Ambos endpoints están estrictamente protegidos por `authMiddleware` y `activeContextMiddleware`. Requieren el header `x-active-membership-id: <UUID>` y token Bearer.
3. **Consumo Transparente vía `ApiService`:** Gracias a la infraestructura inmutable de la Fase 1, `ApiService` inyecta automáticamente el header sin necesidad de lógica manual o parámetros adicionales.
4. **Hub $
eq$ ProviderDashboard (Aislamiento B2C):** Se ratifica que `ProviderDashboardScreen` (3,053 líneas) es una consola domiciliaria B2C. `HubSalonScreen` es un cockpit SaaS multi-tenant completamente desacoplado.
5. **Composición de N02..N06:** El Hub Salón actúa como la superficie central de navegación hacia las capacidades especializadas ya cerradas en backend (NODO-02 Ofertas, NODO-03A Horarios, NODO-04 Materialización, NODO-05 Disponibilidad, NODO-06 Agenda).

---

## 2. EXISTING APPROVED ARCHITECTURE

De acuerdo con los contratos cerrados (`NODO-07 Contract v1.0`, `Fase 1`, `Fase 2` y `Fase 3`):

```
+───────────────────────────────────────────────────────────────────────────────+
|                             FLUJO ARQUITECTÓNICO                              |
+───────────────────────────────────────────────────────────────────────────────+

                 AvailableContextSelectorScreen (Fase 3)
                                   │
                                   ▼ (Selección Explícita DEC-N07-AC-001)
                 ActiveContextHolder.setActiveMembershipId(id)  [RAM]
                                   │
                                   ▼
                            /saas/hub (Ruta)
                                   │
                                   ▼
                             HubSalonScreen
                                   │
                  ┌────────────────┴────────────────┐
                  ▼                                 ▼
    GET /api/v1/saas/hub/summary      GET /api/v1/saas/hub/staff
  (Header x-active-membership-id)   (Header x-active-membership-id)
                  │                                 │
                  └────────────────┬────────────────┘
                                   ▼
                        [COCKPIT OPERACIONAL]
            ├── Header: Sede Física + Organización + Rol
            ├── Conmutador de Sede (Vuelve a Available Context)
            ├── Métricas Operativas y Conteo de Personal
            └── Accesos a Módulos Especializados:
                ├── Agenda & Citas (NODO-06)
                ├── Catálogo de Servicios & Asignaciones (NODO-02)
                ├── Horarios de Personal (NODO-03A)
                └── Estado de Sincronización Marketplace (NODO-04)
```

---

## 3. BACKEND SUMMARY ENDPOINT FORENSIC

Inspección de [`backend/src/routes/hubSalonRoutes.js:14`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/routes/hubSalonRoutes.js) y [`backend/src/services/hubSalonService.js:17-110`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/hubSalonService.js):

| Atributo Forense | Evidencia Real en Backend | Detalle Técnico |
| :--- | :--- | :--- |
| **Ruta Exacta** | `hubSalonRoutes.js:14` montado en `index.js:271` | `GET /api/v1/saas/hub/summary` |
| **Método HTTP** | `GET` | Lectura de resumen operacional. |
| **Middleware de Seguridad**| `authMiddleware, activeContextMiddleware` | Exige JWT Bearer válido + `x-active-membership-id`. |
| **Resolución SQL** | `hubSalonService.js:30-74` | Ejecuta `set_config('app.tenant_id', tenantId, true)` y consulta `establishments e INNER JOIN organizations o` filtrando por `e.id = establishmentId AND e.tenant_id = tenantId`. |
| **Manejo de Errores** | `hubSalonController.js:33-53` | 400: `ACTIVE_CONTEXT_NOT_INITIALIZED`, 404: `ESTABLISHMENT_NOT_FOUND`, 500: `INTERNAL_SERVER_ERROR`. |

### Payload Exacto JSON (HTTP 200 OK):
```json
{
  "status": "success",
  "data": {
    "summary": {
      "establishment": {
        "id": "c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f",
        "name": "Sede Chicó Norte",
        "slug": "sede-chico-norte",
        "phone": "3001234567",
        "address": "Calle 93 # 11-20",
        "city": "Bogotá",
        "is_active": true,
        "operating_hours": {}
      },
      "organization": {
        "id": "b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e",
        "legal_name": "Glow Hair S.A.S."
      },
      "active_user_context": {
        "membership_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "role": "PROFESIONAL",
        "relation_type": "EMPLOYEE",
        "status": "ACTIVE"
      },
      "staff_summary": {
        "active_members_count": 3
      }
    }
  }
}
```

---

## 4. BACKEND STAFF ENDPOINT FORENSIC

Inspección de [`backend/src/routes/hubSalonRoutes.js:17`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/routes/hubSalonRoutes.js) y [`backend/src/services/hubSalonService.js:119-179`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/hubSalonService.js):

| Atributo Forense | Evidencia Real en Backend | Detalle Técnico |
| :--- | :--- | :--- |
| **Ruta Exacta** | `hubSalonRoutes.js:17` montado en `index.js:271` | `GET /api/v1/saas/hub/staff` |
| **Método HTTP** | `GET` | Consulta del equipo activo de la sede. |
| **Middleware** | `authMiddleware, activeContextMiddleware` | Exige JWT Bearer + `x-active-membership-id`. |
| **Consulta SQL** | `hubSalonService.js:136-152` | `SELECT m.id, m.user_id, u.nombre, u.email, m.role, m.relation_type, m.status, m.joined_at FROM memberships m INNER JOIN usuarios u ON u.id = m.user_id WHERE m.establishment_id = $1 AND m.tenant_id = $2 AND m.status = 'ACTIVE' ORDER BY m.joined_at ASC;` |

### Payload Exacto JSON (HTTP 200 OK):
```json
{
  "status": "success",
  "data": {
    "establishment_id": "c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f",
    "staff_count": 2,
    "members": [
      {
        "membership_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "user_id": 101,
        "user_name": "Laura Directora",
        "user_email": "laura@glowhair.com",
        "role": "OWNER",
        "relation_type": "OWNER",
        "status": "ACTIVE",
        "joined_at": "2026-08-15T08:00:00.000Z"
      },
      {
        "membership_id": "b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e",
        "user_id": 102,
        "user_name": "Carlos Estilista",
        "user_email": "carlos@glowhair.com",
        "role": "PROFESIONAL",
        "relation_type": "EMPLOYEE",
        "status": "ACTIVE",
        "joined_at": "2026-09-01T09:30:00.000Z"
      }
    ]
  }
}
```

---

## 5. ACTIVE CONTEXT BOUNDARY

1. **Consumo Estricto:** El Hub Salón solo opera cuando existe un `ActiveContextHolder.activeMembershipId` válido en memoria.
2. **Cero Mutación en Carga:** El Hub Salón **jamás modifica o establece el contexto activo al montarse**. Solo lee el que ya fue establecido explícitamente en `AvailableContextSelectorScreen`.
3. **Cero Identificadores Sintéticos:** Prohibido crear variables como `active_salon_id`, `active_tenant_id` o `current_branch_id`.

---

## 6. HTTP BOUNDARY (FASE 1 REUSE)

- `ApiService.get('/api/v1/saas/hub/summary')` y `ApiService.get('/api/v1/saas/hub/staff')`.
- La infraestructura de la Fase 1 (`api_service.dart:141-146`) detecta el prefijo `/api/v1/saas/` e inyecta automáticamente `x-active-membership-id: <ActiveContextHolder.activeMembershipId>` junto con `Authorization: Bearer <token>`.
- **Cero duplicación de headers:** Ningún servicio del Hub Salón manipulará cabeceras manualmente.

---

## 7. HUB SUMMARY DATA vs AUTHORITY

| Campo en `summary` | Tipo | Rol Arquitectónico | Restricción de Cliente |
| :--- | :---: | :--- | :--- |
| `establishment.id` | `UUID` | ID de la sede física activa. | Solo lectura / display. |
| `establishment.name` | `String` | Nombre de la sede (ej. "Sede Chicó"). | Display en AppBar / Header. |
| `establishment.address` | `String` | Dirección física de la sede. | Display informativo. |
| `establishment.city` | `String` | Ciudad de operación. | Display informativo. |
| `establishment.is_active` | `bool` | Estado operativo de la sede. | Indicador visual de operatividad. |
| `organization.legal_name`| `String` | Razón social de la empresa. | Display corporativo en cabecera. |
| `active_user_context.role`| `String` | Rol del usuario en esta sede. | Badge informativo del operador. |
| `staff_summary.active_members_count` | `int` | Cantidad total de personal activo. | Métrica de resumen en tarjeta. |

> [!IMPORTANT]
> **DATOS DE PRESENTACIÓN $
eq$ AUTORIDAD:** El cliente Flutter utiliza estos datos exclusivamente para renderizar la interfaz. La autorización transaccional de cada operación posterior emana estrictamente de PostgreSQL RLS en el backend.

---

## 8. HUB STAFF DATA vs AUTHORITY

- `staff.members`: Lista de miembros activos en la sede.
- Utilizado para visualizar al equipo de trabajo y navegar a la gestión de horarios individuales (NODO-03A).
- El frontend **no calcula permisos** a partir de `member.role`.

---

## 9. HUB SCREEN BOUNDARY (`HubSalonScreen`)

La futura pantalla `HubSalonScreen` se estructurará modularmente:
1. **AppBar & Header:**
   - Nombre de la Sede Activa (`establishment.name`) y Organización (`organization.legal_name`).
   - Badge con el Rol del Operador (`active_user_context.role`).
   - Botón de Conmutación de Sede (*Branch Switcher*): Permite regresar a `AvailableContextSelectorScreen` para cambiar de contexto explícitamente.
2. **Resumen de Métricas Operativas:**
   - Tarjeta de Equipo (`staff_summary.active_members_count` miembros).
   - Tarjetas de Acceso a Módulos Operativos (Agenda, Catálogo, Horarios).
3. **Sección de Equipo de Trabajo:**
   - Lista de miembros activos (`GET /staff`) con avatar, nombre, correo y rol.
4. **Accesos Rápidos a Nodos Especializados:**
   - Botón a Agenda y Citas (NODO-06).
   - Botón a Catálogo de Servicios (NODO-02).
   - Botón a Horarios de Personal (NODO-03A).

---

## 10. PROVIDERDASHBOARD ISOLATION (B2C SAFEGUARD)

- `ProviderDashboardScreen` (`frontend/lib/screens/provider_dashboard_screen.dart`, 3,053 líneas):
  - Modelo B2C Marketplace para prestadores independientes y domiciliarios.
  - No usa `x-active-membership-id` ni pertenece al ecosistema multi-tenant de organizaciones/establecimientos físicos.
  - **Permanecerá 100% aislada e intacta.**

---

## 11. N02..N06 INTEGRATION BOUNDARIES

El Hub Salón actúa como lanzador y concentrador de las capacidades SaaS especializadas:

| Nodo Técnico | Endpoint Backend Verificado | Superficie en Hub Salón |
| :--- | :--- | :--- |
| **NODO-06 (Agenda & Citas)** | `/api/v1/saas/hub/appointments/*` | Tarjeta / Tab de Agenda Operativa. |
| **NODO-02 (Catálogo & Asignaciones)**| `/api/v1/saas/hub/services`, `/assignments` | Módulo de Catálogo de Servicios y Asignación de Staff. |
| **NODO-03A (Horarios Semanales)** | `/api/v1/saas/hub/staff/:id/schedule` | Módulo de Horarios y Disponibilidad de Personal. |
| **NODO-04 (Materialización B2C)** | `/api/v1/saas/hub/materializations/services` | Badge de Estado de Sincronización Downstream. |
| **NODO-05 (Availability Pre-Check)** | `/api/v1/saas/hub/availability/check` | Consulta en tiempo real de slots para nuevas citas. |

---

## 12. HUB STATES ARCHITECTURE

1. **`LOADING`:** Consulta concurrente `Future.wait([getSummary(), getStaff()])` mientras muestra Shimmer / Spinner.
2. **`SUCCESS`:** Datos recibidos exitosamente; renderiza el cockpit completo.
3. **`ERROR`:** Fallo de red o error de servidor; muestra banner con botón "Reintentar".
4. **`NO_ACTIVE_CONTEXT`:** Si `ActiveContextHolder.hasActiveContext == false` al montar la pantalla:
   - Cero invención de contexto.
   - Presenta vista de bloqueo ("No hay sede activa seleccionada") con botón "Seleccionar Sede" que transiciona a `AvailableContextSelectorScreen`.

---

## 13. ACTIONS CLASSIFICATION

| Acción en Hub Salón | Tipo | Destino / Efecto Técnico |
| :--- | :---: | :--- |
| **Recargar Resumen y Staff** | `READ` | Re-invoca `getHubSummary()` y `getHubStaff()`. |
| **Conmutar Sede Activa** | `NAVIGATION` | Navega a `AvailableContextSelectorScreen` para selección explícita. |
| **Abrir Agenda de Citas** | `NAVIGATION` | Navega a módulo NODO-06 (`/saas/agenda`). |
| **Abrir Catálogo de Servicios**| `NAVIGATION` | Navega a módulo NODO-02 (`/saas/services`). |
| **Abrir Horarios de Personal** | `NAVIGATION` | Navega a módulo NODO-03A (`/saas/staff-schedules`). |

---

## 14. JOURNEY BOUNDARY (ARCHITECTURAL STOP)

- El Hub Salón se define formalmente como la etapa final de llegada tras la selección de contexto.
- Cero modificaciones a `login_screen.dart`, `register_screen.dart`, `main.dart` o `auth_service.dart`.
- `JOURNEY` permanece en **ARCHITECTURAL STOP**.

---

## 15. B2C BOUNDARY

- `home_screen.dart`, `provider_dashboard_screen.dart` y flujos de reserva cliente B2C no son afectados.

---

## 16. UI REUSE DISCOVERY

- Reutilización de `AppTheme` (`theme/app_theme.dart`) para tipografías, tarjetas y paleta de colores.
- Reutilización de widgets base (`Card`, `ListView`, `AppBar`, `ElevatedButton`).
- Cero creación de nuevos design systems.

---

## 17. PHYSICAL FILE PLAN (PROJECTION FOR FUTURE IMPLEMENTATION)

| Archivo Proyectado | Clasificación | Responsabilidad |
| :--- | :---: | :--- |
| `frontend/lib/models/saas/hub_salon_model.dart` | `NEW` | DTOs inmutables para Summary (`HubSummaryResponse`) y Staff (`HubStaffResponse`). |
| `frontend/lib/services/hub_salon_service.dart` | `NEW` | Servicio que consume `/api/v1/saas/hub/summary` y `/staff`. |
| `frontend/lib/screens/saas/hub_salon_screen.dart` | `NEW` | Cockpit operacional de la sede física activa. |
| `frontend/test/saas_hub_salon_test.dart` | `NEW` | Suite de pruebas unitarias y de widgets para Hub Salón. |
| `frontend/lib/services/active_context_holder.dart` | `PROTECTED / REUSE` | Fase 1 inmutable. |
| `frontend/lib/services/api_service.dart` | `PROTECTED / REUSE` | Fase 1 inmutable. |
| `frontend/lib/models/saas/available_context_model.dart`| `PROTECTED / REUSE` | Fase 3 inmutable. |
| `frontend/lib/screens/saas/available_context_selector_screen.dart` | `PROTECTED / REUSE` | Fase 3 inmutable. |

---

## 18. TEST PLAN (FUTURE IMPLEMENTATION SPECIFICATION)

1. **Test A (Summary DTO Parsing):** Deserialización correcta de `HubSummaryResponse`.
2. **Test B (Staff DTO Parsing):** Deserialización correcta de `HubStaffResponse`.
3. **Test C (Loading State):** Estado inicial de carga mientras se resuelven los endpoints.
4. **Test D (Success State):** Renderizado correcto de sede, organización, rol y lista de staff.
5. **Test E (Error State & Retry):** Manejo de fallo 500 y recarga al pulsar "Reintentar".
6. **Test F (No Active Context Handling):** Comportamiento seguro cuando `ActiveContextHolder` está vacío.
7. **Test G (No Active Context Mutation):** Montar el Hub no muta `ActiveContextHolder`.
8. **Test H (Header Delegation):** Las llamadas a `/api/v1/saas/hub/*` reciben `x-active-membership-id` vía `ApiService`.
9. **Test I (B2C Isolation):** Cero impacto en llamadas o modelos B2C.

---

## 19. RISKS & MITIGATIONS

| Riesgo | Nivel | Mitigación Arquitectónica |
| :--- | :---: | :--- |
| **Intento de auto-restaurar contexto si `activeMembershipId == null`** | Alto | Prohibición expresa. Si no hay contexto activo, se muestra vista de bloqueo que invita a seleccionar sede en `AvailableContextSelectorScreen`. |
| **Mezcla con `ProviderDashboardScreen`** | Alto | Aislamiento total: `HubSalonScreen` es un archivo 100% nuevo e independiente. |
| **Cálculo de permisos en cliente basado en `role`** | Medio | El frontend solo muestra el badge del rol; las autorizaciones de mutación las aplica PostgreSQL RLS. |

---

## 20. FINDINGS

- **FINDING-N07-08 (Dual Endpoint Separation):** La separación de `GET /summary` y `GET /staff` en backend permite que la pantalla cargue el resumen estructural y la lista de personal de forma concurrently optimizada con `Future.wait`.

---

## 21. RECOMMENDATION

1. Aprobar el Discovery y la Especificación Física de Hub Salón aquí documentada.
2. Proceder a la fase de **Definición de Contrato y Arquitectura Física de Hub Salón** antes de cualquier implementación de código.

---

## 22. DIRECTOR DECISION REQUIRED

```
================================================================================
                    DECISIÓN REQUERIDA DEL DIRECTOR
================================================================================
¿Se aprueba el Discovery de Hub Salón y se autoriza proceder con la definición
de Arquitectura Física para la FASE 4?
================================================================================
```
