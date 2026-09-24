# HANDOVER SEMANTIC RECONCILIATION REPORT v1.0
## Reconciliación de Asignación Semántica y Estados de Handover

**Versión:** 1.0.0  
**Fecha:** 2026-09-10  
**Estado:** RECONCILIATION COMPLETE / PENDING DIRECTOR ARCHITECTURAL DECISION 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Read-Only Architectural Discovery & Semantic Reconciliation

---

## 1. PROPÓSITO

Reconciliar exclusivamente dos cuestiones arquitectónicas identificadas en el `HANDOVER-BOUNDARY-CONTRACT-DISCOVERY-v1.0`:
1. Determinar si `people_initial_roles.assigned_categories` demuestra semánticamente una **ASSIGNMENT** de profesional a servicio.
2. Determinar si `READY_FOR_PRE_NODE_01` constituye un estado formal, necesario y válido del Handover.

Este documento no implementa código, no modifica la base de datos ni altera contratos previamente aprobados.

---

## 2. SCOPE Y EVIDENCIA FÍSICA AUDITADA

- **Contrato de Crear Desde Cero:** `/ncp/CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` (Secciones 8, 9, 11).
- **Servicio de Crear Desde Cero:** `backend/src/services/crearDesdeCeroService.js` (Líneas 120-165).
- **Controlador de Crear Desde Cero:** `backend/src/controllers/crearDesdeCeroController.js`.
- **Suite de Pruebas:** `backend/tests/test_crear_desde_cero_suite.js` (Líneas 180-235).
- **Esquema Core B2C (Pre-Nodo 01):** `backend/init.sql` (`usuarios`, `perfiles_prestador`, `services`, `bookings`).
- **Controladores Core B2C:** `serviceController.js`, `providerController.js`, `bookingController.js`.

---

## 3. QUESTION HR-Q01 — NATURALEZA DE `assigned_categories`

### Análisis Basado en Evidencia:
1. **Origen y Generación:** Se origina en el payload interactivo del cliente (`clientPayload.staff_assignments[i].assigned_categories`).
2. **Construcción en Servicio:** En `crearDesdeCeroService.js` (L142-154), se extrae del payload y se mapea directamente al objeto en memoria `people_initial_roles[i].assigned_categories`.
3. **Participación en Autorización:** **NULA**. La autorización en Crear Desde Cero evalúa exclusivamente identidad, membresía activa y rol (`OWNER` / `MANAGER`). No valida categorías.
4. **Participación en Creación de Servicios / Publicación / Disponibilidad:** **NULA**. En Crear Desde Cero no se crean registros en BD ni se calculan slots.
5. **Validación de Correspondencia:** **INEXISTENTE**. No existe validación de que un `relevant_services[i].category` coincida con algún `assigned_categories` de los colaboradores, ni viceversa.
6. **Interpretación de Código:** Ningún componente de backend interpreta la coincidencia de strings de categoría como una asignación formal a un servicio individual.

### Clasificación Semántica:
**`CAPABILITY / CLASSIFICATION`**  
`assigned_categories` representa la aptitud temática declarada o catálogo general de habilidades de un colaborador dentro de la sede. **NO es una `ASSIGNMENT` relacional ni una vinculación a servicios específicos.**

---

## 4. QUESTION HR-Q02 — EVIDENCIA FÍSICA DE VINCULACIÓN PROFESIONAL ↔ SERVICIO

| Dimensión Operacional | Evidencia Física en Repositorio | Conclusión |
| :--- | :--- | :---: |
| **Creación Física** | No existe `INSERT` ni estructura relacional que enlace un profesional a un servicio mediante categorías. | **NO DEMOSTRADO** |
| **Validación de Negocio** | No existe regla que obligue a tener profesionales asignados a cada servicio del catálogo. | **NO DEMOSTRADO** |
| **Consulta SQL** | Ninguna consulta relaciona `memberships` o `usuarios` con `services` a través de categorías. | **NO DEMOSTRADO** |
| **Filtrado Operacional** | No existe filtrado de catálogo en función de `assigned_categories`. | **NO DEMOSTRADO** |
| **Autorización** | No participa en la autorización de ejecución ni reserva. | **NO DEMOSTRADO** |
| **Publicación B2C** | En Pre-Nodo 01, la publicación requiere `services.provider_id NOT NULL` unívoco. | **NO DEMOSTRADO** |

---

## 5. QUESTION HR-Q03 — LEGITIMIDAD DE LA INFERENCIA DE ASIGNACIÓN

### Inferencia Auditada:
```text
service.category == professional.assigned_categories[]  ==>  SERVICE ASSIGNMENT
```

### Respuesta:
**`NOT DEMONSTRATED` (No Demostrada)**

### Fundamento Técnico:
1. **Disparidad de Granularidad:** Una categoría (`HAIR_STYLING`) es una agrupación taxonómica abstracta; un servicio (`Corte Bob - 45min - $45.000`) es una oferta comercial específica. Compartir categoría denota afinidad técnica (`CAPABILITY`), pero no formaliza una orden o consentimiento de ejecución individual (`ASSIGNMENT`).
2. **Ausencia de Regla Codificada:** No existe en los contratos cerrados ni en el código una regla que dicte que todos los colaboradores con una categoría quedan asignados automáticamente a todos los servicios de dicha categoría.
3. **Cardinalidad Pre-Nodo 01:** En el plano B2C físico, la asignación es exclusivamente 1:1 mediante la clave foránea `services.provider_id`. El matching de categorías es una propuesta de diseño para el futuro adaptador de aprovisionamiento, no una regla semántica demostrada en el código actual.

---

## 6. QUESTION HR-Q04 — NATURALEZA DE `READY_FOR_PRE_NODE_01`

### Análisis Basado en Evidencia:
- **En Crear Desde Cero:** Es un estado formal derivado deterministamente en `crearDesdeCeroService.js` (L156-164) y verificado en `test_crear_desde_cero_suite.js` (L211, L225) cuando el payload no presenta bloqueos y contiene servicios o actividades.
- **En Pre-Nodo 01:** Pre-Nodo 01 **no conoce, no consume y no valida** el campo `READY_FOR_PRE_NODE_01`.

### Clasificación Formal:
- **A. Estado formal existente:** **SÍ**, como estado terminal de la máquina de estados interna de `CREAR-DESDE-CERO-v1.0`.
- **B. Estado propuesto:** **SÍ**, como bandera de habilitación para el transporte de handover.
- **C. Estado de transición:** **SÍ**, marca la culminación de la fase de preparación en el Cockpit SaaS.
- **D. Estado requerido por Pre-Nodo 01:** **NO DEMOSTRADO**. Pre-Nodo 01 no tiene consumidores para este estado.

---

## 7. QUESTION HR-Q05 — NECESIDAD DE CAMPO `state` EN EL HANDOVER

1. **En el Context Package de Crear Desde Cero:** El campo `state: "READY_FOR_PRE_NODE_01"` es contractual y obligatorio (Atributo Canónico 7 de los 16 atributos aprobados en `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`).
2. **En el Límite de Ingestión hacia Pre-Nodo 01:** El downstream requiere los datos sustantivos (`establishment_context`, `service_offers`, `assigned_staff`, `authorizing_identity`). El campo `state` actúa como precondición lógica de emisión en SaaS, pero no constituye una entidad transaccional para Pre-Nodo 01.

---

## 8. TABLA DE RECONCILIACIÓN SEMÁNTICA

| Elemento | Evidencia Física | Semántica Demostrada | Estado de Demostración |
| :--- | :--- | :--- | :---: |
| **`assigned_categories`** | `crearDesdeCeroService.js` L152; `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` L166 | Declaración de aptitud temática / portafolio del colaborador en el establecimiento. | **DEMOSTRADO como `CAPABILITY` / `CLASSIFICATION`** |
| **`service.category`** | `crearDesdeCeroService.js` L127; `relevant_services` | Clasificación taxonómica de la oferta de la sede. | **DEMOSTRADO como `OFFER CLASSIFICATION`** |
| **`category matching`** | Ninguna en runtime / tests | Inferencia hipotética de asignación sin soporte en código ni reglas contractuales vigentes. | **NO DEMOSTRADO** |
| **`Assignment`** | `public.services.provider_id` en Pre-Nodo 01 | Vínculo contractual de ejecución unívoco. No existe a nivel granular en el plano SaaS actual. | **NO DEMOSTRADO en SaaS / DEMOSTRADO en B2C físico** |
| **`Handover state`** | `crearDesdeCeroService.js` L156-164 | Estado de salida de la máquina de estados de onboarding de Crear Desde Cero. | **DEMOSTRADO en Crear Desde Cero** |
| **`READY_FOR_PRE_NODE_01`** | `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` L173; `test_crear_desde_cero_suite.js` L211 | Valor determinista derivado al validar con éxito el Context Package. No consumido por Pre-Nodo 01. | **DEMOSTRADO en Crear Desde Cero / NO DEMOSTRADO en Pre-Nodo 01** |

---

## 9. DECISION GATES

### HR-DEC-001 — ¿Puede `assigned_categories` utilizarse como fuente de una Assignment?
```text
NO — NOT DEMONSTRATED
```
* **Fundamento:** `assigned_categories` califica la capacidad técnica de una persona (`CAPABILITY`), pero no establece un vínculo operacional explícito con servicios individuales.

---

### HR-DEC-002 — ¿Puede `category == assigned_categories` utilizarse como regla de asignación?
```text
NO — NOT DEMONSTRATED
```
* **Fundamento:** No existe base de código ni regla de negocio aprobada que active una asignación por simple equivalencia de categoría. Constituye una propuesta de diseño sujeta a la decisión del Director (`DEC-SE-001`).

---

### HR-DEC-003 — ¿`READY_FOR_PRE_NODE_01` es un estado formal demostrado?
```text
PARTIALLY
```
* **Fundamento:** Está completamente demostrado e implementado como estado de salida en `CREAR-DESDE-CERO-v1.0`, pero **no está demostrado** como un requisito o estado operativo dentro de Pre-Nodo 01.

---

### HR-DEC-004 — ¿Existe suficiente evidencia para cerrar estas dos ambigüedades?
```text
YES
```
* **Fundamento:** La evidencia física delimita taxativamente el alcance de cada elemento, eliminando cualquier ambigüedad interpretativa sin necesidad de suposiciones.

---

## 10. ACTIVOS PROTEGIDOS

Se ratifica que los siguientes activos protegidos permanecen **100% INTACTOS**:
- Foundation v1.0
- Context Resolution v1.0
- Active Context v1.0
- Hub Salón v1.0
- Crear Desde Cero v1.0
- Pre-Nodo 01
- SOUL
- Governance
- NCP Core

---

## 11. ESTADO FINAL

```text
================================================================================
ESTADO FINAL:
RECONCILIATION COMPLETE / PENDING DIRECTOR ARCHITECTURAL DECISION 🟡
================================================================================
```
