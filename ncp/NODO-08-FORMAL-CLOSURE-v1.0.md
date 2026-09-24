# NODO-08 — FORMAL CLOSURE RECORD v1.0
## SaaS Service Ticket & Financial Checkout Engine

**DOCUMENTO:** `NODO-08-FORMAL-CLOSURE-v1.0`  
**ESTADO:** `PENDING FORMAL CONFIRMATION (RECONCILED)`  
**CONTRATO:** `v1.0 — RATIFIED 🔒` (`ncp/NODO-08-SAAS-SERVICE-TICKET-CHECKOUT-CONTRACT-v1.0.md`)  
**RATIFICACIÓN:** `ncp/NODO-08-FORMAL-RATIFICATION-v1.0.md`  
**MIGRACIÓN DDL:** `backend/migrations/072_saas_service_tickets.sql` (EXECUTED & PHYSICALLY VALIDATED)  
**IMPLEMENTACIÓN:** `CONFORMANT` (11 endpoints, routes, controller, service)  
**AUDITORÍA INDEPENDIENTE:** `PASS (0 BLOCKER, 0 MAJOR, 0 MINOR, 0 OBSERVATIONS)`  
**SUITE DE PRUEBAS NODO-08:** `34/34 PASS`  
**REGRESIÓN GLOBAL SAAS:** `214/214 PASS`  
**FECHA DE RECONCILIACIÓN:** `2026-09-12`  
**AUTORIDAD DIRECTIVA:** `Director del Proyecto GlowApp SaaS (GO-08.09-R1)`  

---

## 1. IDENTITY & NODE SUMMARY

- **Node ID:** `NODO-08`
- **Node Name:** `SaaS Service Ticket & Financial Checkout Engine`
- **Canonical Responsibility:** Autoridad transaccional y de persistencia financiera para la creación, tarifación, consolidación de consumos multi-servicio (`saas_ticket_items`), registro de pagos presenciales en mostrador (*split tender* en `saas_ticket_payments`), y liquidación económica de atenciones en el salón físico dentro de GlowApp SaaS.
- **Contract Specification:** [`ncp/NODO-08-SAAS-SERVICE-TICKET-CHECKOUT-CONTRACT-v1.0.md`](file:///ncp/NODO-08-SAAS-SERVICE-TICKET-CHECKOUT-CONTRACT-v1.0.md)
- **Ratification Record:** [`ncp/NODO-08-FORMAL-RATIFICATION-v1.0.md`](file:///ncp/NODO-08-FORMAL-RATIFICATION-v1.0.md)
- **Audit Record:** `GO-08.08-INDEPENDENT-AUDIT.md`

---

## 2. ARTEFACTOS FÍSICOS AUDITADOS Y VALIDADOS

| Capa / Componente | Archivo Físico | Estado Físico |
| :--- | :--- | :---: |
| **Contrato Canónico** | [`ncp/NODO-08-SAAS-SERVICE-TICKET-CHECKOUT-CONTRACT-v1.0.md`](file:///ncp/NODO-08-SAAS-SERVICE-TICKET-CHECKOUT-CONTRACT-v1.0.md) | `CONTRACT v1.0 — RATIFIED 🔒` |
| **Ratificación Formal** | [`ncp/NODO-08-FORMAL-RATIFICATION-v1.0.md`](file:///ncp/NODO-08-FORMAL-RATIFICATION-v1.0.md) | `RATIFIED 🔒` |
| **Persistencia DDL** | [`backend/migrations/072_saas_service_tickets.sql`](file:///backend/migrations/072_saas_service_tickets.sql) | `PHYSICALLY APPLIED & VALIDATED` |
| **Servicio de Dominio** | [`backend/src/services/nodo08TicketsService.js`](file:///backend/src/services/nodo08TicketsService.js) | `CONFORMANT` |
| **Controlador Backend** | [`backend/src/controllers/nodo08TicketsController.js`](file:///backend/src/controllers/nodo08TicketsController.js) | `CONFORMANT` |
| **Rutas Backend (11 EPs)** | [`backend/src/routes/nodo08TicketsRoutes.js`](file:///backend/src/routes/nodo08TicketsRoutes.js) | `CONFORMANT` |
| **Montaje de Rutas** | [`backend/index.js`](file:///backend/index.js), [`backend/src/startup/app.js`](file:///backend/src/startup/app.js) | `CONFORMANT` |
| **Suite de Tests NODO-08** | [`backend/tests/test_nodo08_tickets_suite.js`](file:///backend/tests/test_nodo08_tickets_suite.js) | `34/34 PASS` |

---

## 3. AUDIT RESULT & COMPLIANCE SUMMARY

- **Fase de Auditoría:** `GO-08.08 — INDEPENDENT BACKEND AUDIT`
- **Resultado:** `AUDIT RESULT: PASS`
- **Métricas de Hallazgos:**
  - `0 BLOCKER`
  - `0 MAJOR`
  - `0 MINOR`
  - `0 OBSERVATIONS`
- **Pruebas de Unidad e Integración NODO-08:** `34 / 34 PASS (100%)`
- **Regresión Global del Ecosistema SaaS:** `214 / 214 PASS (100%)`
- **Integridad de Nodos Previos:** `NODO-01`, `NODO-02`, `NODO-03A`, `NODO-04`, `NODO-05`, `NODO-06`, `NODO-07` permanecen 100% operativos e inmutables.

---

## 4. CONFORMIDAD ARQUITECTÓNICA EXACTA CON EL CONTRATO RATIFICADO

1. **Contexto Activo Obligatorio (DEC-AS-003 / DEC-AS-007):**  
   Resolución de `establishment_id` y `tenant_id` exclusivamente a través del header canónico `x-active-membership-id: <UUID>` y la función RLS `app_fn_saas_context_establishment_id()`. Rechazo terminante de `x-establishment-id` y parámetros inyectados en body/query.

2. **Validación de Asignación de Servicios (`service_assignments`):**  
   Para cada ítem de tipo `SERVICE`, el servidor valida determinísticamente:
   - Que `service_offer_id` pertenece al `tenant_id` y `establishment_id` del contexto activo.
   - Que `performed_by_membership_id` pertenece al mismo `tenant_id` y `establishment_id` del contexto activo y su membresía se encuentra en estado `ACTIVE`.
   - Que existe una fila de asignación válida en `service_assignments` relacionando `service_offer_id`, `membership_id`, `tenant_id` y `establishment_id`.
   - Para ítems de tipo `CUSTOM`, se requiere únicamente que `performed_by_membership_id` sea una membresía `ACTIVE` del establecimiento activo.

3. **Tipos de Ítem Contractuales (DEC-08-01):**  
   Exclusivamente `SERVICE` (asociado a oferta de catálogo) y `CUSTOM` (concepto libre y precio provisto en mostrador). No se contemplan ítems de tipo `PRODUCT` ni inventarios.

4. **Métodos de Pago Presenciales / Split Tender (DEC-08-02):**  
   Exclusivamente los métodos contractuales: `CASH`, `CARD`, `TRANSFER`, `OTHER`. Registro 1:N en `saas_ticket_payments` con trazabilidad de `received_by_membership_id`.

5. **Numeración de Folios Concurrente y Atómica (DEC-08-03):**  
   Secuencia por establecimiento en `saas_establishment_ticket_sequences` con columna `last_sequence_number`. Incremento atómico bajo la sentencia contractual:
   ```sql
   INSERT INTO saas_establishment_ticket_sequences (establishment_id, last_sequence_number, updated_at)
   VALUES ($1, 1, NOW())
   ON CONFLICT (establishment_id) 
   DO UPDATE SET 
       last_sequence_number = saas_establishment_ticket_sequences.last_sequence_number + 1,
       updated_at = NOW()
   RETURNING last_sequence_number;
   ```
   Formateo determinista: `'TICK-' || LPAD(last_sequence_number::text, 6, '0')`.

6. **Estructura Física y Nombres Reales de Tablas:**  
   - `saas_establishment_ticket_sequences`
   - `saas_service_tickets`
   - `saas_ticket_items`
   - `saas_ticket_payments`

7. **Modelo Dual de Cliente (XOR):**  
   Exclusividad mutua validada por constraint física `chk_ticket_client_mode`:
   - `GUEST`: `customer_user_id IS NULL` y `guest_name_snapshot IS NOT NULL`.
   - `REGISTERED`: `customer_user_id IS NOT NULL` y snapshots de invitado nulos.

8. **Máquina de Estados Contractual:**  
   Flujo estricto:
   - `DRAFT` -> `OPEN` -> `PAID` -> `CLOSED`
   - Anulaciones: `DRAFT` -> `VOID`, `OPEN` -> `VOID` (con `void_reason` obligatorio).
   - Transición a `PAID`: Automática al saldar el `balance_due = 0.00`.
   - Transición a `CLOSED`: Mediante acción explícita de cierre post-pago (`POST /api/saas/tickets/:id/close`).

9. **Frontera Unidireccional y Desacoplada con NODO-06:**  
   `NODO-06` permanece inmutable. El ticket almacena la relación opcional mediante la columna nullable `saas_service_tickets.appointment_id`. La cita asociada debe encontrarse en estado operacional `IN_SERVICE` o `COMPLETED` y pertenecer a la misma sede. La unicidad de ticket activo se protege mediante el índice parcial `idx_tickets_active_appointment`.

10. **Matriz RBAC Estricta:**  
    Permisos formalmente definidos para roles `OWNER`, `MANAGER`, `RECEPTIONIST` y `PROFESSIONAL` (este último con acceso restringido a consulta de sus propios ítems ejecutados).

---

## 5. PROTECTED ASSETS DECLARATION (DECLARACIÓN DE PROTECCIÓN)

Al completarse la ratificación y cierre formal de NODO-08:
1. Todos los esquemas DDL de la migración `072_saas_service_tickets.sql`, endpoints de `/api/saas/tickets`, controladores, servicios de dominio y suites de pruebas de `NODO-08` quedan protegidos bajo gobierno arquitectónico estricto.
2. Queda prohibida cualquier modificación o reinterpretación que vulnere los límites contractuales ratificados de este nodo o de los nodos previos `NODO-01` a `NODO-07`.

---

**FIN DEL REGISTRO DE RECONCILIACIÓN DE CIERRE FORMAL — NODO-08**
