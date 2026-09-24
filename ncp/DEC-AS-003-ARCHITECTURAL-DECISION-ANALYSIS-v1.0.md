# DEC-AS-003 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0 (RECONCILIADO R1)
## Reconciliación del Disparador de Materialización en B2C (Materialization Trigger Reconciliation)

**DECISION_ID:** `DEC-AS-003`  
**ESTADO:** `RECONCILIATION COMPLETED — ARCHITECTURAL STOP ISSUED 🛑 — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Decision Analysis & Reconciliation  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-003-001` / `DEC-AS-003-R1`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`, `DEC-AS-001-DECISION-RECORD-v1.0.md`, `DEC-CAT-001-DECISION-RECORD-v1.0.md`, `DEC-AS-002-DECISION-RECORD-v1.0.md`  
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EXECUTIVE FINDING (HALLAZGO EJECUTIVO)

La reconciliación rigurosa de la frontera B2C y los contratos cerrados establece:

1. **[FACT] Restricción Física Irreductible en B2C:** En PostgreSQL (`schema.sql` / `init.sql`), la tabla `public.services` impone:
   $$\texttt{provider\_id INTEGER NOT NULL REFERENCES perfiles\_prestador(id)}$$
   Por ende, la materialización física en B2C **exige como precondición técnica que el usuario asignado posea un registro en `perfiles_prestador`**.
2. **[FACT] Inexistencia de Trigger en el Código:** En el repositorio actual (Legacy B2C / SaaS Core / Hub Salón / Nodo 01), no existe ninguna función, evento, endpoint ni contrato que formalice cuándo o mediante qué comando se dispara la materialización de un servicio asignado ($\text{NO EXISTING TRIGGER DEMONSTRATED}$).
3. **[EVIDENCE] Supresión de Supuestos No Demostrados:**  
   - No existe un comando formalizado de publicación ($\text{PUBLICATION COMMAND} = \text{UNDEFINED}$).
   - No existe un estado o acción de activación cerrada ($\text{ACTIVATION} = \text{UNDEFINED}$).
   - No existe política de revocación ni de desactivación B2C ($\text{REVOCATION / DEACTIVATION POLICY} = \text{UNDEFINED}$).
   - No existe estrategia física de idempotencia cerrada ($\text{IDEMPOTENCY} = \text{NOT YET DECIDED}$).
4. **[DICTAMEN / STOP]** Se emite un **`ARCHITECTURAL STOP`**. El disparador de materialización (`MATERIALIZATION TRIGGER`) permanece **`UNDEFINED`** y requiere una decisión de negocio y gobernanza del Director antes de poder especificarse el adaptador técnico downstream (`NODO-02`).

---

## 2. PRECEDENTES CERRADOS Y MARCO NORMATIVO

```text
================================================================================
MARCO NORMATIVO CERRADO:

1. DEC-CAT-001: SERVICE_OFFER = OPERATIONAL STATE POST-HANDOVER (Identity Demonstrated).
2. DEC-AS-001:  ASSIGNMENT AUTHORITY = OWNER/MANAGER en activeContext.
3. DEC-AS-002:  ASSIGNMENT = DURABLE SAAS STATE (Ref Oferta + Ref Profesional).
4. DEC-SE-001:  SERVICE_OFFER ≠ public.services (Instanciación Tardía).
                assignment NOT_ESTABLISHED => NO public.services.
5. DEC-SE-002:  Autonomía desacoplada de ubicación y horarios en B2C.
================================================================================
```

---

## 3. SEPARACIÓN RIGUROSA DE CUATRO DIMENSIONES

Para evitar cualquier confusión conceptual, se establece formalmente la frontera entre los cuatro conceptos:

$$\text{ASSIGNMENT} \neq \text{B2C PROVIDER ELIGIBILITY} \neq \text{MATERIALIZATION TRIGGER} \neq \text{ACTIVATION}$$

```text
+------------------------------+----------------------------------------------------+------------------------------------+
| Dimensión                    | Naturaleza Semántica                               | Estatus Factual Actual             |
+------------------------------+----------------------------------------------------+------------------------------------+
| ASSIGNMENT                   | Estado durable en SaaS: vinculación explícita      | DEC-AS-002 (Cerrado 🔒).           |
|                              | SERVICE_OFFER -> ACTIVE PROFESSIONAL.              |                                    |
|                              |                                                    |                                    |
| B2C PROVIDER ELIGIBILITY     | Precondición técnica física: existencia de fila en | Requisito físico de Foreign Key en |
|                              | public.perfiles_prestador(id).                     | PostgreSQL (schema.sql L88).       |
|                              |                                                    |                                    |
| MATERIALIZATION TRIGGER      | Evento o acción autorizada que ordena insertar     | NO DEMOSTRADO EN EL REPOSITORIO    |
|                              | registros en public.services.                      | (UNDEFINED 🛑).                    |
|                              |                                                    |                                    |
| ACTIVATION / PUBLICATION     | Acción de negocio opcional para hacer visible      | NO DEMOSTRADO EN EL REPOSITORIO    |
|                              | la oferta en el marketplace.                       | (UNDEFINED 🛑).                    |
+------------------------------+----------------------------------------------------+------------------------------------+
```

---

## 4. INVESTIGACIÓN DE DISPARADORES EN EL CÓDIGO EXISTENTE

Se auditó exhaustivamente el backend existente:
* **`backend/src/routes/serviceRoutes.js` / `serviceController.js`:**  
  Solo existe el endpoint legacy `POST /api/services` donde un prestador B2C individual crea sus propios servicios (`provider_id = req.user.id`).
* **Hub Salón (`hubSalonRoutes.js`):** Solo provee `/summary` y `/staff`. No tiene endpoints de publicación ni materialización.
* **Nodo 01 (`nodo01Service.js`):** Entrega `DOWNSTREAM ADAPTATION RESULT` en memoria. No inserta en `public.services`.
* **Conclusión Factual:** En el código actual **no existe ningún trigger implementado ni diseñado** para la materialización SaaS $\rightarrow$ B2C.

---

## 5. ANÁLISIS CRÍTICO DE LOS 5 CASOS

```text
+-------------------------------------------------------------------------------+-----------------------------------+
| Caso Evaluado                                                                 | Grado de Soporte en Evidencia     |
+-------------------------------------------------------------------------------+-----------------------------------+
| CASO 1: ASSIGNMENT -> MATERIALIZATION                                         | NOT SUPPORTED                     |
|         (Materialización automática al asignar; viola DEC-SE-001 e ignora FK) |                                   |
|                                                                               |                                   |
| CASO 2: ASSIGNMENT + EXPLICIT BUSINESS ACTION -> MATERIALIZATION              | PARTIALLY SUPPORTED (Hipótesis)   |
|         (Requiere definir cuál es la acción de negocio inexistente hoy)       |                                   |
|                                                                               |                                   |
| CASO 3: ASSIGNMENT + B2C ELIGIBILITY -> MATERIALIZATION                       | PARTIALLY SUPPORTED (Hipótesis)   |
|         (Identifica precondición técnica, pero carece de evento autorizador)  |                                   |
|                                                                               |                                   |
| CASO 4: ASSIGNMENT + B2C ELIGIBILITY + EXPLICIT ACTION -> MATERIALIZATION     | PARTIALLY SUPPORTED (Propuesta)   |
|         (Lógicamente completa, pero depende de decisiones previas no tomadas) |                                   |
|                                                                               |                                   |
| CASO 5: NO EXISTING TRIGGER DEMONSTRATED                                      | SUPPORTED BY EVIDENCE ✅          |
|         (Refleja con total honestidad el estado real del repositorio)         |                                   |
+-------------------------------------------------------------------------------+-----------------------------------+
```

---

## 6. CLASIFICACIÓN FACTUAL DE CONDICIONES Y ELEGIBILIDAD B2C

Se auditan las condiciones de elegibilidad del profesional para B2C:

* **`perfiles_prestador(id)` existe:** `REQUIRED` (Restricción física de Foreign Key `NOT NULL` en PostgreSQL).
* **`memberships.status = 'ACTIVE'`:** `REQUIRED` (`065` / `DEC-AS-001`).
* **`usuarios.rol = 'provider'` en B2C:** `UNDEFINED` (Validado en controladores legacy, pero no en contratos SaaS).
* **`perfiles_prestador.estatus_verificacion`:** `NOT REQUIRED` (B2C permite servicios con verificación `PENDIENTE`).
* **`perfiles_prestador.is_active`:** `NOT REQUIRED` (La tabla `services` gestiona su propio `is_active`).
* **`perfiles_prestador.ubicacion`:** `NOT REQUIRED` (Desacoplado por `DEC-SE-002`).

---

## 7. MAPEO DE MATERIALIZACIÓN Y LÍMITES DE CARDINALIDAD

* **En B2C (`public.services`):** Cada fila transaccional física representa estrictamente la tupla `(provider_id, name, price, duration_minutes)`.
* **En SaaS:** `DEC-AS-002` ratificó que $\text{CARDINALITY} = \text{UNDEFINED}$.
* **Regla:** La cardinalidad física en B2C ($1:1$ por prestador) **no** impone ni condiciona retroactivamente la cardinalidad de asignación en SaaS.

---

## 8. MATRIZ DE ECONOMÍA ARQUITECTÓNICA PURIFICADA

```text
+------------------------------+--------------------+--------------------+--------------------+--------------------+-----------------------+
| Criterio                     | Assignment Trigger | Explicit Action    | Eligibility Only   | Existing Event     | UNDEFINED (Recomend)  |
+------------------------------+--------------------+--------------------+--------------------+--------------------+-----------------------+
| Respaldo en Evidencia        | NOT SUPPORTED      | PARTIALLY SUPP.    | PARTIALLY SUPP.    | NOT SUPPORTED      | SUPPORTED ✅          |
| Cumplimiento DEC-SE-001      | INCOMPATIBLE ❌    | TOTAL              | Parcial            | Incierto           | TOTAL ✅              |
| Cumplimiento DEC-AS-001/002  | TOTAL              | TOTAL              | TOTAL              | Incierto           | TOTAL ✅              |
| Respeto a FK perfiles        | RIESGO DE ERROR ❌ | RIESGO DE ERROR ❌ | TOTAL              | Incierto           | TOTAL (Precondición)✅|
| Supuestos no demostrados     | Asume automatismo  | Asume comando      | Asume automatismo  | Asume evento       | NINGUNO (Cero supuest)✅|
| Complejidad                  | Baja               | Media              | Media              | Alta               | NULA                  |
| Necesidad de Decisiones      | Sí                 | Sí                 | Sí                 | Sí                 | SÍ (Formalizar Stop)  |
+------------------------------+--------------------+--------------------+--------------------+--------------------+-----------------------+
```

---

## 9. ARCHITECTURAL STOP (EMISIÓN FORMAL)

En estricto cumplimiento de la directiva del Director, se emite formalmente un **ARCHITECTURAL STOP**:

```text
================================================================================
🛑 ARCHITECTURAL STOP — DEC-AS-003:

PROBLEMA:
No se puede formalizar el disparador de materialización (MATERIALIZATION TRIGGER)
porque en el código existente y en los contratos cerrados NO existe ningún evento,
comando ni endpoint de publicación o activación de catálogo que ordene la
inserción física en public.services.

EVIDENCIA:
1. schema.sql (L88): services.provider_id exige perfiles_prestador(id) NOT NULL.
2. backend/src/routes/serviceRoutes.js: Solo existe creación manual por prestador B2C.
3. HUB-SALON-NODE-CONTRACT-v1.0: Cero endpoints de publicación o materialización.
4. DEC-SE-001: Exige que no haya materialización automática sin evento explícito.

IMPACTO:
Fabricar una "Activación Explícita" o un "Comando de Publicación" sin una decisión
previa de negocio del Director constituiría una invención no autorizada.

OPCIONES PARA EL DIRECTOR:
1. OPCIÓN TRIGGER AUTOMÁTICO CONDICIONADO: La materialización ocurre automáticamente
   cuando una asignación es autorizada Y el colaborador posee perfiles_prestador.
2. OPCIÓN TRIGGER MANUAL / COMANDO DE PUBLICACIÓN: Se requiere una decisión formal
   que cree el concepto de "Publicar Catálogo" en el Hub Salón.
3. OPCIÓN ON-BOARDING HANDOVER MATERIALIZATION: La materialización ocurre al
   completarse el flujo de Handover si el bundle viene con personal elegible.

DECISIÓN REQUERIDA:
El Director debe formalizar cuál de los mecanismos de negocio anteriores debe
constituir el disparador legítimo de materialización hacia B2C.
================================================================================
```

---

## 10. NO AUTORIZACIÓN DE IMPLEMENTACIÓN

Este documento es **exclusivamente de análisis y reconciliación**.

**NO autoriza:**
- Creación de código backend, endpoints ni middlewares.
- Modificaciones en tablas de base de datos B2C ni SaaS.
- Modificación de contratos cerrados (`CDC`, `HBC`, `NODO-01`, `Foundation`).
- Diseño o implementación de `NODO-02`.

---

## 11. SÍNTESIS DE LA RECONCILIACIÓN Y ESTADO FINAL

```text
================================================================================
ESTADO FORMAL RECONCILIADO (DEC-AS-003):

ASSIGNMENT
= DURABLE SAAS STATE (DEC-AS-002 🔒)

B2C PROVIDER ELIGIBILITY
= TECHNICAL PRECONDITION (perfiles_prestador.id REQUIRED)

MATERIALIZATION TRIGGER
= UNDEFINED 🛑 (PRIOR DIRECTOR DECISION REQUIRED)

STATUS: RECONCILIATION COMPLETED — ARCHITECTURAL STOP ISSUED 🛑
================================================================================
```

---

## 12. DECISIÓN REQUERIDA DEL DIRECTOR (DIRECTOR DECISION REQUIRED)

Se somete a consideración del Director la siguiente resolución:

```text
================================================================================
PROPUESTA DE RESOLUCIÓN PARA DEC-AS-003:

1. DECLARAR que la elegibilidad en perfiles_prestador es una PRECONDICIÓN TÉCNICA
   obligatoria impuesta por la base de datos PostgreSQL.
2. RECONOCER el ARCHITECTURAL STOP en DEC-AS-003 (Trigger = UNDEFINED).
3. SELECCIONAR la política de disparo de negocio:
   - ALTERNATIVA A: Disparo Automático Condicionado (Al asignar si es elegible).
   - ALTERNATIVA B: Disparo Manual Explícito (Comando "Publicar Catálogo").
   - ALTERNATIVA C: Disparo por Handover de Onboarding.
================================================================================
```

---
*Fin del documento reconciliado de Análisis de Decisión Arquitectónica DEC-AS-003.*
