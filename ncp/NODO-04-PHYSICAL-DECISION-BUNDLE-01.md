# NODO-04 — PHYSICAL DECISION BUNDLE 01
## RATIFIED PHYSICAL ARCHITECTURAL DECISIONS: PROVIDER, IDENTITY & GRANULARITY

**DOCUMENT ID**: `DEC-BUNDLE-N04-PHYSICAL-01`  
**NODE**: `NODO-04 (Downstream B2C Materialization Adapter)`  
**DATE**: 2026-09-11  
**AUTHORITY**: Director del Proyecto GlowApp SaaS  
**GOAL ORIGIN**: `GO — NODO-04-PHYSICAL-DECISION-BUNDLE-RATIFICATION-01`  
**STATUS**: `PHYSICAL DECISION BUNDLE — RATIFIED 🔒`  
**IMPLEMENTATION**: `NOT AUTHORIZED 🔴`

---

## 1. ESTADO DE PARTIDA Y MARCO DE AUTORIDAD

El presente documento consolida las decisiones físicas y arquitectónicas evaluadas y dictaminadas por el **Director del Proyecto GlowApp SaaS** para `NODO-04` (Downstream B2C Materialization Adapter).

### Estado de Nodos y Decisiones Previas:
- **NODO-04 Node Contract v1.0**: `CONTRACT APPROVED / CLOSED 🔒`
- **DEC-AS-003**: `APPROVED / CLOSED 🔒` (Acto explícito de autorización por `OWNER`/`MANAGER` en Active Context).
- **NODO-03A**: `CLOSED / RATIFIED 🔒`
- **NODO-02**: `CLOSED / RATIFIED 🔒`
- **NODO-01 / Foundation Core (065, 066)**: `CLOSED 🔒`

---

## 2. CUADRO RESUMEN DE DECISIONES RATIFICADAS POR EL DIRECTOR

```text
================================================================================
           DICTAMEN OFICIAL DEL DIRECTOR — DECISION BUNDLE NODO-04
================================================================================
DECISIÓN A: PROVIDER RESOLUTION          ──► 🔒 APPROVED
DECISIÓN B: PROVIDER PROVISIONING        ──► 🔴 REJECTED (NO AUTO-PROVISIONING)
DECISIÓN C: MATERIALIZATION IDENTITY     ──► 🔒 APPROVED CONCEPTUALLY
            (Rematerialization / Update) ──► 🟡 OPEN DECISION
DECISIÓN D: MATERIALIZATION GRANULARITY  ──► 🔒 APPROVED (1 ASSIGNMENT = 1 UNIT)
================================================================================
```

---

## 3. SECCIÓN I — DECISIONES APROBADAS (APPROVED)

### 3.1. DECISIÓN A — PROVIDER RESOLUTION (`APPROVED 🔒`)

- **Dictamen:** **APROBADA**.
- **Definición Arquitectónica:**  
  La correspondencia entre un colaborador SaaS con membresía profesional activa (`memberships`) y la entidad prestador B2C (`perfiles_prestador`) se resuelve canónicamente a través de la identidad del usuario subyacente:
  ```text
  memberships.user_id ──► usuarios.id ≡ perfiles_prestador.id
  ```
- **Fundamento:**  
  En PostgreSQL, `perfiles_prestador` es una tabla de extensión 1:1 de `usuarios` (`FOREIGN KEY (id) REFERENCES usuarios(id)`). `memberships.user_id` referencia directamente a `usuarios(id)`. Por tanto, el identificador físico de prestador B2C asociado al colaborador es unívocamente `provider_id = memberships.user_id`. No se crean entidades ni capas intermedias artificiales de mapeo de usuario.

---

### 3.2. DECISIÓN C — MATERIALIZATION IDENTITY (`APPROVED CONCEPTUALLY 🔒`)

- **Dictamen:** **APROBADA CONCEPTUALMENTE**.
- **Definición Arquitectónica:**  
  La unidad indivisible y canónica de identidad de una materialización downstream es la tupla tridimensional:
  ```text
  (establishment_id, service_offer_id, membership_id)
  ```
  La cual se proyecta de forma biunívoca hacia la estructura B2C:
  ```text
  (provider_id, services.id)
  ```
- **Fundamento:**  
  Una oferta SaaS (`service_offers`) es un ítem de catálogo abstracto de sede con cardinalidad $N:M$ respecto a sus colaboradores asignados (`service_assignments`). En B2C, `public.services` requiere obligatoriamente un único `provider_id`. Por consiguiente, una oferta con múltiples asignaciones se compone de múltiples unidades de materialización independientes.
- **Trazabilidad Downstream:**  
  Queda aprobado conceptualmente que la persistencia del vínculo y su trazabilidad residirán en una entidad técnica de mapeo downstream, preservando completamente inalterada la tabla legacy `public.services`.

---

### 3.3. DECISIÓN D — MATERIALIZATION GRANULARITY (`APPROVED 🔒`)

- **Dictamen:** **APROBADA (1 Assignment por Materialización)**.
- **Definición Arquitectónica:**  
  La granularidad de autorización y ejecución de una materialización opera estrictamente a nivel de **una asignación específica**:
  ```text
  Unidad de Comando = (service_offer_id, membership_id)
  ```
- **Fundamento:**  
  Al requerir la especificación exacta de la oferta y del colaborador asignado, se respeta con máxima fidelidad el principio de autorización deliberada (`DEC-AS-003`), eliminando cualquier riesgo de proyecciones accidentales o masivas no deseadas sobre el catálogo B2C.

---

## 4. SECCIÓN II — DECISIONES RECHAZADAS (REJECTED)

### 4.1. DECISIÓN B — PROVIDER AUTO-PROVISIONING (`REJECTED 🔴`)

- **Dictamen:** **RECHAZADO EL AUTO-PROVISIONING AUTOMÁTICO**.
- **Regla Normativa Ratificada:**  
  `NODO-04` **NO provisionará automáticamente registros en `perfiles_prestador` ni creará wallets en `provider_wallet`**.
- **Comportamiento Físico Obligatorio (Strict Precondition):**  
  Para que una materialización sea ejecutable, el colaborador (`memberships.user_id`) **debe existir previamente en `perfiles_prestador`**.
- **Manejo de Excepción:**  
  Si al procesar una solicitud de materialización válida se constata que no existe fila en `perfiles_prestador` para `memberships.user_id`, `NODO-04` abortará la operación retornando el estado contractual:
  ```text
  MATERIALIZATION_NOT_EXECUTABLE (PROVIDER_PROFILE_REQUIRED)
  ```
- **Fundamento del Rechazo:**  
  La creación de una identidad prestador en B2C constituye una mutación estructural sobre el dominio marketplace con efectos secundarios irreversibles (disparo de `trg_crear_wallet` y creación de `provider_wallet`). Un adaptador downstream SaaS → B2C no debe asumir la potestad de crear identidades prestador sin un flujo explícito de enrolamiento B2C.

---

## 5. SECCIÓN III — DECISIONES ABIERTAS (OPEN DECISIONS)

Las siguientes materias quedan formalmente delimitadas como **decisiones abiertas** para la posterior fase de Arquitectura Física / Implementation Contract:

1. **Comportamiento ante Re-materialización y Actualización (DEC-C)**:  
   El tratamiento específico ante solicitudes repetidas sobre una tupla ya materializada (ej. si ejecuta `UPDATE` sobre atributos comerciales en `public.services`, si retorna error de conflicto o si requiere comando de sincronización explícito) permanece como **OPEN DECISION**.
2. **Esquema Físico de la Tabla de Mapeo**:  
   La definición DDL exacta de la tabla técnica de mapeo downstream (`070_...`) será formalizada en el Implementation Contract.
3. **Transporte y DTOs HTTP**:  
   La especificación formal de rutas, métodos y payloads HTTP permanece pendiente de definición física.
4. **Lifecycle de Desmaterialización y Desasignación**:  
   El comportamiento en B2C ante la baja o desasignación en SaaS permanece fuera de este bundle.

---

## 6. MAPA FÍSICO INTEGRADO TRAS EL DICTAMEN

```text
================================================================================
              FLUJO FÍSICO INTEGRADO DE MATERIALIZACIÓN NODO-04
================================================================================

  [SOLICITUD EXPLÍCITA (DEC-AS-003)]
  Actor: OWNER / MANAGER en Active Context
  Objetivo: (service_offer_id, membership_id) [DEC-D: APPROVED]
          │
          ▼
  [1. VALIDACIÓN DE PRECONDICIONES SAAS]
  Verifica oferta válida + membresía ACTIVE + asignación existente.
          │
          ▼
  [2. RESOLUCIÓN DE PROVIDER (DEC-A: APPROVED)]
  Extrae user_id de la membresía ➔ target_provider_id = memberships.user_id.
          │
          ▼
  [3. COMPROBACIÓN DE EXISTENCIA PREVIA (DEC-B: REJECTED AUTO-PROVISION)]
  Consulta: SELECT id FROM perfiles_prestador WHERE id = target_provider_id;
  ├── NO EXISTE  ──► ABORTA: MATERIALIZATION_NOT_EXECUTABLE (400/422)
  └── SÍ EXISTE  ──► CONTINÚA A PERSISTENCIA
          │
          ▼
  [4. PROYECCIÓN DOWNSTREAM (DEC-C: APPROVED CONCEPTUALLY)]
  Inserta/Registra en public.services + Registra mapeo downstream.
================================================================================
```

---

## 7. IMPACTO EN EL SISTEMA Y VALIDACIÓN DE NO-MUTACIÓN

```text
================================================================================
                    VALIDACIÓN DE NO-MUTACIÓN FÍSICA
================================================================================
ARCHIVOS DE CÓDIGO MODIFICADOS:     0
ARCHIVOS DE MIGRACIÓN CREADOS:      0
TABLAS O VISTAS MUTADAS:            0
NODOS CERRADOS MODIFICADOS:         0
FRONTEND MODIFICADO:                0
================================================================================
```

---

## 8. ESTADO FINAL

```text
================================================================================
NODO-04
PHYSICAL DECISION BUNDLE — RATIFIED 🔒

DIRECTOR AUTHORITY: RATIFIED
NEXT PHASE: PHYSICAL ARCHITECTURE BUNDLE / IMPLEMENTATION CONTRACT 🟡
IMPLEMENTATION: NOT AUTHORIZED 🔴
================================================================================
```
