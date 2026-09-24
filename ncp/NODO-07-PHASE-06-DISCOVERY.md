# NODO-07 — FASE 6 — DESCUBRIMIENTO DEL SIGUIENTE LÍMITE ARQUITECTÓNICO SAAS

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto GlowApp SaaS  
NODE IDENTIFIER: NODO-07 — FASE 6  
DOCUMENT CLASSIFICATION: ARCHITECTURAL DISCOVERY REPORT (FORENSIC & READ-ONLY)  
DATE: 2026-09-12  
STATUS: DISCOVERY COMPLETE / ARCHITECTURAL STOP / AWAITING DIRECTOR DECISION 🛑  
================================================================================

---

## 1. ESTADO ACTUAL Y PREMISAS DE AUTORIDAD

Las Fases 1 a 5 de NODO-07 se encuentran **CERRADAS, AUDITADAS E INMUTABLES**:

1. **Fase 1 (Infraestructura Cliente & Active Context):** `ActiveContextHolder` + interceptor contextual `ApiService` (`x-active-membership-id`). *(11/11 tests PASS)*.
2. **Fase 2 (Available Context Discovery):** Definición de contratos DTO y reglas de multiplicidad contextual (`ONE_CONTEXT` vs `MULTIPLE_CONTEXTS`).
3. **Fase 3 (Available Context Implementation):** `AvailableContextModel`, `SaaSContextService`, `AvailableContextSelectorScreen`. *(10/10 tests PASS)*.
4. **Fase 4 (Hub Salón Cockpit):** `HubSalonModel`, `HubSalonService`, `HubSalonScreen`. *(12/12 tests PASS)*.
5. **Fase 5 (Navegación SaaS Canónica):** Registro de la ruta `/saas/hub` en `frontend/lib/main.dart` y suite `saas_navigation_test.dart`. *(8/8 tests PASS)*.

**Total Regresión SaaS Frontend:** **41 / 41 Tests PASS (100%)**.

### Circuito Físico Operativo Actual:
```
AvailableContextSelectorScreen
        ↓ (selección explícita de tenant/rol)
ActiveContextHolder.setActiveContext(...)
        ↓ (navegación declarativa)
Navigator.of(context).pushReplacementNamed('/saas/hub')
        ↓
HubSalonScreen (Consume ActiveContextHolder + HubSalonService)
```

---

## 2. EVIDENCIA FORENSE FRONTEND

### 2.1. Inventario de Componentes Físicos Existentes (`frontend/lib/`)
* **Modelos (`frontend/lib/models/saas/`):**
  * `available_context_model.dart`: DTOs `AvailableContextResponse`, `AvailableContextItem`, `ContextOrganization`, `ContextEstablishment`, `ContextMembership`.
  * `hub_salon_model.dart`: DTOs `HubSalonSummary`, `HubSalonStaffMember`, `HubSalonCockpitData`.
* **Servicios (`frontend/lib/services/`):**
  * `active_context_holder.dart`: Singleton reactivo (`ChangeNotifier`) portador exclusivo del `membership_id` y metadatos de sesión activa.
  * `saas_context_service.dart`: Cliente HTTP para `GET /api/v1/saas/context/available`.
  * `hub_salon_service.dart`: Cliente HTTP para `GET /api/v1/saas/hub/summary` y `GET /api/v1/saas/hub/staff`.
  * `api_service.dart`: Inyector del header `x-active-membership-id` hacia `/api/v1/saas/*`.
* **Pantallas (`frontend/lib/screens/saas/`):**
  * `available_context_selector_screen.dart`: Selector explícito de sede.
  * `hub_salon_screen.dart`: Cockpit principal de sede (`/saas/hub`).

### 2.2. Rutas Nombradas Existentes (`frontend/lib/main.dart`)
* **SaaS:**
  * `'/saas/hub'`: Mapeado a `HubSalonScreen()`.
* **Regla de Oro Verificada:**
  * `'/saas/context/available'`: **NO REGISTRADA** (Regla *No Route Without Consumer*; navegación modal directa vía `MaterialPageRoute`).
  * `initialRoute: '/'` (Permanece en Splash B2C sin introspección SaaS).

### 2.3. Código B2C Aislado (No Confundir con SaaS)
* `frontend/lib/screens/provider_dashboard_screen.dart`: Dashboard de prestadores independientes B2C (domiciliarios). No es un Hub Salón ni interactúa con `ActiveContextHolder`.
* `frontend/lib/screens/booking_screen.dart`, `booking_tracking_screen.dart`, `client_bookings_screen.dart`: Módulos de marketplace B2C para clientes finales.
* `frontend/lib/screens/auth/register_screen.dart`: Pantalla de registro con toggle de roles heredado (B2C) bajo **ARCHITECTURAL STOP**.

---

## 3. EVIDENCIA FORENSE BACKEND

El backend dispone de una arquitectura modularizada con contratos y migraciones cerradas e inmutables:

| Nodo Técnico | Migración DB | Tablas Principales | Servicios / Controladores | Endpoints Clave |
| :--- | :---: | :--- | :--- | :--- |
| **Foundation / Context** | 065, 066 | `tenants`, `organizations`, `establishments`, `memberships`, `usuarios` | `contextResolutionService`, `activeContextService` | `GET /api/v1/saas/context/available`<br>`GET /api/v1/saas/context/active` |
| **Hub Salón** | 065 | Consulta agregada sobre `establishments`, `memberships`, `usuarios` | `hubSalonService`, `hubSalonController` | `GET /api/v1/saas/hub/summary`<br>`GET /api/v1/saas/hub/staff` |
| **Crear Desde Cero** | In-Memory | Transitorio (Compila `Context Package` de 16 atributos) | `crearDesdeCeroService`, `crearDesdeCeroController` | `POST /api/v1/saas/hub/onboarding/bootstrap` |
| **NODO-01** | In-Memory | Transitorio (Handover Ingestion in-memory) | `nodo01Service`, `nodo01Controller` | `POST /api/v1/saas/hub/onboarding/ingest` *(definido en nodo01Routes)* |
| **NODO-02** | 067, 068 | `service_offers`, `service_assignments` | `serviceOfferService`, `serviceAssignmentService` | `POST/GET/PUT /api/v1/saas/hub/services`<br>`POST/GET/DELETE /api/v1/saas/hub/assignments` |
| **NODO-03A** | 069 | `staff_schedules` (GiST Exclude no solapamiento) | `staffAvailabilityService`, `staffAvailabilityController` | `GET /api/v1/saas/hub/staff/schedules`<br>`GET/PUT/DELETE /api/v1/saas/hub/staff/:id/schedule` |
| **NODO-04** | 070 | `saas_service_materializations` | `nodo04MaterializationService`, `nodo04MaterializationController` | `POST/GET /api/v1/saas/hub/materializations/services` |
| **NODO-05** | Read-Only | Proyección determinista (Pre-Check transitorio) | `nodo05AvailabilityService`, `nodo05AvailabilityController` | `GET /api/v1/saas/hub/availability/projection` |
| **NODO-06** | 071 | `saas_appointments` (GiST Exclude intervalos de staff) | `nodo06AppointmentsService`, `nodo06AppointmentsController` | `POST /api/v1/saas/hub/appointments`<br>`GET /api/v1/saas/hub/appointments/agenda`<br>`PATCH /api/v1/saas/hub/appointments/:id/status` |

---

## 4. MAPA DE COMPONENTES SAAS (FRONTEND VS BACKEND)

```
+-----------------------------------------------------------------------------------------------+
| CAPA ARQUITECTÓNICA SAAS         | BACKEND STATUS       | FRONTEND STATUS                     |
+-----------------------------------------------------------------------------------------------+
| 1. Active Context & Headers      | CLOSED (Mig 065/066) | CLOSED (ActiveContextHolder)        |
| 2. Available Context Selector    | CLOSED (Mig 066)     | CLOSED (AvailableContextSelector)   |
| 3. Hub Salón Cockpit             | CLOSED (Mig 065)     | CLOSED (HubSalonScreen + /saas/hub) |
| 4. Crear Desde Cero (Onboarding) | CLOSED (In-Memory)   | ZERO FRONTEND (Sin UI/Service)      |
| 5. NODO-01 HBC Ingestion         | CLOSED (In-Memory)   | ZERO FRONTEND (Sin UI/Service)      |
| 6. NODO-02 Catálogo & Asignación | CLOSED (Mig 067/068) | ZERO FRONTEND (Sin UI/Service)      |
| 7. NODO-03A Horarios de Staff    | CLOSED (Mig 069)     | ZERO FRONTEND (Sin UI/Service)      |
| 8. NODO-04 B2C Materialization   | CLOSED (Mig 070)     | ZERO FRONTEND (Sin UI/Service)      |
| 9. NODO-05 Pre-Check Slots       | CLOSED (Read-Only)   | ZERO FRONTEND (Sin UI/Service)      |
| 10. NODO-06 Citas & Agenda       | CLOSED (Mig 071)     | ZERO FRONTEND (Sin UI/Service)      |
| 11. Journey Resolution           | ARCHITECTURAL STOP   | ARCHITECTURAL STOP                  |
+-----------------------------------------------------------------------------------------------+
```

---

## 5. MAPA DE RUTAS (CLIENTE)

| Ruta Cliente | Componente Mapeado | Estado | Consumidor / Origen |
| :--- | :--- | :---: | :--- |
| `/` | `SplashScreen` | CLOSED (B2C) | Arranque nativo |
| `/home` | `HomeScreen` | CLOSED (B2C) | Marketplace B2C |
| `/provider-dashboard` | `ProviderDashboardScreen`| CLOSED (B2C) | Prestador B2C |
| `/saas/hub` | `HubSalonScreen` | **CLOSED (SaaS)** | AvailableContextSelectorScreen |
| `/saas/context/available`| `AvailableContextSelector` | **MODAL DIRECTO** | HubSalonScreen (Branch Switcher) |
| `/saas/crear-desde-cero` | `CrearDesdeCeroWizardScreen`| **PROPOSAL (No impl)**| HubSalonScreen (Quick Action) |
| `/saas/services` | `ServiceOffersScreen` | **PROPOSAL (No impl)**| HubSalonScreen (Catálogo) |
| `/saas/staff/schedules` | `StaffSchedulesScreen`| **PROPOSAL (No impl)**| HubSalonScreen (Horarios) |
| `/saas/agenda` | `SaaSAgendaScreen` | **PROPOSAL (No impl)**| HubSalonScreen (Agenda Citas) |

---

## 6. MAPA DE ENDPOINTS (BACKEND)

| Endpoint | Método | Auth / Middleware | Nodo Técnico | Propósito |
| :--- | :---: | :--- | :---: | :--- |
| `/api/v1/saas/context/available` | GET | `authMiddleware` | FASE 2/3 | Lista sedes y membresías accesibles |
| `/api/v1/saas/context/active` | GET | `authMiddleware` + `activeContextMiddleware` | FASE 1 | Valida contexto activo |
| `/api/v1/saas/hub/summary` | GET | `authMiddleware` + `activeContextMiddleware` | FASE 4 | Métricas y metadatos de sede |
| `/api/v1/saas/hub/staff` | GET | `authMiddleware` + `activeContextMiddleware` | FASE 4 | Directorio de personal de sede |
| `/api/v1/saas/hub/onboarding/bootstrap` | POST | `authMiddleware` + `activeContextMiddleware` | CDC | Handover Package transitorio |
| `/api/v1/saas/hub/staff/schedules` | GET | `authMiddleware` + `activeContextMiddleware` | NODO-03A | Horarios semanales de personal |
| `/api/v1/saas/hub/staff/:id/schedule` | GET/PUT/DEL | `authMiddleware` + `activeContextMiddleware` | NODO-03A | Configuración horario de 1 staff |
| `/api/v1/saas/hub/materializations/services` | POST/GET | `authMiddleware` + `activeContextMiddleware` | NODO-04 | Sincronización downstream B2C |
| `/api/v1/saas/hub/availability/projection` | GET | `authMiddleware` + `activeContextMiddleware` | NODO-05 | Pre-Check de disponibilidad de slots |
| `/api/v1/saas/hub/appointments` | POST | `authMiddleware` + `activeContextMiddleware` | NODO-06 | Creación de cita interna SaaS |
| `/api/v1/saas/hub/appointments/agenda` | GET | `authMiddleware` + `activeContextMiddleware` | NODO-06 | Proyección de agenda operativa |
| `/api/v1/saas/hub/appointments/:id/status` | PATCH | `authMiddleware` + `activeContextMiddleware` | NODO-06 | Transición de estado de cita |

---

## 7. DEPENDENCIAS CERRADAS

1. **Active Context:** Toda llamada subsiguiente a `/api/v1/saas/hub/*` exige de forma mandatoria e inmutable el header `x-active-membership-id: <UUID>`.
2. **Jerarquía Operativa del Salón:**
   $$	ext{Hub Salón} \longrightarrow egin{cases} 	ext{Aprovisionamiento Inicial (Crear Desde Cero)} \ 	ext{Catálogo y Ofertas (NODO-02)} \longrightarrow 	ext{Horarios de Staff (NODO-03A)} \longrightarrow 	ext{Agenda Operativa (NODO-06)} \end{cases}$$
3. **Invariante de Citas (NODO-06):** No es físicamente posible agendar una cita operativa en el frontend si no existen previamente:
   - Una oferta de servicio durable (`service_offer_id` vía NODO-02).
   - Un colaborador asignado al servicio (`membership_id` vía NODO-02/03A).
   - Disponibilidad operativa en el rango horario (NODO-03A / NODO-05).

---

## 8. LÍMITES ARQUITECTÓNICOS ACTUALES

1. **Límite Frontend Actual:** La aplicación se detiene actualmente en `HubSalonScreen` (`/saas/hub`), el cual renderiza el cockpit pasivo de la sede pero carece de botones de navegación interactiva hacia módulos hijos.
2. **Límite de Aprovisionamiento vs Operación:**
   - **Caso Sede Nueva / Sin Configurar:** Requiere el asistente transitorio de **Crear Desde Cero** (`CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`).
   - **Caso Sede Operativa:** Requiere la administración de **Catálogo de Servicios y Asignación de Personal** (NODO-02).
3. **Límite de Autenticación / Journey:** El punto de entrada (`Login`/`Register`) sigue desacoplado y en **ARCHITECTURAL STOP**, por lo que el acceso a SaaS se evalúa en caliente mediante invocación directa a Available Context.

---

## 9. OPCIONES LEGÍTIMAS PARA EL SIGUIENTE PASO

```
+---------------------------------------------------------------------------------------------------+
| OPCIÓN A: CREAR DESDE CERO UI (Asistente de Aprovisionamiento Inicial & Handover)                 |
+---------------------------------------------------------------------------------------------------+
| Evidencia:                                                                                        |
| 1. Contrato cerrado en ncp/CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md.                               |
| 2. Backend implementado en backend/src/controllers/crearDesdeCeroController.js y verificado.      |
| 3. Contrato NODO-07 (Sección 14 / SCR-06) define CrearDesdeCeroWizardScreen como la rama de     |
|    onboarding inicial directamente disparada desde Hub Salón.                                     |
|                                                                                                   |
| Impacto:                                                                                          |
| Permite a sedes recién creadas estructurar sus actividades comerciales y catálogo base en         |
| tránsito para enviarlo hacia el backend mediante POST /api/v1/saas/hub/onboarding/bootstrap.       |
|                                                                                                   |
| Riesgo:                                                                                           |
| Bajo. Es un flujo autocontenido y transitorio (in-memory) que no altera tablas relacionales       |
| operativas y opera bajo el ActiveContext ya cerrado.                                              |
+---------------------------------------------------------------------------------------------------+
```

```
+---------------------------------------------------------------------------------------------------+
| OPCIÓN B: NODO-02 UI (Catálogo de Ofertas de Servicio & Asignaciones de Personal)                |
+---------------------------------------------------------------------------------------------------+
| Evidencia:                                                                                        |
| 1. Migraciones 067 (service_offers) y 068 (service_assignments) cerradas e inmutables.           |
| 2. Backend implementado en serviceOfferController.js y serviceAssignmentController.js.            |
| 3. Contrato NODO-07 (Sección 16 / SCR-08) define ServiceOffersScreen como el corazón de gestión  |
|    duradera del catálogo de la sede.                                                              |
|                                                                                                   |
| Impacto:                                                                                          |
| Permite al Administrador (OWNER / MANAGER) crear, editar y listar ofertas de servicios y          |
| vincular colaboradores a las ofertas, habilitando el prerrequisito para NODO-03A, 05 y 06.        |
|                                                                                                   |
| Riesgo:                                                                                           |
| Bajo a Medio. Requiere asegurar el montaje canónico de las rutas en el backend si no están        |
| explícitamente expuestas en index.js y construir la UI cliente bajo Active Context.               |
+---------------------------------------------------------------------------------------------------+
```

```
+---------------------------------------------------------------------------------------------------+
| OPCIÓN C: NODO-06 UI (Agenda Operativa de Citas & Máquina de Estados)                             |
+---------------------------------------------------------------------------------------------------+
| Evidencia:                                                                                        |
| 1. Migración 071 (saas_appointments) y máquina de estados cerrada.                               |
| 2. Backend implementado en nodo06AppointmentsController.js y montado en backend/index.js.         |
| 3. Contrato NODO-07 (Sección 16 / SCR-07) define SaaSAgendaScreen.                                |
|                                                                                                   |
| Impacto:                                                                                          |
| Proporciona la interfaz de trabajo diario del personal (calendario operativo de citas).           |
|                                                                                                   |
| Riesgo:                                                                                           |
| Alto si se implementa antes de NODO-02, ya que la creación de citas depende estrictamente de      |
| que existan servicios reales y staff asignado (service_offers / service_assignments).             |
+---------------------------------------------------------------------------------------------------+
```

---

## 10. OPCIONES DESCARTADAS Y EVIDENCIA

1. **DESCARTADA: Implementación de Journey / Login / Register (SCR-01, SCR-02, GRD-01):**
   * *Evidencia:* `NODO-07-SAAS-SCREEN-FLOW-CONTRACT-v1.0.md` (Sección 23, Architectural Stop #1).
   * *Motivo:* El desacoplamiento de la identidad neutral de la persona y la selección de Journey están en **ARCHITECTURAL STOP** por mandato directivo expreso.
2. **DESCARTADA: Reutilizar `ProviderDashboardScreen` como Hub o Agenda:**
   * *Evidencia:* `NODO-07-SAAS-SCREEN-FLOW-CONTRACT-v1.0.md` (Sección 22) y `N06-DEC-14`.
   * *Motivo:* `ProviderDashboardScreen` pertenece al Marketplace B2C (prestador domiciliario independiente) y está estrictamente aislado del SaaS multitenant.
3. **DESCARTADA: NODO-05 UI Directa (Disponibilidad / Pre-Check):**
   * *Evidencia:* `NODO-05-NODE-CONTRACT-v1.0.md`.
   * *Motivo:* NODO-05 es un motor computacional de sólo lectura (transitorio) que no constituye una pantalla independiente, sino un servicio de soporte para la creación de citas (NODO-06).

---

## 11. ARCHITECTURAL STOPS VIGENTES

```
================================================================================
                           ARCHITECTURAL STOP #1: JOURNEY
================================================================================
ESTADO: ACTIVO / INMUTABLE
REGLA: Prohibido implementar lógica de detección automática de SaaS en Login,
       Register, Splash o B2C Home. La navegación al subsistema SaaS debe
       permanecer desacoplada hasta que el Director defina la UX de Journey.
================================================================================

================================================================================
                           ARCHITECTURAL STOP #2: SOBERANÍA
================================================================================
ESTADO: ACTIVO / INMUTABLE
REGLA: El frontend NUNCA es autoridad de acceso. El backend valida token, tenant,
       membresía y RLS en cada petición contextualizada.
================================================================================
```

---

## 12. RECOMENDACIÓN TÉCNICA DEL AGENTE

Examinando la evidencia documental, el estado del backend y la progresión canónica del flujo de pantallas:

1. **Secuencia Canónica de Producto:**
   - Si se busca completar el ciclo de **incorporación inicial de nuevas sedes**: **OPCIÓN A (`Crear Desde Cero` / SCR-06)** es el siguiente paso canónico inmediato derivado de `HubSalonScreen`.
   - Si se busca habilitar la **operación continua y gestión duradera del salón**: **OPCIÓN B (`NODO-02 UI — Catálogo y Asignaciones` / SCR-08)** es el siguiente paso fundamental indispensable, dado que sin catálogo de sede no puede existir agenda operativa (NODO-06).

2. **Recomendación Específica:**
   El agente recomienda al Director priorizar **OPCIÓN A (Crear Desde Cero)** si el objetivo prioritario del sprint es el onboarding de nuevos salones, o **OPCIÓN B (NODO-02 Catálogo & Staff)** si el objetivo es habilitar la administración de servicios y configuración operativa de salones existentes.

---

## 13. DECISIÓN REQUERIDA DEL DIRECTOR

El Director del Proyecto debe determinar cuál de los siguientes caminos autorizar para la siguiente fase arquitectónica:

* [ ] **DECISIÓN 1:** Autorizar el Discovery y Arquitectura Física de **OPCIÓN A: CREAR DESDE CERO (SCR-06 — Wizard de Aprovisionamiento Inicial & Handover)**.
* [ ] **DECISIÓN 2:** Autorizar el Discovery y Arquitectura Física de **OPCIÓN B: NODO-02 UI (SCR-08 — Catálogo de Servicios de Sede & Asignaciones de Staff)**.
* [ ] **DECISIÓN 3:** Instrucción alternativa del Director.

================================================================================
                         FIN DEL REPORTE DE FASE 6
================================================================================
