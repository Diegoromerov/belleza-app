# DEC-SE-001-DECISION-RECORD-v1.0
## Registro Formal de Decisión Arquitectónica: Estrategia de Instanciación de Servicios en Dominio B2C

**DECISION_ID:** `DEC-SE-001`  
**TITLE:** Estrategia de Instanciación y Asignación de Servicios B2C  
**STATUS:** APPROVED — CLOSED 🔒  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**DECISIÓN APROBADA:** OPCIÓN A — INSTANCIACIÓN TARDÍA / ASIGNACIÓN EXPLÍCITA BAJO DEMANDA  
**GOAL ORIGEN:** DEC-SE-001-002  
**CONTRATOS RELACIONADOS:** `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`  
**FECHA DE FORMALIZACIÓN:** 2026-09-10  

---

## 1. CONTEXTO

En la arquitectura de transición entre el Cockpit SaaS Multitenant y el motor operacional B2C Pre-Nodo 01, se identificó una tensión estructural entre:
1. **El modelo SaaS (B2B):** Donde un establecimiento (`establishments`) oferta un catálogo comercial (`service_offers`) sin asignar un prestador individual en el momento del onboarding inicial (`assignment.status = "NOT_ESTABLISHED"`).
2. **El modelo Core B2C (Pre-Nodo 01):** Donde la tabla física `public.services` exige la restricción de no nulidad `provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id)`.

Tras la emisión y análisis del documento `/ncp/DEC-SE-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`, el Director del Proyecto GlowApp SaaS ha aprobado de manera vinculante la **OPCIÓN A**.

---

## 2. PROBLEMA ARQUITECTÓNICO

¿Cómo debe materializarse un `service_offer` proveniente de SaaS en el dominio B2C, preservando la inmutabilidad de Pre-Nodo 01, la soberanía de HBC v1.0 y la separación semántica entre aptitud profesional y asignación de agenda?

---

## 3. EVIDENCIA RESUMIDA

- **Restricción Física B2C:** `public.services` exige `provider_id INTEGER NOT NULL`. Cada fila en `services` pertenece exclusivamente a un prestador individual.
- **Dependencia Transaccional:** `public.bookings` referencia `service_id` y `provider_id`, validando en controladores (`bookingController.js`) que `service.provider_id == booking.provider_id`.
- **Invariante de Frontera:** `HBC v1.0` y `NODO-01-v1.0` establecen que las ofertas llegan a nivel de sede sin `provider_id` y que la coincidencia temática (`category matching`) **NO** constituye una asignación demostrada.

---

## 4. ALTERNATIVAS EVALUADAS

1. **OPCIÓN A (Instanciación Tardía / Bajo Demanda):** Mantener el modelo B2C intacto y diferir la inserción física en `public.services` hasta que exista una asignación explícita. *(APROBADA)*
2. **OPCIÓN B (Tabla Puente Downstream):** Crear tablas intermedias `establishment_services` sin `provider_id`. *(Descartada por introducir complejidad física y migraciones no esenciales)*
3. **OPCIÓN C (Modificación Estructural DDL en `public.services`):** Hacer `provider_id` nullable y agregar `establishment_id`. *(Descartada por violar la inmutabilidad de Pre-Nodo 01 y quebrar controladores B2C)*
4. **OPCIÓN D (Category Matching / Eager Replication):** Replicar automáticamente el servicio para cada colaborador cuya categoría coincida. *(Descartada por violar frontalmente el principio `identity ≠ capability ≠ assignment`)*

---

## 5. DECISIÓN APROBADA (DECLARACIONES CANÓNICAS)

### DEC-SE-001.1
El modelo SaaS puede mantener `service_offer` sin asignación durante el Handover inicial.

### DEC-SE-001.2
Mientras `assignment.status = "NOT_ESTABLISHED"`, **NO se materializa ningún registro** correspondiente en la tabla física `public.services`.

### DEC-SE-001.3
La materialización física de un servicio en el dominio B2C (`public.services`) únicamente puede producirse posteriormente cuando exista una **asignación operativa explícita y válida** a un colaborador con perfil de prestador.

### DEC-SE-001.4
La asignación explícita **NO puede inferirse automáticamente** desde el rol (`OWNER`, `MANAGER`, `PROFESSIONAL`), las capacidades declaradas (`capabilities`) ni la coincidencia temática de categorías (`category`).

### DEC-SE-001.5
`service_offer` (oferta comercial de sede en SaaS) y `public.services` (registro transaccional de prestador en B2C) permanecen formalmente como **conceptos y entidades distintas**.

### DEC-SE-001.6
`provider_id` pertenece exclusivamente al modelo operacional B2C y **NO** forma parte de `service_offers` en el Handover Boundary Contract.

### DEC-SE-001.7
`NODO-01-v1.0` permanece **estrictamente neutral** respecto de la asignación, limitándose a emitir el descriptor conceptual en memoria sin mutar la base de datos.

---

## 6. RATIONALE (FUNDAMENTO DE LA DECISIÓN)

1. **Preservación de Inmutabilidad:** Pre-Nodo 01 permanece 100% inalterado, sin requerir migraciones DDL ni cambios en los controladores B2C existentes.
2. **Blindaje Semántico:** Se respeta rigurosamente el axioma canónico:
   $$\text{IDENTITY } (\texttt{usuarios.id}) \neq \text{CAPABILITY } (\texttt{assigned\_categories}) \neq \text{ASSIGNMENT } (\texttt{public.services.provider\_id})$$
   $$\text{SERVICE OFFER } (\text{SaaS}) \neq \text{B2C SERVICE } (\text{Pre-Nodo 01})$$
3. **Economía Arquitectónica:** No genera código muerto, no crea tablas provisionales y evita la inserción de registros fantasma o huérfanos en la base de datos.
4. **Trazabilidad y Seguridad:** Garantiza que toda futura fila en `public.services` provenga de una decisión de negocio explícita y auditable.

---

## 7. CONSECUENCIAS TÉCNICAS

1. **En SaaS / Crear Desde Cero:** Continúa emitiendo `relevant_services` y `people_initial_roles` con `assignment.status = "NOT_ESTABLISHED"`.
2. **En Handover Boundary Contract (HBC v1.0):** El contrato permanece 100% válido, estable e intacto.
3. **En Nodo 01:** `nodo01Service.js` continúa operando en memoria, produciendo `catalog_offer_descriptors` sin inserciones en `public.services`.
4. **En Dominio B2C:** La tabla `public.services` solo recibirá inserciones cuando se diseñe e implemente un flujo downstream formal de asignación.

---

## 8. LÍMITES DE LA DECISIÓN (LO QUE DEC-SE-001 NO DECIDE)

Esta decisión se circunscribe exclusivamente a la **estrategia de instanciación conceptual y materialización tardía**. Por lo tanto, **NO define ni prejuzga**:
- Quién ni qué rol ejecutará la futura asignación operativa.
- Qué interfaz o pantalla capturará la asignación de profesionales a servicios.
- Qué endpoint específico procesará dicha asignación.
- Cómo se seleccionará el profesional para cada oferta de catálogo.
- Cómo se persistirá la asignación (si en memoria, en tabla B2C directa o en adapter downstream).
- Si será necesaria una entidad relacional adicional en el futuro downstream.
- Cómo se sincronizarán la ubicación física y los horarios semanales (materia exclusiva de `DEC-SE-002`).

---

## 9. RELACIÓN CON CONTRATOS Y COMPONENTES

### 9.1. Relación con Handover Boundary Contract (`HBC v1.0`)
- `HBC v1.0` permanece como el estándar inmutable de entrega semántica.
- La decisión ratifica que el HBC **NO debe contener `provider_id`** en `service_offers`.

### 9.2. Relación con `NODO-01-v1.0`
- Nodo 01 procesa el Handover y genera `DOWNSTREAM ADAPTATION RESULT` en memoria.
- Nodo 01 **no crea `provider_id`**, **no crea filas en `public.services`**, **no asigna profesionales** y **no transforma capabilities en asignaciones**.
- El contrato de Nodo 01 permanece 100% intacto.

### 9.3. Relación con Pre-Nodo 01
- Pre-Nodo 01 permanece en estado **`IMPLEMENTED / IMMUTABLE`**.
- Cero modificaciones en `usuarios`, `perfiles_prestador`, `services`, `bookings`, controladores y frontend B2C.

---

## 10. DEPENDENCIAS PENDIENTES

```text
DEC-SE-002 (Sincronización de Ubicación y Horarios)
STATUS: PENDING 🟡
```
`DEC-SE-002` corresponde exclusivamente a la estrategia de sincronización de ubicación y horarios semanales hacia `perfiles_prestador`. Su análisis y decisión permanecen pendientes y no son afectados por el cierre de `DEC-SE-001`.

---

## 11. ESTADO FINAL

```text
================================================================================
DEC-SE-001
OPCIÓN A — INSTANCIACIÓN TARDÍA / ASIGNACIÓN EXPLÍCITA BAJO DEMANDA

STATUS: APPROVED — CLOSED 🔒

DEC-SE-002: PENDING 🟡

NO IMPLEMENTATION AUTHORIZED BY THIS DECISION
================================================================================
```
