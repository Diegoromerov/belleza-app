# DEC-AS-002 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0 (RECONCILIADO R1)
## Reconciliación del Estado de Asignación y Requisitos Mínimos (Assignment State Reconciliation)

**DECISION_ID:** `DEC-AS-002`  
**ESTADO:** `RECONCILIATION COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Reconciliation  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-002-001` / `DEC-AS-002-R1`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`, `DEC-AS-001-DECISION-RECORD-v1.0.md`, `DEC-CAT-001-DECISION-RECORD-v1.0.md`  
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EXECUTIVE FINDING & CONCLUSIÓN BASE ACEPTADA

En cumplimiento de las directivas de `DEC-AS-002-R1`, se depuran todas las hipótesis y supuestos no demostrados (cardinalidad asumida, máquinas de estados complejas, columnas de auditoría), estableciendo como base:

1. **[BASE ACEPTADA] Durabilidad Provisional:**  
   $$\text{ASSIGNMENT} = \text{DURABLE SAAS STATE (Aceptado Provisionalmente)}$$
   Dado que `DEC-CAT-001` formalizó que `SERVICE_OFFER` adquiere estado operativo e identidad demostrada post-handover, y `DEC-AS-001` estableció la potestad explícita de asignación por `OWNER`/`MANAGER`, la vinculación debe poder sobrevivir al request original para permitir su existencia operativa previa a la materialización tardía de `DEC-SE-001`.
2. **[FACT] Supresión de Supuestos No Demostrados:**  
   - No existe regla contractual de cardinalidad aprobada ($\text{CARDINALITY} = \text{UNDEFINED}$).
   - No existe máquina de estados ni ciclo de vida formalizado ($\text{ASSIGNMENT LIFECYCLE} = \text{UNDEFINED}$).
   - No existe requerimiento demostrado de persistir `assigned_by` ni marcas temporales ($\text{AUDIT / TIMESTAMPS} = \text{UNDEFINED}$).
3. **[EVIDENCE] Mínimo Estado Conceptual Demostrado:**  
   El estado durable mínimo consiste estrictamente en:
   $$\text{REFERENCE TO SERVICE\_OFFER} + \text{REFERENCE TO ACTIVE PROFESSIONAL}$$
4. **[EVIDENCE] Contexto Derivable:**  
   `establishment_id` y `tenant_id` no requieren duplicación conceptual obligatoria; son derivables del contexto de la oferta de servicio y de la membresía del profesional.
5. **[DICTAMEN]** Se formaliza la definición de **Estado Mínimo Conceptual**, manteniendo el modelo físico de persistencia como **`NOT YET DECIDED`** y sometiendo a consideración del Director las opciones estructurales purificadas.

---

## 2. PRECEDENTES CERRADOS Y MARCO NORMATIVO

```text
================================================================================
MARCO NORMATIVO CERRADO:

1. DEC-CAT-001 (Catálogo Post-Handover):
   SERVICE_OFFER = OPERATIONAL STATE post-handover.
   IDENTITY REQUIREMENT = DEMONSTRATED.
   OPERATIONAL STATE ≠ PHYSICAL TABLE.

2. DEC-AS-001 (Autoridad de Asignación):
   Acto explícito autorizado por OWNER/MANAGER con membresía ACTIVE en activeContext.
   Vincula SERVICE_OFFER -> ACTIVE PROFESSIONAL.

3. DEC-SE-001 (Instanciación Tardía B2C):
   SERVICE_OFFER ≠ public.services.
   assignment.status = NOT_ESTABLISHED => NO public.services.
   ASSIGNMENT ≠ AUTOMATIC B2C MATERIALIZATION.

4. DEC-SE-002 (Autonomía de Ubicación y Horarios):
   Desacoplamiento absoluto de datos B2C en perfiles_prestador.
================================================================================
```

---

## 3. INVESTIGACIÓN EXHAUSTIVA DE CARDINALIDAD

Se analiza la evidencia física del repositorio:
* En `HBC v1.0`: `service_offers` es un array y `professional_context` es un array.
* En `DEC-AS-001`: La asignación vincula un `SERVICE_OFFER` con un `PROFESSIONAL`.
* En `public.services` (B2C): Cada fila transaccional exige exactamente un `provider_id INTEGER NOT NULL`.
* **Hallazgo Fáctico:** Ningún contrato ni código existente define formalmente si en el dominio SaaS una oferta puede asignarse a un solo colaborador ($1:1$) o a múltiples colaboradores ($1:N$).
* **Conclusión:**
  $$\text{CARDINALITY} = \text{UNDEFINED}$$

---

## 4. INVESTIGACIÓN DEL CICLO DE VIDA DE ASIGNACIÓN (LIFECYCLE)

* En `HBC v1.0` (L128): Se define únicamente `"assignment": { "status": "NOT_ESTABLISHED" }`.
* No existen contratos, tablas ni enums que definan estados como `REVOKED`, `SUSPENDED` o `INACTIVE` para una asignación.
* La condición de no-asignado es simplemente la ausencia de vínculo formal ("NO ASSIGNMENT EXISTS").
* **Conclusión:**
  $$\text{ASSIGNMENT LIFECYCLE} = \text{UNDEFINED}$$

---

## 5. ESTADO MÍNIMO CONCEPTUAL DEMOSTRADO (DURABLE STATE MINIMUM)

Aplicando el principio de máxima economía y necesidad demostrada:

```text
================================================================================
MÍNIMO ESTADO CONCEPTUAL DEMOSTRADO:

  1. REFERENCIA A SERVICE_OFFER (Identidad demostrada post-handover en DEC-CAT-001).
  2. REFERENCIA A ACTIVE PROFESSIONAL (user_id / membership_id activo en 065).

NO DEMOSTRADOS EN EL MODELO MÍNIMO:
  - assigned_by          -> ASSIGNING ACTOR PERSISTENCE = UNDEFINED
  - timestamps (at/by)   -> TEMPORAL ATTRIBUTES = UNDEFINED
  - status codes         -> ASSIGNMENT LIFECYCLE = UNDEFINED
================================================================================
```

---

## 6. ANÁLISIS DE CONTEXTO Y REDUNDANCIA

* **`establishment_id`:** Derivable de la pertenencia de la oferta de servicio al establecimiento y de la membresía activa del profesional (`065`).
* **`tenant_id`:** Derivable del establecimiento y del usuario mediante `066` (`fn_resolve_user_tenant`).
* **Conclusión de Contexto:**
  $$\text{CONTEXT REQUIREMENTS} = \text{DERIVABLE}$$
  El modelo conceptual mínimo no requiere duplicar claves de contexto que ya están implícitas en sus extremos.

---

## 7. ANÁLISIS DE AUTORIDAD Y ACTOR AUDITOR (AUTHORITY AUDIT)

* `DEC-AS-001` formalizó la **Autoridad de Ejecución** (`OWNER`/`MANAGER` en contexto activo).
* Sin embargo, la facultad de ejecutar una acción **no demuestra por sí misma** la necesidad de persistir la identidad del autor (`assigned_by`) como atributo del estado durable.
* **Conclusión:**
  $$\text{ASSIGNING ACTOR PERSISTENCE} = \text{UNDEFINED}$$

---

## 8. DEPENDENCIAS DE HUB SALÓN Y B2C

### 8.1. Hub Salón:
* En `HUB-SALON-NODE-CONTRACT-v1.0`, los endpoints `/summary` y `/staff` no gestionan actualmente asignaciones de servicios.
* **Conclusión:**
  $$\text{HUB DEPENDENCY} = \text{NOT DEMONSTRATED (en v1.0)}$$

### 8.2. Ecosistema B2C:
* `public.services` requiere un `provider_id` asignado para poder ser materializado.
* La materialización downstream consume el vínculo `(SERVICE_OFFER, PROFESSIONAL)` cuando se active `DEC-AS-003`.

---

## 9. EVALUACIÓN DE OPCIONES ESTRUCTURALES

Habiendo purificado los supuestos, se evalúan las opciones arquitectónicas conceptuales:

```text
================================================================================
OPCIONES CONCEPTUALES:

[OPTION A: DURABLE ASSIGNMENT STATE INDEPENDIENTE]
  La asignación existe como un vínculo durable autónomo:
  (Ref: SERVICE_OFFER, Ref: PROFESSIONAL).
  *Ventaja:* Desacoplamiento conceptual total; flexibilidad si se define cardinalidad N:M.

[OPTION B: DURABLE ASSIGNMENT STATE EMBEBIDO]
  La asignación forma parte del estado operativo de SERVICE_OFFER:
  SERVICE_OFFER { assigned_professional_ref: ... }.
  *Ventaja:* Máxima economía de entidades; cohesión con el estado operativo de DEC-CAT-001.

[OPTION C: OTRA ALTERNATIVA DEMOSTRADA]
  (No respaldada por evidencia actual).

[OPTION D: PRIOR ARCHITECTURAL DECISION REQUIRED]
  (Si el Director considera que la cardinalidad o el modelo de catálogo
   deben formalizarse antes de cerrar este punto).
================================================================================
```

---

## 10. MATRIZ DE ECONOMÍA ARQUITECTÓNICA PURIFICADA

```text
+---------------------------------+-----------------------------------+-----------------------------------+---------------------+
| Criterio                        | OPTION A (Vínculo Independiente)  | OPTION B (Estado Embebido en Ofer)| OPTION D (Decisión) |
+---------------------------------+-----------------------------------+-----------------------------------+---------------------+
| Respaldo en Evidencia           | SUPPORTED ✅                      | SUPPORTED ✅                      | PARTIALLY SUPP.     |
| Cumplimiento DEC-AS-001         | TOTAL                             | TOTAL                             | Total               |
| Cumplimiento DEC-CAT-001        | TOTAL                             | TOTAL                             | Total               |
| Cumplimiento DEC-SE-001         | TOTAL                             | TOTAL                             | Total               |
| Estado Mínimo Requerido         | Exacto (Ref Oferta + Ref Prof)    | Exacto (Ref Prof en Oferta)       | Pendiente           |
| Contexto Requerido              | Derivable                         | Derivable                         | Pendiente           |
| Supuestos de Cardinalidad       | Neutral (Soporta 1:1, 1:N, N:M)   | Favorece 1:1 o 1:N                | No asume            |
| Complejidad Conceptual          | Baja                              | MUY BAJA ✅                       | Nula                |
| Nuevas Entidades Físicas        | 0 (No decide DDL todavía)         | 0 (No decide DDL todavía)         | 0                   |
+---------------------------------+-----------------------------------+-----------------------------------+---------------------+
```

---

## 11. NO AUTORIZACIÓN DE IMPLEMENTACIÓN FÍSICA

Este análisis es **exclusivamente conceptual y normativo**.

**NO autoriza:**
- Creación de tablas SQL, columnas, FKs, UUIDs ni migraciones (`067+`).
- Creación de endpoints o código backend.
- Modificación de B2C (`public.services`, `public.perfiles_prestador`).
- Resolución de `DEC-AS-003` (Materialization Triggering Policy).
- Redacción del Node Contract de NODO-02.

---

## 12. SÍNTESIS DE LA RECONCILIACIÓN Y ESTADO FINAL

```text
================================================================================
ESTADO FORMAL RECONCILIADO (DEC-AS-002):

DURABILITY
= ACCEPTED PROVISIONALLY

CARDINALITY
= UNDEFINED

LIFECYCLE
= UNDEFINED

MINIMUM STATE
= REFERENCE TO SERVICE_OFFER + REFERENCE TO ACTIVE PROFESSIONAL

CONTEXT REQUIREMENTS
= DERIVABLE (from Service Offer & Membership)

PHYSICAL PERSISTENCE MODEL
= NOT YET DECIDED

DEC-AS-003: PENDING 🟡
================================================================================
```

---

## 13. DECISIÓN REQUERIDA DEL DIRECTOR (DIRECTOR DECISION REQUIRED)

Se somete a consideración del Director la siguiente resolución:

```text
================================================================================
PROPUESTA DE RESOLUCIÓN PARA DEC-AS-002:

1. RATIFICAR la durabilidad provisional del estado de Assignment en SaaS.
2. DECLARAR que el Estado Mínimo Conceptual consiste estrictamente en:
   (REFERENCE TO SERVICE_OFFER + REFERENCE TO ACTIVE PROFESSIONAL).
3. DECLARAR que el contexto (establishment_id, tenant_id) es DERIVABLE.
4. DECLARAR que Cardinalidad, Ciclo de Vida y Auditoría son actualmente UNDEFINED.
5. DECLARAR que el Modelo de Persistencia Física permanece NOT YET DECIDED.
6. SELECCIONAR entre OPTION A (Vínculo Autónomo) u OPTION B (Estado Embebido en Oferta).
================================================================================
```

---
*Fin del documento reconciliado de Análisis de Decisión Arquitectónica DEC-AS-002.*
