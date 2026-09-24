# DEC-AS-001 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0
## Autoridad de Asignación y Workflow Semántico (Assignment Authority & Workflow)

**DECISION_ID:** `DEC-AS-001`  
**ESTADO:** `ANALYSIS COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Decision Analysis  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-001-001`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`  
**FECHA:** 2026-09-10  

---

## 1. EXECUTIVE FINDING (HALLAZGO EJECUTIVO)

El análisis riguroso de la evidencia física y contractual en el repositorio establece:

1. **[FACT] Inexistencia de Reglas de Asignación:** Actualmente no existe en el repositorio ninguna función, endpoint, tabla o contrato que defina quién tiene la potestad de crear una asignación (`ASSIGNMENT AUTHORITY = UNDEFINED`).
2. **[EVIDENCE] Autoridad Contextual:** En la arquitectura GlowApp SaaS, la autoridad nunca es global; reside exclusivamente en el contexto activo validado de un establecimiento (`establishment_id`, `membership_id`, `role`, `tenant_id`).
3. **[EVIDENCE] Separación de Dominios:** `OWNER` y `MANAGER` representan roles administrativos y de gobernanza dentro del establecimiento en `memberships`. `PROFESSIONAL` y `RECEPTIONIST` representan roles operativos y de ejecución.
4. **[EVIDENCE] Objetivo de la Asignación:** El objetivo semántico legítimo de una asignación es vincular una oferta de servicio (`service_offer`) con un colaborador activo (`professional / user_id`) del mismo establecimiento.
5. **[DICTAMEN]** Se concluye que la autoridad legítima para emitir una asignación debe corresponder a los roles de gobernanza del establecimiento (**`OWNER` y `MANAGER`** en el contexto activo), requiriendo que el destinatario sea un miembro activo del mismo establecimiento. Se somete a decisión del Director formalizar **`OPTION B`** o **`OPTION C`**.

---

## 2. EXISTING EVIDENCE (EVIDENCIA FÍSICA EXISTENTE)

```text
+------------------------------------+---------------------------------------------+-------------------------------------------------------------+
| Componente / Archivo               | Elemento Físico Identificado                | Significado Arquitectónico Demostrado                       |
+------------------------------------+---------------------------------------------+-------------------------------------------------------------+
| backend/migrations/065_...sql      | memberships.role IN ('OWNER', 'MANAGER',    | Catálogo cerrado de roles contextuales en la sede.          |
|                                    | 'PROFESSIONAL', 'RECEPTIONIST')             |                                                             |
| backend/migrations/065_...sql      | uq_membership_establishment_user            | Un usuario tiene una sola membresía por establecimiento.   |
| backend/src/middleware/active...   | req.activeContext / x-active-membership-id  | Autoridad validada por servidor ligada a establishment_id.  |
| backend/src/services/crearDesde... | staff_assignments[].assigned_categories    | Declaración de capacidad temática (CAPABILITY), no vínculo. |
| ncp/HANDOVER-SEMANTIC-...md        | HR-DEC-001 / HR-DEC-002                     | CAPABILITY ≠ ASSIGNMENT. No hay auto-asignación por match.  |
| ncp/DEC-SE-001-DECISION-RECORD...  | DEC-SE-001.1 / DEC-SE-001.2                 | No se crean filas en public.services sin asignación previa. |
+------------------------------------+---------------------------------------------+-------------------------------------------------------------+
```

---

## 3. SEPARACIÓN RIGUROSA DE DIMENSIONES SEMÁNTICAS

Para erradicar ambigüedades, se establece formalmente la frontera entre conceptos:

$$\text{IDENTITY} \neq \text{ROLE} \neq \text{CAPABILITY} \neq \text{MEMBERSHIP} \neq \text{ACCESS AUTHORITY} \neq \text{ASSIGNMENT AUTHORITY} \neq \text{EXECUTOR} \neq \text{B2C PROVIDER}$$

* **`IDENTITY` (`usuarios.id`):** Sujeto humano o cuenta única global.
* **`ROLE` (`memberships.role`):** Designación funcional (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`).
* **`CAPABILITY` (`assigned_categories`):** Aptitud técnica temática declarada por el colaborador.
* **`MEMBERSHIP` (`memberships.id`):** Relación contractual activa entre una `IDENTITY` y un `ESTABLISHMENT`.
* **`ACCESS AUTHORITY`:** Permiso de lectura/interacción con el Cockpit SaaS (concedido por el token y membresía activa).
* **`ASSIGNMENT AUTHORITY`:** Potestad formal de comprometer la oferta de la sede vinculando un servicio con un colaborador.
* **`EXECUTOR / PROFESSIONAL`:** Colaborador que ejecuta materialmente el servicio de belleza.
* **`B2C PROVIDER` (`public.perfiles_prestador`):** Registro transaccional en el marketplace público.

---

## 4. ANÁLISIS DE EVIDENCIA DE ASIGNACIÓN (EXISTING ASSIGNMENT EVIDENCE)

* En el flujo `Crear Desde Cero`, el cliente envía un payload con `staff_assignments`. El servicio `crearDesdeCeroService.js` valida que los `membership_id` existan y estén `ACTIVE`, extrayendo únicamente `assigned_categories`.
* En `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, la salida normalizada transporta `capabilities` en `eligible_professionals`, mientras que los servicios llegan con `assignment: { status: "NOT_ESTABLISHED", provider_id: null }`.
* En `NODO-01-v1.0`, esta separación se mantiene intacta en memoria.
* **Conclusión Factual:** En ningún punto del pipeline existente ocurre una asignación efectiva o persistente de servicio a colaborador.

---

## 5. ANÁLISIS DE AUTORIDAD DE ASIGNACIÓN (PREGUNTAS Q1 A Q10)

### Q1: ¿Existe actualmente alguna regla formal que determine quién puede crear una assignment?
**NO [FACT].** No existe en contratos previos ninguna cláusula que defina esta potestad.

### Q2: ¿Existe algún endpoint, servicio, tabla o estructura existente que represente assignment?
**NO [FACT].** No existe tabla en PostgreSQL ni método en backend para persistir o procesar asignaciones.

### Q3: ¿OWNER tiene evidencia suficiente para ser Assignment Authority?
**SÍ [EVIDENCE].** En el modelo SaaS (`065`), `OWNER` representa al titular o socio principal de la organización/establecimiento (`relation_type = 'OWNER_PARTNER'`), con plena soberanía sobre los activos comerciales y el personal.

### Q4: ¿MANAGER tiene evidencia suficiente para ser Assignment Authority?
**SÍ [EVIDENCE].** `MANAGER` representa la administración operativa y la gestión diaria de la sede. En la operación de salones y centros de estética, la asignación de turnos y servicios al personal es una función típica de la gerencia.

### Q5: ¿PROFESSIONAL tiene evidencia suficiente?
**NO [EVIDENCE].** `PROFESSIONAL` es el rol ejecutor (`STAFF_EMPLOYEE` o `INDEPENDENT_PROVIDER`). Permitirle auto-asignarse unilateralmente servicios del catálogo general del establecimiento alteraría la soberanía administrativa del salón, salvo que exista delegación explícita.

### Q6: ¿RECEPTIONIST tiene evidencia suficiente?
**NO [EVIDENCE].** `RECEPTIONIST` es un rol operativo de atención al cliente y agendamiento diario. No posee facultades demostradas para definir la estructura de asignación del catálogo comercial.

### Q7: ¿De qué factores depende la autoridad de asignación?
**EVALUACIÓN:** Depende de la combinación de:
1. `active_context.establishment_id` (Ámbito territorial y operativo).
2. `active_context.role` (`OWNER` o `MANAGER`).
3. `active_context.membership_status == 'ACTIVE'`.
4. `relation_type` (Informativo, no restrictivo para la autoridad de mando).

### Q8: ¿La autoridad es GLOBAL o CONTEXTUAL?
**CONTEXTUAL [EVIDENCE].** Todo el control de acceso en GlowApp SaaS es contextual al establecimiento activo (`065`, `Active Context v1.0`).

### Q9: ¿Puede una persona con múltiples memberships tener autoridad en un establecimiento y no en otro?
**SÍ [FACT].** La restricción `uq_membership_establishment_user` garantiza que las membresías sean independientes por sede. Un usuario puede ser `OWNER` en la Sede A y `PROFESSIONAL` en la Sede B.

### Q10: ¿La assignment debe estar limitada al establecimiento del Active Context?
**SÍ [EVIDENCE].** Un `OWNER`/`MANAGER` solo puede asignar servicios de la Sede X a colaboradores con membresía `ACTIVE` en la misma Sede X.

---

## 6. ANÁLISIS DEL OBJETIVO DE LA ASIGNACIÓN (ASSIGNMENT TARGET)

Se evalúan los posibles destinos semánticos de una asignación:

1. **`service_offer → professional (user_id / membership_id)` [RECOMENDADO]:**  
   Vincula la oferta comercial con una persona real y activa en la sede. Permite saber exactamente quién ejecutará el servicio.
2. **`service_offer → capability` [RECHAZADO]:**  
   Una capacidad es un concepto abstracto (`HAIR_STYLING`), no un ejecutor humano. No resuelve la necesidad operativa ni el requisito de B2C.
3. **`service_offer → b2c provider` [RECHAZADO]:**  
   Viola el desacoplamiento SaaS/B2C. Un colaborador SaaS puede no tener perfil B2C creado al momento de la asignación inicial en el Cockpit.

---

## 7. ANÁLISIS DE CAPACIDAD TÉCNICA (CAPABILITY)

* **¿Qué representa `assigned_categories`?** Aptitud técnica temática declarada durante el onboarding o gestión de perfil.
* **¿Quién la posee?** El colaborador dentro del contexto de la sede.
* **¿Es condición para asignar?**  
  - No existe regla automática en el código (`NO RULE DEFINED`).
  - **Criterio Arquitectónico:** La autoridad administrativa (`OWNER`/`MANAGER`) es soberana para asignar. La coincidencia con `capabilities` puede servir como filtro de conveniencia en la UI o validación suave (warning), pero no debe bloquear físicamente la autoridad del dueño a menos que el negocio lo exija formalmente.

---

## 8. ANÁLISIS DE AUTORIDAD CONTEXTUAL (MULTI-ESTABLECIMIENTO)

```text
+---------------------------------------------------------------------------------------------------+
| EJEMPLO DE AUTORIDAD CONTEXTUAL:                                                                 |
|                                                                                                   |
| Usuario: Carlos (usuarios.id = 100)                                                               |
|                                                                                                   |
| Contexto A (Sede Chapinero):                                                                      |
| - active_membership_id = mem_001                                                                  |
| - role = 'OWNER'                                                                                  |
| - status = 'ACTIVE'                                                                               |
| -> TIENE AUTORIDAD DE ASIGNACIÓN sobre Sede Chapinero ✅                                          |
|                                                                                                   |
| Contexto B (Sede Usaquén):                                                                        |
| - active_membership_id = mem_002                                                                  |
| - role = 'PROFESSIONAL'                                                                           |
| - status = 'ACTIVE'                                                                               |
| -> NO TIENE AUTORIDAD DE ASIGNACIÓN sobre Sede Usaquén ❌                                         |
+---------------------------------------------------------------------------------------------------+
```

---

## 9. WORKFLOW SEMÁNTICO DE ASIGNACIÓN

El ciclo de vida conceptual de una oferta de servicio en SaaS se define en la siguiente secuencia:

```text
================================================================================
WORKFLOW SEMÁNTICO:

[1. CATALOG INGESTION]
    service_offer generado en establecimiento
    assignment.status = "NOT_ESTABLISHED"
    provider_id = null
           │
           ▼
[2. AUTHORIZATION CHECK]
    Actor invoca acción de asignación
    Verificación de Active Context:
      - caller.role IN ('OWNER', 'MANAGER') ?
      - caller.membership_status == 'ACTIVE' ?
      - target_collaborator.establishment_id == current_establishment_id ?
      - target_collaborator.status == 'ACTIVE' ?
           │
           ▼
[3. ASSIGNMENT ACTION]
    Acto explícito de vinculación:
    (establishment_id, service_offer_id, target_user_id)
           │
           ▼
[4. ASSIGNED STATE]
    assignment.status = "ASSIGNED"
    collaborator_id = target_user_id
    (Permanece en dominio SaaS hasta decisión de persistencia/materialización)
================================================================================
```

---

## 10. EVALUACIÓN DE OPCIONES DE LÍMITE DE AUTORIDAD

* **OPTION A — OWNER Únicamente:** Solo el propietario puede asignar servicios.
* **OPTION B — OWNER + MANAGER [RECOMENDADA]:** Propietarios y administradores de la sede tienen autoridad de asignación.
* **OPTION C — ROLE + CONDICIÓN ADICIONAL:** OWNER/MANAGER con validación estricta de `CAPABILITY` coincidente.
* **OPTION D — PROFESSIONAL:** El profesional se auto-asigna servicios.
* **OPTION E — OTRO ACTOR:** Asignación delegada a recepcionistas o sistema externo.
* **OPTION F — INSUFFICIENT EVIDENCE / DECISION REQUIRED:** No definir y postergar.

---

## 11. MATRIZ COMPARATIVA DE OPCIONES

```text
+------------------------------+-----------+---------------------+-------------------+------------+------------+
| Criterio                     | OPTION A  | OPTION B (Recomend) | OPTION C          | OPTION D   | OPTION E/F |
|                              | (Owner)   | (Owner + Manager)   | (Role + Cap)      | (Prof)     | (Otros)    |
+------------------------------+-----------+---------------------+-------------------+------------+------------+
| Respaldo en Evidencia        | Parcial   | SUPPORTED           | PARTIALLY SUPP.   | NOT SUPP.  | NOT SUPP.  |
| Compatibilidad SaaS Core     | Alta      | ALTA                | Alta              | Baja       | Baja       |
| Compatibilidad Membership    | Alta      | ALTA                | Alta              | Media      | Baja       |
| Respeto a Roles (065)        | Restringe | TOTAL               | Total             | Invalida   | N/A        |
| Tratamiento de Capability    | Neutral   | DESACOPLADO         | ESTRICTO/ACOPLADO | N/A        | N/A        |
| Riesgo de Sobreautoridad     | Muy Bajo  | BAJO                | Muy Bajo          | Alto       | Incierto   |
| Complejidad Conceptual       | Muy Baja  | BAJA                | Media             | Media      | Alta       |
| Necesidad de Cambios Físicos | Nula      | NULA                | Nula              | Nula       | Nula       |
+------------------------------+-----------+---------------------+-------------------+------------+------------+
```

---

## 12. RECOMENDACIÓN FORMAL DE ARQUITECTURA

**Se recomienda formalmente la adopción de `OPTION B — OWNER + MANAGER`:**

1. **Definición Canónica:** La potestad de efectuar una asignación operativa (`ASSIGNMENT AUTHORITY`) reside de forma exclusiva y contextual en los usuarios que posean una membresía con rol **`OWNER`** o **`MANAGER`** en estado **`ACTIVE`** para el establecimiento en cuestión.
2. **Requisitos del Destinatario:** El destinatario de la asignación debe ser un colaborador con membresía en estado **`ACTIVE`** en el mismo establecimiento.
3. **Rol de Capability:** `assigned_categories` actúa como información de orientación operativa para la toma de decisiones del administrador, pero no bloquea la autoridad soberana de asignación.

---

## 13. SEPARACIÓN DE RESPONSABILIDADES Y OPEN QUESTIONS

Este análisis resuelve y cierra **exclusivamente**:
- **QUIÉN PUEDE ASIGNAR:** `OWNER` y `MANAGER` del contexto activo.
- **A QUIÉN SE PUEDE ASIGNAR:** A miembros activos del mismo establecimiento.
- **QUÉ ES SEMÁNTICAMENTE UNA ASIGNACIÓN:** Vinculación explícita de `service_offer` con `professional (user_id)`.

Quedan formalmente desacopladas y pendientes de decisiones posteriores:
- **`DEC-AS-002`:** ¿Dónde y cómo se almacena la asignación? (*Persistence vs In-Memory/Event*).
- **`DEC-AS-003`:** ¿Cuándo y cómo se dispara la materialización hacia `public.services`? (*Immediate vs On-Demand/Publishing*).

---

## 14. DECISIÓN REQUERIDA DEL DIRECTOR (DIRECTOR DECISION REQUIRED)

Se somete a consideración del Director la siguiente resolución:

```text
================================================================================
PROPUESTA DE RESOLUCIÓN PARA DEC-AS-001:

1. APROBAR OPTION B (OWNER + MANAGER como Autoridad de Asignación Contextual).
2. RATIFICAR que la asignación es una vinculación contextual service_offer -> professional.
3. RATIFICAR que CAPABILITY no bloquea la autoridad de asignación de la sede.
4. MANTENER PENDIENTES DEC-AS-002 (Persistencia) y DEC-AS-003 (Materialización).
================================================================================
```

---
*Fin del documento de Análisis de Decisión Arquitectónica DEC-AS-001.*
