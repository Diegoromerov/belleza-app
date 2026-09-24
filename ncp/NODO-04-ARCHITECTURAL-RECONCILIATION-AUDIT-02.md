# NODO-04 — AUDITORÍA DE RECONCILIACIÓN ARQUITECTÓNICA v2.0
## ARCHITECTURAL RECONCILIATION AUDIT — FINDINGS & EXTENSION FORENSICS

**DOCUMENT ID**: `N04-ARCHITECTURAL-RECONCILIATION-AUDIT-02`  
**NODE ID**: `NODO-04`  
**NAME**: Downstream B2C Materialization Adapter  
**DATE**: 2026-09-11  
**AUTHORITY**: Auditoría Forense y de Reconciliación Arquitectónica  
**GOAL ORIGIN**: `GO — NODO-04 ARCHITECTURAL RECONCILIATION AUDIT-02`  
**STATUS**: `FORENSIC AUDIT COMPLETED — PENDING DIRECTOR DETERMINATION 🟡`  
**IMPLEMENTATION MUTATION**: `STRICTLY ZERO CODE / ZERO SQL MUTATION APPLIED 🛑`

---

## 1. EXECUTIVE SUMMARY

En cumplimiento estricto de las directivas del Director del Proyecto, se ejecutó una auditoría forense y de reconciliación sobre los hallazgos identificados en `NODO-04-INDEPENDENT-AUDIT-01.md`.

### Síntesis Forense de Hallazgos:
1. **Metadata de Actoría (`materialized_by_user_id`, `materialized_at`, `fk_mat_actor_user`)**:
   - Aparecieron por primera vez en el borrador de diseño `/ncp/NODO-04-PHYSICAL-ARCHITECTURE-DESIGN-01.md` clasificadas explícitamente como `PROPOSAL — NOT APPROVED`.
   - El `Director Gate 01` aprobó la arquitectura física para pasar a Implementation Contract, pero **no emitió ratificación expresa ni aprobó crear columnas de auditoría** en el core del mapping.
   - Fueron incorporadas en el DDL de `backend/migrations/070_saas_service_materializations.sql` y en el servicio runtime.
   - **Clasificación**: `UNAUTHORIZED PHYSICAL EXTENSION` (No alteran la tupla de identidad tridimensional ni son recibidas del cliente, pero constituyen una extensión física no ratificada explícitamente).
2. **Comportamiento ante Re-materialización (`409 RE_MATERIALIZATION_NOT_AUTHORIZED`)**:
   - La decisión arquitectónica ratificada en el Decision Bundle y Director Gate es `REMATERIALIZATION = OPEN`.
   - En el runtime (`backend/src/services/nodo04MaterializationService.js`, líneas 108–123), ante la existencia de una fila previa, el código interrumpe la transacción lanzando un error HTTP 409 con el código `RE_MATERIALIZATION_NOT_AUTHORIZED`.
   - Aunque este bloqueo previene que el sistema ejecute unilateralmente un `UPDATE`, un `NO-OP` o una duplicación, la selección formal del código HTTP 409 y su semántica de error **no fue dictaminada como decisión cerrada por el Director**, sino que fue derivada en el Implementation Contract/Runtime para forzar el aborto ante una decisión OPEN.
   - **Clasificación**: `UNAUTHORIZED ARCHITECTURAL BEHAVIOR` / `RUNTIME ENFORCEMENT OF OPEN STATE`.
3. **Git Scope (`docker-compose.yml`, `init.sql`)**:
   - `docker-compose.yml` e `init.sql` contienen modificaciones pertenecientes a la configuración del entorno de ejecución local / bootstrap de roles no-superusuario para pruebas RLS.
   - **Clasificación**: `HISTORICAL INFRASTRUCTURE / ENVIRONMENT BOOTSTRAP` (No constituyen código de feature de NODO-04).

---

## 2. EVIDENCE & TRACEABILITY SOURCES

- **Documentos Evaluados**:
  - `/ncp/NODO-04-PHYSICAL-DECISION-BUNDLE-01.md` (`RATIFIED 🔒`)
  - `/ncp/NODO-04-PHYSICAL-ARCHITECTURE-DESIGN-01.md` (`APPROVED FOR CONTRACT 🔒`)
  - `/ncp/NODO-04-IMPLEMENTATION-CONTRACT-v1.0.md` (`CONTRACT SPECIFICATION`)
  - `/ncp/DEC-AS-003-RESOLUTION-v1.0.md` (`APPROVED 🔒`)
  - `/ncp/DEC-SE-001-DECISION-RECORD-v1.0.md` (`APPROVED 🔒`)
  - `/ncp/DEC-SE-002-DECISION-RECORD-v1.0.md` (`APPROVED 🔒`)
  - `/ncp/DEC-AS-014-ASSIGNMENT-CONSOLIDATED-DEFINITION-v1.0.md` (`APPROVED 🔒`)
- **Código y DDL Físico**:
  - `backend/migrations/070_saas_service_materializations.sql`
  - `backend/src/services/nodo04MaterializationService.js`
  - `backend/src/controllers/nodo04MaterializationController.js`
  - `backend/src/routes/nodo04MaterializationRoutes.js`
  - `backend/index.js`
  - `backend/tests/test_nodo04_materialization_suite.js`
- **Control de Versiones**:
  - Git working tree y registro de diffs directos.

---

## 3. HALLAZGO 1 — METADATA DE ACTORÍA Y AUDITORÍA

### 3.1. Respuestas a las Preguntas Obligatorias

1. **¿En qué documento apareció por primera vez `materialized_by_user_id`?**  
   Apareció en `/ncp/NODO-04-PHYSICAL-ARCHITECTURE-DESIGN-01.md` (Línea 179 y Línea 402), documentado en la tabla de normalización bajo la clasificación: `PROPOSAL — NOT APPROVED`.
2. **¿En qué documento apareció por primera vez `materialized_at`?**  
   Apareció en `/ncp/NODO-04-PHYSICAL-ARCHITECTURE-DESIGN-01.md` (Línea 180 y Línea 403), clasificado como: `PROPOSAL — NOT APPROVED`.
3. **¿Existió una aprobación explícita del Director para convertirlos en columnas físicas?**  
   **NO**. En el dictamen `Director Gate 01` se aprobó el paso a Implementation Contract, pero la matriz de decisiones físicas dejó la categoría de auditoría como `Audit Metadata: PROPOSAL — NOT APPROVED 🟡`. No existe ningún acta ni Decision Record que ratifique `materialized_by_user_id` como columna física autorizada.
4. **¿Existió una aprobación explícita para `fk_mat_actor_user`?**  
   **NO**. La clave foránea `fk_mat_actor_user` (que vincula `materialized_by_user_id` con `usuarios(id, tenant_id)`) fue introducida como parte de la propuesta no ratificada.
5. **¿La migration 070 contiene esas columnas y constraints?**  
   **SÍ**. `backend/migrations/070_saas_service_materializations.sql` incluye:
   - `materialized_by_user_id INTEGER`
   - `materialized_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`
   - `CONSTRAINT fk_mat_actor_user FOREIGN KEY (materialized_by_user_id, tenant_id) REFERENCES public.usuarios(id, tenant_id) ON DELETE RESTRICT`
6. **¿El código NODO-04 las utiliza realmente?**  
   **SÍ**. En `nodo04MaterializationService.js`:
   - Línea 146: `const actorUserId = user && user.id ? user.id : null;`
   - Línea 156: Inserción de `$6` (`actorUserId`) en `saas_service_materializations`.
   - En `OP-02` (`listMaterializations`): `SELECT ... m.materialized_at ... ORDER BY m.materialized_at DESC`.
7. **¿El endpoint las recibe desde cliente?**  
   **NO**. `materialized_by_user_id` se extrae server-side del JWT autenticado (`req.user.id`). El body del endpoint solo acepta `service_offer_id` y `membership_id`.
8. **¿Son necesarias funcionalmente para cumplir el Node Contract?**  
   **NO**. El Node Contract solo exige registrar la proyección downstream de la asignación y garantizar el aislamiento y autorización. La identidad técnica reside en `(establishment_id, service_offer_id, membership_id) -> service_id`.
9. **¿Su presencia cambia la identidad arquitectónica de Materialization?**  
   **NO**. La identidad tridimensional única está garantizada por `uq_mat_assignment_establishment (establishment_id, service_offer_id, membership_id)` y `uq_mat_service_id (service_id)`. `materialized_by_user_id` es un campo puramente informativo/nullable.
10. **¿Pueden eliminarse sin alterar el core funcional?**  
    **SÍ**. Pueden eliminarse `materialized_by_user_id`, `fk_mat_actor_user` y ajustarse el orden de `OP-02` sin alterar en absoluto la integridad ni la semántica de la materialización.

### 3.2. Clasificación
$$\mathbf{UNAUTHORIZED\ PHYSICAL\ EXTENSION}$$

---

## 4. HALLAZGO 2 — RE-MATERIALIZATION BEHAVIOR

### 4.1. Respuestas a las Preguntas Obligatorias

1. **¿Dónde se implementó este comportamiento?**  
   En la capa de servicio runtime de NODO-04.
2. **¿Qué archivo y función?**  
   Archivo: `backend/src/services/nodo04MaterializationService.js`  
   Función: `materializeServiceAssignment`
3. **¿Qué línea/bloque?**  
   Líneas 108–123:
   ```javascript
   // 6. Check Existing Materialization (RE-MATERIALIZATION BEHAVIOR = OPEN)
   const existingMatQuery = `
     SELECT id, service_id
     FROM public.saas_service_materializations
     WHERE establishment_id = $1 AND service_offer_id = $2 AND membership_id = $3;
   `;
   const existingMatRes = await client.query(existingMatQuery, [establishmentId, service_offer_id, membership_id]);
   if (existingMatRes.rows.length > 0) {
     throw createError(
       'RE_MATERIALIZATION_NOT_AUTHORIZED',
       'La materialización ya existe. La re-materialización (actualización/sincronización/reemplazo) permanece como una decisión arquitectónica OPEN no autorizada.',
       409
     );
   }
   ```
4. **¿Qué documento lo autorizó?**  
   Fue redactado en `/ncp/NODO-04-IMPLEMENTATION-CONTRACT-v1.0.md` (Sección 4.3, Paso 9 y Caso T17), formulado como un mecanismo de aborto defensivo para impedir la ejecución de acciones no aprobadas.
5. **¿Existe una decisión del Director posterior que haya cerrado REMATERIALIZATION?**  
   **NO**. En todos los documentos de decisión y en el Physical Decision Bundle, `REMATERIALIZATION BEHAVIOR` está calificado unánimemente como `OPEN 🟡`.
6. **¿El Node Contract fue modificado para autorizar 409?**  
   **NO**. El Node Contract v1.0 se mantiene `APPROVED / CLOSED 🔒` y no especifica códigos HTTP ni políticas de conflicto.
7. **¿El Implementation Contract fue modificado para autorizar 409?**  
   El Implementation Contract v1.0 especificó que ante una tupla existente la operación "se DETIENE y ABORTA", pero no existió una decisión de negocio aprobada que formalizara el 409 como la política definitiva del ciclo de vida.
8. **¿Existe una decisión registrada que permita este comportamiento?**  
   No como decisión de negocio cerrada; fue una salvaguarda runtime para no ejecutar mutaciones (UPDATE/NO-OP/DUPLICATE) en ausencia de una decisión aprobada.
9. **¿El comportamiento fue inventado durante implementación?**  
   El mecanismo de interrupción responde a la necesidad de no mutar datos cuando la decisión es OPEN; sin embargo, transformar el estado OPEN en un código HTTP 409 contractual sin un Decision Record formal previo constituye una determinación operativa que no fue ratificada por el Director.

### 4.2. Clasificación
$$\mathbf{UNAUTHORIZED\ ARCHITECTURAL\ BEHAVIOR\ /\ RUNTIME\ DEFENSIVE\ GUARD}$$

---

## 5. HALLAZGO 3 — GIT SCOPE

### 5.1. Análisis Forense de Modificaciones

1. **`backend/docker-compose.yml`**:
   - **Diff**:
     ```diff
     - DB_USER=admin
     - DB_PASSWORD=admin123
     + DB_USER=beauty_app_user
     + DB_PASSWORD=${DB_PASSWORD:-beauty_app_secure_runtime_2026}
     ```
   - **Pertenencia**: Configuración de infraestructura local / Docker.
   - **Clasificación**: `HISTORICAL ENVIRONMENT CONFIGURATION / UNRELATED TO N04 FEATURE`.
2. **`backend/init.sql`**:
   - **Diff**:
     ```sql
     -- Bootstrap Rol de Runtime No-Superusuario (SaaS Security Architecture)
     DO $$
     BEGIN
       IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'beauty_app_user') THEN
         CREATE ROLE beauty_app_user WITH LOGIN PASSWORD 'beauty_app_secure_runtime_2026'
           NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
     ...
     ```
   - **Pertenencia**: Script de inicialización de base de datos para pruebas con RLS estricto.
   - **Clasificación**: `HISTORICAL ENVIRONMENT CONFIGURATION / UNRELATED TO N04 FEATURE`.
3. **`backend/index.js`**:
   - **Diff**: Inserción de 6 líneas para registrar rutas de SaaS (incluyendo `/api/v1/saas/hub/materializations`).
   - **Pertenencia**: Autorizado explícitamente en la lista blanca de `GO: NODO-04-IMPLEMENTATION-01` exclusivamente para el montaje del router.
   - **Clasificación**: `NODO-04 AUTHORIZED CHANGE`.

---

## 6. TABLA DE EXTENSIONES NO AUTORIZADAS

| Elemento | Evidencia Físico-Lógica | Estado de Aprobación | Clasificación |
|---|---|---|---|
| **Columna `materialized_by_user_id`** | Presente en `saas_service_materializations` | `PROPOSAL — NOT APPROVED` | `UNAUTHORIZED PHYSICAL EXTENSION` |
| **Columna `materialized_at`** | Presente en `saas_service_materializations` | `PROPOSAL — NOT APPROVED` | `UNAUTHORIZED PHYSICAL EXTENSION` |
| **Constraint `fk_mat_actor_user`** | FK a `usuarios(id, tenant_id)` | `PROPOSAL — NOT APPROVED` | `UNAUTHORIZED PHYSICAL EXTENSION` |
| **Comportamiento 409 en Re-materialización** | `throw createError('RE_MATERIALIZATION_NOT_AUTHORIZED', ..., 409)` | Decisión `OPEN 🟡` | `UNAUTHORIZED ARCHITECTURAL BEHAVIOR` |
| **Default `is_active = true` en B2C** | Inserción en `public.services` toma DEFAULT legacy | `OUT OF SCOPE / SCHEMA FACT` | `OBSERVATION / LEGACY SCHEMA FACT` |
| **Entidad `saas_service_materializations`** | DDL Migration 070 ejecutado | Aprobado en Director Gate para Implementation Contract | `CONFORMS TO GATE` |
| **FKs triples de contexto (`fk_mat_offer_context`, `fk_mat_membership_context`)** | Presentes en DDL | Aprobado en Director Gate para Implementation Contract | `CONFORMS TO GATE` |
| **FK `fk_mat_assignment`** | Presente en DDL sobre `(service_offer_id, membership_id)` | Aprobado en Director Gate para Implementation Contract | `CONFORMS TO GATE` |
| **FK `fk_mat_service` (`ON DELETE CASCADE`)** | Presente en DDL hacia `public.services` | Aprobado en Director Gate para Implementation Contract | `CONFORMS TO GATE` |
| **Unique `uq_mat_assignment_establishment`** | Presente en DDL | Aprobado conceptualmente (`DEC-C`) | `CONFORMS TO CONTRACT` |
| **Unique `uq_mat_service_id`** | Presente en DDL | Aprobado conceptualmente (`DEC-C`) | `CONFORMS TO CONTRACT` |

---

## 7. MODEL INTEGRITY (INTEGRIDAD DEL MODELO)

Se verificó que la identidad canónica ratificada:
$$\mathbf{Identidad:\ (establishment\_id,\ service\_offer\_id,\ membership\_id)\ \longrightarrow\ service\_id}$$

- Permanece intacta y no ha sido alterada ni sustituida por ninguna extensión.
- Ninguna de las columnas accesorias (`materialized_by_user_id`, `materialized_at`) forma parte de la clave primaria ni de las restricciones de unicidad.
- No existe una segunda identidad física ni lógica.

---

## 8. DECISION REGISTER CONTRAST

| Decisión / Documento | Estado Documental | Estado en Implementación | Consistencia |
|---|---|---|:---:|
| **`DEC-AS-003`** (Acto de Autorización) | `APPROVED / CLOSED 🔒` | OWNER/MANAGER obligatorio en Active Context | **CONFORMS** |
| **`DEC-SE-001`** (Instanciación Tardía B2C) | `APPROVED / CLOSED 🔒` | No materializa sin asignación previa válida | **CONFORMS** |
| **`DEC-SE-002`** (Independencia de Horarios) | `APPROVED / CLOSED 🔒` | Cero sincronización automática con prestador | **CONFORMS** |
| **`DEC-AS-014`** (Consolidación Assignment) | `APPROVED / CLOSED 🔒` | Assignment como relación pura sin provider directo | **CONFORMS** |
| **Physical Decision Bundle: DEC-A** | `APPROVED 🔒` | `memberships.user_id ≡ perfiles_prestador.id` | **CONFORMS** |
| **Physical Decision Bundle: DEC-B** | `REJECTED (No Provisioning) 🔴` | Aborta con 422 si perfil no existe | **CONFORMS** |
| **Physical Decision Bundle: DEC-C** | `APPROVED CONCEPTUALLY 🔒` | Tupla tridimensional a `services(id)` | **CONFORMS** |
| **Physical Decision Bundle: DEC-D** | `APPROVED 🔒` | 1 Assignment = 1 Materialización | **CONFORMS** |
| **Re-materialization Policy** | `OPEN 🟡` | Implementa 409 defensivo en runtime | **DEVIATION (BEHAVIOR NOT FORMALLY CLOSED)** |
| **Audit Metadata Policy** | `PROPOSAL — NOT APPROVED 🟡` | Columnas y FK implementadas físicamente | **DEVIATION (UNAUTHORIZED PHYSICAL EXTENSION)** |

---

## 9. FINDINGS CLASSIFICATION

1. **`MAJOR-01`: Metadata de Auditoría no Ratificada Físicamente (`materialized_by_user_id`, `fk_mat_actor_user`, `materialized_at`)**
   - **Clasificación**: `MAJOR`.
   - **Impacto**: Se crearon columnas físicas y restricciones FK en PostgreSQL que no contaban con un Decision Record formal de aprobación, aunque no comprometen la identidad ni la seguridad.
2. **`MAJOR-02`: Comportamiento de Re-materialización Definido Runtime sin Cierre Arquitectónico**
   - **Clasificación**: `MAJOR`.
   - **Impacto**: El runtime responde con HTTP 409 ante tuplas repetidas. Aunque es una salvaguarda defensiva correcta que impide mutaciones no autorizadas (UPDATE/NO-OP), el estado formal del sistema era `OPEN`, requiriendo dictamen del Director.
3. **`OBS-01`: Modificaciones en `docker-compose.yml` e `init.sql`**
   - **Clasificación**: `OBSERVATION`.
   - **Impacto**: Archivos de entorno local preexistentes con ajustes de usuarios para pruebas RLS, sin afectación de código de negocio de NODO-04.

---

## 10. DECISIONES QUE REQUIEREN DICTAMEN DEL DIRECTOR

El Director del Proyecto debe resolver explícitamente los siguientes puntos antes de cualquier acción correctiva o cierre:

### Decisión Requerida 1: Destino de la Metadata de Auditoría
- **Opción 1.A (Ratificar)**: Aprobar formalmente `materialized_by_user_id`, `materialized_at` y `fk_mat_actor_user` como metadatos estándar de trazabilidad en la tabla de mapping.
- **Opción 1.B (Remover / Purgar)**: Ordenar la eliminación de `materialized_by_user_id`, `materialized_at` y `fk_mat_actor_user` mediante ajuste de migración 070 y servicio para mantener un esquema físico minimalista estricto.

### Decisión Requerida 2: Formalización del Comportamiento ante Re-materialización
- **Opción 2.A (Ratificar 409 Conflict)**: Cerrar formalmente `REMATERIALIZATION BEHAVIOR` como `REJECT WITH 409 CONFLICT` (Cualquier solicitud sobre una tupla existente es rechazada).
- **Opción 2.B (Mantener OPEN con Error Específico)**: Ratificar que toda re-materialización está suspendida/bloqueada bajo un código específico hasta el diseño del ciclo de vida downstream.
- **Opción 2.C (Definir Otra Política)**: Dictaminar `UPDATE` de atributos comerciales o `NO-OP` determinista.

---

## 11. ESTADO FINAL OBLIGATORIO

```text
================================================================================
NODO-04 — DOWNSTREAM B2C MATERIALIZATION ADAPTER
ARCHITECTURAL RECONCILIATION AUDIT-02 — COMPLETED 🟡

NODO-04 STATE: IMPLEMENTED / RECONCILIATION FINDINGS REPORTED
CLOSURE STATUS: NOT CLOSED — PENDING DIRECTOR DETERMINATION 🛑
================================================================================
```
