# NODO-07 — CONTRATO DEL FLUJO CANÓNICO DE PANTALLAS SaaS v1.0
## GlowApp SaaS Screen Flow & UX-Architectural Contract (Reconciled)

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto  
NODE IDENTIFIER: NODO-07  
NODE NAME: Canonical SaaS Screen Flow & UX-Architectural Contract  
DOCUMENT VERSION: v1.0.0 (Reconciled)  
CLASSIFICATION: FORMAL UX-ARCHITECTURAL SPECIFICATION & CONTRACT  
STATUS: CONTRACT RECONCILED / AWAITING DIRECTOR APPROVAL 🟡  
SCOPE: Definición del flujo canónico de pantallas SaaS desde REGISTER hasta la OPERACIÓN  
================================================================================

---

## 1. PROPÓSITO

Formalizar el contrato integral de navegación, estados de interfaz, compuertas lógicas (guards), resolución de contexto y experiencias de usuario (UX) para el subsistema **GlowApp SaaS**.

Este documento traduce la arquitectura canónica cerrada en el backend (Foundation, Context Resolution, Active Context, Hub Salón, Crear Desde Cero y Nodos 01 al 06) en especificaciones operativas para la capa de presentación (Frontend), asegurando:
1. **Desacoplamiento Estricto:** Separación absoluta entre *Persona*, *Cuenta*, *Identidad*, *Journey*, *Organización*, *Establecimiento*, *Membresía* y *Rol*.
2. **Dirección Arquitectónica Unidireccional:** La arquitectura gobierna y define al UX ($\text{Arquitectura} \longrightarrow \text{UX}$), erradicando cualquier intento de forzar la arquitectura a adaptarse a diagramas visuales históricos o legados monolíticos.
3. **Preservación de la Frontera B2C/SaaS:** Coexistencia pacífica entre el Marketplace B2C existente y la plataforma SaaS multitenant bajo la frontera asimétrica aprobada (`N06-DEC-14`).
4. **Cero Ambigüedad de Implementación:** Proveer una guía contractual exhaustiva con inventario de componentes UX, matrices de transición de estados y guards para que la fase de construcción proceda sin necesidad de reinterpretar la arquitectura.

---

## 2. AUTORIDAD Y DEPENDENCIAS

### 2.1. Autoridad Raíz
- **Director del Proyecto GlowApp SaaS:** Máxima autoridad directiva, arbitral y de diseño.

### 2.2. Fuentes de Verdad Arquitectónica (Cerradas e Inmutables)
1. **SOUL + Architectural Governance Protocol v1.0**
2. **SAAS FOUNDATION CORE v1.0 (Migración 065 / 066)**: Modelos `tenants`, `organizations`, `establishments`, `memberships`, `usuarios`.
3. **CONTEXT RESOLUTION v1.0 (Migración 066 / `fn_resolve_user_tenant`)**
4. **ACTIVE CONTEXT NODE CONTRACT v1.0 (`ARCH-AC-001` / `x-active-membership-id`)**
5. **HUB SALÓN NODE CONTRACT v1.0 (`GET /api/v1/saas/hub/summary`, `GET /api/v1/saas/hub/staff`)**
6. **CREAR DESDE CERO NODE CONTRACT v1.0 (`DEC-CDC-001`, `DEC-CDC-002`, `Context Package`)**
7. **HANDOVER BOUNDARY CONTRACT v1.0**
8. **NODO-01 A NODO-06 (CLOSED):**
   - *NODO-01:* Handover Boundary Ingestion (HBC Ingestion in-memory del Context Package)
   - *NODO-02:* Catalog & Staff Assignment Runtime (`service_offers`, `service_assignments`)
   - *NODO-03A:* Staff Operational Availability & Schedule Runtime (`staff_schedules`)
   - *NODO-04:* Downstream B2C Materialization Adapter
   - *NODO-05:* Availability Projection & Booking Slot Engine (Read-Only Deterministic Pre-Check / Transient)
   - *NODO-06:* SaaS Internal Appointments & Operational Agenda Engine (`saas_appointments`, GiST Exclude, State Machine)
9. **EVIDENCIA DE AUDITORÍA DISCOVERY NODO-07**

---

## 3. PRINCIPIOS UX-ARQUITECTÓNICOS

1. **La Arquitectura Gobierna al UX ($\text{Arquitectura} \longrightarrow \text{UX}$):** Las decisiones de seguridad, multi-tenancy, inmutabilidad y atomicidad transaccional dictan la experiencia de usuario.
2. **No Todo Concepto Arquitectónico es una Pantalla:** Conceptos como `ACTIVE CONTEXT`, `SAAS ELIGIBILITY`, `JOURNEY RESOLUTION` o `NODO-01` se materializan mediante orquestadores de estado, guards de navegación, interceptores HTTP o selectores contextuales, evitando la proliferación innecesaria de pantallas artificiales.
3. **Separación de Autoridad Frontend vs Backend:**
   - **Frontend:** Presenta opciones visuales, resuelve la experiencia UX, captura inputs del usuario, mantiene el estado reactivo de Active Context y adjunta el header canónico `x-active-membership-id`. El frontend **NUNCA** concede acceso SaaS ni define permisos.
   - **Backend:** Autentica la identidad, autoriza operaciones, valida membresías y afinidad de tenant, aplica PostgreSQL Row-Level Security (RLS) y determina el acceso efectivo.
4. **Identidad Neutral y Desacoplada:** La cuenta de usuario (`ACCOUNT/IDENTITY`) pertenece a una persona natural neutral. Los roles y capacidades operativas emanan exclusivamente de las membresías contextuales activas dentro de cada sede física (`memberships`).
5. **Aislamiento Multi-Tenant Visible:** La interfaz debe reflejar inequívocamente en todo momento cuál es la Organización y el Establecimiento activo, facilitando el cambio de sede (*Branch Switcher*) sin mezclar datos de diferentes tenants.
6. **Degradación Segura y Feedback Determinista:** Todo error de autorización (`401`, `403`), fallo de contexto (`NO_ACTIVE_CONTEXT`, `MEMBERSHIP_INACTIVE`) o conflicto temporal (`409 CONFLICT`) debe ser capturado y presentado con mensajes claros y acciones de recuperación.

---

## 4. DEFINICIONES CANÓNICAS

- **PERSONA:** El ser humano físico que interactúa con la aplicación a través de un dispositivo.
- **REGISTER:** Punto de entrada donde la persona proporciona sus datos básicos para crear una cuenta.
- **ACCOUNT:** Registro durable de credenciales y datos de contacto en la tabla `usuarios`.
- **IDENTITY:** Sujeto autenticado que posee una sesión o token JWT válido (`req.user.id`).
- **JOURNEY:** Etapa de resolución de experiencia posterior a `IDENTITY`. Define el modo de interacción del usuario (ej. Cliente B2C vs Administrador/Operador SaaS).  
  $$\text{JOURNEY} \neq \text{ROLE} \quad \wedge \quad \text{JOURNEY} \neq \text{MEMBERSHIP} \quad \wedge \quad \text{JOURNEY} \neq \text{ACCOUNT} \quad \wedge \quad \text{JOURNEY} \neq \text{TENANT}$$
- **SAAS ELIGIBILITY:** Condición evaluada server-side que determina si la identidad posee vínculos legítimos (membresías) con organizaciones y sedes SaaS.
- **SAAS ACCESS:** Concesión formal de entrada a los módulos operativos SaaS, otorgada exclusivamente por el backend tras validar autenticación, membresía y RLS.
- **AVAILABLE CONTEXT:** Conjunto determinista de sedes físicas (`establishments`) y membresías (`memberships`) a las que una identidad tiene acceso legítimo según `GET /api/v1/saas/context/available`.
- **ACTIVE CONTEXT:** Estado contextual unificado de la aplicación que fija la sede física activa y su rol mediante el identificador técnico canónico `membership_id` transportado vía `x-active-membership-id`. **No es una pantalla obligatoria.**
- **HUB SALÓN:** Cockpit operativo central de la sede física activa (`GET /summary`, `GET /staff`). Punto de anclaje de la operación SaaS.
- **CREAR DESDE CERO:** Asistente orquestador de aprovisionamiento inicial y configuración de catálogo en tránsito.
- **PRE-NODO 01 / HANDOVER BOUNDARY:** Frontera arquitectónica de empaquetado y entrega del `Context Package` transitorio hacia el motor del core.
- **OPERACIÓN SaaS:** Ejecución cotidiana del negocio (Agenda NODO-06, Catálogo NODO-02, Horarios NODO-03A).

---

## 5. FLUJO CANÓNICO COMPLETO

```
PERSONA
  │
  ▼
REGISTER (Datos básicos neutrales)
  │
  ▼
ACCOUNT (Credenciales creadas)
  │
  ▼
IDENTITY (Autenticación / JWT emitido)
  │
  ▼
JOURNEY (Resolución de experiencia: B2C vs SaaS)
  │
  ▼
SAAS ELIGIBILITY (Evaluación server-side de membresías disponibles)
  │
  ▼
SAAS ACCESS (Validación y autorización de entrada al subsistema SaaS)
  │
  ▼
AVAILABLE CONTEXT (Resolución de sedes: ONE_CONTEXT vs MULTIPLE_CONTEXTS)
  │
  ▼
ACTIVE CONTEXT (Fijación de estado contextual + inyección x-active-membership-id)
  │
  ▼
HUB SALÓN (Cockpit Operativo de Sede: /summary, /staff)
  │
  ├───> [Si requiere Aprovisionamiento Inicial] ──> CREAR DESDE CERO
  │                                                      │
  │                                                      ▼
  │                                                PRE-NODO 01 / HBC INGESTION (NODO-01)
  │                                                      │
  │                                                      ▼
  ▼                                                OPERACIÓN SaaS
OPERACIÓN SaaS (NODO-02 Ofertas, NODO-03A Horarios, NODO-05 Pre-Check, NODO-06 Agenda)
```

---

## 6. REGISTER CONTRACT

### 6.1. Propósito
Capturar exclusivamente los datos necesarios para formalizar la existencia de una `ACCOUNT` y establecer la `IDENTITY` de la persona natural en el sistema.

### 6.2. Entrada / Captura de Datos
- `full_name` (Texto obligatorio, min. 3 caracteres)
- `email` (Email válido obligatorio, formato RFC 5322)
- `password` (Contraseña obligatoria, min. 8 caracteres, complejidad estándar)
- `phone` (Teléfono opcional/recomendado con formato E.164)

### 6.3. Invariante de Desacoplamiento (Regla Fundamental)
> [!IMPORTANT]
> **PROHIBIDO SELECTOR DE ROL OPERACIONAL EN REGISTER:**
> La pantalla de registro **no debe contener** selectores de rol tipo `CLIENTE`, `PRESTADOR`, `DUEÑO DE SALÓN` o `RECEPCIONISTA`. La cuenta nace como una Identidad Neutral.

### 6.4. Comportamiento Post-Registro
1. El backend emite `201 CREATED` persistiendo el registro en `usuarios`.
2. Se autentica la sesión emitiendo el JWT de `IDENTITY`.
3. El frontend transfiere el control a la etapa de resolución de **Journey**.

---

## 7. POST-AUTH / IDENTITY RESOLUTION

### 7.1. Propósito
Procesar el token JWT emitido tras Login (`POST /api/auth/login`) o Register (`POST /api/auth/register`) para inicializar la sesión segura del cliente y derivar la identidad autenticada (`req.user.id`).

### 7.2. Responsabilidad de la Capa de Identidad
1. Almacenar de forma segura el token JWT en el cliente.
2. Derivar la identidad sin asumir roles operativos estáticos ni forzar redirecciones directas a dashboards de sede sin pasar por las compuertas de Journey y Contexto.

---

## 8. JOURNEY CONTRACT

### 8.1. Propósito
Resolver la experiencia de interacción deseada por la identidad autenticada, diferenciando la experiencia de **Marketplace B2C** de la experiencia de **Plataforma SaaS de Salón**.

### 8.2. Naturaleza Conceptual del Journey
- **Desacoplamiento Total:** `JOURNEY` no es un rol de base de datos, no es una membresía y no es un tenant.
- **Sin Determinación Automática Arbitraria:** El Journey no se deduce automáticamente de forma implícita.
- **Mecanismo de Resolución:** El mecanismo exacto para que el usuario elija o confirme su Journey (ej. pantalla de selección explícita, conmutador en perfil o preferencia guardada) queda definido como propuesta pendiente de decisión del Director.

> [!WARNING]
> **PROPOSAL — NOT APPROVED:**
> - Presentar un diálogo o pantalla interactiva post-login de selección de Journey ("¿Cómo deseas operar hoy? Explorar Servicios B2C / Gestionar mi Salón SaaS") $\to$ Pendiente de decisión directiva.

---

## 9. SAAS ELIGIBILITY CONTRACT

### 9.1. Propósito
Determinar si la identidad autenticada posee membresías o vínculos legítimos con organizaciones y sedes físicas en el subsistema SaaS.

### 9.2. Mecanismo de Consulta Server-Side
- Se evalúa consultando el endpoint canónico:
  ```http
  GET /api/v1/saas/context/available
  ```
- **Condición Elegible:** La respuesta contiene una o más membresías con `status = 'ACTIVE'`.
- **Condición No Elegible (`NO_CONTEXT`):** La respuesta contiene un arreglo vacío de membresías.

---

## 10. SAAS ACCESS CONTRACT

### 10.1. Propósito
Formalizar la frontera de seguridad donde el backend autoriza la entrada al subsistema SaaS.

### 10.2. Reglas de Autoridad de Acceso
1. **Autoridad Exclusiva del Backend:** El backend valida el token JWT, verifica que la membresía pertenezca al usuario, valida el tenant y aplica RLS. El frontend nunca otorga acceso por sí mismo.
2. **Respuesta ante NO_CONTEXT:** Si el usuario solicita operar en SaaS pero no posee membresías activas, la UI presenta feedback informativo y la opción de iniciar el aprovisionamiento de un nuevo establecimiento (*Create Salon Onboarding*).

---

## 11. AVAILABLE CONTEXT CONTRACT

### 11.1. Propósito
Gestionar la resolución de la sede física operativa cuando la identidad posee acceso SaaS legítimo.

### 11.2. Reglas de Multiplicidad Contextual
1. **Caso `ONE_CONTEXT` (1 Membresía Activa):**
   - Procede según el contrato de resolución contextual aprobado, permitiendo al cliente fijar el `membership_id` y avanzar al Hub Salón.
2. **Caso `MULTIPLE_CONTEXTS` (>1 Membresías Activas):**
   - **Requiere Selección Explícita Obligatoria:** El frontend debe presentar la pantalla/modal `AvailableContextSelectorScreen` para que el usuario escoja deliberadamente con qué sede desea operar.
   - **Cero Auto-Selección / Cero Memoria Canónica:** El contrato canónico **no autoriza** la auto-selección de sedes en multi-contexto ni el uso de "última sede usada" como autoridad.

### 11.3. Especificación del Selector (`AvailableContextSelectorScreen`)
- **Datos Presentados por Sede:**
  - Nombre de la Organización (`organization.legal_name`)
  - Nombre de la Sede (`establishment.name`)
  - Dirección y Ciudad (`establishment.address`, `establishment.city`)
  - Rol del usuario en esa sede (`membership.role`)
- **Identificador Técnico:** Exclusivamente `membership_id` (UUID v4).

---

## 12. ACTIVE CONTEXT CONTRACT

### 12.1. Propósito
Definir y mantener el estado contextual de la sede activa en la aplicación cliente y garantizar su propagación sistemática hacia el backend.

### 12.2. Naturaleza de Estado (No Pantalla)
> [!IMPORTANT]
> **ACTIVE CONTEXT NO ES UNA PANTALLA:**
> Es una entidad de estado reactivo en el Frontend. La interfaz puede incluir un botón/modal de conmutación (*Branch Switcher*), pero Active Context representa el contexto transaccional en memoria.

### 12.3. Transporte Canónico
- El frontend adjunta obligatoriamente en cada petición hacia `/api/v1/saas/*` el header:
  ```http
  x-active-membership-id: <UUID>
  ```
- **Prohibición de Identificadores Sintéticos:** Queda terminantemente prohibido inventar o utilizar en el cliente atributos como `active_salon_id`, `active_establishment_id`, `active_tenant_id` o `current_branch_id`.

---

## 13. HUB SALÓN CONTRACT

### 13.1. Propósito
Servir como el **Punto de Entrada Operativo (Cockpit)** de la sede física activa en GlowApp SaaS.

### 13.2. Especificación de la Pantalla (`HubSalonScreen`)
- **Ruta Frontend:** `/saas/hub`
- **Consumo de Endpoints Backend:**
  - `GET /api/v1/saas/hub/summary` (Información de la sede, organización matriz, rol contextual y métricas resumen).
  - `GET /api/v1/saas/hub/staff` (Lista de colaboradores activos de la sede).
- **Desacoplamiento Total de `ProviderDashboard`:**
  - `ProviderDashboard` pertenece al Marketplace B2C de prestadores independientes y **no debe utilizarse como sustituto** del Hub Salón.

---

## 14. CREAR DESDE CERO CONTRACT

### 14.1. Propósito
Guiar al Administrador (`OWNER` o `MANAGER`) en la configuración inicial de la sede física activa, estructurando especialidades y catálogo en tránsito.

### 14.2. Flujo Operativo del Asistente
- **Punto de Entrada:** Disparado exclusivamente desde `HubSalonScreen` bajo `Active Context`.
- **Naturaleza Transitoria:** No genera tablas relacionales de catálogo de sede ni persiste entidades intermedias en base de datos.
- **Compilación de Handover:** Compila en memoria el `Context Package` estructurado bajo los 16 atributos del contrato de handover y lo entrega mediante `POST /api/v1/saas/hub/crear-desde-cero`.

---

## 15. PRE-NODO 01 & HANDOVER BOUNDARY UX

### 15.1. Distinción Arquitectónica
- **HANDOVER BOUNDARY:** Contrato de frontera que formaliza la entrega del `Context Package`.
- **PRE-NODO 01:** Capacidad arquitectónica de recepción y validación del paquete de contexto.
- **NODO-01:** Capacidad de ingestión en memoria (*HBC Ingestion*).

### 15.2. Experiencia de Usuario
- Las fronteras técnicas `PRE-NODO 01` y `NODO-01` **no se exponen como pantallas técnicas al usuario**.
- La UI manifiesta la culminación exitosa mediante una confirmación visual integrada en el flujo del asistente: *"Configuración de sede recibida con éxito"* y transiciona hacia el Hub Salón o la Agenda.

---

## 16. MAPA UX DE NODO-01 A NODO-06

Mapeo riguroso de las capacidades técnicas del backend hacia las interfaces correspondientes:

| Nodo Técnico | Definición Arquitectónica Formal | Manifestación UX / Pantalla | Roles Permitidos |
| :--- | :--- | :--- | :--- |
| **NODO-01** | **HBC Ingestion (Ingestión in-memory del Handover)** | Confirmación y cierre del asistente inicial | `OWNER`, `MANAGER` |
| **NODO-02** | **Catalog & Staff Assignment Runtime** | Gestión de Ofertas de Sede (`ServiceOffersScreen`) y Asignaciones M:N de Staff | `OWNER`, `MANAGER` |
| **NODO-03A** | **Staff Operational Availability & Schedules** | Configuración de Horarios Semanales de Personal (`StaffSchedulesScreen`) | `OWNER`, `MANAGER`, `PROFESSIONAL` (propio) |
| **NODO-04** | **Downstream B2C Materialization Adapter** | Indicador / Badge de sincronización con Marketplace B2C | `OWNER`, `MANAGER` |
| **NODO-05** | **Availability Projection & Booking Slot Engine** *(Read-Only / Transient)* | Visualizador de disponibilidad y huecos libres en creación de citas (Pre-Check) | `OWNER`, `MANAGER`, `RECEPTIONIST` |
| **NODO-06** | **SaaS Internal Appointments & Operational Agenda Engine** | Agenda Operativa Interactiva (`SaaSAgendaScreen`), Creación y Máquina de Estados de Citas | `OWNER`, `MANAGER`, `RECEPTIONIST`, `PROFESSIONAL` |

---

## 17. FRONTERA UX SaaS / B2C

Para preservar la coexistencia pacífica definida en `N06-DEC-14`:

1. **Rutas B2C Preservadas:**
   - `/home`: Marketplace geolocalizado de prestadores y búsqueda pública.
   - `/client-bookings`, `/booking-tracking`: Gestión de reservas para clientes.
   - `/provider`: Consola del Prestador Domiciliario B2C (`ProviderDashboardScreen`).
   - `/ideas`, `/biometric-welcome`, `/store`: Experiencias de diagnóstico IA Aura y tienda.
2. **Rutas SaaS Exclusivas:**
   - `/saas/context-selector`: Selector explícito de sede física.
   - `/saas/hub`: Cockpit de Salón.
   - `/saas/crear-desde-cero`: Wizard de configuración inicial.
   - `/saas/agenda`: Agenda operativa NODO-06.
   - `/saas/services`: Catálogo y asignaciones NODO-02.
   - `/saas/staff`: Horarios y personal NODO-03A.

---

## 18. MULTI-JOURNEY SCENARIOS

### 18.1. Principio de Identidad Multidimensional
Una misma cuenta de usuario (`req.user.id`) puede interactuar legítimamente como Cliente B2C en ciertos momentos y como Administrador o Profesional de una sede SaaS en otros.

### 18.2. Reglas de Separación Técnica
- Las solicitudes al namespace `/api/v1/saas/*` requieren obligatoriamente `x-active-membership-id`.
- Las solicitudes a endpoints B2C operan con el token JWT estándar sin header de membresía.
- La interfaz debe permitir la conmutación explícita de entorno sin cerrar la sesión de la cuenta.

---

## 19. SCREEN INVENTORY CANÓNICO

| ID | Componente UX | Tipo | Propósito | Entrada | Salida | Contexto Requerido | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **SCR-01** | `RegisterScreen` | `SCREEN` | Captura de credenciales neutrales de cuenta | Formulario básico | Cuenta creada $\to$ Login | Ninguno | `PROPOSAL` |
| **SCR-02** | `LoginScreen` | `SCREEN` | Autenticación de identidad (Email/OAuth) | Credenciales | JWT Identity $\to$ Journey | Ninguno | `PROPOSAL` |
| **SCR-03** | `ForgotPasswordScreen` | `SCREEN` | Recuperación de contraseña vía OTP | Email | Contraseña actualizada | Ninguno | `KEEP / APPROVED` |
| **GRD-01** | `JourneyResolverGuard` | `GUARD` | Evalúa Available Contexts y despacha ruta | JWT autenticado | Redirección a SCR-04 o B2C | Ninguno | `PROPOSAL` |
| **SCR-04** | `AvailableContextSelectorScreen`| `SCREEN` | Selección explícita de sede en multi-contexto | Membresías activas | `membership_id` $\to$ Hub Salón | Token JWT | `PROPOSAL` |
| **SRV-01** | `ActiveContextStateHolder` | `STATE / SERVICE`| Mantiene en memoria el `membership_id` activo | `membership_id` | `x-active-membership-id` | `membership_id` | `PROPOSAL` |
| **INT-01** | `SaaSHttpInterceptor` | `INTERCEPTOR` | Inyecta header contextual en requests SaaS | HTTP Request | Request con header | `membership_id` | `PROPOSAL` |
| **SCR-05** | `HubSalonCockpitScreen` | `SCREEN` | Tablero de comando de la sede activa | Contexto activo | Navegación operacional | `Active Context` | `PROPOSAL` |
| **SCR-06** | `CrearDesdeCeroWizardScreen` | `SCREEN` | Asistente de configuración de catálogo | Trigger desde Hub | Context Package $\to$ Handover | `Active Context` (Owner/Mgr) | `PROPOSAL` |
| **SCR-07** | `SaaSAgendaScreen` (NODO-06) | `SCREEN` | Agenda operativa y máquina de estados de citas| Contexto activo | Citas gestionadas | `Active Context` | `PROPOSAL` |
| **SCR-08** | `ServiceOffersScreen` (NODO-02) | `SCREEN` | Catálogo de sede y asignaciones de staff | Contexto activo | Ofertas persistidas | `Active Context` (Owner/Mgr) | `PROPOSAL` |
| **SCR-09** | `StaffSchedulesScreen` (NODO-03A)| `SCREEN` | Configuración de disponibilidad semanal | Contexto activo | Horarios persistidos | `Active Context` | `PROPOSAL` |
| **SCR-10** | `B2CHomeScreen` | `SCREEN` | Marketplace B2C geolocalizado | Acceso público/cliente| Citas B2C reservadas | Opcional | `KEEP AS B2C` |
| **SCR-11** | `ProviderDashboardScreen` | `SCREEN` | Consola de prestador independiente B2C | Rol provider B2C | Operación domiciliaria B2C | Perfil B2C | `ISOLATE B2C` |

---

## 20. NAVIGATION / TRANSITION MATRIX

| Origen | Condición / Evento | Destino | Contexto Inyectado | Autoridad / Roles | Manejo de Fallo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Anónimo** | Abre la app | `B2CHomeScreen` o `LoginScreen` | Ninguno | Público | N/A |
| `RegisterScreen` | Registro exitoso | `JourneyResolverGuard` | JWT Identity | Todos | Muestra error de validación |
| `LoginScreen` | Autenticación exitosa | `JourneyResolverGuard` | JWT Identity | Todos | Muestra error de login |
| `JourneyResolverGuard` | `memberships.length == 0` | `B2CHomeScreen` (con opción SaaS) | JWT Identity | Sin membresías | Fallback B2C |
| `JourneyResolverGuard` | `memberships.length == 1` | `HubSalonCockpitScreen` | `x-active-membership-id` | Cualquier rol SaaS | Redirige a selector manual |
| `JourneyResolverGuard` | `memberships.length > 1` | `AvailableContextSelectorScreen` | JWT Identity | Múltiples sedes | Muestra lista de sedes |
| `AvailableContextSelector`| Selecciona sede física | `HubSalonCockpitScreen` | `x-active-membership-id` | Rol de la membresía | Muestra error de selección |
| `HubSalonCockpitScreen` | Presiona "Branch Switcher" | `AvailableContextSelectorScreen` | JWT Identity | Todos en Hub | Mantiene contexto previo |
| `HubSalonCockpitScreen` | Presiona "Configuración Inicial"| `CrearDesdeCeroWizardScreen` | `x-active-membership-id` | `OWNER`, `MANAGER` | `403 FORBIDDEN` si es otro rol |
| `HubSalonCockpitScreen` | Presiona "Agenda Operativa" | `SaaSAgendaScreen` | `x-active-membership-id` | Todos los roles de sede | Redirige a Hub si no hay contexto |
| `CrearDesdeCeroWizard` | Handover completado exitosamente| `HubSalonCockpitScreen` | `x-active-membership-id` | `OWNER`, `MANAGER` | Permanece en wizard con error |
| Cualquier vista SaaS | Token expirado (`401`) | `LoginScreen` | Limpia contexto | Ninguno | Notifica sesión expirada |
| Cualquier vista SaaS | Contexto inválido (`403/404`)| `AvailableContextSelectorScreen` | Limpia active ID | Ninguno | Notifica contexto no disponible |

---

## 21. STATE & GUARD MATRIX

```
+------------------------+-------------------------------------------------------------+
| GUARD / ESTADO         | RESPONSABILIDAD Y COMPORTAMIENTO                            |
+------------------------+-------------------------------------------------------------+
| AuthGuard              | Bloquea acceso a rutas privadas si no existe token JWT.     |
+------------------------+-------------------------------------------------------------+
| SaaSActiveContextGuard | Verifica que `ActiveContextStateHolder` tenga un             |
|                        | `membership_id` activo antes de renderizar vistas SaaS.     |
|                        | Si falta, intercepta y despacha a Context Selector.         |
+------------------------+-------------------------------------------------------------+
| SaaSRoleGuard(roles)   | Verifica que el rol contextual coincida con los roles       |
|                        | permitidos para la acción (ej. solo OWNER/MANAGER en        |
|                        | Crear Desde Cero y gestión de ofertas NODO-02).             |
+------------------------+-------------------------------------------------------------+
```

---

## 22. LEGACY FRONTEND DISPOSITION

| Artefacto / Archivo Existente | Clasificación | Justificación Arquitectónica |
| :--- | :---: | :--- |
| `screens/auth/register_screen.dart` | **ADAPT LATER** | Eliminar toggle `CLIENTE/PRESTADOR` y convertir en captura neutral de cuenta. |
| `screens/auth/login_screen.dart` | **ADAPT LATER** | Actualizar despacho post-login para invocar `JourneyResolverGuard`. |
| `screens/auth/forgot_password_screen.dart` | **KEEP AS B2C / COMMON** | Flujo neutral de seguridad de cuenta 100% reutilizable. |
| `screens/auth/onboarding_screen.dart` | **ISOLATE** | Mantener para onboarding de prestadores independientes del Marketplace B2C. |
| `screens/auth/verification_pending_screen.dart`| **ISOLATE** | Mantener para validación manual de prestadores B2C. |
| `screens/provider_dashboard_screen.dart` | **ISOLATE** | Mantener para prestadores domiciliarios B2C. **No utilizar como Hub Salón.** |
| `screens/home/home_screen.dart` | **KEEP AS B2C** | Pantalla principal del Marketplace de belleza para clientes. |
| `screens/ideas/*` (IA Aura / VTO) | **KEEP AS B2C** | Diagnóstico y colorimetría para clientes finales. |

---

## 23. ARCHITECTURAL STOPS

```
================================================================================
                           ARCHITECTURAL STOP #1
================================================================================
PROBLEMA:
El formulario de registro actual (`RegisterScreen`) inyecta rígidamente un rol
operacional (`CLIENTE` vs `PRESTADOR`) durante la creación de cuenta, violando la
separación canónica `PERSONA -> ACCOUNT -> IDENTITY -> JOURNEY`.

EVIDENCIA:
`frontend/lib/screens/auth/register_screen.dart:20, 190-256`.

IMPACTO:
Impide que una misma identidad opere de forma neutral y multidimensional en SaaS y B2C.

OPCIONES:
- Opción A: Simplificar `RegisterScreen` a captura pura de datos de cuenta (Nombre, Email, Password, Teléfono) y delegar toda decisión de negocio al Journey Resolver post-autenticación.
- Opción B: Conservar el selector visual solo como "Preferencia de Bienvenida" sin escribir roles estáticos en la tabla `usuarios`.

RECOMENDACIÓN:
Aprobar Opción A.

DECISIÓN REQUERIDA:
Autorización del Director para formalizar la Opción A en la especificación final.
================================================================================
```

---

## 24. DECISIONS REQUIRED

1. **Aprobación de la Descontaminación de Register:** Autorizar que el registro de cuenta sea 100% neutral sin selección de roles operacionales.
2. **Mecanismo de Selección de Journey en Frontend:** Determinar si la selección de Journey se realiza mediante modal explícito post-login o conmutador de modo en el menú principal.
3. **Mecanismo de Conmutación de Sede:** Validar la presentación de `AvailableContextSelectorScreen` para el caso `MULTIPLE_CONTEXTS`.

---

## 25. PROPOSALS — NOT APPROVED

> [!WARNING]
> **PROPOSALS — NOT APPROVED:**
> 1. Eliminación del toggle de roles en `RegisterScreen` $\to$ Propuesta técnica documentada.
> 2. Implementación de `JourneyResolverGuard` como orquestador post-login $\to$ Propuesta técnica documentada.
> 3. Creación de las pantallas `AvailableContextSelectorScreen` y `HubSalonCockpitScreen` $\to$ Propuesta técnica documentada.
> 4. Inyección del header `x-active-membership-id` en el cliente Flutter $\to$ Propuesta técnica documentada.
> 5. Memoria local de última sede (`last_active_membership_id`) para atajo de navegación $\to$ Propuesta técnica documentada (Fuera del flujo canónico).

---

## 26. CRITERIA FOR NEXT PHASE

1. **Aprobación Formal del Contrato Reconciliado:** Firma directiva de este documento.
2. **Cero Modificación de Backend:** Mantener inmutables las migraciones 065 a 071 y los servicios de NODO-01 a NODO-06.
3. **Construcción Guiada por Contrato:** La implementación en Flutter deberá ajustarse estrictamente a este inventario, matrices de transición y guards.

---

## CONTRACT RECONCILIATION LOG

| Elemento Auditado | Estado en Draft Inicial | Corrección Aplicada en Reconciliación Final | Justificación y Regla de Gobernanza |
| :--- | :--- | :--- | :--- |
| **JOURNEY** | Mencionaba resolución automática según estado relacional | Se eliminó toda determinación automática. Se fijó que Journey es posterior a Identity y su mecanismo es `PROPOSAL — NOT APPROVED`. | Corrección 1 / Desacoplamiento conceptual estricto. |
| **MULTI-CONTEXT** | Proponía `last_active_membership_id` como comportamiento canónico | Se eliminó del flujo canónico. `MULTIPLE_CONTEXTS` requiere selección explícita obligatoria (`AvailableContextSelectorScreen`). | Corrección 2 / Cero auto-selección en contrato canónico. |
| **ACTIVE CONTEXT** | Redacción ambigua sobre si era una pantalla | Se formalizó explícitamente: Active Context es **estado contextual**, no una pantalla obligatoria. Identificador único: `x-active-membership-id`. | Corrección 3 / Prohibición de identificadores sintéticos. |
| **AUTORIDAD SaaS** | Redacción ambigua sobre la concesión de acceso | Se delimitó: Frontend presenta/selecciona, Backend autentica/autoriza/aplica RLS. El frontend nunca "concede" acceso. | Corrección 4 / Autoridad exclusiva server-side. |
| **NODO-01** | Podía confundirse con pantalla o catálogo | Se formalizó: NODO-01 es **HBC Ingestion** (ingestión in-memory del handover). No es pantalla ni CRUD de ofertas. | Corrección 5 / Semántica estricta de NODO-01. |
| **NODO-05 vs NODO-06** | Riesgo de mezcla conceptual | Se separó estrictamente: NODO-05 = Availability Pre-Check (Read-Only/Transient), NODO-06 = Appointments & Agenda Engine (Creación y Estado). | Corrección 6 / Preservación de fronteras de nodos cerrados. |
| **SERVICE OFFERS** | Podía atribuirse a NODO-01 | Se ratificó: NODO-02 = Service Offer + Assignment Runtime; NODO-01 = HBC Ingestion. | Corrección 7 / Inmutabilidad de NODO-02. |
| **LEGACY FRONTEND** | Riesgo de eliminación o confusión | Se mantuvo la clasificación formal: `ProviderDashboardScreen` permanece aislado como B2C y nunca como Hub Salón. | Corrección 8 / Aislamiento de módulos heredados. |
| **DECISIONS REQUIRED** | Contenía propuestas presentadas como aprobadas | Se depuró la sección para incluir únicamente decisiones que requieren resolución del Director. | Corrección 9 / Cero recomendaciones como decisiones aprobadas. |
| **ORDEN CANÓNICO** | Orden de la cadena | Se ratificó el orden de 13 etapas canónicas sin alteración alguna. | Corrección 10 / Integridad del flujo arquitectónico. |

```
================================================================================
               FIN DEL CONTRATO DE PANTALLAS SaaS (RECONCILIADO)
================================================================================
ESTADO: NODO-07 CONTRACT RECONCILED / AWAITING DIRECTOR APPROVAL 🟡
================================================================================
```
