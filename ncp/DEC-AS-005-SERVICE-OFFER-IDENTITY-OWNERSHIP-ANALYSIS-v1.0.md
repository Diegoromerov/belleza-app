# DEC-AS-005 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0
## Service Offer Identity & Establishment Ownership Analysis

**DECISION_ID:** `DEC-AS-005`  
**ESTADO:** `DEC-AS-005 — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Identity & Ownership Analysis  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-005-001`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`, `DEC-AS-001-DECISION-RECORD-v1.0.md`, `DEC-CAT-001-DECISION-RECORD-v1.0.md`, `DEC-AS-002-DECISION-RECORD-v1.0.md`, `DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`, `DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md`, `DEC-AS-004-PHYSICAL-STATE-MODEL-ANALYSIS-v1.0.md`  
**FECHA DE EMISIÓN:** 2026-09-10  

---

## 1. EXECUTIVE FINDINGS & CONTEXTO ARQUITECTÓNICO CERRADO

El presente análisis resuelve con alcance deliberadamente acotado las dos preguntas basales para la persistencia física de `SERVICE_OFFER` en el dominio SaaS:
1. **Identidad Física:** ¿Cómo se identifica unívocamente una oferta de servicio?
2. **Pertenencia Física (Ownership):** ¿A qué entidad pertenece físicamente la oferta?

### 1.1. Decisiones Previas Inmutables y Protegidas
- **`DEC-CAT-001` (APPROVED / CLOSED):** `SERVICE_OFFER` es transitoria durante *Crear Desde Cero*, snapshot en el *Handover Boundary Contract (HBC v1.0)*, y se convierte en **estado operativo durable** post-handover en SaaS.
- **`DEC-SE-001` (APPROVED / CLOSED):** `SERVICE_OFFER ≠ public.services` y `SERVICE_OFFER ≠ B2C SERVICE`.
- **`DEC-SE-002` (APPROVED / CLOSED):** La oferta no posee ubicación física ni horario propios; se desacoplan y derivan del establecimiento y del profesional.
- **`DEC-AS-001` (APPROVED / CLOSED):** La asignación es autorizada por `OWNER/MANAGER` en contexto activo hacia un profesional activo.
- **`DEC-AS-002` (APPROVED / CLOSED):** `ASSIGNMENT = DURABLE SAAS STATE`. Sobrevive al request original de creación.
- **`DEC-PUB-001` (RECONCILED):** Inexistencia de workflow de publicación/activación en SaaS. `services.is_active` es una semántica puramente B2C.
- **`DEC-AS-004-R1` (RECONCILED):** Se depuraron supuestos prematuros de embedding de asignación, cardinalidad forzada, semánticas de `NULL` y nombres de tablas.

### 1.2. Exclusiones Explícitas del Presente Análisis
- **NO** se resuelve la representación física de `ASSIGNMENT` (`ASSIGNMENT physical representation = UNDEFINED`).
- **NO** se resuelve la cardinalidad de `ASSIGNMENT` (`ASSIGNMENT cardinality = UNDEFINED`).
- **NO** se resuelve el ciclo de vida de `ASSIGNMENT` (`ASSIGNMENT lifecycle = UNDEFINED`).
- **NO** se resuelve la materialización en B2C (`public.services`).
- **NO** se crean migraciones, DDL, tablas ni código en runtime.

---

## 2. CORRECCIÓN Y PRECISIONES SOBRE DEC-AS-004-R1

En `DEC-AS-004-R1` se identificó que conceptualmente `SERVICE_OFFER` viaja encapsulado dentro de un `establishment_context` (`HBC v1.0` L140). Sin embargo:
- **`SERVICE_OFFER conceptual establishment ownership = REQUIRED BY ARCHITECTURE`**.
- **`SERVICE_OFFER physical establishment FK = UNDEFINED`** (hasta la evaluación formal del presente análisis).

Este análisis formaliza por qué la pertenencia debe materializarse como una clave foránea física directa hacia `establishments(id, tenant_id)`.

---

## 3. PREGUNTA A — IDENTIDAD FÍSICA DE `SERVICE_OFFER`

### 3.1. Opciones Evaluadas

| Opción | Descripción | Análisis de Factibilidad y Riesgos |
| :--- | :--- | :--- |
| **Option A** | **Identidad propia UUID (`gen_random_uuid()`)** | - **Estabilidad:** Inmutable ante cambios de nombres, precios o asignaciones.<br>- **Alineación Foundation:** Consistente con el modelo de identidades de Foundation `065` (`organizations.id UUID`, `establishments.id UUID`, `memberships.id UUID`).<br>- **Aislamiento Multi-Tenant:** Compatible con composite unique `(id, tenant_id)` y RLS.<br>- **Desacoplamiento B2C:** Totalmente independiente de enteros incrementales de `public.services.id` o `providers.id`.<br>- **Downstream:** Permite referencias estables desde `ASSIGNMENT`, auditoría, catálogo y eventual materialización. |
| **Option B** | **Identidad propia de otro tipo (BIGSERIAL / INTEGER / Clave Natural)** | - **INTEGER/BIGSERIAL:** Riesgo de colisiones en sharding, inconsistencia tipológica con las PKs UUID de Foundation.<br>- **Clave Natural (`establishment_id + slug/name`):** Frágil ante renombrado de servicios comerciales, complejiza referencias downstream en asignaciones. |
| **Option C** | **Reutilizar identidad de entidad existente (`public.services.id`, `provider_id`, `user_id`, `membership_id`)** | - **`public.services.id`:** Viola `DEC-SE-001` (`SERVICE_OFFER ≠ public.services`), rompería antes de la materialización downstream.<br>- **`user_id` / `membership_id`:** Confunde la persona o membresía con el servicio, impidiendo ofertas sin asignar o con múltiples asignados.<br>- **`provider_id`:** B2C puro, prohibido en SaaS (`DEC-SE-001`). |
| **Option D** | **Otra alternativa (e.g. ULID / UUIDv7)** | No aporta ventajas diferenciales sobre el estándar UUID de PostgreSQL soportado nativamente en `065` (`gen_random_uuid()`). |

### 3.2. Evaluación de Criterios de Identidad
1. **Lifecycle post-handover:** La identidad persiste indefinidamente en SaaS tras el handover de *Crear Desde Cero* (`DEC-CAT-001`).
2. **Assignment:** Permite que cualquier mecanismo de asignación referencie un `service_offer_id UUID` unívoco.
3. **Referencias Downstream:** El Hub Salón y motores de consumo pueden consultar la entidad sin ambigüedad.
4. **Independencia de B2C:** Protege la frontera SaaS-B2C de forma estricta.
5. **Tenant Isolation:** Se integra con la infraestructura RLS existente en PostgreSQL.

---

## 4. PREGUNTA B — OWNERSHIP FÍSICO DE `SERVICE_OFFER`

### 4.1. Opciones Evaluadas

| Opción | Estructura | Análisis de Pertenencia y Aislamiento |
| :--- | :--- | :--- |
| **Option A** | **Relación física directa con `ESTABLISHMENT`** (`establishment_id UUID` + `tenant_id INTEGER` con FK compuesta) | - La oferta pertenece a la sede física (`establishments.id`).<br>- La integridad es directa y autónoma.<br>- Compatible al 100% con `HBC v1.0` y Foundation `065`. |
| **Option B** | **Pertenencia derivada mediante otra relación** (e.g. `SERVICE_OFFER → ASSIGNMENT → MEMBERSHIP → ESTABLISHMENT` o `SERVICE_OFFER → ORGANIZATION`) | - Si se deriva de `MEMBERSHIP`, una oferta no asignada (`NOT_ESTABLISHED`) no tendría sede ni tenant (registro huérfano).<br>- Si se deriva solo de `ORGANIZATION`, una organización con múltiples sedes no sabría en qué local se ofrece el servicio. |
| **Option C** | **Otra estructura respaldada por evidencia** | No existe evidencia de otra entidad propietaria en el dominio SaaS. |

---

## 5. CRITERIOS DE EVALUACIÓN DE OWNERSHIP

Evaluación estricta de las 8 preguntas obligatorias para **Option A (Directa)** vs **Option B (Derivada)**:

| Criterio | Option A (Directa a Establishment) | Option B (Derivada vía Assignment/Membership) |
| :--- | :--- | :--- |
| **1. ¿Puede existir SERVICE_OFFER antes de ASSIGNMENT?** | **SÍ.** La oferta nace en la sede (`HBC v1.0`) con `assignment = NOT_ESTABLISHED` (`DEC-SE-001`). | **NO.** Requeriría un profesional obligatorio para poder registrar el servicio. |
| **2. ¿Puede existir SERVICE_OFFER sin PROFESSIONAL?** | **SÍ.** La oferta comercial es un activo del establecimiento, independientemente del staffing. | **NO.** Quedaría huérfana de pertenencia. |
| **3. ¿Puede cambiar posteriormente ASSIGNMENT?** | **SÍ.** La reasignación de personal no altera en absoluto la propiedad del servicio por la sede. | **NO.** Reasignar mutaría la relación de propiedad o rompería integridad. |
| **4. ¿La pertenencia a Establishment permanece estable aunque cambie Assignment?** | **SÍ.** La FK `establishment_id` es inmutable ante cambios de personal. | **NO.** Cambiaría la ruta de derivación. |
| **5. ¿La integridad tenant puede garantizarse físicamente?** | **SÍ.** Mediante FK compuesta `(establishment_id, tenant_id)` y política RLS directa por `tenant_id`. | **NO.** Transitividad frágil y dependiente de relaciones mutables. |
| **6. ¿La eliminación/revocación de un profesional afecta la identidad/propiedad de SERVICE_OFFER?** | **NO.** Si una membresía es revocada (`status = REVOKED`), la oferta en la sede permanece intacta. | **SÍ.** Provocaría cascadas destructivas o pérdida de contexto de la oferta. |
| **7. ¿La materialización B2C queda desacoplada?** | **SÍ.** La oferta existe en SaaS y se evalúa su materialización downstream de forma independiente. | **NO.** Acoplaría la oferta al profesional en todas las etapas. |
| **8. ¿El modelo conserva el contexto de Create From Zero / HBC?** | **SÍ.** En `HBC v1.0`, `establishment_context` contiene directamente `establishment_id` y `tenant_id`. | **NO.** Desnaturaliza el contrato de handover. |

---

## 6. REGLA FUNDAMENTAL: SEPARACIÓN DE OWNERSHIP Y ASSIGNMENT

Queda estrictamente formalizada la regla de desacoplamiento:

```text
================================================================================
REGLA FUNDAMENTAL DE DOMINIO SAAS:

1. PROPIEDAD (OWNERSHIP):
   - Una SERVICE_OFFER pertenece directa y exclusivamente a un ESTABLISHMENT.
   - El ESTABLISHMENT es el único propietario del catálogo y de la oferta comercial.

2. ASIGNACIÓN (ASSIGNMENT):
   - Es un vínculo operacional subordinado y desacoplado.
   - NO determina quién es el dueño de la SERVICE_OFFER.
   - La propiedad de la SERVICE_OFFER NO determina quién es el profesional asignado.

                  ┌──────────────────────────────┐
                  │        ESTABLISHMENT         │
                  └──────────────┬───────────────┘
                                 │
                                 │ (physical ownership - DIRECT FK)
                                 ▼
                  ┌──────────────────────────────┐
                  │        SERVICE_OFFER         │
                  └──────────────┬───────────────┘
                                 │
                                 │ (optional/decoupled link)
                                 ▼
                  [ ASSIGNMENT (Durable SaaS State) ]
                                 │
                                 ▼
                       ACTIVE PROFESSIONAL (065)
================================================================================
```

---

## 7. TENANT ISOLATION Y COMPATIBILIDAD CON FOUNDATION (065)

Para garantizar la seguridad multi-tenant de `SERVICE_OFFER` sin depender de inputs manipulables de cliente o JWT:

1. **Columna Física de Tenant:**  
   `tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT`
2. **Clave Foránea Compuesta de Integridad de Sede:**  
   `CONSTRAINT fk_service_offer_establishment FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT`
3. **Restricción de Afinidad Tenant:**  
   `CONSTRAINT uq_service_offer_id_tenant UNIQUE (id, tenant_id)`
4. **Aislamiento Row-Level Security (RLS) PostgreSQL:**  
   ```sql
   ALTER TABLE service_offers ENABLE ROW LEVEL SECURITY;
   CREATE POLICY tenant_isolation_service_offers ON service_offers
       FOR ALL
       USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
       WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
   ```
5. **Garantía:** No se aceptan `tenant_id` enviados por el cliente. El `tenant_id` es inyectado por el middleware de contexto SaaS verificado (`066_context_resolution_tenant_resolver.sql`).

---

## 8. CLASIFICACIÓN RIGUROSA DE ATRIBUTOS

Basado en la evidencia de `CDC v1.0` y `HBC v1.0`:

| Atributo | Tipo Conceptual | Clasificación Epistemológica | Justificación |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `REQUIRED BY DECISION` | Identidad propia unívoca durable (`DEC-CAT-001`). |
| `tenant_id` | `INTEGER` | `REQUIRED BY DECISION` | Aislamiento multi-tenant en Foundation `065`. |
| `establishment_id` | `UUID` | `REQUIRED BY DECISION` | Ownership físico directo de la sede (`HBC v1.0`). |
| `name` | `VARCHAR(255)` | `REQUIRED BY DECISION` | Nombre comercial del servicio (`HBC v1.0` L142). |
| `category` | `VARCHAR(100)` | `REQUIRED BY DECISION` | Categoría del catálogo (`HBC v1.0` L143). |
| `duration_minutes` | `INTEGER` | `REQUIRED BY DECISION` | Duración operativa del servicio (`HBC v1.0` L144). |
| `price` | `NUMERIC(12,2)` | `REQUIRED BY DECISION` | Tarifa comercial del servicio (`HBC v1.0` L145). |
| `description` | `TEXT` | `DEMONSTRATED` | Descripción extendida opcional (`HBC v1.0` L146). |
| `created_at` | `TIMESTAMPTZ` | `DEMONSTRATED` | Auditoría temporal estándar Foundation `065`. |
| `updated_at` | `TIMESTAMPTZ` | `DEMONSTRATED` | Auditoría temporal estándar Foundation `065`. |

### Atributos Prohibidos y Excluidos Explícitamente:
- **`provider_id`:** `NOT REQUIRED / PROHIBITED` (Pertenece a B2C, `DEC-SE-001`).
- **`membership_id`:** `UNDEFINED / OUT OF SCOPE` (Pertenece al vínculo de Asignación, `DEC-AS-004-R1`).
- **`publication` / `activation`:** `NOT REQUIRED / NOT PRESENT` (`DEC-PUB-001`).
- **`booking data` / `availability data`:** `NOT REQUIRED` (Dominio transaccional de agenda).
- **`location propia`:** `NOT REQUIRED` (`DEC-SE-002` — la ubicación pertenece al establecimiento).
- **`schedule propio`:** `NOT REQUIRED` (`DEC-SE-002` — el horario pertenece al establecimiento/profesional).

---

## 9. ESTADO OPERATIVO (`is_active`)

- **Análisis:** `DEC-PUB-001` determinó que `is_active` en `public.services` controla exclusivamente la disponibilidad y visibilidad de consumo en el marketplace B2C.
- En el dominio SaaS, ningún contrato cerrado ha definido un ciclo de vida `is_active` para la entidad `SERVICE_OFFER`.
- **Clasificación:**
  $$\text{SERVICE\_OFFER operational status} = \text{UNDEFINED}$$

---

## 10. SEMÁNTICA DE ELIMINACIÓN (DELETE SEMANTICS)

- **Análisis:** La relación física con `ESTABLISHMENT` debe protegerse con `ON DELETE RESTRICT` para evitar huérfanos accidentales en la Foundation. Sin embargo, las políticas de borrado lógico, archivado o desactivación de ofertas no han sido legisladas.
- **Clasificación:**
  $$\text{DELETE SEMANTICS} = \text{UNDEFINED}$$

---

## 11. EXCLUSIÓN EXPLÍCITA DE ASSIGNMENT

Se reitera formalmente:
- **`ASSIGNMENT physical representation`** = `UNDEFINED`
- **`ASSIGNMENT cardinality`** = `UNDEFINED`
- **`ASSIGNMENT lifecycle`** = `UNDEFINED`

El modelo de `SERVICE_OFFER` aquí diseñado es 100% agnóstico a cómo se implemente físicamente el `ASSIGNMENT`, garantizando que la oferta existe y es operable independientemente de si la asignación es 1:1, 1:N, embebida o en tabla puente.

---

## 12. MATRIZ DE DECISIÓN

| Dimensión | Option A (UUID Propio + Direct Establishment FK) | Option B (Clave Secuencial / Natural) | Option C (Reutilizar B2C / Derivar vía Assignment) |
| :--- | :--- | :--- | :--- |
| **Identidad estable** | **ÓPTIMA** (Inmutable, globalmente única) | **DEFICIENTE** (Frágil ante renombres/shards) | **INVIABLE** (Colisión conceptual y física) |
| **Ownership Establishment** | **ÓPTIMA** (FK directa e incondicional) | **DEFICIENTE** (Acoplada o natural compleja) | **INVIABLE** (Huérfana si no hay asignación) |
| **Tenant isolation** | **ÓPTIMA** (Doble FK compuesta + RLS `065`) | **REGULAR** (Mayor riesgo de leakage) | **INVIABLE** (Transitividad insegura) |
| **Pre-assignment existence** | **ÓPTIMA** (Totalmente soportada) | **SOPORTADA** | **INVIABLE** (Imposible existir sin profesional) |
| **Cambio de Assignment** | **ÓPTIMA** (Cero impacto en la oferta) | **SOPORTADA** | **INVIABLE** (Rompe la relación de propiedad) |
| **B2C isolation** | **ÓPTIMA** (Desacoplamiento total `DEC-SE-001`)| **SOPORTADA** | **INVIABLE** (Viola `DEC-SE-001`) |
| **Compatibilidad DEC-CAT-001** | **ÓPTIMA** (SaaS operational state puro) | **REGULAR** | **INVIABLE** |
| **Compatibilidad DEC-AS-002** | **ÓPTIMA** (Permite asignar limpiamente) | **REGULAR** | **INVIABLE** |
| **Economía y Simplicidad** | **ÓPTIMA** (Sigue patrones existentes de `065`)| **DEFICIENTE** (Requiere converters/secuencias)| **DEFICIENTE** (Alta complejidad de sincronización) |

---

## 13. RESULTADO ESPERADO Y RECOMENDACIÓN TÉCNICA

### 13.1. Recomendación sobre Identidad de SERVICE_OFFER
Formalizar que `SERVICE_OFFER` posea **Identidad Propia UUID** generada vía `gen_random_uuid()`, unívoca, inmutable e independiente de cualquier identificador B2C o de membresía.

### 13.2. Recomendación sobre Ownership de SERVICE_OFFER
Formalizar que `SERVICE_OFFER` pertenezca **directa y físicamente al `ESTABLISHMENT`** mediante:
1. `establishment_id UUID NOT NULL`
2. `tenant_id INTEGER NOT NULL`
3. Clave foránea compuesta `FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT`
4. Aislamiento estricto por RLS sobre `tenant_id`.

---

## 14. MATRIZ EPISTEMOLÓGICA DE ESTADO FINAL

```text
| Elemento                               | Estado Final                         |
| -------------------------------------- | ------------------------------------ |
| SERVICE_OFFER physical identity        | RECOMMENDED: UUID PROPIO             |
| SERVICE_OFFER physical ownership       | RECOMMENDED: DIRECT ESTABLISHMENT FK |
| SERVICE_OFFER tenant isolation         | RECOMMENDED: COMPOSITE FK + RLS      |
| SERVICE_OFFER minimum attributes       | DEMONSTRATED (name, cat, dur, price) |
| SERVICE_OFFER operational status       | UNDEFINED                            |
| DELETE SEMANTICS                       | UNDEFINED                            |
| ASSIGNMENT physical representation     | UNDEFINED (OUT OF SCOPE)             |
| ASSIGNMENT cardinality                 | UNDEFINED (OUT OF SCOPE)             |
| ASSIGNMENT lifecycle                   | UNDEFINED (OUT OF SCOPE)             |
| MATERIALIZATION implementation         | UNDEFINED (OUT OF SCOPE)             |
```

---

## 15. ESTADO DEL ANÁLISIS

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}005 \text{ — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION } \odot}
