# DEC-AS-002 — ARCHITECTURAL DECISION RECORD v1.0
## Formalización y Cierre: Modelo de Persistencia de la Asignación (Assignment Persistence Model)

**DECISION_ID:** `DEC-AS-002`  
**TÍTULO:** Assignment Persistence Model & Minimum Durable State  
**DECISIÓN APROBADA:** `ASSIGNMENT = DURABLE SAAS STATE`  
**STATUS:** `APPROVED — CLOSED 🔒`  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-002-002`  
**ANÁLISIS PREVIO:** [`/ncp/DEC-AS-002-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-AS-002-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md)  
**FECHA DE CIERRE:** 2026-09-10  

---

## 1. DECLARACIÓN FORMAL DE LA DECISIÓN

El Director del Proyecto GlowApp SaaS aprueba y formaliza como regla canónica:

```text
================================================================================
REGLA CANÓNICA DE DURABILIDAD (DEC-AS-002):

ASSIGNMENT = DURABLE SAAS STATE

La asignación representa conceptualmente:
    SERVICE_OFFER ──> ACTIVE PROFESSIONAL

y debe poder sobrevivir al request original del flujo que creó la oferta,
manteniendo memoria durable en el dominio SaaS post-handover.
================================================================================
```

---

## 2. MÍNIMO ESTADO CONCEPTUAL DEMOSTRADO

El estado mínimo conceptual indispensable y demostrado para representar una asignación consiste exclusivamente en:

$$\text{REFERENCE TO SERVICE\_OFFER} + \text{REFERENCE TO ACTIVE PROFESSIONAL}$$

No se incorporan atributos adicionales como parte de esta decisión.

---

## 3. CARDINALIDAD Y CICLO DE VIDA (DELIMITACIÓN DE LÍMITES)

### 3.1. Cardinalidad:
$$\text{CARDINALITY} = \text{UNDEFINED}$$
* No se asume $1:1$, $1:N$ ni $N:M$ como verdad arquitectónica cerrada. La cardinalidad será objeto de una decisión posterior cuando se diseñe el modelo físico.

### 3.2. Ciclo de Vida:
$$\text{ASSIGNMENT LIFECYCLE} = \text{UNDEFINED}$$
* La ausencia de asignación **NO** constituye un estado persistido `UNASSIGNED`; es simplemente la ausencia de vínculo formal.
* No se crean estados ni máquinas de transición (`ASSIGNED`, `REVOKED`, `SUSPENDED`).

---

## 4. AUDITORÍA, MARCAS TEMPORALES Y CONTEXTO

1. **Auditoría de Actor:**  
   $$\text{ASSIGNING ACTOR} = \text{UNDEFINED}$$  
   No se establece la persistencia obligatoria de `assigned_by`.
2. **Marcas Temporales:**  
   $$\text{TEMPORAL ATTRIBUTES} = \text{UNDEFINED}$$  
   No se establecen columnas como `assigned_at`, `revoked_at` ni `updated_at`.
3. **Contexto Operativo:**  
   $$\text{TENANT / ESTABLISHMENT CONTEXT} = \text{DERIVABLE}$$  
   `establishment_id` y `tenant_id` se derivan del contexto de la oferta de servicio y de la membresía activa del profesional, sin exigir duplicación física redundante.

---

## 5. ARTICULACIÓN CON DECISIONES CERRADAS

### 5.1. Relación con `DEC-CAT-001` (Catálogo Post-Handover)
* `SERVICE_OFFER = OPERATIONAL STATE POST-HANDOVER` (`IDENTITY REQUIREMENT = DEMONSTRATED`).
* La Assignment referencia conceptualmente esa oferta durable. Esta decisión **no** decide todavía cómo se materializa físicamente dicha referencia.

### 5.2. Relación con `DEC-AS-001` (Autoridad de Asignación)
* Se preserva íntegramente la regla de autoridad:
  $$\text{ACTIVE USER} + \text{ACTIVE MEMBERSHIP} + \text{ROLE} \in \{\text{'OWNER'}, \text{'MANAGER'}\} + \text{ACTIVE CONTEXT} + \text{TARGET ESTABLISHMENT == ACTIVE ESTABLISHMENT}$$

### 5.3. Relación con `DEC-SE-001` (Instanciación Tardía)
* Se preserva el axioma:
  $$\text{ASSIGNMENT} \neq \text{B2C MATERIALIZATION}$$
  Una Assignment durable en SaaS **NO** crea automáticamente filas en `public.services`.

### 5.4. Relación con `DEC-AS-003` (Materialization Triggering)
* `DEC-AS-003` permanece **`PENDING 🟡`**. Esta decisión no determina cuándo ni bajo qué disparador se produce la materialización en B2C.

---

## 6. MODELO FÍSICO DE PERSISTENCIA

Se formaliza explícitamente:

$$\text{PHYSICAL PERSISTENCE MODEL} = \text{NOT YET DECIDED}$$

### Registro de Opciones Físicas para Decisión Posterior:
Queda registrado que una fase posterior podrá evaluar:
* **OPTION A:** *Independent Assignment State* (Vínculo/Relación autónoma en base de datos).
* **OPTION B:** *Embedded Assignment State* (Estado integrado dentro del activo operativo de `SERVICE_OFFER`).

*Ninguna de estas opciones queda seleccionada ni diseñada físicamente por este Decision Record.*

---

## 7. DISTINCIONES CANÓNICAS FORMALIZADAS

```text
================================================================================
DISTINCIONES CANÓNICAS OBLIGATORIAS:

1. SERVICE_OFFER    ≠  ASSIGNMENT
2. ASSIGNMENT       ≠  B2C SERVICE (public.services)
3. PROFESSIONAL     ≠  B2C PROVIDER (perfiles_prestador)
4. CAPABILITY       ≠  ASSIGNMENT (assigned_categories)
5. OPERATIONAL STATE≠  PHYSICAL TABLE (DDL en PostgreSQL)
================================================================================
```

---

## 8. NO AUTORIZACIÓN DE IMPLEMENTACIÓN

Este Decision Record es exclusivamente **arquitectónico y normativo**.

**NO autoriza:**
- Creación de tablas SQL, índices, foreign keys ni migraciones (`067+`).
- Creación de endpoints, middlewares o servicios backend.
- Modificación de esquemas B2C (`public.services`, `public.perfiles_prestador`).
- Modificación de contratos cerrados (`CDC`, `HBC`, `NODO-01`, `Foundation`).
- Diseño o implementación de `NODO-02`.

---

## 9. MATRIZ DE ACTIVOS PROTEGIDOS

```text
+------------------------------------+----------------------------------+-----------------------------+
| Activo Protegido                   | Contrato / Migración             | Estado                      |
+------------------------------------+----------------------------------+-----------------------------+
| SaaS Foundation Core               | 065_saas_foundation_core.sql     | CLOSED 🔒                   |
| Context Resolution                 | 066_context_resolution_...sql    | CLOSED 🔒                   |
| Active Context Module              | ACTIVE-CONTEXT-NODE-CONTRACT     | CLOSED 🔒                   |
| Hub Salón Cockpit                  | HUB-SALON-NODE-CONTRACT          | CLOSED 🔒                   |
| Crear Desde Cero Pipeline          | CREAR-DESDE-CERO-NODE-CONTRACT   | CLOSED 🔒                   |
| Handover Boundary Contract (HBC)   | HANDOVER-BOUNDARY-CONTRACT-v1.0  | CLOSED 🔒                   |
| NODO-01 Adapter                    | NODO-01-NODE-CONTRACT-v1.0       | CLOSED 🔒                   |
| DEC-SE-001 (Instanciación Tardía)  | DEC-SE-001-DECISION-RECORD-v1.0  | CLOSED 🔒                   |
| DEC-SE-002 (Autonomía B2C)         | DEC-SE-002-DECISION-RECORD-v1.0  | CLOSED 🔒                   |
| DEC-AS-001 (Assignment Authority)  | DEC-AS-001-DECISION-RECORD-v1.0  | CLOSED 🔒                   |
| DEC-CAT-001 (Catalog Lifecycle)    | DEC-CAT-001-DECISION-RECORD-v1.0 | CLOSED 🔒                   |
| DEC-AS-002 (Assignment Model)      | DEC-AS-002-DECISION-RECORD-v1.0  | CLOSED 🔒                   |
| Pre-Node 01 (B2C Schema)           | PostgreSQL public schema         | IMMUTABLE 🔒                |
| SOUL + Governance Protocol         | NCP Protocols                    | PROTECTED 🔒                |
+------------------------------------+----------------------------------+-----------------------------+
```

---

## 10. ESTADO FINAL CANÓNICO

```text
================================================================================
DEC-AS-002

ASSIGNMENT PERSISTENCE MODEL & MINIMUM DURABLE STATE

DECISION:
ASSIGNMENT = DURABLE SAAS STATE
MINIMUM STATE = REFERENCE TO SERVICE_OFFER + REFERENCE TO ACTIVE PROFESSIONAL

STATUS: APPROVED — CLOSED 🔒

CARDINALITY = UNDEFINED
LIFECYCLE = UNDEFINED
AUDIT = UNDEFINED
TEMPORAL ATTRIBUTES = UNDEFINED
CONTEXT = DERIVABLE
PHYSICAL MODEL = NOT YET DECIDED

DEC-AS-003 = PENDING 🟡

NO IMPLEMENTATION AUTHORIZED BY THIS DECISION
================================================================================
```

---
*Fin del Decision Record DEC-AS-002.*
