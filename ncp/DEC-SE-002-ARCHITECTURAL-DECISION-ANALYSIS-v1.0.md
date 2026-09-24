# DEC-SE-002-ARCHITECTURAL-DECISION-ANALYSIS-v1.0
## Análisis Arquitectónico: Estrategia de Sincronización de Ubicación y Horarios entre SaaS y Dominio B2C

**DECISION_ID:** `DEC-SE-002`  
**TITLE:** Estrategia de Sincronización de Ubicación y Horarios  
**TYPE:** Architectural Decision Analysis (Read-Only)  
**STATUS:** DEFINED → ANALYZED → PENDING DIRECTOR DECISION 🟡  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** DEC-SE-002-001  
**CONTRATOS RELACIONADOS:** `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`  
**FECHA:** 2026-09-10  

---

## 1. PREGUNTA ARQUITECTÓNICA CENTRAL

> **¿Cómo deben relacionarse y, eventualmente, materializarse la ubicación y los horarios del Establecimiento SaaS respecto de los datos operativos existentes en el dominio B2C (`perfiles_prestador`), sin modificar prematuramente Pre-Nodo 01 ni crear una sincronización semánticamente incorrecta o destructiva?**

---

## 2. EVIDENCIA FÍSICA OBSERVABLE

### 2.1. Dominio SaaS: Tabla `establishments` (`backend/migrations/065_saas_foundation_core.sql`)
```sql
CREATE TABLE IF NOT EXISTS establishments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    organization_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    address TEXT,
    city VARCHAR(100) DEFAULT 'Bogotá',
    location GEOGRAPHY(Point, 4326),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    operating_hours JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_establishment_organization FOREIGN KEY (organization_id, tenant_id) 
        REFERENCES organizations(id, tenant_id) ON DELETE RESTRICT,
    CONSTRAINT uq_establishment_id_tenant UNIQUE (id, tenant_id)
);
```
- **`location` (GEOGRAPHY Point):** Coordenadas PostGIS (SRID 4326) de la sede física multitenant.
- **`address` y `city`:** Dirección física fija y ciudad de operación de la sede comercial.
- **`operating_hours` (JSONB):** Horarios comerciales de apertura y cierre de las instalaciones del establecimiento (ej. Lunes a Sábado de 08:00 a 20:00).
- **Propietario Semántico:** **El Establecimiento / Sede (SaaS B2B)**. Representa las condiciones físicas y comerciales del local donde operan múltiples colaboradores.

---

### 2.2. Dominio B2C: Tabla `perfiles_prestador` (`backend/init.sql`)
```sql
CREATE TABLE perfiles_prestador (
  id INTEGER PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  business_name VARCHAR(255),
  description TEXT,
  is_online BOOLEAN DEFAULT FALSE,
  ubicacion GEOGRAPHY(Point, 4326),
  portafolio_servicios JSONB DEFAULT '[]'::jsonb,
  documento_id_url TEXT,
  rut_url TEXT,
  certificacion_url TEXT,
  estatus_verificacion estado_verificacion DEFAULT 'PENDIENTE',
  rating_avg NUMERIC(3,2) DEFAULT 0.0 CHECK (rating_avg >= 0 AND rating_avg <= 5),
  rating_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  metodo_retiro tipo_metodo_retiro DEFAULT 'NEQUI',
  numero_cuenta_nequi VARCHAR(20),
  documento_titular VARCHAR(20),
  creado_en TIMESTAMPTZ DEFAULT NOW()
);
```
- **`ubicacion` (GEOGRAPHY Point):** Coordenada personal del prestador individual para búsquedas hiper-locales por proximidad (`ST_DWithin`) en el marketplace B2C.
- **`weekly_schedule` / `active_start_hour` / `active_end_hour` (en uso por `providerController.js`):** Define los bloques horarios y días activos en que un profesional específico ofrece citas.
- **Propietario Semántico:** **El Profesional / Prestador Individual (B2C)**.

---

### 2.3. Comportamiento en Controladores B2C (`providerController.js`)
- **Búsqueda Geográfica (`getProviders`):** Filtra por `ST_DWithin(p.ubicacion, Point, radio)` asumiendo que `p.ubicacion` es la posición operativa del prestador.
- **Cálculo de Disponibilidad de Citas (`getProviderSlots`, Líneas 212-235):**
  Consulta `weekly_schedule` y calcula los slots libres del día contrastándolos contra `bookings` existentes de ese `provider_id`.
- **Restricción Clave:** El motor transaccional B2C calcula disponibilidad a nivel de **prestador individual**, no a nivel de establecimiento multitenant.

---

## 3. PREGUNTA CLAVE DE PROPIEDAD SEMÁNTICA

$$\text{¿A quién pertenecen la ubicación y los horarios?}$$

### Dictamen de la Evidencia:
La ubicación y los horarios **NO representan el mismo concepto**, sino **conceptos distintos y autónomos que coexisten en diferentes niveles de agregación**:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        NIVEL SEDE / ESTABLISHMENT                      │
│                                                                        │
│  - Ubicación: Inmueble físico fijo del Salón (Cra 43A # 1-50, Sede).  │
│  - Horario: Ventana comercial del local (08:00 - 20:00).              │
│  - Capacidad: Multi-estación, multi-colaborador.                       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Contiene / Enmarca
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      NIVEL PROFESIONAL / PRESTADOR                     │
│                                                                        │
│  - Ubicación Operativa: Lugar donde atiende (Sede vs Domicilio).       │
│  - Horario Laboral / Turno: Jornada individual (ej. 08:00 - 14:00).   │
│  - Disponibilidad: Depende de sus reservas individuales (bookings).   │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Incompatibilidad de Asimilación:**
   $$\text{establishment.location} \neq \text{professional.ubicacion (independiente)}$$
   $$\text{establishment.operating\_hours} \neq \text{professional.weekly\_schedule (turno individual)}$$
2. **Principio de Subconjunto:** La disponibilidad de un colaborador dentro de una sede es conceptualmente un **subconjunto** del horario de la sede:
   $$\text{professional.schedule} \subseteq \text{establishment.operating\_hours}$$
3. **Peligro de Sobrescritura Ciega:** Copiar directamente los horarios de la sede en los perfiles de todos los miembros del staff destruiría la gestión de turnos (ej. personal de media jornada o días rotativos) y desvirtuaría perfiles preexistentes de prestadores en B2C.

---

## 4. ANÁLISIS DE LA TENSIÓN ARQUITECTÓNICA

| Atributo | Plano SaaS (Establishment) | Plano B2C (Perfiles Prestador) | Tensión / Incompatibilidad |
| :--- | :--- | :--- | :--- |
| **Ubicación** | Punto fijo de la infraestructura física compartida. | Posición del prestador individual para búsqueda marketplace. | Un salón tiene 1 ubicación física compartida por $N$ colaboradores; B2C busca profesionales individuales. |
| **Horarios** | Horario de atención al público del establecimiento. | Horario laboral / disponibilidad de agenda individual. | Un local abre 12 horas al día, pero ningún empleado individual atiende las 12 horas consecutivas todos los días. |
| **Gobernanza** | Administrado por el `OWNER` / `MANAGER` de la sede. | Administrado por el usuario / prestador. | El dueño de sede no debe sobreescribir destructivamente el perfil personal B2C sin consentimiento explícito. |

---

## 5. ANÁLISIS DE OPCIONES ARQUITECTÓNICAS

---

### OPCIÓN A: No Sincronización Automática / Autonomía Desacoplada (Decoupled Autonomy — APROBACIÓN RECOMENDADA)

- **Descripción:** Los datos del establecimiento (`location` y `operating_hours`) se transfieren en el Handover exclusivamente como **descriptores de contexto de sede** (`target_establishment_descriptor` en Nodo 01). **NO se ejecuta ninguna sentencia `UPDATE` ni `UPSERT` sobre `perfiles_prestador` durante el Handover.**
- **Mecanismo Operativo:**
  - La sede mantiene sus horarios comerciales en SaaS.
  - La asignación de horarios individuales o vinculación de turnos a prestadores se realiza en un flujo operacional posterior y explícito (downstream).
- **Evaluación Técnica:**
  - **Compatibilidad con SaaS y HBC v1.0:** **100% Compatible.**
  - **Inmutabilidad de Pre-Nodo 01:** **100% Preservada.** Cero modificaciones a `perfiles_prestador` ni a controladores de búsqueda.
  - **Impacto en `bookings` y Slots:** Cero impacto negativo. Los slots continúan calculándose con base en la agenda configurada del prestador.
  - **Riesgo y Complejidad:** **Mínima / Cero Riesgo de Corrupción de Datos.**
  - **Reversibilidad:** **100% Reversible.**
  - **Economía Arquitectónica:** Máxima (cero DDL, cero migraciones).

---

### OPCIÓN B: Sincronización Unilateral Forzada (`ESTABLISHMENT → PERFILES_PRESTADOR`)

- **Descripción:** Al completarse el Handover, ejecutar un `UPDATE` masivo sobre `perfiles_prestador` para todos los miembros activos del staff, sobreescribiendo su `ubicacion` con las coordenadas de la sede y su `weekly_schedule` con el `operating_hours` del establecimiento.
- **Evaluación Técnica:**
  - **Problemas Graves:**
    1. Si la sede abre de 7:00 a 21:00 de Lunes a Domingo, todos los colaboradores quedan marcados con 14 horas diarias los 7 días.
    2. Sobreescribe y corrompe la ubicación personal de profesionales que atienden a domicilio o en múltiples sedes.
    3. Viola el principio de no mutación destructiva del Handover.
  - **Veredicto:** **INVIABLE / RECHAZADA.**

---

### OPCIÓN C: Sincronización Bidireccional (`ESTABLISHMENT ⇄ PERFILES_PRESTADOR`)

- **Descripción:** Cualquier cambio en el horario del prestador en B2C muta el horario de la sede en SaaS y viceversa.
- **Evaluación Técnica:**
  - **Problemas Graves:** Destruye el modelo de autoridad SaaS. Un estilista individual no puede alterar el horario comercial de apertura de una empresa.
  - **Veredicto:** **INVIABLE / RECHAZADA.**

---

### OPCIÓN D: Modelo Intermedio de Turnos por Sede (Establishment Shifts Downstream Model)

- **Descripción:** Diseñar en una fase downstream posterior una tabla relacional `establishment_staff_schedules` que permita definir turnos individuales (ej. Turno Mañana: 08:00 - 14:00) dentro de la sede.
- **Evaluación Técnica:**
  - **Viabilidad Futura:** Es una evolución natural para un módulo avanzado de agenda multi-sede (Nodo 02+).
  - **Oportunidad:** No es necesaria ni requerida para la frontera actual de Nodo 01.
  - **Veredicto:** **DIFERIDA A FUTURAS FASES OPERACIONALES.**

---

## 6. MATRIZ COMPARATIVA DE EVALUACIÓN

| Criterio de Evaluación | OPCIÓN A (No Sincronización Automática) | OPCIÓN B (Sincronización Unilateral) | OPCIÓN C (Sincronización Bidireccional) | OPCIÓN D (Modelo Turnos Futuro) |
| :--- | :---: | :---: | :---: | :---: |
| **Respeto a la Propiedad Semántica** | **TOTAL 🟢** | NULO (Sobrescritura Ciega) 🔴 | NULO (Violación de Autoridad) 🔴 | **TOTAL 🟢** |
| **Inmutabilidad Pre-Nodo 01** | **TOTAL 🟢** | PARCIAL (Mutación Masiva) 🟡 | PARCIAL 🟡 | Requiere DDL 🟡 |
| **Preservación de Turnos Staff** | **TOTAL 🟢** | DESTRUIDO 🔴 | DESTRUIDO 🔴 | TOTAL 🟢 |
| **Impacto en Motor de Slots** | **CERO 🟢** | CORRUPCIÓN DE SLOTS 🔴 | CORRUPCIÓN DE SLOTS 🔴 | Requiere refactor 🟡 |
| **Migraciones DDL Requeridas** | **0 (CERO) 🟢** | 0 🟢 | 0 🟢 | 2+ Tablas 🟡 |
| **Economía Arquitectónica** | **MÁXIMA 🟢** | BAJA 🔴 | NULA 🔴 | MEDIA 🟡 |
| **Riesgo Operativo** | **NULO 🟢** | CRÍTICO 🔴 | CRÍTICO 🔴 | MEDIO 🟡 |

---

## 7. RELACIÓN CON DEC-SE-001 Y NODO 01

1. **Relación con DEC-SE-001 (Instanciación de Servicios):**
   - DEC-SE-001 resolvió que los servicios no se insertan en `public.services` sin una asignación explícita previa (`OPCIÓN A — APPROVED`).
   - DEC-SE-002 es plenamente coherente y análoga: la ubicación y los horarios de la sede no se insertan ni sobreescriben en `perfiles_prestador` sin una configuración operativa explícita de turno.
2. **Relación con `NODO-01-v1.0`:**
   - Nodo 01 ya implementó este principio en memoria: entrega `target_establishment_descriptor` con las coordenadas y horarios validados de la sede, manteniendo `pending_decisions.DEC_SE_002 = "PENDING"` y ejecutando cero sentencias `UPDATE`.

---

## 8. RECOMENDACIÓN TÉCNICA (NO APROBADA)

```text
RECOMENDACIÓN TÉCNICA — NO APROBADA (PENDIENTE DE DECISIÓN DEL DIRECTOR):

Se recomienda adoptar la OPCIÓN A (No Sincronización Automática / Autonomía Desacoplada).

FUNDAMENTO:
1. Reconoce que la sede y el colaborador poseen identidades espaciales y temporales distintas.
2. Evita la corrupción destructiva de perfiles y la asignación irreal de 14 horas diarias a todos los miembros del staff.
3. Preserva 100% la inmutabilidad de Pre-Nodo 01 y el motor transaccional de slots en providerController.js.
4. Mantiene la neutralidad e integridad de NODO-01-v1.0 sin requerir migraciones DDL en PostgreSQL.
```

---

## 9. ESTADO FINAL Y DECISIÓN REQUERIDA

```text
================================================================================
DEC-SE-002: ESTRATEGIA DE SINCRONIZACIÓN DE UBICACIÓN Y HORARIOS

STATUS: PENDING DIRECTOR DECISION 🟡

PUNTOS SOMETIDOS A DECISIÓN FORMAL DEL DIRECTOR:
1. ¿Se aprueba formalmente la OPCIÓN A (No Sincronización Automática / Autonomía
   Desacoplada) como la directiva canónica para DEC-SE-002?
2. ¿Se ratifica que el Handover inicial NO debe ejecutar sentencias UPDATE ni UPSERT
   sobre perfiles_prestador.ubicacion ni perfiles_prestador.weekly_schedule?
3. ¿Se ratifica que la gestión de turnos y agendas individuales corresponde a
   módulos operacionales downstream posteriores?
================================================================================
```