# DEC-AS-001 — ARCHITECTURAL DECISION RECORD v1.0
## Formalización y Cierre: Autoridad de Asignación y Workflow Semántico (Assignment Authority & Workflow)

**DECISION_ID:** `DEC-AS-001`  
**TÍTULO:** Assignment Authority & Workflow  
**OPCIÓN APROBADA:** `OPTION B — OWNER + MANAGER`  
**STATUS:** `APPROVED — CLOSED 🔒`  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-001-002`  
**ANÁLISIS PREVIO:** [`/ncp/DEC-AS-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-AS-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md)  
**FECHA DE CIERRE:** 2026-09-10  

---

## 1. DECLARACIÓN FORMAL DE LA DECISIÓN

El Director del Proyecto GlowApp SaaS aprueba y formaliza **`OPTION B — OWNER + MANAGER`** como la regla canónica de autoridad y flujo conceptual para la asignación de personal a servicios en el dominio SaaS.

---

## 2. REGLA CANÓNICA DE AUTORIDAD (ASSIGNMENT AUTHORITY)

La facultad legítima para efectuar una asignación operacional en el catálogo de un establecimiento se define formalmente como:

```text
================================================================================
REGLA CANÓNICA DE AUTORIDAD (DEC-AS-001):

ASSIGNMENT AUTHORITY =
    ACTIVE USER
    + ACTIVE MEMBERSHIP
    + ROLE ∈ { 'OWNER', 'MANAGER' }
    + ACTIVE CONTEXT (Validado por Servidor)
    + TARGET ESTABLISHMENT == ACTIVE ESTABLISHMENT
================================================================================
```

### Principios Fundamentales:
1. **La Autoridad es Exclusivamente CONTEXTUAL:** No existe autoridad global ni transversal. La facultad de mando se limita estrictamente al `establishment_id` resuelto en el contexto activo (`req.activeContext`).
2. **Independencia de Roles entre Establecimientos:** Un usuario que posea membresías en múltiples establecimientos solo puede ejercer `Assignment Authority` en aquellos donde su rol sea `OWNER` o `MANAGER` y su membresía esté `ACTIVE`.
3. **Fuente de Autoridad:** La autoridad deriva exclusivamente de `memberships.role` + `memberships.status` en SaaS Foundation (`065`), nunca de roles heredados ni de campos no contextuales como `usuarios.rol` o `id_dueno`.

---

## 3. DEFINICIÓN CANÓNICA DE ASIGNACIÓN

```text
================================================================================
DEFINICIÓN CANÓNICA DE ASIGNACIÓN (DEC-AS-001):

ASSIGNMENT =
    Acto explícito y autorizado mediante el cual un OWNER o MANAGER contextual
    vincula una oferta de servicio (SERVICE_OFFER) con un colaborador (PROFESSIONAL)
    con membresía en estado ACTIVE dentro del mismo ESTABLISHMENT.
================================================================================
```

---

## 4. DESTINATARIO VÁLIDO DE LA ASIGNACIÓN (ASSIGNMENT TARGET)

El modelo semántico de destino de una asignación es:

$$\text{SERVICE\_OFFER} \longrightarrow \text{PROFESSIONAL}$$

### Requisitos del Destinatario:
1. Debe ser un colaborador con membresía formal en el mismo establecimiento del contexto activo.
2. Su membresía debe estar en estado **`ACTIVE`**.
3. Debe estar registrado y ser identificable como colaborador operativo dentro del modelo SaaS vigente.
4. **No Sustitución:** Queda prohibido utilizar `CAPABILITY` o `B2C PROVIDER` como sustitutos del colaborador humano destinatario.

---

## 5. WORKFLOW SEMÁNTICO CONCEPTUAL

El ciclo de vida de la asignación en la capa conceptual de gobernanza SaaS se define en la siguiente secuencia:

```text
================================================================================
WORKFLOW SEMÁNTICO DE ASIGNACIÓN:

      SERVICE_OFFER
            │
            │ assignment = NOT_ESTABLISHED
            ▼
 AUTHORIZED ASSIGNMENT ACTION (Invocada por OWNER/MANAGER contextual)
            │
            │ explicit target professional (Active Member de la misma sede)
            ▼
   ASSIGNMENT ESTABLISHED (Estado asignado en gobernanza SaaS)
================================================================================
```

*Nota: Este workflow es puramente conceptual y normativo. No autoriza la creación de una máquina de estados física, tablas, endpoints ni código.*

---

## 6. PRESERVACIÓN DE INVARIANTES SEMÁNTICOS

### 6.1. Invariante `CAPABILITY ≠ ASSIGNMENT`
* La posesión de aptitudes técnicas (`assigned_categories` / `capabilities`) **NO** constituye una asignación operativa.
* La coincidencia temática entre categoría de servicio y capacidades del colaborador no autoriza auto-asignación ni pre-asignación automática.

### 6.2. Invariante `PROFESSIONAL ≠ B2C PROVIDER`
* La asignación conceptual en SaaS **NO** crea automáticamente registros en `public.perfiles_prestador`.
* No altera el esquema `public.services` ni genera un `provider_id` B2C de forma automática.

### 6.3. Compatibilidad con `DEC-SE-001` (Instanciación Tardía)
* Una `ASSIGNMENT` habilita conceptualmente una futura materialización, pero no la ejecuta por defecto:
  $$\text{ASSIGNMENT} \neq \text{AUTOMATIC B2C MATERIALIZATION}$$
* Continúa vigente la regla de oro:
  $$\text{assignment.status = NOT\_ESTABLISHED} \implies \text{NO public.services}$$

### 6.4. Compatibilidad con `DEC-SE-002` (Autonomía de Ubicación y Horarios)
* La asignación no autoriza ni ejecuta sincronización de ubicación o de horarios sobre `perfiles_prestador`.

### 6.5. Compatibilidad con `NODO-01-v1.0`
* `NODO-01` permanece neutral, en memoria y sin ejecución de persistencia ni mutación de asignaciones.

---

## 7. SEPARACIÓN RIGUROSA DE RESPONSABILIDADES Y DECISIONES PENDIENTES

Esta decisión resuelve y cierra **únicamente**:
- **WHO MAY ASSIGN:** `OWNER` y `MANAGER` del contexto activo.
- **TARGET OF ASSIGNMENT:** `SERVICE_OFFER → ACTIVE PROFESSIONAL`.

Quedan formalmente desacopladas y en estado pendiente:
* **`DEC-AS-002`:** *Assignment Persistence Model* — Modelo de persistencia (Tabla Relacional vs Payload Efímero / Evento). `[PENDING 🟡]`
* **`DEC-AS-003`:** *Materialization Triggering Policy* — Política de disparo de materialización en `public.services` (Inmediata vs Publicación de Catálogo). `[PENDING 🟡]`

---

## 8. ALCANCE Y NO-IMPLEMENTACIÓN

Este Decision Record es exclusivamente **arquitectónico y documental**.

**NO autoriza:**
- Creación ni modificación de código fuente backend/frontend.
- Creación de endpoints, middlewares ni servicios.
- Creación de tablas, columnas ni migraciones de base de datos.
- Creación de registros en `public.services` ni `public.perfiles_prestador`.
- Redacción del Node Contract de NODO-02.

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
| Pre-Node 01 (B2C Schema)           | PostgreSQL public schema         | IMMUTABLE 🔒                |
| SOUL + Governance Protocol         | NCP Protocols                    | PROTECTED 🔒                |
+------------------------------------+----------------------------------+-----------------------------+
```

---

## 10. ESTADO FINAL CANÓNICO

```text
================================================================================
DEC-AS-001

ASSIGNMENT AUTHORITY & WORKFLOW

OPTION B — OWNER + MANAGER

AUTHORITY:
ACTIVE OWNER/MANAGER
WITHIN ACTIVE CONTEXT
AND ACTIVE MEMBERSHIP

TARGET:
SERVICE_OFFER → ACTIVE PROFESSIONAL

STATUS: APPROVED — CLOSED 🔒

DEC-AS-002: PENDING 🟡
DEC-AS-003: PENDING 🟡

NO IMPLEMENTATION AUTHORIZED BY THIS DECISION
================================================================================
```

---
*Fin del Decision Record DEC-AS-001.*
