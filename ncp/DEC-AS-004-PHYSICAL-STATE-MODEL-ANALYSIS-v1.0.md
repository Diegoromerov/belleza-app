# DEC-AS-004 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0 (RECONCILIADO R1)
## Reconciliación del Modelo Físico de Estado para Service Offer y Assignment (Physical State Model Reconciliation)

**DECISION_ID:** `DEC-AS-004`  
**ESTADO:** `DEC-AS-004 — RECONCILED ANALYSIS — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Physical State Model Reconciliation  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-004-001` / `DEC-AS-004-R1`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`, `DEC-AS-001-DECISION-RECORD-v1.0.md`, `DEC-CAT-001-DECISION-RECORD-v1.0.md`, `DEC-AS-002-DECISION-RECORD-v1.0.md`, `DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`, `DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md`  
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EXECUTIVE FINDING & DEPURACIÓN DE SUPUESTOS PREMATUROS

En estricto cumplimiento de las directivas de `DEC-AS-004-R1`, se eliminan todos los supuestos prematuros introducidos en el borrador previo (embedding forzado de asignación, cardinalidad 1:1 asumida, semántica de `NULL`, DDL provisional, políticas de cascada `ON DELETE`, y nombres físicos de tabla), estableciendo:

1. **[FACT] Pertenencia Directa de `SERVICE_OFFER` a `ESTABLISHMENT`:**  
   Una oferta de servicio pertenece directamente a la sede física (`establishments.id`). No puede derivar su pertenencia a través de `Assignment → Membership`, pues esto impediría que una oferta exista antes de ser asignada (`assignment = NOT_ESTABLISHED` en `HBC v1.0` y `DEC-SE-001`).
2. **[EVIDENCE] Identidad Propia Requerida:**  
   `SERVICE_OFFER` requiere identidad física propia en el dominio SaaS post-handover (`DEC-CAT-001`), unívoca e independiente de cualquier identificador B2C (`public.services.id`).
3. **[EVIDENCE] No Absorción Prematura de `ASSIGNMENT`:**  
   La asignación (`DEC-AS-002`) no debe absorberse como una columna embebida (`assigned_membership_id`) sin una decisión previa de cardinalidad. El vínculo debe mantenerse conceptualmente separado.
4. **[FACT] Supresión de Semánticas No Aprobadas:**  
   - $\text{CARDINALITY} = \text{UNDEFINED}$.
   - $\text{ASSIGNMENT LIFECYCLE} = \text{UNDEFINED}$.
   - $\text{DELETE SEMANTICS} = \text{UNDEFINED}$.
   - $\text{SERVICE\_OFFER ACTIVE STATE} = \text{UNDEFINED}$.
   - $\text{PHYSICAL TABLE NAME} = \text{UNDEFINED}$.
5. **[DICTAMEN]** Se formaliza el **Modelo Mínimo Conceptual Desacoplado**, sin convertirlo en DDL ni migraciones, dejando preparado el terreno para que el Director sancione la estructura definitiva.

---

## 2. INVESTIGACIÓN Y RECONCILIACIÓN DE PREGUNTAS CLAVE

### 2.1. RECONCILIACIÓN A — Identidad de `SERVICE_OFFER`
* **¿Qué identidad necesita?**  
  Requiere una identidad unívoca y durable en el dominio SaaS post-handover para ser referenciada por `Assignment` y consultada en el Hub Salón (`DEC-CAT-001`).
* **Delimitación:** Queda prohibido reutilizar `public.services.id`, `provider_id`, `membership_id` o `user_id`.
* **Clasificación:** $\text{SERVICE\_OFFER identity} = \text{REQUIRED BY DECISION (DEC-CAT-001)}$.

### 2.2. RECONCILIACIÓN B — Pertenencia Directa a `ESTABLISHMENT`
* **Evaluación Directa vs Indirecta:**
  - Si `SERVICE_OFFER` dependiera de `Membership` para conocer su establecimiento, una oferta no asignada (`NOT_ESTABLISHED`) sería un registro huérfano sin sede ni tenant.
  - La oferta nace en la sede (`HBC v1.0` L140).
* **Conclusión:** La relación $\text{SERVICE\_OFFER} \longrightarrow \text{ESTABLISHMENT}$ debe ser **directa**.
* **Clasificación:** $\text{SERVICE\_OFFER } \rightarrow \text{ Establishment} = \text{REQUIRED BY DECISION}$.

### 2.3. RECONCILIACIÓN C — No Absorción Prematura de `ASSIGNMENT`
* Incrustar `assigned_membership_id` directamente en la entidad de oferta forzaría arbitrariamente cardinalidad $1:1$ y crearía ambigüedad sobre el valor `NULL`.
* Por `DEC-AS-002`, la ausencia de asignación es simplemente la **ausencia de vínculo**, no un estado `UNASSIGNED` ni un `NULL` sobrecargado.
* **Clasificación:** $\text{Assignment physical representation} = \text{UNDEFINED}$.

### 2.4. RECONCILIACIÓN D — Cardinalidad de Asignación
* Ningún contrato cerrado define si una oferta puede asignarse a un solo profesional ($1:1$) o a múltiples colaboradores ($1:N$).
* **Regla:** Queda prohibido introducir `UNIQUE`, composite `UNIQUE`, arrays de IDs o tablas puente de forma prematura.
* **Clasificación:** $\text{Assignment cardinality} = \text{UNDEFINED}$.

### 2.5. RECONCILIACIÓN E — Estado Operativo (`is_active`)
* `public.services.is_active` pertenece a B2C (`DEC-PUB-001`).
* En SaaS, no existe decisión que formalice un ciclo de vida activo/inactivo para `SERVICE_OFFER`.
* **Clasificación:** $\text{SERVICE\_OFFER active state} = \text{UNDEFINED}$.

### 2.6. RECONCILIACIÓN F — Semántica de Eliminación
* No se asumen reglas `ON DELETE SET NULL`, `ON DELETE CASCADE`, `REVOKED`, `DISABLED` ni borrado lógico.
* **Clasificación:** $\text{Delete semantics} = \text{UNDEFINED}$.

### 2.7. RECONCILIACIÓN G — Denominación Física
* No se asume `establishment_services`, `service_offers` ni `catalog_services` como nombre final de tabla.
* **Clasificación:** $\text{Physical table name} = \text{UNDEFINED}$.

---

## 3. MODELO MÍNIMO CONCEPTUAL DESACOPLADO

El modelo conceptual resultante expresa de forma pura y desacoplada las relaciones demostradas:

```text
================================================================================
MODELO MÍNIMO CONCEPTUAL (SAAS DOMAIN):

1. ENTIDAD OFERTA (SERVICE_OFFER):
   - Posee Identidad Estable Propia (post-handover).
   - Pertenece directamente a un ESTABLISHMENT (y su TENANT correspondiente).
   - Conserva los descriptores comerciales mínimos (name, category, price, duration, description).

           │
           │ (belongs to)
           ▼
     ESTABLISHMENT (Sede Física en 065)

2. VÍNCULO DE ASIGNACIÓN (ASSIGNMENT):
   - Representa el vínculo conceptual entre SERVICE_OFFER y ACTIVE MEMBERSHIP / PROFESSIONAL.
   - Existe como estado durable en SaaS (DEC-AS-002).
   - Su representación física concreta (tabla independiente vs relación embebida)
     permanece DESACOPLADA y NO DECIDIDA.

     SERVICE_OFFER ◄────── [ASSIGNMENT] ──────► ACTIVE MEMBERSHIP (065)
================================================================================
```

---

## 4. MATRIZ FORMAL DE ESTADO ARQUITECTÓNICO

```text
+------------------------------------+-----------------------+-------------------------------------------------------------+
| Elemento Arquitectónico            | Estado                | Fundamento Normativo                                        |
+------------------------------------+-----------------------+-------------------------------------------------------------+
| SERVICE_OFFER durable              | REQUIRED BY DECISION  | DEC-CAT-001 (Operational State post-handover).              |
| SERVICE_OFFER identity             | REQUIRED BY DECISION  | DEC-CAT-001 (Identity Requirement = Demonstrated).          |
| SERVICE_OFFER → Establishment      | REQUIRED BY DECISION  | HBC v1.0 / CDC (Soberanía de sede; ofertas no asignadas).   |
| Assignment durable                 | REQUIRED BY DECISION  | DEC-AS-002 (Durable SaaS State).                            |
| Assignment target                  | DEMONSTRATED          | DEC-AS-001 (Active Professional vía memberships en 065).   |
| Assignment cardinality             | UNDEFINED             | No contractada (Permanece abierta).                         |
| Assignment lifecycle               | UNDEFINED             | DEC-AS-002 (No asume estados ni revoked).                   |
| Assignment physical representation | UNDEFINED             | Permanece abierta (Independiente vs Embebida).              |
| SERVICE_OFFER active state         | UNDEFINED             | DEC-PUB-001 (is_active pertenece a B2C; no duplicado en SaaS|
| Delete semantics                   | UNDEFINED             | No decidida (Sin cascadas ni soft deletes asumidos).        |
| Physical table name                | UNDEFINED             | No decidido (Evita fijar nombres de tabla prematuramente).  |
+------------------------------------+-----------------------+-------------------------------------------------------------+
```

---

## 5. SEPARACIÓN ABSOLUTA CON EL ECOSISTEMA B2C

Se ratifica la segregación entre el modelo SaaS y el esquema B2C:
* **En SaaS (Este Modelo):** `SERVICE_OFFER` pertenece a `ESTABLISHMENT` y se vincula mediante `ASSIGNMENT` a `MEMBERSHIP`.
* **En B2C (`public.services`):** `public.services` pertenece a `perfiles_prestador` (`provider_id INTEGER NOT NULL`).
* **Frontera:** Cero columnas de B2C en SaaS; cero dependencias hacia `public.bookings` o `public.perfiles_prestador`.

---

## 6. PROHIBICIONES Y NO-AUTORIZACIÓN DE IMPLEMENTACIÓN

Este documento es **exclusivamente conceptual y normativo**.

**NO autoriza:**
- Creación física de tablas SQL, índices, foreign keys ni migraciones (`067+`).
- Creación de endpoints, middlewares o servicios backend.
- Modificación de esquemas B2C (`public.services`, `public.perfiles_prestador`).
- Modificación de contratos cerrados (`CDC`, `HBC`, `NODO-01`, `Foundation`).
- Redacción del Node Contract de NODO-02.

---

## 7. ESTADO FINAL RECONCILIADO

```text
================================================================================
DEC-AS-004

SERVICE_OFFER & ASSIGNMENT PHYSICAL STATE MODEL ANALYSIS

STATUS: DEC-AS-004 — RECONCILED ANALYSIS — PENDING DIRECTOR DECISION 🟡

NO IMPLEMENTATION AUTHORIZED BY THIS ANALYSIS
================================================================================
```

---
*Fin del documento reconciliado de Análisis de Decisión Arquitectónica DEC-AS-004.*
