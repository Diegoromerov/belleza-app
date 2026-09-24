# DEC-AS-006 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0
## Assignment Physical Model Analysis

**DECISION_ID:** `DEC-AS-006`  
**ESTADO:** `DEC-AS-006 — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Physical Representation Analysis  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-006-001`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`, `DEC-AS-001-DECISION-RECORD-v1.0.md`, `DEC-CAT-001-DECISION-RECORD-v1.0.md`, `DEC-AS-002-DECISION-RECORD-v1.0.md`, `DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`, `DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md`, `DEC-AS-004-PHYSICAL-STATE-MODEL-ANALYSIS-v1.0.md`, `DEC-AS-005-SERVICE-OFFER-IDENTITY-OWNERSHIP-ANALYSIS-v1.0.md`  
**FECHA DE EMISIÓN:** 2026-09-10  

---

## 1. EXECUTIVE SUMMARY & ARQUITECTURA CERRADA

El presente análisis resuelve exclusivamente la representación física mínima y correcta de la **Asignación Durable** (`DEC-AS-002`), vinculando una oferta comercial (`SERVICE_OFFER`) con un colaborador operativo (`ACTIVE PROFESSIONAL`) dentro del dominio SaaS de GlowApp.

### 1.1. Decisiones Previas Inmutables y Protegidas
1. **`DEC-AS-001` (APPROVED / CLOSED):** La autoridad para asignar reside exclusivamente en un `ACTIVE USER` con `ACTIVE MEMBERSHIP` y rol `OWNER` o `MANAGER` operando en su `ACTIVE CONTEXT` sobre el `TARGET ESTABLISHMENT`.
2. **`DEC-AS-002` (APPROVED / CLOSED):** `ASSIGNMENT = DURABLE SAAS STATE`. Representa el vínculo conceptual `SERVICE_OFFER → ACTIVE PROFESSIONAL` y sobrevive al request HTTP original de creación. Mínimo estado conceptual: `REF(SERVICE_OFFER) + REF(ACTIVE PROFESSIONAL)`.
3. **`DEC-AS-005` (APPROVED / PENDING FORMALIZATION):** `SERVICE_OFFER` posee identidad propia UUID (`gen_random_uuid()`), pertenece directa e incondicionalmente a `ESTABLISHMENT` vía FK física compuesta con RLS, y existe con independencia total del estado de asignación.
4. **`DEC-SE-001` & `DEC-AS-003` (APPROVED / CLOSED):** La asignación SaaS no equivale a materialización B2C (`ASSIGNMENT ≠ public.services` y `ASSIGNMENT ≠ MATERIALIZATION`).
5. **`DEC-PUB-001` (RECONCILED):** Inexistencia de workflows de publicación o activación en SaaS.

---

## 2. PREGUNTA CENTRAL DE DISEÑO

> **¿Cuál es el modelo físico mínimo para representar un Assignment durable entre `SERVICE_OFFER` y un `ACTIVE PROFESSIONAL`?**

---

## 3. EVALUACIÓN EXHAUSTIVA DE CANDIDATOS FÍSICOS

```text
================================================================================
CANDIDATOS DE REPRESENTACIÓN FÍSICA PARA ASSIGNMENT:

OPTION A (Entidad Propia / Relación Desacoplada):
  ┌───────────────────┐        ┌───────────────────┐        ┌───────────────────┐
  │   SERVICE_OFFER   │◄───────┤ service_assignments├───────►│    MEMBERSHIP     │
  └───────────────────┘        └───────────────────┘        └───────────────────┘

OPTION B (Relación Embebida en SERVICE_OFFER):
  ┌─────────────────────────────────────────────────┐
  │                  SERVICE_OFFER                  │
  │   id | name | price | assigned_membership_id    │
  └─────────────────────────────────────────────────┘

OPTION C (Relación Inversa Embebida en MEMBERSHIP):
  ┌─────────────────────────────────────────────────┐
  │                   MEMBERSHIP                    │
  │   id | user_id | role | assigned_service_ids[]  │ ──► (Modifica Foundation 065)
  └─────────────────────────────────────────────────┘
================================================================================
```

### 3.1. OPTION A — Asignación como Entidad Física Propia (Relación Desacoplada)
- **Estructura Conceptual:** Tabla de relación/asociación con identidad propia UUID o PK compuesta que vincula `service_offer_id` con `membership_id`.
- **Análisis de Propiedades:**
  1. **Agnóstica a la Cardinalidad:** Soporta con cero cambios estructurales tanto $1:1$ (mediante constraint única) como $1:N$ o $N:M$ si el negocio lo determina.
  2. **Ausencia de Asignación (`NOT_ESTABLISHED`):** La ausencia de asignación es exactamente la **inexistencia de un registro**, sin forzar columnas mutables con valores `NULL`.
  3. **Mutación y Reasignación:** La reasignación es una inserción/reemplazo limpio, sin mutar la fila de la oferta comercial ni bloquear concurrentemente el catálogo.
  4. **Preservación de Auditoría:** Permite registrar marcas temporales (`created_at`) específicas de cuándo se vinculó el profesional, desacopladas del ciclo de vida de la oferta.
  5. **Integridad Referencial:** Permite claves foráneas compuestas que garantizan coincidencia estricta de `establishment_id` y `tenant_id`.

### 3.2. OPTION B — Relación Embebida en `SERVICE_OFFER` (`assigned_membership_id`)
- **Estructura Conceptual:** Columna `assigned_membership_id UUID NULL` en la tabla `service_offers`.
- **Consecuencias Técnicas Demostradas:**
  1. **Fuerza Cardinalidad 1:1:** Impide que múltiples profesionales presten el mismo servicio (e.g. 3 estilistas que realizan "Corte Dama"), a menos que se dupliquen ofertas comerciales idénticas en el catálogo (generando redundancia e inconsistencia de precios/duración).
  2. **Sobrecarga Semántica de `NULL`:** `NULL` significaría simultáneamente "oferta creada sin asignar", "profesional desasignado", o "asignación revocada".
  3. **Acoplamiento de Concurrencia:** Mutar la asignación requiere un `UPDATE` con lock de fila sobre la entidad principal de catálogo `service_offers`.
  4. **Pérdida de Historial:** Sobrescribir la columna destruye la trazabilidad de asignaciones previas.

### 3.3. OPTION C — Relación Embebida en `MEMBERSHIP`
- **Estructura Conceptual:** Agregar `assigned_service_ids` dentro de la tabla `memberships`.
- **Consecuencias Técnicas Demostradas:**
  1. **Violación de Inmutabilidad de Foundation `065`:** Modificaría el contrato cerrado y protegido de `memberships` (`065_saas_foundation_core.sql`).
  2. **Inversión Antinatural de Dependencias:** El catálogo de servicios no debe estar atrapado en el registro de contrato laboral de un usuario.
  3. **Inviable.**

### 3.4. OPTION D — Puente Transaccional / Sin Persistencia Propia
- Descartada por `DEC-AS-002`: `ASSIGNMENT = DURABLE SAAS STATE` (debe persistir en base de datos post-handover).

---

## 4. ANÁLISIS PROFUNDO DEL TARGET: `USER` vs `MEMBERSHIP` vs `PROFESSIONAL`

Para garantizar la pureza del modelo SaaS, se diferencian estrictamente tres conceptos:

```text
================================================================================
DISTINCIÓN DE ENTIDADES DE IDENTIDAD Y OPERACIÓN:

1. USUARIO (usuarios.id - INTEGER):
   - Persona natural / Cuenta de acceso global.
   - NO posee contexto de sede ni rol por sí sola.
   - Prohibido como target de asignación directa.

2. MEMBRESÍA (memberships.id - UUID):
   - Vínculo contextual: Usuario ◄──► Sede (Establishment) ◄──► Tenant.
   - Contiene: rol (OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST), tipo de relación y status.
   - TARGET FÍSICO DEMOSTRADO EN SAAS FOUNDATION 065.

3. PROFESIONAL (Concepto Operativo / Capacidad):
   - Es una MEMBERSHIP activa cuyo rol u atribución le permite ejecutar servicios.
   - No es una tabla independiente en Foundation 065; se materializa a través de MEMBERSHIP.
================================================================================
```

### 4.1. Evaluación de Escenarios de Integridad sobre `memberships.id`
* **¿Qué sucede si una membresía cambia a `status = 'REVOKED'` o `'SUSPENDED'`?**  
  La asignación física sigue apuntando a la membresía contextual, pero la regla de negocio (`DEC-AS-001`) o la consulta de elegibilidad descarta la operatividad del profesional sin corromper la integridad referencial.
* **¿Qué sucede si un usuario tiene múltiples membresías en distintas sedes?**  
  Como el target es `memberships.id` (y no `user_id`), cada asignación está estrictamente acotada a la sede donde el usuario tiene contrato/rol activo.

---

## 5. INVESTIGACIÓN DE CARDINALIDAD

- **Evidencia en `CDC v1.0` y `HBC v1.0`:** En el flujo de creación desde cero, un servicio puede no tener asignación (`NOT_ESTABLISHED`) o crearse con un profesional inicial.
- **Evidencia en Modelos de Negocio de Belleza / Salones:** En salones reales, un servicio comercial estándar (e.g. "Manicure Tradicional") suele ser prestado por múltiples manicuristas de la misma sede ($1:N$). En otros casos específicos o cabinas unipersonales, puede existir relación $1:1$.
- **Dictamen Arquitectónico:** Ninguna decisión previa ha legislado si la cardinalidad es rígidamente $1:1$ o $1:N$.
- **Clasificación:**
  $$\text{ASSIGNMENT cardinality} = \text{UNDEFINED}$$
- **Repercusión en el Modelo Físico:** La **Option A (Entidad Propia)** es la única opción que preserva la neutralidad estructural, permitiendo operar como $1:1$ o evolucionar a $1:N$ sin refactorizar la tabla `service_offers`.

---

## 6. INTEGRIDAD DE ESTABLECIMIENTO (ESTABLISHMENT INTEGRITY)

Dado que `SERVICE_OFFER` pertenece a un `ESTABLISHMENT` (`DEC-AS-005`) y `MEMBERSHIP` pertenece a un `ESTABLISHMENT` (`065`), es un requisito crítico garantizar que:

$$\text{SERVICE\_OFFER.establishment\_id} == \text{MEMBERSHIP.establishment\_id}$$

### 6.1. Mecanismos de Garantía Física Evaluados
1. **Doble Clave Foránea Compuesta con `establishment_id` Compartido (Recomendada):**  
   La entidad de asignación almacena `establishment_id` y `tenant_id`, vinculando:
   - `FOREIGN KEY (service_offer_id, establishment_id, tenant_id) REFERENCES service_offers(id, establishment_id, tenant_id)`
   - `FOREIGN KEY (membership_id, establishment_id, tenant_id) REFERENCES memberships(id, establishment_id, tenant_id)`
   - **Garantía:** El motor PostgreSQL rechaza físicamente a nivel de base de datos cualquier asignación cruzada entre ofertas de la Sede A y profesionales de la Sede B.
2. **Validación Exclusiva por Software / Middleware:**  
   Inaceptable: deja la integridad sujeta a bugs en capas superiores o scripts de migración.

---

## 7. AISLAMIENTO MULTI-TENANT (TENANT INTEGRITY & RLS)

En estricta consonancia con Foundation `065`:
1. La entidad de asignación debe incluir `tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT`.
2. Las claves foráneas compuestas validan la afinidad `tenant_id`.
3. Se habilita Row-Level Security (RLS):
   ```sql
   ALTER TABLE service_assignments ENABLE ROW LEVEL SECURITY;
   CREATE POLICY tenant_isolation_service_assignments ON service_assignments
       FOR ALL
       USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
       WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
   ```
4. Ningún dato de tenant es provisto por el cliente ni inferido de claims inseguros; es derivado del contexto activo validado (`066`).

---

## 8. CICLO DE VIDA (LIFECYCLE) Y AUSENCIA DE ASIGNACIÓN

- **Regla Basal:** La ausencia de asignación es simplemente la **inexistencia del vínculo** (`NOT_ESTABLISHED`).
- **Estados Prohibidos:** No se introducen estados sintéticos como `UNASSIGNED`, `PENDING`, `DRAFT`, `DISABLED` ni `REVOKED`.
- **Clasificación:**
  $$\text{ASSIGNMENT lifecycle} = \text{UNDEFINED (Existencia del registro = Asignación Activa)}$$

---

## 9. SEMÁNTICAS DE ELIMINACIÓN (DELETE SEMANTICS)

- Las políticas finales de desvinculación (e.g. si al revocar una membresía se elimina el registro de asignación o se restringe la acción) permanecen:
  $$\text{DELETE SEMANTICS} = \text{UNDEFINED}$$

---

## 10. CLASIFICACIÓN DE ATRIBUTOS DE ASIGNACIÓN

| Atributo | Tipo Conceptual | Clasificación Epistemológica | Justificación |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `REQUIRED BY DECISION` | Identidad unívoca de la asignación (`DEC-AS-002`). |
| `tenant_id` | `INTEGER` | `REQUIRED BY DECISION` | Aislamiento multi-tenant en Foundation `065`. |
| `establishment_id` | `UUID` | `REQUIRED BY DECISION` | Integridad referencial de sede compartida. |
| `service_offer_id` | `UUID` | `REQUIRED BY DECISION` | Referencia a la oferta de servicio (`DEC-AS-005`). |
| `membership_id` | `UUID` | `REQUIRED BY DECISION` | Referencia al profesional contextual (`065`). |
| `created_at` | `TIMESTAMPTZ` | `DEMONSTRATED` | Auditoría temporal estándar Foundation `065`. |
| `updated_at` | `TIMESTAMPTZ` | `DEMONSTRATED` | Auditoría temporal estándar Foundation `065`. |
| `assigned_by` | `INTEGER / UUID` | `UNDEFINED` | Auditoría de autorizador (no legislada formalmente). |
| `revoked_at` | `TIMESTAMPTZ` | `NOT REQUIRED` | Fuera de alcance (ausencia = desasignado). |
| `provider_id` | `INTEGER` | `PROHIBITED` | Perteneciente a B2C (`DEC-SE-001`). |

---

## 11. MATRIZ DE DECISIÓN COMPARATIVA

| Criterio | Option A (Entidad Propia / Tabla Desacoplada) | Option B (Embebida en `SERVICE_OFFER`) | Option C (Embebida en `MEMBERSHIP`) | Option D (Sin Persistencia) |
| :--- | :--- | :--- | :--- | :--- |
| **Representa Assignment durable** | **ÓPTIMA** (`DEC-AS-002`) | **SOPORTADA** | **SOPORTADA** | **INVIABLE** (Viola `DEC-AS-002`) |
| **Integridad referencial** | **ÓPTIMA** (Doble FK compuesta) | **REGULAR** (FK simple) | **DEFICIENTE** (Arrays) | **INVIABLE** |
| **Cardinalidad futura** | **ÓPTIMA** (Soporta 1:1, 1:N, N:M) | **INVIABLE** (Fuerza 1:1 rígido) | **DEFICIENTE** | **INVIABLE** |
| **Ausencia de Assignment** | **ÓPTIMA** (Inexistencia de fila) | **DEFICIENTE** (Sobrecarga de `NULL`) | **DEFICIENTE** | **INVIABLE** |
| **Cambio de Assignment** | **ÓPTIMA** (Sin mutar catálogo) | **DEFICIENTE** (`UPDATE` sobre oferta) | **DEFICIENTE** | **INVIABLE** |
| **Membership integrity** | **ÓPTIMA** (Target `memberships.id`) | **SOPORTADA** | **INVIABLE** (Modifica `065`) | **INVIABLE** |
| **Establishment integrity** | **ÓPTIMA** (FK compuesta triple) | **REGULAR** | **DEFICIENTE** | **INVIABLE** |
| **Tenant isolation** | **ÓPTIMA** (RLS nativo Foundation) | **ÓPTIMA** | **REGULAR** | **INVIABLE** |
| **Compatibilidad DEC-AS-001** | **ÓPTIMA** | **SOPORTADA** | **REGULAR** | **INVIABLE** |
| **Compatibilidad DEC-AS-002** | **ÓPTIMA** | **REGULAR** | **REGULAR** | **INVIABLE** |
| **Compatibilidad DEC-AS-005** | **ÓPTIMA** (Total desacoplamiento) | **DEFICIENTE** (Acopla oferta a asignado) | **REGULAR** | **INVIABLE** |
| **Economía y Mantenibilidad** | **ÓPTIMA** (Patrón relacional estándar) | **DEFICIENTE** (Deuda técnica en 1:N) | **INVIABLE** | **INVIABLE** |

---

## 12. RESULTADO ESPERADO Y RECOMENDACIÓN TÉCNICA

### 12.1. Recomendación sobre Representación Física de ASSIGNMENT
Formalizar la **Option A (Entidad de Asignación Desacoplada)** como el modelo físico canónico para `ASSIGNMENT` en GlowApp SaaS:
1. Representada como una entidad relacional autónoma (e.g. `service_assignments` o equivalente).
2. Con clave primaria propia UUID (`gen_random_uuid()`).
3. Con referencias foráneas hacia `service_offers` y hacia `memberships`.

### 12.2. Recomendación sobre Target de Asignación
Formalizar que el target físico sea unívocamente:
$$\text{ASSIGNMENT.target} = \text{memberships.id (Active Contextual Professional en Foundation 065)}$$

### 12.3. Dictamen sobre Cardinalidad
Mantener formalmente:
$$\text{ASSIGNMENT cardinality} = \text{UNDEFINED}$$
La Option A permite que el Director formalice posteriormente $1:1$ (agregando un índice único sobre `service_offer_id`) o $1:N$ sin alterar la tabla `service_offers`.

---

## 13. MATRIZ EPISTEMOLÓGICA DE ESTADO FINAL

```text
| Elemento                               | Estado Final                         |
| -------------------------------------- | ------------------------------------ |
| ASSIGNMENT physical representation     | RECOMMENDED: OPTION A (DESACOPLADA)  |
| ASSIGNMENT target                      | RECOMMENDED: memberships.id (065)    |
| ASSIGNMENT cardinality                 | UNDEFINED                            |
| ASSIGNMENT lifecycle                   | UNDEFINED (Ausencia = Desasignado)   |
| ASSIGNMENT establishment integrity     | RECOMMENDED: COMPOSITE FK ENFORCED   |
| ASSIGNMENT tenant isolation            | RECOMMENDED: COMPOSITE FK + RLS      |
| DELETE SEMANTICS                       | UNDEFINED                            |
| MATERIALIZATION implementation         | UNDEFINED (OUT OF SCOPE)             |
```

---

## 14. ESTADO DEL ANÁLISIS

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}006 \text{ — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION } \odot}
