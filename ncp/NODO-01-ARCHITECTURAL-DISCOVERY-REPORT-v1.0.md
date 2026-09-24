# NODO 01 — ARCHITECTURAL DISCOVERY REPORT v1.0
## Responsabilidad, Límites de Ingestión y Modelo Físico Downstream

**Versión:** 1.0.0 (Reconciled)  
**Fecha:** 2026-09-10  
**Estado:** RECONCILIATION COMPLETE / PENDING DIRECTOR ARCHITECTURAL DECISION 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Read-Only Architectural Discovery & Reconciled Evidence Audit  

---

## 1. EXECUTIVE SUMMARY

El presente informe constituye la **Reconciliación Arquitectónica del Discovery de NODO 01**, enfocado en clasificar rigurosamente la evidencia física y separar:
- **FACT (Hecho Demostrado):** Observaciones verificables directamente en código, base de datos y contratos cerrados.
- **INFERENCE (Inferencia Válida):** Conclusiones lógicas directas derivadas de hechos demostrados.
- **PROPOSAL (Propuesta No Aprobada):** Alternativas de diseño y materialización que requieren decisión arquitectónica posterior.

### Síntesis Reconciliada:
1. **[FACT]** NODO 01 **no existe actualmente como componente físico en el repositorio**.
2. **[FACT]** Pre-Nodo 01 está físicamente centrado en el **prestador individual** (`usuarios` + `perfiles_prestador` + `services.provider_id` + `bookings.provider_id`).
3. **[FACT]** Pre-Nodo 01 **no posee actualmente una frontera de ingestión** formal desde SaaS.
4. **[FACT]** `HANDOVER-BOUNDARY-CONTRACT-v1.0` entrega **Contexto SaaS + Intención Operativa Declarada**, con `service_offers` a nivel de establecimiento, `assignment = NOT_ESTABLISHED` y sin `provider_id`.
5. **[FACT]** Existe una incompatibilidad entre el catálogo de establecimiento de SaaS y la restricción física `provider_id NOT NULL` en `public.services` de B2C.
6. **[INFERENCE]** Para materializar directamente el Handover sobre el modelo B2C actual, alguna capa downstream tendría que resolver las incompatibilidades demostradas.
7. **[PROPOSAL — NOT APPROVED]** La propuesta de que esa capa deba ser formalmente un "Provisioning Engine" denominado Nodo 01 que duplique servicios, copie horarios o inserte perfiles de prestador, constituye una alternativa de diseño sujeta a la decisión formal del Director.

---

## 2. EVIDENCE SCOPE

### Fuentes Físicas Auditadas:
- **Core B2C (Pre-Nodo 01):**
  - `backend/init.sql` (`usuarios`, `perfiles_prestador`, `services`, `bookings`, `reviews`, `portfolio_items`).
  - `backend/src/controllers/providerController.js` (Búsquedas PostGIS `ST_DWithin`, cálculo de slots `getAvailableSlots`).
  - `backend/src/controllers/serviceController.js` (CRUD de servicios acoplado a `req.user.id`).
  - `backend/src/controllers/bookingController.js` (Validación transaccional de reservas y comprobación de `provider_id`).
  - `backend/src/controllers/authController.js` (Registro y perfiles base).
- **Contratos y Descubrimientos Previos:**
  - `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`
  - `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`
  - `HANDOVER-SEMANTIC-RECONCILIATION-v1.0.md`
  - `SERVICE-EXECUTION-SEMANTIC-DISCOVERY-REPORT-v1.0.md`
  - `SERVICE-EXECUTION-SEMANTIC-MODEL-DISCOVERY-REPORT-v1.0.md`

---

## 3. RESPUESTAS A PREGUNTAS CANÓNICAS (N01-Q01 → N01-Q10)

### N01-Q01 — ¿Existe actualmente NODO 01 como componente físico?
* **Evidencia:** Inspección exhaustiva de directorios `backend/src/controllers`, `backend/src/services`, `backend/src/routes`, `backend/src/middleware` y `backend/index.js`.
* **Hecho Observable:** No existe ningún archivo, módulo, servicio, controlador, ruta ni proceso denominado `nodo01`, `ingestion`, `provisioning` o `bridge`.
* **Clasificación:** **`FACT — DEMONSTRATED`**. NODO 01 no existe como componente físico en el repositorio.

---

### N01-Q02 — ¿Cuál es la unidad funcional real que opera Pre-Nodo 01?
* **Evidencia:**
  - `usuarios` (`init.sql` L43): Individuo humano (`id SERIAL PRIMARY KEY`).
  - `perfiles_prestador` (`init.sql` L60): Perfil B2C (`id INTEGER PRIMARY KEY REFERENCES usuarios(id)`) con `ubicacion` (Point 4326), `weekly_schedule` (JSONB) y `estatus_verificacion`.
  - `services` (`init.sql` L93): Catálogo dependiente de `provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id)`.
  - `bookings` (`init.sql` L109): Transacción que vincula `client_id`, `provider_id`, `service_id` y `scheduled_at`.
  - `Disponibilidad`: `providerController.js` L213 (`getAvailableSlots`) calcula slots evaluando el `weekly_schedule` del prestador individual contra sus `bookings`.
* **Clasificación:** **`FACT — DEMONSTRATED`**. La unidad funcional de Pre-Nodo 01 es el **`PROVIDER INDIVIDUAL`** (`perfiles_prestador.id == usuarios.id`). No existe entidad física de establecimiento en Pre-Nodo 01.

---

### N01-Q03 — ¿Existe actualmente una frontera de ingestión?
* **Evidencia:**
  - `serviceController.js` L34: La creación de servicios requiere sesión interactiva con rol prestador y asigna unívocamente `provider_id = req.user.id`.
  - `authController.js`: Los perfiles de prestador se crean manualmente durante el onboarding de usuario individual.
  - No existen endpoints, mappers, colas o listeners que reciban DTOs externos para aprovisionar prestadores o servicios.
* **Clasificación:** **`FACT — DEMONSTRATED`**. No existe actualmente ninguna frontera de ingestión implementada en Pre-Nodo 01.

---

### N01-Q04 — ¿Qué necesita físicamente el B2C para operar?

| Entidad / Función | Requisitos Físicos en Esquema y Código | Clasificación |
| :--- | :--- | :---: |
| **1. Provider Operativo** | - `usuarios.id` con rol `PRESTADOR`<br>- `perfiles_prestador.id = usuarios.id`<br>- `estatus_verificacion = 'APROBADO'` y `is_active = true`<br>- `ubicacion` (Point 4326) para búsquedas PostGIS<br>- `weekly_schedule` (JSONB) para cálculo de turnos | **REQUIRED** |
| | - `business_name`, `description`, `foto_url` | **OPTIONAL** |
| | - `rating_avg`, `rating_count`, `loyalty_tier` | **DERIVABLE** |
| **2. Service Operativo** | - `provider_id` apuntando a `perfiles_prestador.id`<br>- `name`, `price >= 0`, `duration_minutes > 0`<br>- `is_active = true` | **REQUIRED** |
| | - `category`, `description` | **OPTIONAL** |
| **3. Disponibilidad (Slots)**| - `perfiles_prestador.weekly_schedule`<br>- `services.duration_minutes`<br>- Exclusión de colisiones con `bookings` existentes | **REQUIRED**<br>**REQUIRED**<br>**COMPUTED** |
| **4. Booking** | - `client_id` (`usuarios.id`)<br>- `provider_id` (`perfiles_prestador.id`)<br>- `service_id` (`services.id`)<br>- `scheduled_at` y `service_address` | **REQUIRED** |
| | - `total_amount`, `comision_plataforma`, `pago_neto` | **DERIVABLE** |
| **5. Ejecución** | - `pin_verificacion` de 4 dígitos y confirmación de llegada/finalización | **REQUIRED (Runtime)** |

* **Clasificación:** **`FACT — DEMONSTRATED`**.

---

### N01-Q05 — ¿Qué puede recibir directamente del Handover Contract?

| Bloque del Handover DTO v1.0 | Compatibilidad con Pre-Nodo 01 | Justificación Técnica basada en Evidencia |
| :--- | :---: | :--- |
| **`establishment_context`** | **REQUIRES TRANSFORMATION** | Pre-Nodo 01 no tiene tabla `establishments`. `location` y `operating_hours` son de sede en SaaS, pero Pre-Nodo 01 los requiere en `perfiles_prestador`. |
| **`professional_context`** | **REQUIRES TRANSFORMATION** | `user_id` coincide con `usuarios.id`, pero Pre-Nodo 01 requiere que exista la fila correspondiente en `perfiles_prestador` con estado `APROBADO`. |
| **`service_offers`** | **REQUIRES TRANSFORMATION** | `name`, `price`, `duration_minutes`, `category` coinciden con columnas de `services`, pero **falta `provider_id NOT NULL`**. |
| **`authorizing_identity`** | **NOT REQUIRED / INFORMATIONAL** | Pre-Nodo 01 no almacena identidades de auditoría B2B. |
| **`assignment` (`NOT_ESTABLISHED`)**| **REQUIRES TRANSFORMATION / DECISION** | Pre-Nodo 01 no admite servicios sin prestador asignado (`provider_id NOT NULL`). |
| **`source_state`** | **NOT REQUIRED** | Pre-Nodo 01 no evalúa estados de ciclo de vida de SaaS. |

* **Clasificación:** **`FACT — DEMONSTRATED`**.

---

### N01-Q06 — ¿Dónde aparece exactamente el primer conflicto semántico?
* **Ubicación Exacta del Conflicto:** 
  - **SaaS:** La oferta de catálogo (`service_offers`) pertenece al **`ESTABLECIMIENTO`** y la asignación a personal está formalmente en **`NOT_ESTABLISHED`**.
  - **B2C (Pre-Nodo 01):** La tabla `public.services` contiene una restricción `provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id)`.
* **Hecho Observable:** En Pre-Nodo 01 no existe el concepto de "servicio de establecimiento". Un servicio solo puede existir si pertenece unívocamente a un prestador individual.
* **Clasificación:** **`FACT — DEMONSTRATED`**.

---

### N01-Q07 — Evaluación de Decisiones DEC-SE-001 y DEC-SE-002
* **[FACT]** `DEC-SE-001` (Estrategia de instanciación en `public.services`) y `DEC-SE-002` (Sincronización de ubicación/horarios en `perfiles_prestador`) permanecen **`PENDING`**.
* **[FACT]** Ambas decisiones afectan la eventual materialización física sobre el modelo B2C actual.
* **[INFERENCE]** Son potencialmente bloqueantes para especificar cualquier estrategia de materialización física que dependa del modelo B2C actual.
* **[INFERENCE]** La arquitectura de Nodo 01 puede continuar definiéndose conceptualmente a nivel de responsabilidad, frontera, validación y contrato sin aprobar todavía una estrategia concreta de persistencia física.

---

### N01-Q08 — Responsabilidad de Materialización Downstream
* **[FACT]** Existe una brecha estructural entre el Handover semántico (catálogo de sede sin asignación) y el modelo físico B2C (`services` vinculados a `provider_id`).
* **[INFERENCE]** Para materializar directamente el Handover sobre el modelo B2C actual, alguna capa downstream tendría que resolver las incompatibilidades demostradas.
* **[PROPOSAL — NOT APPROVED]** Que dicha capa downstream sea formalmente Nodo 01 implementando creación automática de perfiles, duplicación de servicios o sincronización forzada de horarios, constituye una propuesta de diseño sujeta a decisión del Director.

---

### N01-Q09 — Límites del Handover Boundary
* **[FACT]** `HANDOVER-BOUNDARY-CONTRACT-v1.0` es independiente del mecanismo de transporte y de la persistencia física downstream.
* **[FACT]** El modelo B2C actual necesita transformación para materializar determinados bloques del Handover.
* **[INFERENCE]** Una capa downstream deberá resolver esa transformación si se decide la materialización física.
* **[PROPOSAL — NOT APPROVED]** La delimitación interna exacta de los componentes de Nodo 01 permanece como propuesta de diseño.

---

### N01-Q10 — Viabilidad del Node Contract de Nodo 01
* **Respuesta Reconciliada:** **`PARTIAL`**.
* **Fundamentación:**
  - El contexto arquitectónico está completamente demostrado (`FACT`).
  - La frontera semántica de entrada está formalizada y cerrada en `HBC v1.0` (`FACT`).
  - El conflicto físico con el modelo B2C está demostrado (`FACT`).
  - **Falta por definir:** La responsabilidad física exacta de Nodo 01 y su estrategia de materialización downstream aún no han sido aprobadas por el Director (`DEC-SE-001`, `DEC-SE-002`).

---

## 4. PHYSICAL EVIDENCE SUMMARY

```text
┌─────────────────────────┬───────────────────────────────┬──────────────────────────────────────┐
│ Entidad / Archivo       │ Ubicación / Código            │ Hecho Físico Observable              │
├─────────────────────────┼───────────────────────────────┼──────────────────────────────────────┤
│ perfiles_prestador      │ backend/init.sql:L60          │ PK id REFERENCES usuarios(id).       │
│                         │                               │ 1 sola ubicacion, 1 weekly_schedule. │
├─────────────────────────┼───────────────────────────────┼──────────────────────────────────────┤
│ public.services         │ backend/init.sql:L93          │ provider_id INTEGER NOT NULL.        │
│                         │                               │ No existe establishment_id.          │
├─────────────────────────┼───────────────────────────────┼──────────────────────────────────────┤
│ providerController.js   │ backend/src/controllers/:L51  │ ST_DWithin requiere ubicacion Point. │
│                         │ backend/src/controllers/:L213 │ Slots calculados de weekly_schedule. │
├─────────────────────────┼───────────────────────────────┼──────────────────────────────────────┤
│ serviceController.js    │ backend/src/controllers/:L57  │ createService asigna req.user.id.    │
├─────────────────────────┼───────────────────────────────┼──────────────────────────────────────┤
│ bookingController.js    │ backend/src/controllers/:L60  │ Valida services WHERE provider_id.   │
└─────────────────────────┴───────────────────────────────┴──────────────────────────────────────┘
```

---

## 5. SEMANTIC BOUNDARY FINDINGS

```text
PLANO SAAS (Contexto Multitenant)            PLANO B2C (Pre-Nodo 01 Monolítico)
┌─────────────────────────────────┐          ┌──────────────────────────────────┐
│ Sede: establishments            │          │ Prestador: perfiles_prestador    │
│ - Ubicación Sede (Point)        │ ──(DTO)─►│ - Ubicación Prestador (Point)    │
│ - Horario Sede (JSONB)          │          │ - Horario Prestador (JSONB)      │
│                                 │          │                                  │
│ Catálogo: relevant_services     │          │ Catálogo: public.services        │
│ - Catálogo a nivel de Sede      │ ──(DTO)─►│ - Catálogo con provider_id NOT NULL
│ - assignment = NOT_ESTABLISHED  │          │                                  │
│                                 │          │ Transacciones: public.bookings   │
│ Personal: memberships           │ ──(DTO)─►│ - Requiere provider_id individual│
│ - capabilities (categorías)     │          │ - Requiere client_id             │
└─────────────────────────────────┘          └──────────────────────────────────┘
                 │                                            ▲
                 └───────────► [ CAPA DOWNSTREAM ] ───────────┘
```

---

## 6. FACT / INFERENCE / PROPOSAL MATRIX

| Hallazgo / Elemento | Clasificación | Estado de Validación |
| :--- | :---: | :---: |
| Nodo 01 no existe físicamente en el repositorio | **FACT** | **DEMONSTRATED** |
| Pre-Nodo 01 está centrado en Provider individual | **FACT** | **DEMONSTRATED** |
| No existe frontera de ingestión actual en Pre-Nodo 01 | **FACT** | **DEMONSTRATED** |
| `service_offers` pertenece semánticamente al establecimiento | **FACT** | **CONTRACTED** |
| `service_offers` no tiene `provider_id` | **FACT** | **CONTRACTED** |
| `assignment` = `NOT_ESTABLISHED` | **FACT** | **CONTRACTED** |
| `capabilities` NO constituye `Assignment` | **FACT** | **CONTRACTED** |
| `category matching` NO constituye `Assignment` | **FACT** | **CONTRACTED** |
| B2C físico requiere `provider_id` para persistir `services` | **FACT** | **DEMONSTRATED** |
| Pre-Nodo 01 mantiene ubicación y horarios en `perfiles_prestador` | **FACT** | **DEMONSTRATED** |
| Existe incompatibilidad de materialización directa | **FACT** | **DEMONSTRATED** |
| Alguna capa downstream deberá resolver la incompatibilidad si se materializa | **INFERENCE** | **VALID INFERENCE** |
| Nodo 01 debe ser esa capa | **PROPOSAL** | **NOT APPROVED** |
| Nodo 01 debe crear `perfiles_prestador` automáticamente | **PROPOSAL** | **NOT APPROVED** |
| Nodo 01 debe duplicar `services` por colaborador | **PROPOSAL** | **NOT APPROVED** |
| Nodo 01 debe copiar horarios/ubicación de sede a colaboradores | **PROPOSAL** | **NOT APPROVED** |
| `DEC-SE-001` (Estrategia de instanciación de servicios) | **DECISION** | **PENDING** |
| `DEC-SE-002` (Sincronización de ubicación y horarios) | **DECISION** | **PENDING** |

---

## 7. DEC-SE-001 ASSESSMENT (INSTANCIACIÓN DE SERVICIOS)

- **Problema:** `service_offers` no tiene `provider_id`, pero `public.services` exige `provider_id NOT NULL`.
- **Evidencia Física:** `backend/init.sql:L93`, `backend/src/controllers/serviceController.js:L57`.
- **Impacto:** Para persistir servicios sobre el esquema B2C actual, se requiere una regla de asignación de `provider_id`.
- **Alternativas Bajo Análisis:**
  - *Opción A (Duplicación por Staff con Capability coincidente):* Instanciar una fila en `public.services` por cada colaborador que declare la categoría.
  - *Opción B (Host Delegado / Owner Central):* Instanciar los servicios bajo el `provider_id` del Owner/Manager.
- **Estado:** **`PENDING DIRECTOR DECISION`** (Ninguna opción queda seleccionada ni aprobada en este Discovery).

---

## 8. DEC-SE-002 ASSESSMENT (UBICACIÓN Y HORARIOS)

- **Problema:** La sede tiene su `location` y `operating_hours`, pero Pre-Nodo 01 solo lee `perfiles_prestador.ubicacion` y `perfiles_prestador.weekly_schedule`.
- **Evidencia Física:** `backend/src/controllers/providerController.js:L51, L213`.
- **Impacto:** Para habilitar búsquedas geográficas y turnos en B2C, `perfiles_prestador` requiere coordenadas y horarios.
- **Alternativas Bajo Análisis:**
  - *Opción A (Copia Directa):* Sobreescribir `ubicacion` y `weekly_schedule` en `perfiles_prestador` con los datos de la sede.
  - *Opción B (Copia Condicional):* Copiar únicamente si los campos del prestador son nulos.
- **Estado:** **`PENDING DIRECTOR DECISION`** (Ninguna opción queda seleccionada ni aprobada en este Discovery).

---

## 9. CONCLUSIÓN ARQUITECTÓNICA FUNDAMENTAL

El Discovery demuestra la existencia de una frontera semántica entre el modelo SaaS de establecimiento y el modelo B2C de prestador individual.

También demuestra que el modelo B2C actual no puede materializar directamente determinadas partes del Handover sin resolver relaciones que actualmente no existen en B2C.

No queda demostrado todavía que la solución deba ser un determinado mecanismo de provisioning, duplicación, sincronización o persistencia.

Por tanto, el Discovery es suficiente para definir la frontera arquitectónica de Nodo 01, pero no para aprobar todavía su mecanismo físico de materialización.

`DEC-SE-001` y `DEC-SE-002` permanecen **`PENDING`**.

---

## 10. ACTIVOS PROTEGIDOS

Se certifica que la reconciliación documental preserva la integridad absoluta de:
1. **Foundation v1.0**
2. **Context Resolution v1.0**
3. **Active Context v1.0**
4. **Hub Salón v1.0**
5. **Crear Desde Cero v1.0**
6. **Handover Boundary Contract v1.0**
7. **Pre-Nodo 01**
8. **SOUL**
9. **Governance & NCP Core**

---

## 11. GIT SCOPE

Ejecución de `git status --short`:
```text
 M backend/docker-compose.yml
 M backend/index.js
 M backend/init.sql
?? backend/migrations/065_saas_foundation_core.sql
?? backend/migrations/066_context_resolution_tenant_resolver.sql
?? backend/src/controllers/activeContextController.js
?? backend/src/controllers/contextController.js
?? backend/src/controllers/crearDesdeCeroController.js
?? backend/src/controllers/hubSalonController.js
?? backend/src/middleware/activeContextMiddleware.js
?? backend/src/routes/activeContextRoutes.js
?? backend/src/routes/contextRoutes.js
?? backend/src/routes/crearDesdeCeroRoutes.js
?? backend/src/routes/hubSalonRoutes.js
?? backend/src/services/activeContextService.js
?? backend/src/services/contextResolutionService.js
?? backend/src/services/crearDesdeCeroService.js
?? backend/src/services/hubSalonService.js
?? backend/tests/test_active_context_controller.js
?? backend/tests/test_active_context_suite.js
?? backend/tests/test_crear_desde_cero_suite.js
?? backend/tests/test_hub_salon_suite.js
?? ncp/
```
*0 modificaciones runtime en esta meta. Único archivo modificado: `/ncp/NODO-01-ARCHITECTURAL-DISCOVERY-REPORT-v1.0.md`.*

---

## 12. ESTADO FINAL

```text
================================================================================
ESTADO FINAL:
RECONCILIATION COMPLETE / PENDING DIRECTOR ARCHITECTURAL DECISION 🟡
================================================================================
```
