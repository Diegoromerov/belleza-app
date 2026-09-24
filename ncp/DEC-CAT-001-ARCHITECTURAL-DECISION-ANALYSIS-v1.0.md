# DEC-CAT-001 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0 (RECONCILIADO)
## Ciclo de Vida de la Oferta de Servicio Post-Handover (Service Offer Post-Handover Lifecycle)

**DECISION_ID:** `DEC-CAT-001`  
**ESTADO:** `RECONCILIATION COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Lifecycle Reconciliation  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-CAT-001-001` / `DEC-CAT-001-R1`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`, `DEC-AS-001-DECISION-RECORD-v1.0.md`  
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EXECUTIVE FINDING (HALLAZGO EJECUTIVO)

La reconciliación rigurosa del ciclo de vida post-handover establece:

1. **[FACT] Transitoriedad en Origen (CDC):** En `Crear Desde Cero` (`DEC-CDC-001`), la oferta de servicio nace como una **intención inicial transitoria** (`relevant_services`), transportada como un DTO en memoria (`NEW TABLES = 0`).
2. **[EVIDENCE] La Necesidad Post-Handover:** Al cruzar la frontera de `NODO-01-v1.0`, la oferta se entrega como `candidate_service_descriptor` con `assignment.status = "NOT_ESTABLISHED"`.
3. **[EVIDENCE] Incompatibilidad de Descarte (Opción A):** Si la oferta se descartara al finalizar el request de handover (`OPTION A — DISCARD`), resultaría imposible cumplir `DEC-SE-001` (Instanciación Tardía) y `DEC-AS-001` (Asignación por OWNER/MANAGER), ya que la oferta desaparecería antes de que el administrador pueda asignarla.
4. **[EVIDENCE] Transición a Estado Operativo (Opción B):** Para satisfacer la arquitectura global, la oferta de servicio debe transformarse post-handover en un **ACTIVO OPERATIVO (Operational State)** en el dominio SaaS, adquiriendo identidad y durabilidad.
5. **[EVIDENCE] Preservación de DEC-CDC-001:** Esta transición ocurre **aguas abajo del Handover**, preservando estrictamente la regla `NEW TABLES = 0` dentro del nodo `Crear Desde Cero`.
6. **[DICTAMEN]** Se recomienda formalmente **`OPTION B — BECOMES OPERATIONAL STATE`** (`IDENTITY REQUIREMENT = DEMONSTRATED`), lo cual desbloquea la resolución de `DEC-AS-002` (Persistencia de Asignación).

---

## 2. ESTADO ACTUAL DEMOSTRADO EN EL PIPELINE

```text
================================================================================
ESTADO ACTUAL DEMOSTRADO:

[CREAR DESDE CERO] ──> [CONTEXT PACKAGE] ──> [HBC v1.0] ──> [NODO-01 v1.0] ──> [ADAPTATION RESULT]
(Intención Inicial)     (DTO 16 Atributos)    (Handover DTO) (Adapter Memoria) (candidate_services)
                                                                                       │
                                                                                       ▼
                                                                                assignment:
                                                                                NOT_ESTABLISHED
================================================================================
```

* `service_offers` no posee actualmente en código: ID durable, UUID, tabla propia, ni persistencia física en PostgreSQL.

---

## 3. INVESTIGACIÓN EXHAUSTIVA DE ACTIVOS

### 3.1. Create From Zero (`CREAR-DESDE-CERO-NODE-CONTRACT-v1.0` / `DEC-CDC-001`) [FACT]:
* Representa una **intención inicial de configuración** (*Initial Onboarding Intent*).
* Captura datos en tránsito y compila el DTO en memoria.
* Aplica la regla `NEW TABLES = 0` exclusivamente al ámbito interno del nodo CDC.

### 3.2. Handover Boundary Contract (`HBC v1.0`) [FACT]:
* Es un **Handover Snapshot** o paquete de lanzamiento (*Launch Bundle*).
* Transporta `service_offers` a nivel de establecimiento, fijando `assignment = NOT_ESTABLISHED` y omitiendo `provider_id`.

### 3.3. Nodo 01 (`NODO-01-v1.0`) [FACT]:
* Es un adaptador downstream de ingestión neutral en memoria.
* Entrega `candidate_service_descriptors` listos para ser operados o asignados aguas abajo (`ADAPTATION_READY`).

### 3.4. Hub Salón (`HUB-SALON-v1.0`) [FACT]:
* Es el cockpit operativo donde `OWNER` y `MANAGER` gobiernan la sede.
* Para poder mostrar el catálogo y asignar colaboradores en sesiones posteriores, requiere que las ofertas existan como estado consultable.

### 3.5. DEC-AS-001 y DEC-SE-001 [EVIDENCE]:
* `DEC-AS-001`: La asignación es un acto explícito ejecutado por `OWNER`/`MANAGER`.
* `DEC-SE-001`: Un servicio no asignado **no puede ingresar a `public.services`**.
* *Deducción Ineludible:* Si el servicio no está en `public.services` y tampoco persiste en SaaS, la oferta deja de existir en el universo físico, bloqueando cualquier asignación futura.

---

## 4. DEFINICIÓN SEMÁNTICA CRÍTICA DE `SERVICE_OFFER`

Se clasifica la naturaleza de la oferta a lo largo del pipeline:

```text
+-----------------------+----------------------------------+----------------------------------------------------+
| Fase del Pipeline     | Categoría Semántica              | Comportamiento y Durabilidad                       |
+-----------------------+----------------------------------+----------------------------------------------------+
| 1. En Crear Desde Cero| INTENTION (Intención Inicial)    | Payload en tránsito en memoria (DEC-CDC-001).      |
| 2. En Handover (HBC)  | SNAPSHOT (Paquete de Entrega)    | DTO inmutable en memoria (HBC v1.0 / Nodo 01).     |
| 3. Post-Handover      | OPERATIONAL ASSET (Activo SaaS)  | Estado durable que puede ser asignado y publicado. |
+-----------------------+----------------------------------+----------------------------------------------------+
```

---

## 5. EVALUACIÓN DE ALTERNATIVAS DE CICLO DE VIDA

```text
================================================================================
ALTERNATIVAS DE CICLO DE VIDA POST-HANDOVER:

[OPTION A: TRANSIENT LIFECYCLE / CONSUME & DISCARD]
  CREATE ──> TRANSIENT ──> HANDOVER ──> CONSUME ──> DISCARD
  (Inviable con DEC-SE-001: Si no hay asignación en el instante del onboarding,
   la oferta se pierde definitivamente).

[OPTION B: OPERATIONAL STATE (Recomendada)]
  CREATE ──> TRANSIENT ──> HANDOVER ──> BECOMES OPERATIONAL STATE
  (La oferta transitoria de CDC se convierte en un activo operativo durable
   en el dominio SaaS post-handover, permitiendo asignación asíncrona).

[OPTION C: EXPLICIT ACTIVATION]
  CREATE ──> TRANSIENT ──> HANDOVER ──> REQUIRES EXPLICIT ACTIVATION ──> OPERATIONAL STATE
  (Variante de Option B que exige un paso manual adicional de aprobación).

[OPTION D: ALTERNATIVE LIFECYCLE]
  (Cualquier otro flujo no demostrado por la evidencia actual).
================================================================================
```

---

## 6. ANÁLISIS DE RECUPERABILIDAD (PREGUNTAS Q1 A Q6)

### Q1: Después del onboarding, ¿el sistema necesita volver a encontrar la misma oferta?
**SÍ [EVIDENCE].** Para que el `OWNER`/`MANAGER` pueda asignarle un profesional (`DEC-AS-001`), el sistema debe poder recuperar la oferta.

### Q2: ¿Necesita modificarla?
**SÍ [EVIDENCE].** Actualizar precio, duración o descripción desde el Cockpit del salón.

### Q3: ¿Necesita asignarla posteriormente?
**SÍ [EVIDENCE].** `DEC-SE-001` establece que los servicios llegan sin asignar (`NOT_ESTABLISHED`) y se asignan bajo demanda.

### Q4: ¿Necesita conservar su relación con el establecimiento?
**SÍ [EVIDENCE].** La oferta pertenece a la sede (`establishments.id`), no al profesional ni al usuario.

### Q5: ¿Necesita conservar su estado independientemente de B2C?
**SÍ [EVIDENCE].** En B2C no puede existir hasta tener `provider_id` (`DEC-SE-001`). Por ende, su existencia previa reside exclusivamente en SaaS.

### Q6: ¿Puede todo lo anterior ocurrir dentro del mismo flujo transitorio?
**NO [EVIDENCE].** Obligar a que la asignación ocurra estrictamente en el instante del onboarding inicial eliminaría la flexibilidad operativa del salón y violaría la premisa de instanciación tardía de `DEC-SE-001`.

---

## 7. DEPENDENCIAS: CATÁLOGO $\rightarrow$ ASIGNACIÓN $\rightarrow$ MATERIALIZACIÓN

Se mantiene la segregación absoluta entre las tres dimensiones:

```text
================================================================================
SEPARACIÓN DE TRES CONCEPTOS:

1. CATALOG LIFECYCLE (DEC-CAT-001):
   Oferta de servicio en SaaS -> Pasa a ser Activo Operativo Durable.

2. ASSIGNMENT (DEC-AS-001 / DEC-AS-002):
   OWNER/MANAGER vincula la Oferta de Servicio con un Profesional Activo.

3. B2C MATERIALIZATION (DEC-SE-001 / DEC-AS-003):
   La oferta asignada se inserta como fila ejecutable en public.services.
================================================================================
```

---

## 8. REQUERIMIENTO DE IDENTIDAD (IDENTITY REQUIREMENT)

En virtud de que la oferta debe convertirse en un estado operativo durable post-handover:

$$\text{IDENTITY REQUIREMENT} = \text{DEMONSTRATED}$$

* **Fundamento:** Para que una asignación (`DEC-AS-001`) pueda vincular formalmente una oferta con un colaborador, la oferta debe poseer un identificador estable y referenciable en el dominio SaaS post-handover.

---

## 9. PRESERVACIÓN DE `DEC-CDC-001` (CREAR DESDE CERO)

* **Regla Intacta:** `DEC-CDC-001 (NEW TABLES = 0)` permanece 100% inalterada dentro del nodo `Crear Desde Cero`.
* **Delimitación:** Crear Desde Cero finaliza al emitir el `Context Package` transitorio. La transición de la oferta a estado operativo persistente ocurre **aguas abajo del Handover**, en la capa de persistencia/gestión SaaS post-handover.

---

## 10. MATRIZ COMPARATIVA DE ECONOMÍA Y ARQUITECTURA

```text
+---------------------------------+-----------------------+-------------------------+-----------------------+--------------------+
| Criterio                        | OPTION A              | OPTION B (Recomendada)  | OPTION C              | OPTION D / E       |
|                                 | (Consume & Discard)   | (Operational State)     | (Explicit Activation) | (Alternativas)     |
+---------------------------------+-----------------------+-------------------------+-----------------------+--------------------+
| Respaldo en Evidencia           | NOT SUPPORTED         | SUPPORTED ✅            | PARTIALLY SUPP.       | NOT SUPPORTED      |
| Compatibilidad DEC-CDC-001      | Total                 | TOTAL (Aguas abajo) ✅  | Total                 | Incierto           |
| Compatibilidad HBC v1.0         | Total                 | TOTAL (Inmutable) ✅    | Compatible            | Incierto           |
| Compatibilidad NODO-01 v1.0     | Total                 | TOTAL (In-Memory) ✅    | Compatible            | Incierto           |
| Compatibilidad DEC-AS-001       | INCOMPATIBLE ❌       | TOTAL (Permite asignar)✅| Total                 | Incierto           |
| Compatibilidad DEC-SE-001       | INCOMPATIBLE ❌       | TOTAL (Tardía) ✅       | Total                 | Incierto           |
| Recuperabilidad Post-Handover   | IMPOSIBLE ❌          | TOTAL ✅                | Total                 | Incierto           |
| Requerimiento de Identidad      | No Requerida          | DEMONSTRATED ✅         | Demonstrated          | Undefined          |
| Complejidad Arquitectónica      | Baja                  | MODERADA / CONTROLADA   | Alta                  | Alta               |
| Nuevas Decisiones Requeridas    | Ninguna               | Desbloquea DEC-AS-002   | Sí                    | Sí                 |
+---------------------------------+-----------------------+-------------------------+-----------------------+--------------------+
```

---

## 11. IMPACTO DIRECTO SOBRE DEC-AS-002 Y DEC-AS-003

1. **Desbloqueo de `DEC-AS-002` (Assignment Persistence):**  
   Al reconocer que `service_offer` se convierte en un estado operativo con identidad post-handover, se elimina el bloqueo arquitectónico (`ARCHITECTURAL STOP`), permitiendo que `DEC-AS-002` formalice la persistencia de la relación de asignación.
2. **Desacoplamiento de `DEC-AS-003` (Materialization Policy):**  
   La materialización en `public.services` continúa desacoplada y se activará bajo las reglas que defina `DEC-AS-003`.

---

## 12. RECOMENDACIÓN FORMAL DE ARQUITECTURA

**Se recomienda formalmente la adopción de `OPTION B — BECOMES OPERATIONAL STATE`:**

1. **Definición Canónica:** La oferta de servicio (`service_offer`), concebida inicialmente como una intención transitoria en Crear Desde Cero, se transforma **post-handover** en un **Activo Operativo (Operational State)** en el dominio SaaS del establecimiento.
2. **Requerimiento de Identidad:** Post-handover, las ofertas de servicio requieren identidad estable (`IDENTITY REQUIREMENT = DEMONSTRATED`) para ser consultadas en el Hub Salón y referenciadas en las asignaciones de personal.
3. **Preservación Contractual:** `DEC-CDC-001`, `HBC v1.0` y `NODO-01-v1.0` permanecen intactos y en memoria dentro de sus respectivas fronteras.

---

## 13. DECISIÓN REQUERIDA DEL DIRECTOR (DIRECTOR DECISION REQUIRED)

Se somete a consideración del Director la siguiente resolución:

```text
================================================================================
PROPUESTA DE RESOLUCIÓN PARA DEC-CAT-001:

1. APROBAR OPTION B — BECOMES OPERATIONAL STATE como el ciclo de vida canónico
   de las ofertas de servicio post-handover.
2. RATIFICAR que post-handover las ofertas adquieren naturaleza de activo operativo
   con requerimiento de identidad estable (IDENTITY REQUIREMENT = DEMONSTRATED).
3. RATIFICAR que DEC-CDC-001 (NEW TABLES = 0) permanece intacto dentro de CDC.
4. LEVANTAR el Architectural Stop de DEC-AS-002 para proceder con la definición
   del modelo de persistencia de Assignment.
================================================================================
```

---
*Fin del documento reconciliado de Análisis de Decisión Arquitectónica DEC-CAT-001.*
