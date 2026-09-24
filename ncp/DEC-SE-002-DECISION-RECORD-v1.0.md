# DEC-SE-002-DECISION-RECORD-v1.0
## Registro Formal de Decisión Arquitectónica: Estrategia de Sincronización de Ubicación y Horarios

**DECISION_ID:** `DEC-SE-002`  
**TITLE:** Estrategia de Sincronización de Ubicación y Horarios  
**STATUS:** APPROVED — CLOSED 🔒  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**DECISIÓN APROBADA:** OPCIÓN A — NO SINCRONIZACIÓN AUTOMÁTICA / AUTONOMÍA DESACOPLADA  
**GOAL ORIGEN:** DEC-SE-002-002  
**CONTRATOS RELACIONADOS:** `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`  
**FECHA DE FORMALIZACIÓN:** 2026-09-10  

---

## 1. CONTEXTO

En la arquitectura de transición entre el Cockpit SaaS Multitenant y el motor operacional B2C Pre-Nodo 01, se requirió formalizar la relación semántica y técnica entre:
1. **Los datos físicos y comerciales de la sede SaaS:** `establishments.location`, `establishments.address`, `establishments.city` y `establishments.operating_hours`.
2. **Los datos operativos individuales del colaborador B2C:** `perfiles_prestador.ubicacion` y `perfiles_prestador.weekly_schedule` (junto con `active_start_hour` / `active_end_hour`).

Tras la emisión y análisis del documento `/ncp/DEC-SE-002-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`, el Director del Proyecto GlowApp SaaS ha aprobado de manera vinculante la **OPCIÓN A**.

---

## 2. PROBLEMA ARQUITECTÓNICO

¿Cómo deben relacionarse y materializarse la ubicación física y los horarios comerciales de la sede SaaS respecto de los datos operativos de los prestadores en B2C, sin corromper la gestión de turnos individuales, sin sobrescribir destructivamente perfiles existentes y sin alterar la inmutabilidad de Pre-Nodo 01?

---

## 3. DECISIÓN APROBADA (DECLARACIONES CANÓNICAS)

### DEC-SE-002.1
La ubicación de `establishments` pertenece semánticamente de forma exclusiva al **Establishment / Sede** (infraestructura física multitenant).

### DEC-SE-002.2
La ubicación operativa existente en `perfiles_prestador` pertenece semánticamente de forma exclusiva al **Professional / Provider** (prestador individual en marketplace B2C).

### DEC-SE-002.3
Ambos conceptos coexisten en niveles de agregación distintos y **NO deben considerarse automáticamente equivalentes**.

### DEC-SE-002.4
`establishments.operating_hours` representa el horario comercial de apertura y cierre de las instalaciones de la sede.

### DEC-SE-002.5
`perfiles_prestador.weekly_schedule` representa la disponibilidad de agenda y horario laboral individual del profesional.

### DEC-SE-002.6
**No existe sincronización automática** entre ambos dominios de datos.

### DEC-SE-002.7
El Handover inicial **NO ejecuta** sentencias `UPDATE` ni `UPSERT` sobre `perfiles_prestador` para ubicación u horarios.

### DEC-SE-002.8
La gestión de disponibilidad individual, asignación de turnos y agendas particulares corresponde a **módulos operacionales downstream posteriores**.

### DEC-SE-002.9
`NODO-01-v1.0` permanece **estrictamente neutral** respecto de la ubicación y los horarios, limitándose a emitir el descriptor en memoria (`target_establishment_descriptor`) sin mutar la base de datos.

---

## 4. REGLA SEMÁNTICA FORMAL

```text
ESTABLISHMENT LOCATION ≠ PROFESSIONAL LOCATION
ESTABLISHMENT OPERATING HOURS ≠ PROFESSIONAL WEEKLY SCHEDULE
```

Cuando corresponda operacionalmente:
$$\text{professional.schedule} \subseteq \text{establishment.operating\_hours}$$

> **Aclaración Normativa:** La relación de subconjunto debe entenderse como una **restricción de disponibilidad de negocio**, NO como una identidad de datos ni como un mecanismo de sobrescritura automática.

---

## 5. RATIONALE (FUNDAMENTO DE LA DECISIÓN)

1. **Respeto a la Realidad Operativa:** Un establecimiento comercial opera un horario general (ej. 12 horas diarias, 7 días a la semana), mientras que los colaboradores tienen jornadas laborales individuales, turnos rotativos o esquemas de tiempo parcial.
2. **Prevención de Corrupción de Datos:** Evita que una sobrescritura masiva asigne jornadas laborales irreales (ej. 14 horas continuas diarias) a todos los miembros del equipo.
3. **Preservación del Motor de Slots:** Mantiene 100% intacta la lógica de cálculo de citas en `providerController.getProviderSlots` sin riesgo de regresión.
4. **Cero Impacto en Base de Datos:** No requiere migraciones DDL, no altera el esquema de `perfiles_prestador` y no requiere tablas transitorias.

---

## 6. CONSECUENCIAS TÉCNICAS Y OPERACIONALES

### 6.1. Consecuencias Positivas:
- Preservación absoluta de la propiedad semántica de los datos.
- Preservación de la autonomía de horarios individuales de los colaboradores.
- Ausencia total de sobrescritura masiva o destructiva de perfiles.
- Cero migraciones DDL en PostgreSQL.
- Preservación de la neutralidad de `NODO-01-v1.0`.
- Preservación de la inmutabilidad de Pre-Nodo 01.
- Eliminación del riesgo de corrupción en el cálculo de disponibilidad de slots.
- Separación estricta y limpia entre el plano SaaS y el plano B2C.

### 6.2. Consecuencia Operacional Reconocida:
> **Declaración de Coexistencia:** El plano SaaS y el plano B2C pueden mantener temporalmente información espacial y temporal diferente; cualquier futura coordinación o ajuste de turnos deberá definirse explícitamente dentro del módulo operacional downstream correspondiente.

---

## 7. LÍMITES DE LA DECISIÓN (LO QUE DEC-SE-002 NO DECIDE)

Esta decisión se circunscribe exclusivamente a la **definición de propiedad semántica y desacoplamiento en el Handover**. Por lo tanto, **NO define ni prejuzga**:
- Mecanismos de sincronización futura entre sedes y colaboradores.
- Interfaces o pantallas para configuración de turnos de personal.
- Endpoints o servicios para actualización de disponibilidad.
- Frecuencia, eventos o webhooks de sincronización.
- Mecanismos de reconciliación automática.
- Definición de fuentes maestras futuras.
- Estructuras de datos o tablas para turnos de personal.
- Nuevas entidades o relaciones en la base de datos.

---

## 8. RELACIÓN CON OTROS COMPONENTES Y DECISIONES

### 8.1. Relación con DEC-SE-001 (Instanciación de Servicios)
- `DEC-SE-001` permanece en estado: **`APPROVED — CLOSED 🔒`**.
- Ambas decisiones son plenamente coherentes, simétricas e independientes:
  - `DEC-SE-001` resuelve que las ofertas de catálogo no se insertan en `public.services` sin una asignación explícita previa.
  - `DEC-SE-002` resuelve que los horarios y ubicación de sede no se sobreescriben en `perfiles_prestador` sin una configuración de turno explícita.

### 8.2. Relación con `NODO-01-v1.0`
- `NODO-01-v1.0` permanece en estado: **`CLOSED 🔒`**.
- No se modifica su código ni su contrato; Nodo 01 ya implementó este desacoplamiento emitiendo `target_establishment_descriptor` en memoria sin mutar la base de datos.

### 8.3. Relación con Pre-Nodo 01
- Pre-Nodo 01 permanece en estado: **`IMPLEMENTED / IMMUTABLE`**.
- Cero modificaciones en `usuarios`, `perfiles_prestador`, `services`, `bookings`, controladores y frontend B2C.

---

## 9. ESTADO FINAL

```text
================================================================================
DEC-SE-002
OPCIÓN A — NO SINCRONIZACIÓN AUTOMÁTICA / AUTONOMÍA DESACOPLADA

STATUS: APPROVED — CLOSED 🔒

DEC-SE-001: APPROVED — CLOSED 🔒

NO IMPLEMENTATION AUTHORIZED BY THIS DECISION
================================================================================
```