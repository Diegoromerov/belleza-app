# DEC-PUB-001 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0 (RECONCILIADO R1)
## Reconciliación Semántica de Publicación, Activación y Disponibilidad (Service Availability & Publication Semantics)

**DECISION_ID:** `DEC-PUB-001`  
**ESTADO:** `RECONCILED ANALYSIS — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Semantic Decision Analysis & Reconciliation  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-PUB-001` / `DEC-PUB-001-R1`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`, `DEC-AS-001-DECISION-RECORD-v1.0.md`, `DEC-CAT-001-DECISION-RECORD-v1.0.md`, `DEC-AS-002-DECISION-RECORD-v1.0.md`, `DEC-AS-003-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`  
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EXECUTIVE FINDING & SEPARACIÓN RIGUROSA DE DIMENSIONES

La reconciliación semántica del estado de publicación, activación y disponibilidad en el repositorio establece de forma estricta:

1. **[FACT] Inexistencia de Workflow de Publicación (`PUBLICATION = NOT PRESENT`):** En el código B2C (`Pre-Nodo 01`), frontend y contratos SaaS no existe ninguna entidad, tabla, estado (`PUBLISHED`), comando (`publish`) ni endpoint de publicación.
2. **[FACT] Inexistencia de Workflow de Activación (`ACTIVATION = NOT PRESENT`):** No existe un flujo de activación independiente ni estados como `ACTIVATED` o comandos de activación formal.
3. **[FACT] Disponibilidad B2C Gobernada por Flag Operativo (`is_active`):** En el esquema transaccional `public.services`, la disponibilidad para reservas en `public.bookings` está gobernada exclusivamente por el flag booleano:
   $$\texttt{public.services.is\_active = TRUE}$$
   junto con la disponibilidad del prestador en `public.perfiles_prestador`.
4. **[EVIDENCE] Eliminación de Equivalencia Falsa con Materialización:** Se elimina la inferencia de que la coincidencia de oferta, asignación y elegibilidad equivale automáticamente a la materialización. La formulación correcta y demostrada es:
   $$\text{SERVICE\_OFFER} + \text{ASSIGNMENT} + \text{B2C PROVIDER ELIGIBILITY} = \text{CANDIDATE CONDITIONS FOR MATERIALIZATION}$$
   $$\text{MATERIALIZATION TRIGGER} = \text{UNDEFINED (DEC-AS-003 PENDING 🟡)}$$
5. **[DICTAMEN]** `DEC-PUB-001` define exclusivamente la **semántica B2C existente** y no absorbe ni define el disparador de materialización, el cual corresponde privativamente a **`DEC-AS-003`**.

---

## 2. AXIOMAS DE SEPARACIÓN CONCEPTUAL

Se ratifica el principio obligatorio de no equivalencia entre dominios:

$$\text{SERVICE\_OFFER} \neq \text{B2C SERVICE (public.services)}$$
$$\text{ASSIGNMENT} \neq \text{PUBLICATION}$$
$$\text{ELIGIBILITY} \neq \text{ACTIVATION}$$
$$\text{MATERIALIZATION} \neq \text{PUBLICATION}$$

* **`SERVICE_OFFER`:** Oferta / intención operativa en el dominio SaaS (`DEC-CAT-001`).
* **`public.services`:** Representación física transaccional en el esquema B2C existente.
* **`ASSIGNMENT`:** Vínculo formal `SERVICE_OFFER → ACTIVE PROFESSIONAL` en SaaS (`DEC-AS-001`, `DEC-AS-002`).
* **`B2C PROVIDER ELIGIBILITY`:** Precondición física (existencia de fila en `perfiles_prestador(id)`).
* **`MATERIALIZATION`:** Inserción técnica en `public.services` con `provider_id`.

---

## 3. CLASIFICACIÓN DE CONCEPTOS DEMOSTRADOS EN EL REPOSITORIO

```text
+------------------------------+------------------------------------+---------------------------------------------------------------+
| Concepto                     | Clasificación                      | Evidencia Física y Contractual                                |
+------------------------------+------------------------------------+---------------------------------------------------------------+
| PUBLICATION                  | NOT PRESENT                        | Cero entidades, cero comandos publish, cero tablas borrador.   |
| ACTIVATION                   | NOT PRESENT (como workflow indep.) | No existe entidad ni comando Activate en SaaS ni B2C.         |
| B2C is_active                | DEMONSTRATED AS OPERATIONAL FLAG   | Columna BOOLEAN DEFAULT TRUE en public.services y perfiles.   |
| B2C OPERATIONAL AVAILABILITY | DEMONSTRATED                       | Condición lógica: services.is_active = true + perfiles activos|
| SERVICE_OFFER                | DEMONSTRATED                       | Activo operativo en dominio SaaS (DEC-CAT-001).               |
| ASSIGNMENT                   | DEMONSTRATED / CLOSED              | Estado durable en dominio SaaS (DEC-AS-002).                  |
| MATERIALIZATION              | CONCEPTUALLY REQUIRED DOWNSTREAM   | Requerido para agendamiento B2C (DEC-SE-001).                 |
| MATERIALIZATION TRIGGER      | UNDEFINED                          | No demostrado en el código actual (Pendiente en DEC-AS-003).  |
+------------------------------+------------------------------------+---------------------------------------------------------------+
```

---

## 4. AUDITORÍA FÍSICA DE `public.services.is_active` Y DISPONIBILIDAD B2C

### 4.1. Código B2C (`backend/src/controllers/serviceController.js`) [FACT]:
```javascript
// El listado de servicios para el prestador y para reservas consulta:
const services = await Service.findAll({
  where: { provider_id: req.user.id },
  order: [['name', 'ASC']]
});
// Y formatea is_active: !!service.is_active
```

### 4.2. Base de Datos PostgreSQL (`schema.sql` L86-96) [FACT]:
* `is_active BOOLEAN DEFAULT TRUE` en `public.services`.
* `is_active BOOLEAN DEFAULT TRUE` en `public.perfiles_prestador`.
* `is_online BOOLEAN DEFAULT FALSE` en `public.perfiles_prestador`.

### 4.3. Significado Real de `is_active` [FACT]:
* `public.services.is_active` es un **flag operacional booleano**.
* No equivale a un estado de publicación (`is_active ≠ published`).
* Permite a un prestador habilitar o deshabilitar temporalmente un servicio en el marketplace sin destruirlo de la base de datos.

---

## 5. RESPUESTAS A LAS PREGUNTAS FINALES REQUERIDAS (Q1 A Q8)

### Q1: ¿Existe publicación independiente?
**NO DEMOSTRADA / NOT PRESENT [FACT].** No existe entidad, tabla, estado `PUBLISHED` ni comando de publicación en B2C ni SaaS.

### Q2: ¿Existe activación independiente?
**NO DEMOSTRADA / NOT PRESENT [FACT].** No existe workflow de activación independiente; solo el flag booleano `is_active`.

### Q3: ¿Qué significa `public.services.is_active`?
**FLAG OPERACIONAL BOOLEANO [FACT].** Campo en PostgreSQL que determina si un servicio materializado participa activamente en los flujos de consulta y reserva de clientes.

### Q4: ¿Una fila en `public.services` implica que el servicio está disponible?
**NO AUTOMÁTICAMENTE [FACT].** La existencia física de la fila no garantiza disponibilidad por sí sola; requiere que `is_active = TRUE` y que el prestador en `perfiles_prestador` esté activo y operativo.

### Q5: ¿Puede existir un servicio materializado pero no operativo?
**SÍ [FACT].** Cuando `public.services.is_active = FALSE` o cuando `perfiles_prestador.is_active = FALSE`.

### Q6: ¿Puede existir `SERVICE_OFFER` asignado pero no materializado?
**SÍ [EVIDENCE].** Es arquitectónicamente posible y legal bajo `DEC-SE-001` y `DEC-AS-002`, dado que la asignación es un estado durable en SaaS y el trigger de materialización no ha sido disparado.

### Q7: ¿Puede existir `SERVICE_OFFER` no asignado?
**SÍ [FACT].** Ratificado por `HBC v1.0` (`assignment.status = "NOT_ESTABLISHED"`), `DEC-SE-001` y `DEC-CAT-001`.

### Q8: ¿Está definido el trigger de materialización?
**NO [FACT].** `MATERIALIZATION TRIGGER = UNDEFINED`. Su definición corresponde exclusivamente a **`DEC-AS-003`**.

---

## 6. MATRIZ FINAL DE CLASIFICACIÓN SEMÁNTICA

```text
+-----------------------------------+-------------------------------------+
| Concepto                          | Estado Arquitectónico Demostrado    |
+-----------------------------------+-------------------------------------+
| SERVICE_OFFER                     | DEMONSTRATED                        |
| ASSIGNMENT                        | DEMONSTRATED / CLOSED BY DEC-AS-002 |
| PUBLICATION                       | NOT PRESENT                         |
| ACTIVATION                        | NOT PRESENT                         |
| B2C is_active                     | DEMONSTRATED (Operational Flag)     |
| B2C Operational Availability      | DEMONSTRATED (Conjunción de Flags)  |
| Materialization                   | CONCEPTUALLY REQUIRED DOWNSTREAM    |
| Materialization Trigger           | UNDEFINED                           |
| Automatic Materialization         | NOT APPROVED                        |
| Publication = Materialization     | NOT DEMONSTRATED                    |
| Activation = Materialization      | NOT DEMONSTRATED                    |
+-----------------------------------+-------------------------------------+
```

---

## 7. RELACIÓN Y DELIMITACIÓN CON DEC-AS-003

```text
================================================================================
DELIMITACIÓN DE RESPONSABILIDADES ENTRE DECISIONES:

  DEC-PUB-001 (Esta Decisión):
  ├── Define la semántica de disponibilidad en B2C (is_active = TRUE).
  ├── Demuestra que NO existe un workflow de publicación en el repositorio.
  └── Establece que la concurrencia de (Oferta + Asignación + Elegibilidad)
      constituye CONDICIONES CANDIDATAS, pero NO el trigger de ejecución.
               │
               ▼
  DEC-AS-003 (Decisión Dependiente):
  └── Resuelve y formaliza cuál es el ACTO o CONDICIÓN AUTORIZADA que dispara
      la materialización física hacia public.services.
================================================================================
```

---

## 8. NO AUTORIZACIÓN DE IMPLEMENTACIÓN

Este documento es **exclusivamente conceptual y analítico**.

**NO autoriza:**
- Creación de endpoints, migraciones ni tablas.
- Modificación de código backend ni frontend.
- Modificación de contratos cerrados (`Foundation`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001/002`, `DEC-CAT-001`).
- Diseño o implementación de `NODO-02`.
- Cierre anticipado de `DEC-AS-003`.

---

## 9. ESTADO FINAL RECONCILIADO

```text
================================================================================
DEC-PUB-001

SERVICE AVAILABILITY & PUBLICATION SEMANTICS

PUBLICATION = NOT PRESENT
ACTIVATION  = NOT PRESENT (Independent Workflow)
B2C AVAILABILITY = DEMONSTRATED (services.is_active = TRUE)
MATERIALIZATION TRIGGER = UNDEFINED (DEC-AS-003 PENDING)

STATUS: RECONCILED ANALYSIS — PENDING DIRECTOR DECISION 🟡

NO IMPLEMENTATION AUTHORIZED BY THIS ANALYSIS
================================================================================
```

---
*Fin del documento reconciliado de Análisis de Decisión Arquitectónica DEC-PUB-001.*
