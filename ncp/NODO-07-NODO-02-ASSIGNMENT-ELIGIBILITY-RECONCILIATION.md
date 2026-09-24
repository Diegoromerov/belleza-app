# NODO-07 — RECONCILIACIÓN FORENSE: ELEGIBILIDAD DE ASIGNACIONES (NODO-02 / SCR-08)
## Formal Forensic Reconciliation — Assignment Target Eligibility

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto GlowApp SaaS  
NODE IDENTIFIER: NODO-07 — RECONCILIACIÓN NODO-02 (SCR-08)  
DOCUMENT CLASSIFICATION: FORENSIC RECONCILIATION REPORT (READ-ONLY)  
DATE: 2026-09-12  
STATUS: FORENSIC RECONCILIATION COMPLETE / ARCHITECTURAL STOP / AWAITING DIRECTOR DECISION 🛑  
================================================================================

---

## 1. CONTRADICCIÓN AUDITADA

Durante el Discovery de NODO-02 UI (`NODO-07-NODO-02-UI-DISCOVERY.md`), se identificó una aparente discrepancia semántica entre la decisión fundacional **`DEC-AS-001`** y la implementación física del backend en **`serviceAssignmentService.js`**:

1. **`DEC-AS-001` (Sección 4):**
   * Expresa textualmente:
     $$	ext{SERVICE\_OFFER} \longrightarrow 	ext{PROFESSIONAL}$$
     *"vincula una oferta de servicio (SERVICE_OFFER) con un colaborador (PROFESSIONAL) con membresía en estado ACTIVE dentro del mismo ESTABLISHMENT"*.
2. **Backend Físico (`serviceAssignmentService.js:87-90`):**
   * Implementa la regla:
     ```javascript
     const ELIGIBLE_PROFESSIONAL_ROLES = ['PROFESSIONAL', 'OWNER', 'MANAGER'];
     if (!ELIGIBLE_PROFESSIONAL_ROLES.includes(targetMem.role)) {
       throw createError('INELIGIBLE_PROFESSIONAL_TARGET', 'La membresía destino no representa un contexto profesional elegible para prestar servicios.', 403);
     }
     ```
   * Permite como destinatarios de asignación a miembros activos con rol `PROFESSIONAL`, `OWNER` o `MANAGER`, excluyendo únicamente a `RECEPTIONIST`.

---

## 2. EVIDENCIA FORENSE DETALLADA

### 2.1. Evidencia en Decisiones Arquitectónicas (`ncp/`)

| Documento | Texto Contractual Exacto | Alcance y Dimensión |
| :--- | :--- | :--- |
| **`DEC-AS-001`** (Sec. 2) | `ASSIGNMENT AUTHORITY = ACTIVE USER + ACTIVE MEMBERSHIP + ROLE ∈ {'OWNER', 'MANAGER'}` | Define **quién tiene autoridad** para crear/eliminar asignaciones. |
| **`DEC-AS-001`** (Sec. 4) | `ASSIGNMENT TARGET: Vincula SERVICE_OFFER con colaborador (PROFESSIONAL)` | Define conceptualmente el **rol operativo** destinatario del servicio. |
| **`DEC-AS-006`** (Sec. 1) | `TARGET: MEMBERSHIP`<br>`TARGET CONDITION: ACTIVE PROFESSIONAL CONTEXT (membership.status = 'ACTIVE')` | Formaliza que el destino físico es la tupla `memberships`, no el usuario global. |
| **`DEC-AS-013-B`** (Sec. 2.1) | `memberships define role ('OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST')` | Catálogo canónico de los 4 roles del sistema Foundation `065`. |
| **`DEC-AS-014`** (Sec. 2) | *"vincula a una oferta de servicio (SERVICE_OFFER) con un miembro del equipo operativo (MEMBERSHIP), confiriendo la capacidad operativa para que dicho profesional preste dicho servicio en dicha sede."* | **Definición Consolidada:** Unifica que el target es un miembro del equipo operativo con capacidad técnica. |

---

### 2.2. Evidencia en Backend Físico (`backend/src/`)

* **`backend/src/services/serviceAssignmentService.js`:**
  * **Líneas 30-33 (Autoridad del Actor / Request Context):**
    ```javascript
    // RBAC Check: Only OWNER or MANAGER can create assignments
    if (!['OWNER', 'MANAGER'].includes(activeContext.role)) {
      throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'Se requiere rol OWNER o MANAGER para crear asignaciones.', 403);
    }
    ```
    $ightarrow$ **100% Cumplimiento de `DEC-AS-001` (Authority).**
  * **Líneas 62-90 (Validación del Target / Destinatario):**
    ```javascript
    // Verify Target Membership
    const targetMem = memRes.rows[0];
    if (targetMem.establishment_id !== establishmentId || targetMem.tenant_id !== tenantId) {
      throw createError('CROSS_ESTABLISHMENT_MISMATCH', '...', 422);
    }
    if (targetMem.status !== 'ACTIVE') {
      throw createError('MEMBERSHIP_NOT_ACTIVE', '...', 403);
    }
    const ELIGIBLE_PROFESSIONAL_ROLES = ['PROFESSIONAL', 'OWNER', 'MANAGER'];
    if (!ELIGIBLE_PROFESSIONAL_ROLES.includes(targetMem.role)) {
      throw createError('INELIGIBLE_PROFESSIONAL_TARGET', 'La membresía destino no representa un contexto profesional elegible para prestar servicios.', 403);
    }
    ```
    $ightarrow$ **Validación server-side estricta:** Rechaza membresías inactivas (`403`), de otras sedes (`422`) y roles no operativos como `RECEPTIONIST` (`403`).

---

### 2.3. Evidencia en Base de Datos (`backend/migrations/068_service_assignments.sql`)

* **Restricción de Integridad Referencial:**
  ```sql
  CONSTRAINT fk_service_assignments_membership 
      FOREIGN KEY (membership_id, establishment_id, tenant_id) 
      REFERENCES memberships(id, establishment_id, tenant_id) 
      ON DELETE RESTRICT,
  ```
* **Hallazgo:** La base de datos no contiene un `CHECK constraint` que limite el rol a `'PROFESSIONAL'`. Cualquier fila de `memberships` que coincida en `(id, establishment_id, tenant_id)` satisface la FK en DDL. La política de roles es gobernada en la capa de servicios (`serviceAssignmentService.js`).

---

### 2.4. Evidencia en Suites de Pruebas Backend

1. **`backend/tests/test_nodo02_runtime_suite.js`:**
   * **Test T9 (Líneas 303-317):** Ejecuta `createAssignment` exitosamente vinculando una oferta a una membresía con rol `PROFESSIONAL` (`profMembershipId`).
   * **Test T11 (Líneas 340-363):** Negative test que verifica el rechazo con `403 MEMBERSHIP_NOT_ACTIVE` cuando la membresía está en estado `SUSPENDED`.
   * **Test T15 (Líneas 399-425):** Negative test que verifica el rechazo con `422 CROSS_ESTABLISHMENT_MISMATCH` cuando la membresía pertenece a otra sede.
2. **`backend/tests/test_service_offers_and_assignments_physical_suite.js`:**
   * **Test T7 & T8:** Verifican aislamiento multi-tenant y rechazo de duplicados por clave única.

---

## 3. RESPUESTAS A LAS PREGUNTAS FORENSES DIRECTIVAS

* **A. ¿Qué roles puede recibir actualmente una assignment?**  
  `PROFESSIONAL`, `OWNER` y `MANAGER`. Excluye explícitamente a `RECEPTIONIST`.
* **B. ¿La validación ocurre server-side?**  
  Sí, ocurre dentro de una transacción PostgreSQL en `serviceAssignmentService.js:87-90`.
* **C. ¿Existe una función/helper de elegibilidad?**  
  Sí, la lista blanca `ELIGIBLE_PROFESSIONAL_ROLES = ['PROFESSIONAL', 'OWNER', 'MANAGER']`.
* **D. ¿Qué definición utiliza?**  
  Define como "contexto profesional elegible" a cualquier miembro del equipo con capacidad operativa directa para atender clientes en la sede.
* **E. ¿Existe una diferencia entre "staff elegible para sede" y "professional destinatario"?**  
  Sí:
  - *Staff de Sede:* Todo colaborador adscrito (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`).
  - *Destinatario de Asignación:* Colaborador activo con rol prestador (`PROFESSIONAL`, `OWNER`, `MANAGER`). La recepcionista no puede recibir asignaciones de servicios.
* **F. ¿Qué devuelve realmente el endpoint cuando lista staff?**  
  `GET /api/v1/saas/hub/staff` retorna todos los colaboradores con su `role`, `status` y `membership_id`.
* **G. ¿Qué role llega en el membership?**  
  Llega el enum de Foundation `065`: `'OWNER'`, `'MANAGER'`, `'PROFESSIONAL'`, `'RECEPTIONIST'`.
* **H. ¿Qué rol exige DEC-AS-001?**  
  `DEC-AS-001` exige que el **Actor con Autoridad** sea `OWNER` o `MANAGER`, y define al **Destinatario** genéricamente como `PROFESSIONAL`.

---

## 4. MATRIZ DE RECONCILIACIÓN FORENSE

| Elemento Auditado | Estado / Definición | Consistencia |
| :--- | :--- | :---: |
| **DEC-AS-001 (Actor Authority)** | `ACTIVE USER + ACTIVE MEMBERSHIP + ROLE ∈ {'OWNER', 'MANAGER'}` | **100% MATCH** |
| **DEC-AS-001 (Target Semantics)** | `SERVICE_OFFER ──► PROFESSIONAL (Active Member)` | Semántico |
| **DEC-AS-006 (Physical Target)** | `TARGET = MEMBERSHIP (status = 'ACTIVE')` | **100% MATCH** |
| **DEC-AS-014 (Consolidated Def)**| `TARGET = MEMBERSHIP (miembro del equipo operativo con capacidad)` | **100% MATCH** |
| **Backend Service Validation** | `targetMem.role ∈ {'PROFESSIONAL', 'OWNER', 'MANAGER'} ∧ status == 'ACTIVE'` | **100% MATCH** |
| **Database Schema (068)** | `FK (membership_id, establishment_id, tenant_id) REFERENCES memberships` | **100% MATCH** |
| **Backend Test Suites** | Prueba asignación a `PROFESSIONAL` y rechazo de `SUSPENDED` y cross-tenant | **100% MATCH** |
| **CONCLUSIÓN DE SÍNTESIS** | **RESULTADO C (Distinción Semántica Resuelta):** No hay contradicción real. `DEC-AS-001` utiliza el término genérico "PROFESSIONAL" para denotar la *capacidad operativa de prestación*, la cual en la realidad de los salones de belleza puede ser ejercida por un profesional contratado, o por el dueño/manager si también atiende clientes. | **PASS 🟢** |

---

## 5. IMPACTO EN NODOS POSTERIORES (NODO-03A, NODO-05, NODO-06)

1. **NODO-03A (Staff Schedules / Horarios):**  
   Permite que tanto un `PROFESSIONAL` como un `OWNER`/`MANAGER` con asignaciones configuren su horario de atención semanal en la sede (`staff_schedules`).
2. **NODO-05 (Availability Pre-Check):**  
   Al calcular slots disponibles (`nodo05AvailabilityService.js:348-356`), consulta `service_assignments` haciendo join con `memberships` donde `status = 'ACTIVE'`. Funciona de forma idéntica sin importar si el colaborador asignado es `PROFESSIONAL`, `OWNER` o `MANAGER`.
3. **NODO-06 (SaaS Internal Appointments / Citas):**  
   Al crear una cita (`nodo06AppointmentsService.js:160-179`), valida que el `membership_id` esté en `service_assignments` y `status == 'ACTIVE'`. Permite agendar citas con cualquier prestador asignado.

---

## 6. OPCIONES PARA DECISIÓN DEL DIRECTOR

```
+---------------------------------------------------------------------------------------------------+
| OPCIÓN A: RATIFICACIÓN SEMÁNTICA (RECOMENDADA)                                                    |
+---------------------------------------------------------------------------------------------------+
| Descripción:                                                                                      |
| Ratificar formalmente que "PROFESSIONAL" en DEC-AS-001 y DEC-AS-006 se refiere al                |
| "rol operativo de prestación de servicios", el cual comprende a cualquier miembro activo         |
| con rol ∈ {'PROFESSIONAL', 'OWNER', 'MANAGER'} en la sede física, excluyendo a RECEPTIONIST.     |
|                                                                                                   |
| Justificación:                                                                                    |
| - Respeta al 100% el backend existente y verificado en NODO-02, NODO-03A, NODO-05 y NODO-06.      |
| - Permite la operación real donde propietarios o administradores también realizan servicios.      |
| - CERO cambios de código backend, SQL o tests.                                                   |
+---------------------------------------------------------------------------------------------------+
```

```
+---------------------------------------------------------------------------------------------------+
| OPCIÓN B: RESTRICCIÓN ESTRICTA A ROL 'PROFESSIONAL' EXCLUSIVO                                     |
+---------------------------------------------------------------------------------------------------+
| Descripción:                                                                                      |
| Modificar el backend de NODO-02 para que targetMem.role deba ser estrictamente 'PROFESSIONAL'.   |
|                                                                                                   |
| Impacto:                                                                                          |
| - Requiere modificar serviceAssignmentService.js y suites de prueba.                              |
| - Si un Dueño o Manager corta cabello o atiende clientes, no podrá recibir asignaciones a menos  |
|   que tenga una membresía secundaria con rol PROFESSIONAL.                                        |
+---------------------------------------------------------------------------------------------------+
```

---

## 7. RECOMENDACIÓN TÉCNICA DEL AGENTE

El agente recomienda al Director aprobar la **OPCIÓN A (Ratificación Semántica)**, dado que concilia plenamente la doctrina de gobernanza (`DEC-AS-014`), la física de base de datos (`068`) y el código operativo de Nodos 02 a 06 sin introducir rupturas ni sobrecostos.

---

## 8. DECISIÓN REQUERIDA DEL DIRECTOR

* [ ] **DECISIÓN 1:** Aprobar **OPCIÓN A** (Ratificación semántica de elegibilidad `PROFESSIONAL / OWNER / MANAGER` para asignaciones) y autorizar la continuación hacia la **Arquitectura Física de NODO-02 UI (SCR-08)**.
* [ ] **DECISIÓN 2:** Instruir **OPCIÓN B** (Restricción estricta exclusiva a rol `'PROFESSIONAL'`).
* [ ] **DECISIÓN 3:** Instrucción alternativa del Director.

================================================================================
                 FIN DEL REPORTE DE RECONCILIACIÓN FORENSE
================================================================================
