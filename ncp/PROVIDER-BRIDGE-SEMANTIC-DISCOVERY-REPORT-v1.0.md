# PROVIDER BRIDGE SEMANTIC DISCOVERY REPORT v1.0
## Descubrimiento Semántico: Identidad SaaS, Membresías y Provider B2C

**Versión:** 1.0.0  
**Estado:** DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Read-Only Architectural Discovery (Cero Modificaciones de Runtime o Esquema)

---

## 1. EXECUTIVE SUMMARY

El presente informe formaliza el descubrimiento arquitectónico de la frontera entre los conceptos del plano **SaaS** (`organizations`, `establishments`, `memberships`, roles) y los conceptos del plano **Pre-Nodo 01 B2C** (`usuarios`, `perfiles_prestador`, `services`, `bookings`).

### Hallazgos Principales:
1. **Desacoplamiento Fundamental:** `memberships` (SaaS) y `perfiles_prestador` (B2C) son conceptos de dominios desacoplados. No existe relación física directa entre ellos; su único nexo es la clave foránea compartida hacia `usuarios.id`.
2. **Condición de Provider B2C:** Un `usuarios.id` solo opera como Provider si cuenta con registro en `perfiles_prestador` con `estatus_verificacion = 'APROBADO'`, `is_active = true` y ubicación geográfica válida.
3. **Roles SaaS vs. Providers:** Ningún rol SaaS (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`) equivale automáticamente a un Provider B2C. Un miembro profesional solo puede operar como Provider B2C si cuenta con perfil operativo activo y categorías asignadas.
4. **Acoplamiento de Catálogo:** En Pre-Nodo 01, `public.services` exige estrictamente un `provider_id` individual (1 servicio $\rightarrow$ 1 prestador). No existe soporte nativo en B2C para servicios pertenecientes directamente a un establecimiento (`establishment_id`).
5. **Reservas (Bookings):** Toda reserva en B2C requiere obligatoriamente un `provider_id` y un `service_id`. Pre-Nodo 01 desconoce completamente la entidad `establishments`.

---

## 2. EVIDENCE BOUNDARY

### Fuentes Físicas Auditadas:
- **Esquema Base e Invariantes:** [`backend/init.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/init.sql) (Tablas `usuarios`, `perfiles_prestador`, `services`, `bookings`, `reviews`, `portfolio_items`).
- **SaaS Foundation:** [`backend/migrations/065_saas_foundation_core.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/065_saas_foundation_core.sql) (Tablas `tenants`, `organizations`, `establishments`, `memberships`).
- **Modelos Sequelize:** [`backend/src/models/index.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/models/index.js) (`Service.belongsTo(User, { foreignKey: 'provider_id' })`, `Booking.belongsTo(Service)`).
- **Controladores B2C:**
  - [`backend/src/controllers/serviceController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/serviceController.js)
  - [`backend/src/controllers/providerController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/providerController.js)
  - [`backend/src/controllers/bookingController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/bookingController.js)
- **Contratos NCP:** `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` y `HUB-SALON-NODE-CONTRACT-v1.0.md`.

---

## 3. PROVIDER IDENTITY ANALYSIS (PB-Q01)

Condiciones físicas requeridas para que un `usuarios.id` sea tratado como Provider B2C:

| Elemento Físico | Evidencia en Código / BD | Clasificación | Justificación |
| :--- | :--- | :---: | :--- |
| **`usuarios.id`** | PK en `usuarios` | **REQUIRED** | Identidad base global. |
| **`perfiles_prestador`** | Registro con `id = usuarios.id` | **REQUIRED** | Almacena coordenadas, reputación y horarios. |
| **`estatus_verificacion`** | `providerController.js` L50 | **REQUIRED** | Filtra `estatus_verificacion = 'APROBADO'`. |
| **`usuarios.rol`** | `serviceController.js` L7 | **REQUIRED** | Controladores exigen `rol IN ('provider', 'PRESTADOR')`. |
| **`is_active = true`** | `providerController.js` L50 | **REQUIRED** | Condición para figurar en búsquedas PostGIS. |
| **`ubicacion` (PostGIS)** | `providerController.js` L51 | **REQUIRED** | Cálculo de distancia con `ST_DWithin`. |

---

## 4. PROFESSIONAL PROFILE REQUIREMENTS (PB-Q02)

Desglose de campos de `perfiles_prestador`:

```text
IDENTIDAD        → id (INTEGER PK REFERENCES usuarios.id) [REQUIRED]
VERIFICACIÓN     → estatus_verificacion ('APROBADO') [REQUIRED]
                   documento_id_url, rut_url, certificacion_url [OPTIONAL]
UBICACIÓN        → ubicacion (GEOGRAPHY Point 4326) [REQUIRED para búsquedas]
HORARIOS         → active_start_hour, active_end_hour, weekly_schedule [REQUIRED para slots]
DATOS COMERC.    → business_name, description, portafolio_servicios [OPTIONAL / INFORMATIVO]
ESTADO           → is_active (TRUE) [REQUIRED], is_online (BOOLEAN) [OPTIONAL]
FINTECH / RETIRO → metodo_retiro, numero_cuenta_nequi, documento_titular [OPTIONAL en catálogo / REQUIRED en dispersión]
```

---

## 5. MEMBERSHIP → PROVIDER RELATIONSHIP (PB-Q03)

```text
┌─────────────────┐       user_id       ┌─────────────────┐          id         ┌─────────────────────┐
│   memberships   │ ──────────────────> │    usuarios     │ <────────────────── │ perfiles_prestador  │
│  (Plano SaaS)   │                     │  (Identidad)    │                     │    (Plano B2C)      │
└─────────────────┘                     └─────────────────┘                     └─────────────────────┘
```

* **Relación física directa `memberships → perfiles_prestador`:** **`NONE`** (0 FKs, 0 columnas).
* **Relación física indirecta:** `memberships.user_id = usuarios.id = perfiles_prestador.id`.
* **Conclusión:** Las membresías vinculan usuarios a sedes físicas; los perfiles de prestador dotan a un usuario de capacidades operativas B2C.

---

## 6. ROLE → PROVIDER ANALYSIS (PB-Q04)

| Rol Contextual SaaS | ¿Es Provider B2C? | Clasificación | Fundamento Técnico |
| :--- | :---: | :---: | :--- |
| **`OWNER`** | No necesariamente | **`CONDITIONAL`** | Puede ser socio capitalista/administrativo. Solo es Provider si posee especialidad técnica y perfil activo. |
| **`MANAGER`** | No necesariamente | **`CONDITIONAL`** | Administrador de sede. Solo es Provider si atiende servicios prácticos de belleza. |
| **`PROFESSIONAL`** | Potencial natural | **`YES (CONDICIONAL)`** | Diseñado para ejecutar servicios. Requiere instanciación/aprobación de `perfiles_prestador`. |
| **`RECEPTIONIST`** | Nunca | **`NO`** | Personal de atención, recepción y caja. No ejecuta procedimientos técnicos de belleza. |

---

## 7. SERVICE → PROVIDER RELATIONSHIP (PB-Q05)

* **Clave Foránea:** `services.provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id) ON DELETE CASCADE`.
* **Cardinalidad Física:** **1 a 1** estricto (`1 servicio` pertenece exactamente a `1 prestador`).
* **Multi-Provider:** El modelo B2C **NO permite que un servicio pertenezca a N prestadores simultáneamente**.
* **Restricciones:** No existen tablas asociativas `service_providers` ni campos de arreglo en `services`.

---

## 8. SERVICE → ESTABLISHMENT RELATIONSHIP (PB-Q06)

* **Relación Directa (`services → establishments`):** **`NONE`** (No existe `establishment_id` en `public.services`).
* **Relación Indirecta (`services → provider → establishment`):** **`NONE`** (`perfiles_prestador` no referencia a `establishments`).
* **Conclusión:** En la base de datos física actual, un servicio B2C **desconoce totalmente la existencia de sedes físicas u organizaciones**.

---

## 9. PROVIDER → ESTABLISHMENT RELATIONSHIP (PB-Q07)

* **Clasificación:** **`NONE`** (en el plano B2C).
* En Pre-Nodo 01, el prestador opera como un profesional autónomo geolocalizado en un punto PostGIS individual (`perfiles_prestador.ubicacion`). La pertenencia a una sede solo existe en el plano SaaS mediante `memberships.establishment_id`.

---

## 10. BOOKING DEPENDENCY ANALYSIS (PB-Q08)

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        TABLA PUBLIC.BOOKINGS                           │
├──────────────────────┬──────────────────────┬──────────────────────────┤
│ Campo FK             │ Referencia           │ Restricción              │
├──────────────────────┼──────────────────────┼──────────────────────────┤
│ client_id            │ usuarios(id)         │ NOT NULL, ON DELETE RESTRICT│
│ provider_id          │ perfiles_prestador(id)│ NOT NULL, ON DELETE RESTRICT│
│ service_id           │ services(id)         │ NOT NULL, ON DELETE RESTRICT│
│ scheduled_at         │ TIMESTAMPTZ          │ NOT NULL                 │
└──────────────────────┴──────────────────────┴──────────────────────────┘
```

1. ¿Booking requiere Provider? $\rightarrow$ **SÍ** (`NOT NULL`).
2. ¿Booking requiere Service? $\rightarrow$ **SÍ** (`NOT NULL`).
3. ¿Booking requiere Establishment? $\rightarrow$ **NO** (Inexistente en la tabla).
4. ¿Booking puede existir sin Provider? $\rightarrow$ **NO** (Error de BD `23502`).
5. ¿Booking puede existir sin Service? $\rightarrow$ **NO** (Error de BD `23502`).

---

## 11. MULTI-PROFESSIONAL SCENARIO (PB-Q09)

* **Escenario:** Sede cuenta con `Profesional A`, `Profesional B` y `Profesional C`, y los 3 realizan `Corte de Cabello`.
* **Comportamiento en Pre-Nodo 01:**
  - No existe el concepto de "Servicio de Sede con asignación dinámica de staff".
  - Para soportar este escenario en el modelo actual sin tocar esquemas protegidos, deben existir **3 filas independientes** en `public.services`:
    1. `services` (id: 1, provider_id: A, name: 'Corte de Cabello')
    2. `services` (id: 2, provider_id: B, name: 'Corte de Cabello')
    3. `services` (id: 3, provider_id: C, name: 'Corte de Cabello')
  - El cliente B2C reserva directamente con el profesional seleccionado.

---

## 12. SAAS → PROVIDER INFORMATION GAP (PB-Q10)

| Información Plano SaaS | Entidad/Campo en B2C | Disponible en Context Package | Brecha / Falta en B2C |
| :--- | :--- | :---: | :--- |
| **Identidad** | `usuarios.id` | **SÍ** (`identity.id`, `people_initial_roles.user_id`) | Ninguna |
| **Membresía** | No existe en B2C | **SÍ** (`people_initial_roles.membership_id`) | Desacoplado |
| **Rol Contextual** | `usuarios.rol` | **SÍ** (`people_initial_roles.role`) | Mapeo a `'PRESTADOR'` |
| **Capacidad Técnica** | `services` / categorías | **SÍ** (`assigned_categories`) | Instanciación física |
| **Verificación** | `estatus_verificacion` | **NO** (Validado en SaaS) | Registro en `perfiles_prestador` |
| **Ubicación** | `perfiles_prestador.ubicacion` | **SÍ** (`establishments.location` / address) | Inyección de Point PostGIS |
| **Horarios** | `weekly_schedule` | **SÍ** (`establishments.operating_hours`) | Inyección en perfil |
| **Vínculo con Sede** | No existe en B2C | **SÍ** (`establishments.id`) | Inexistente en B2C |

---

## 13. SAAS SERVICE → B2C SERVICE MAPPING (PB-Q11)

Mapeo de atributos de `relevant_services` a `public.services`:

| Atributo `relevant_services` | Columna `public.services` | Clasificación de Mapeo |
| :--- | :--- | :---: |
| `name` | `name` | **`DIRECT`** |
| `description` | `description` | **`DIRECT`** |
| `price` | `price` | **`DIRECT`** |
| `duration_minutes` | `duration_minutes` | **`DIRECT`** |
| `category` | `category` | **`DIRECT`** |
| *(Catálogo de Sede)* | `provider_id` | **`MISSING`** (Requiere vincular a un `user_id` de staff) |
| *(Por defecto)* | `is_active = true` | **`DIRECT`** |

---

## 14. HECHOS CONFIRMADOS (CONFIRMED FACTS)

1. `Pre-Nodo 01` exige que todo servicio pertenezca a un `provider_id` individual en `perfiles_prestador`.
2. Las tablas B2C (`services`, `bookings`, `perfiles_prestador`) no poseen columnas de `establishment_id` ni `tenant_id`.
3. `memberships` es la única entidad que relaciona formalmente a una persona con una sede en el plano SaaS.
4. El rol `RECEPTIONIST` no puede ser convertido en Provider B2C.

---

## 15. INCÓGNITAS (UNKNOWNS)

1. ¿Si un salón se aprovisiona inicialmente sin colaboradores (`people_initial_roles` solo contiene al Owner), debe crearse el catálogo B2C bajo el `user_id` del Owner?
2. ¿Cómo se sincronizan las coordenadas de la sede con el perfil individual del prestador si este no tenía ubicación previa?

---

## 16. BRECHAS ARQUITECTÓNICAS (ARCHITECTURAL GAPS)

1. **Brecha de Cardinalidad de Catálogo:** Discrepancia entre catálogo 1-a-N por sede (SaaS) y catálogo 1-a-1 por prestador (B2C).
2. **Brecha de Creación de Perfil:** Un usuario con membresía `PROFESSIONAL` no tiene automáticamente una fila en `perfiles_prestador`.
3. **Brecha de Disponibilidad:** La disponibilidad de slots en B2C se calcula por prestador (`perfiles_prestador`), mientras que en SaaS los horarios pertenecen al establecimiento (`establishments.operating_hours`).

---

## 17. DECISION GATES (ARCHITECTURAL STOP)

### DEC-PB-001 — POLÍTICA DE INSTANCIACIÓN DE PERFIL B2C PARA STAFF SAAS
```text
================================================================================
                              ARCHITECTURAL_STOP 🔴
================================================================================
GOAL ID           : PROVIDER-BRIDGE-SEMANTIC-DISCOVERY-v1.0
NODE ID           : SAAS-TO-B2C-PROVIDER-BRIDGE
AGENTE EMISOR     : DISCOVERY_ENGINE
--------------------------------------------------------------------------------
1. PROBLEMA       : Un miembro de staff en people_initial_roles puede no tener
                    un registro en perfiles_prestador en Pre-Nodo 01.
2. EVIDENCIA      : services.provider_id exige FK a perfiles_prestador(id).
3. IMPACTO        : Si no existe el perfil, no se pueden crear los servicios en B2C.
4. OPCIONES       : 
   A) Auto-Provisioning de Perfil: Durante la ingestión, si el colaborador no tiene perfiles_prestador, se crea automáticamente heredando la ubicación y horarios de la sede.
   B) Host Fallback: Los servicios se crean bajo el perfil del Owner/Manager si los profesionales no tienen perfil B2C.
5. RECOMENDACIÓN  : Opción A (Auto-Provisioning de Perfil de Prestador) [PROPUESTA — NO APROBADA].
6. DECISIÓN REQ.  : Director debe autorizar si la ingestión puede crear perfiles_prestador.
================================================================================
```

### DEC-PB-002 — POLÍTICA DE DUPLICACIÓN DE CATÁLOGO MULTI-PROFESIONAL
```text
================================================================================
                              ARCHITECTURAL_STOP 🔴
================================================================================
GOAL ID           : PROVIDER-BRIDGE-SEMANTIC-DISCOVERY-v1.0
NODE ID           : SAAS-TO-B2C-PROVIDER-BRIDGE
AGENTE EMISOR     : DISCOVERY_ENGINE
--------------------------------------------------------------------------------
1. PROBLEMA       : Varios miembros pueden ejecutar el mismo servicio de sede.
2. EVIDENCIA      : public.services solo admite un provider_id por fila.
3. IMPACTO        : Define la cantidad de filas creadas en public.services.
4. OPCIONES       : 
   A) Multi-Row Instantiation: Crear una fila en services por cada profesional asignado a la categoría del servicio.
   B) Single Host Instantiation: Crear una sola fila por servicio asociada al Owner/Manager de la sede.
5. RECOMENDACIÓN  : Opción A [PROPUESTA — NO APROBADA].
6. DECISIÓN REQ.  : Director debe resolver la política de instanciación en public.services.
================================================================================
```

---

## 18. CONCLUSIÓN ARQUITECTÓNICA (PB-Q12)

Con base en la evidencia física analizada:

> **Declaración Canónica:**  
> **`SaaS Membership` y `B2C Provider` son conceptos independientes pertenecientes a dominios desacoplados. Una identidad con membresía `PROFESSIONAL` (u `OWNER`/`MANAGER` con asignación técnica) puede convertirse condicionalmente en un `B2C Provider` únicamente mediante la instanciación de un perfil profesional operativo (`perfiles_prestador`) que herede la ubicación y horarios de la sede física.**

---

## 19. ACTIVOS PROTEGIDOS E INTEGRIDAD GIT

- **Activos Protegidos:** `Foundation v1.0`, `Context Resolution v1.0`, `Active Context v1.0`, `Hub Salón v1.0`, `Crear Desde Cero v1.0`, `Pre-Nodo 01`, `SOUL`, `Governance`, `NCP Core` permanecen **100% INTACTOS**.
- **Integridad Git:**
  - `0 runtime modifications`
  - `0 database modifications`
  - `0 migrations`
  - `0 protected asset modifications`
  - Único archivo creado: Este informe documental.

---

## 20. TABLA FINAL OBLIGATORIA

| Concepto | Evidencia Física | Relación Actual | Estado | Decisión Necesaria |
| :--- | :--- | :--- | :---: | :---: |
| **SaaS Identity** | `usuarios.id` | Base común de identidad | **COMPATIBLE** | Ninguna |
| **Membership** | `memberships` (SaaS) | Vínculo Usuario $\leftrightarrow$ Sede | **DESACOPLADO DE B2C** | Ninguna |
| **Professional** | `memberships.role = 'PROFESSIONAL'` | Rol técnico de staff | **CONVERSIÓN CONDICIONAL** | `DEC-PB-001` |
| **B2C Provider** | `perfiles_prestador` | Ente transaccional B2C | **REQUIERE PERFIL ACTIVO** | `DEC-PB-001` |
| **Provider Profile** | `perfiles_prestador` | Almacena GPS, slots, reputación | **INDEPENDIENTE DE SEDE** | `DEC-PB-001` |
| **Establishment** | `establishments` | Sede física multitenant | **INEXISTENTE EN B2C** | Futuro Nodo 01 |
| **Service** | `public.services` | 1-a-1 con `provider_id` | **BRECHA DE CARDINALIDAD** | `DEC-PB-002` |
| **Booking** | `public.bookings` | Requiere `provider_id` y `service_id` | **OPERATIVO EN B2C** | Ninguna |

---

## 21. ESTADO FINAL

```text
================================================================================
ESTADO:
DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡
================================================================================
```
