# DEC-CAT-001 — ARCHITECTURAL DECISION RECORD v1.0
## Formalización y Cierre: Identidad y Ciclo de Vida del Catálogo SaaS Post-Handover (SaaS Catalog Identity & Lifecycle)

**DECISION_ID:** `DEC-CAT-001`  
**TÍTULO:** SaaS Catalog Identity & Lifecycle Post-Handover  
**OPCIÓN APROBADA:** `OPTION B — OPERATIONAL STATE`  
**STATUS:** `APPROVED — CLOSED 🔒`  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-CAT-001-002`  
**ANÁLISIS PREVIO:** [`/ncp/DEC-CAT-001-ARCHITECTURAL-DECISION-ANALISION-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-CAT-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md)  
**FECHA DE CIERRE:** 2026-09-10  

---

## 1. DECLARACIÓN FORMAL DE LA DECISIÓN

El Director del Proyecto GlowApp SaaS aprueba y formaliza **`OPTION B — OPERATIONAL STATE`** como la regla canónica para el ciclo de vida y la identidad de las ofertas de servicio (`service_offers`) post-handover en la arquitectura SaaS.

---

## 2. REGLA CANÓNICA DE CICLO DE VIDA POST-HANDOVER

```text
================================================================================
REGLA CANÓNICA DE CICLO DE VIDA (DEC-CAT-001):

1. EN ORIGEN (Create From Zero):
   SERVICE_OFFER nace como una intención inicial de configuración (DTO transitorio
   en memoria), respetando estrictamente DEC-CDC-001 (NEW TABLES = 0).

2. EN TRÁNSITO (HBC v1.0 / NODO-01 v1.0):
   SERVICE_OFFER se transporta e ingesta como un Handover Snapshot inmutable
   en memoria con assignment = NOT_ESTABLISHED y sin provider_id.

3. POST-HANDOVER (Downstream Domain):
   Al cruzar la frontera de NODO-01, la oferta NO desaparece ni se descarta;
   adquiere formalmente la naturaleza de ACTIVO OPERATIVO (OPERATIONAL STATE)
   del dominio SaaS del establecimiento.
================================================================================
```

---

## 3. REQUERIMIENTO DE IDENTIDAD ESTABLE

Se formaliza como principio arquitectónico obligatorio:

$$\text{IDENTITY REQUIREMENT} = \text{DEMONSTRATED}$$

### Alcance de la Identidad:
1. **Necesidad Demostrada:** Toda `SERVICE_OFFER` debe poder distinguirse de forma estable y unívoca en el dominio SaaS post-handover para hacer posible su gestión en el Hub Salón y su vinculación en asignaciones operativas (`DEC-AS-001`).
2. **Delimitación Estricta:** Esta decisión formaliza la **necesidad conceptual de identidad estable**. **NO** determina todavía el tipo de identificador físico (`UUID`, `integer ID`, `composite key`, `slug`), ni define nombres de tablas, columnas o esquemas en PostgreSQL.

---

## 4. DISTINCIÓN ENTRE ESTADO OPERATIVO Y TABLA FÍSICA

Se establece como axioma de diseño:

$$\text{OPERATIONAL STATE} \neq \text{PHYSICAL TABLE}$$

La formalización de que una oferta es un activo operativo **NO constituye autorización automática de tablas, columnas ni migraciones DDL**. El modelo de persistencia física concreta queda sujeto a decisiones posteriores.

---

## 5. PRESERVACIÓN DE INVARIANTES Y CONTRATOS CERRADOS

### 5.1. Preservación de `DEC-CDC-001` (Crear Desde Cero)
* Se ratifica la vigencia de `DEC-CDC-001 (NEW TABLES = 0)` dentro del nodo `Crear Desde Cero`.
* La adquisición de estado operativo ocurre **aguas abajo del Handover**, fuera de la responsabilidad de CDC. CDC permanece 100% transitorio.

### 5.2. Preservación de `HANDOVER-BOUNDARY-CONTRACT-v1.0` (HBC)
* `HBC v1.0` permanece `CLOSED` e `IMMUTABLE`.
* Queda prohibido añadir campos o identificadores retroactivamente dentro del DTO de `HBC v1.0`. La identidad requerida aplica al estado downstream post-handover.

### 5.3. Preservación de `NODO-01-v1.0`
* `NODO-01` permanece `CLOSED` e `IMMUTABLE`.
* Continúa operando como adaptador de ingestión, validación y adaptación puramente en memoria (`DOWNSTREAM ADAPTATION RESULT`).

### 5.4. Compatibilidad con `DEC-AS-001` (Assignment Authority)
* Se preserva el vínculo `SERVICE_OFFER → ACTIVE PROFESSIONAL` bajo autoridad exclusiva de `OWNER`/`MANAGER` en contexto activo.
* Esta decisión habilita conceptualmente que dicha asignación opere sobre una oferta que sobrevive al Handover.

### 5.5. Compatibilidad con `DEC-SE-001` (Instanciación Tardía)
* Se ratifica que `SERVICE_OFFER ≠ public.services`.
* Un servicio en estado `assignment: NOT_ESTABLISHED` bajo ninguna circunstancia genera filas en `public.services`. La materialización B2C continúa desacoplada y diferida.

---

## 6. DISTINCIONES CANÓNICAS FORMALIZADAS

```text
================================================================================
DISTINCIONES CANÓNICAS OBLIGATORIAS:

1. SERVICE_OFFER    ≠  B2C SERVICE (public.services)
2. SERVICE_OFFER    ≠  ASSIGNMENT (Vínculo de personal)
3. SERVICE_OFFER    ≠  PROFESSIONAL (Colaborador / Identity)
4. SERVICE_OFFER    ≠  CAPABILITY (assigned_categories)
5. OPERATIONAL STATE≠  PHYSICAL TABLE (DDL en base de datos)
================================================================================
```

---

## 7. IMPACTO Y DESBLOQUEO DE DECISIONES SUBSECUENTES

```text
+------------------------------------+-----------------------+-------------------------------------------------------------+
| Decisión                           | Estado                | Impacto Derivado de DEC-CAT-001                             |
+------------------------------------+-----------------------+-------------------------------------------------------------+
| DEC-AS-002                         | UNBLOCKED FOR         | Se levanta el Architectural Stop. Se autoriza el análisis   |
| (Assignment Persistence Model)     | ANALYSIS 🟡           | de persistencia de Assignment sabiendo que la oferta tiene |
|                                    |                       | estado operativo e identidad demostrada post-handover.     |
|                                    |                       |                                                             |
| DEC-AS-003                         | PENDING 🟡            | Permanece totalmente independiente y pendiente.             |
| (Materialization Triggering)       |                       | (No resuelve cuándo ocurre la inserción en public.services).|
+------------------------------------+-----------------------+-------------------------------------------------------------+
```

---

## 8. NO AUTORIZACIÓN DE IMPLEMENTACIÓN

Este Decision Record es exclusivamente **arquitectónico y normativo**.

**NO autoriza:**
- Creación de tablas, columnas, índices ni migraciones (`067+`).
- Generación o asignación física de `UUIDs` en base de datos.
- Modificación de código fuente en backend ni frontend.
- Modificación de contratos cerrados (`CDC`, `HBC`, `NODO-01`, `Foundation`).
- Implementación de `NODO-02` ni de motores de aprovisionamiento.

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
| Pre-Node 01 (B2C Schema)           | PostgreSQL public schema         | IMMUTABLE 🔒                |
| SOUL + Governance Protocol         | NCP Protocols                    | PROTECTED 🔒                |
+------------------------------------+----------------------------------+-----------------------------+
```

---

## 10. ESTADO FINAL CANÓNICO

```text
================================================================================
DEC-CAT-001

SAAS CATALOG IDENTITY & LIFECYCLE POST-HANDOVER

OPTION B — OPERATIONAL STATE

LIFECYCLE:
TRANSIENT IN CREATE FROM ZERO (DEC-CDC-001)
SNAPSHOT IN HANDOVER BOUNDARY (HBC v1.0)
OPERATIONAL STATE POST-HANDOVER (DOWNSTREAM)

IDENTITY:
IDENTITY REQUIREMENT = DEMONSTRATED

STATUS: APPROVED — CLOSED 🔒

DEC-AS-002: UNBLOCKED FOR ANALYSIS — PENDING 🟡
DEC-AS-003: PENDING 🟡

NO IMPLEMENTATION AUTHORIZED BY THIS DECISION
================================================================================
```

---
*Fin del Decision Record DEC-CAT-001.*
