# DEC-SE-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0
## Análisis Arquitectónico: Estrategia de Instanciación de Servicios en Dominio B2C

**DECISION_ID:** `DEC-SE-001`  
**TITLE:** Estrategia de Instanciación y Asignación de Servicios B2C  
**TYPE:** Architectural Decision Analysis (Read-Only)  
**STATUS:** DEFINED → ANALYZED → PENDING DIRECTOR DECISION 🟡  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** DEC-SE-001-001  
**CONTRATOS RELACIONADOS:** `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`  
**FECHA:** 2026-09-10  

---

## 1. PREGUNTA ARQUITECTÓNICA CENTRAL

> **¿Cómo debe materializarse un `service_offer` proveniente del plano SaaS en el dominio B2C existente, considerando que la tabla física `public.services` exige actualmente `provider_id INTEGER NOT NULL`, mientras que el Handover Boundary Contract (`HBC v1.0`) y `NODO-01-v1.0` establecen explícitamente que la oferta llega sin `provider_id` y con `assignment = NOT_ESTABLISHED`?**

---

## 2. EVIDENCIA FÍSICA OBSERVABLE

### 2.1. Dominio B2C: Tabla `public.services` (`backend/init.sql`)
```sql
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
  category VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
- **Restricción de No Nulidad:** `provider_id INTEGER NOT NULL` exige obligatoriamente un identificador de prestador en cada inserción física.
- **Clave Foránea:** `REFERENCES perfiles_prestador(id)` exige que dicho prestador exista previamente en la tabla `perfiles_prestador`.
- **Cardinalidad:** 1 prestador individual (`provider_id`) posee $N$ servicios. No existe noción de sede, tenant ni asignación múltiple.
- **Comportamiento en Controladores B2C (`backend/src/controllers/serviceController.js`):**
  - `getProviderServices`: Consulta `Service.findAll({ where: { provider_id: req.user.id } })`.
  - `createService`: Inserta directamente asociando `provider_id: req.user.id`.

### 2.2. Dominio B2C: Tabla `public.perfiles_prestador` (`backend/init.sql`)
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
- **Naturaleza:** Representa un perfil individual de prestador independiente en el marketplace B2C (relación 1:1 con `usuarios.id`).
- **Requisitos Operativos:** Exige estatus de verificación, configuración de pagos y localización geográfica personal.

### 2.3. Dominio B2C: Tabla `public.bookings` (`backend/init.sql` y `bookingController.js`)
```sql
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
  provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id) ON DELETE RESTRICT,
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
  scheduled_at TIMESTAMPTZ NOT NULL,
  valor_bruto NUMERIC(10,2) NOT NULL CHECK (valor_bruto >= 0),
  comision_plataforma NUMERIC(10,2) DEFAULT 0.00,
  impuestos_estado NUMERIC(10,2) DEFAULT 0.00,
  pago_neto_prestador NUMERIC(10,2) DEFAULT 0.00,
  estado estado_cita DEFAULT 'PENDIENTE_PAGO',
  pin_verificacion VARCHAR(4),
  payment_status VARCHAR(20) DEFAULT 'unpaid',
  service_address TEXT,
  ...
);
```
- **Dependencia Fuerte:** `bookings.provider_id` y `bookings.service_id` son ambos `NOT NULL`.
- **Validación en `bookingController.js` (Líneas 57-62):**
  `Service.findAll({ where: { id: service_ids, provider_id } })` valida estrictamente que el servicio pertenezca al `provider_id` seleccionado en la reserva.

### 2.4. Dominio SaaS (Activos Cerrados y Protegidos)
- **Jerarquía:** `Tenant` $\rightarrow$ `Organization` $\rightarrow$ `Establishment` $\rightarrow$ `Memberships` (con roles `OWNER`, `MANAGER`, `PROFESSIONAL`).
- **Declaración de Catálogo:** En Crear Desde Cero / Hub Salón, el catálogo se define a nivel de **Establecimiento** (`relevant_services` / `service_offers`).
- **Declaración de Personal:** El personal declara capacidades temáticas (`assigned_categories`) en `people_initial_roles`.
- **Principio Canónico Inviolable:**
  $$\text{IDENTITY } (\texttt{usuarios.id}) \neq \text{CAPABILITY } (\texttt{assigned\_categories}) \neq \text{ASSIGNMENT } (\texttt{public.services.provider\_id})$$
  $$\text{service\_offer (SaaS)} \neq \text{B2C service record (Pre-Nodo 01)}$$

---

## 3. LA TENSIÓN ARQUITECTÓNICA

```text
PLANO SAAS MULTITENANT (B2B)                PLANO CORE TRANSACCIONAL (B2C)
┌─────────────────────────────────┐         ┌─────────────────────────────────┐
│       ESTABLISHMENT (Sede)      │         │   perfiles_prestador (1:1 User) │
└────────────────┬────────────────┘         └────────────────┬────────────────┘
                 │                                           │
                 ▼                                           ▼
┌─────────────────────────────────┐         ┌─────────────────────────────────┐
│      SERVICE_OFFERS (Catálogo)  │         │   public.services (1 Provider)  │
│    (Sin provider_id asignado)   │         │    (provider_id NOT NULL Obrig) │
└────────────────┬────────────────┘         └────────────────┬────────────────┘
                 │                                           │
                 ▼                                           ▼
┌─────────────────────────────────┐         ┌─────────────────────────────────┐
│  assignment: "NOT_ESTABLISHED"  │ ◄─ INCOMPATIBLE ─► │ public.bookings (Transacción)   │
└─────────────────────────────────┘         └─────────────────────────────────┘
```

### Raíz de la Incompatibilidad:
1. **Incompatibilidad de Cardinalidad:** En SaaS, 1 Establecimiento oferta un catálogo para ser ejecutado por cualquiera de sus colaboradores calificados ($1:N:M$). En B2C, cada servicio en `public.services` está inexorablemente anclado a un único prestador ($1:1$).
2. **Incompatibilidad Temporal/Secuencial:** En el momento del Handover inicial, SaaS entrega la intención de catálogo de la sede sin haber realizado asignaciones de staff individuales. B2C no puede almacenar un registro en `public.services` sin un `provider_id`.
3. **Prohibición de Asignación Automática:** Asignar arbitrariamente el servicio al `OWNER` o duplicarlo masivamente para todo el personal viola la soberanía contractual y el principio `identity ≠ capability ≠ assignment`.

---

## 4. ANÁLISIS DE OPCIONES ARQUITECTÓNICAS

---

### OPCIÓN A: Instanciación Tardía / Asignación Explícita Bajo Demanda (Deferred Materialization on Explicit Assignment)

- **Descripción:** El `service_offer` permanece como descriptor en memoria o estado de configuración de la sede. **NO se inserta ninguna fila en `public.services` durante el Handover inicial.** La inserción en `public.services` se posterga hasta que un flujo operacional explícito (e.g. pantalla de asignación de agenda en Hub Salón o workflow downstream) asigne formalmente a un profesional con perfil de prestador.
- **Evaluación Técnica:**
  - **Compatibilidad con HBC v1.0:** **100% Compatible.** Respeta textualmente `assignment.status = "NOT_ESTABLISHED"`.
  - **Compatibilidad con Nodo 01:** **100% Compatible.** Mantiene `DOWNSTREAM ADAPTATION RESULT` como descriptor en memoria sin mutación física.
  - **Compatibilidad con Pre-Nodo 01:** **100% Compatible.** No altera el esquema ni las restricciones de `public.services`, `bookings` ni `perfiles_prestador`.
  - **Impacto en BD / Migraciones:** **CERO migraciones.** Cero nuevas tablas o columnas en B2C.
  - **Impacto en RLS y Seguridad:** Cero impacto sobre RLS de Foundation.
  - **Complejidad y Riesgo:** **Mínima / Cero Riesgo de Regresión.**
  - **Reversibilidad:** **100% Reversible.**
  - **Preservación de Principio:** Cumple rigurosamente `identity ≠ capability ≠ assignment`.

---

### OPCIÓN B: Entidad Puente Downstream para Catálogo de Sede (Establishment Catalog Downstream Bridge Table)

- **Descripción:** Crear una tabla downstream intermedia (e.g., `establishment_services` o `establishment_catalog_offers`) con clave foránea a `establishments(id)`, almacenando los servicios a nivel de sede sin `provider_id`. En una etapa posterior, una tabla de unión (`establishment_service_assignments`) vincularía dichos servicios a los `perfiles_prestador`.
- **Evaluación Técnica:**
  - **Compatibilidad con HBC v1.0:** Compatible.
  - **Compatibilidad con Nodo 01:** Compatible (supeditada a directiva posterior).
  - **Compatibilidad con Pre-Nodo 01:** Parcial. Si `bookings` sigue exigiendo `service_id REFERENCES services(id)`, se requeriría duplicar servicios o modificar `bookings`.
  - **Impacto en BD / Migraciones:** **Requiere nuevas tablas físicas** y migraciones en PostgreSQL.
  - **Complejidad y Riesgo:** Media-Alta. Introduce entidades intermedias no aprobadas previamente y riesgo de fragmentación del catálogo.
  - **Reversibilidad:** Media (requiere rollback de esquemas DDL).

---

### OPCIÓN C: Modificación Estructural de `public.services` (Nullable `provider_id` + `establishment_id`)

- **Descripción:** Modificar la tabla física `public.services` mediante `ALTER TABLE services ALTER COLUMN provider_id DROP NOT NULL` y agregar `establishment_id UUID REFERENCES establishments(id)`.
- **Evaluación Técnica:**
  - **Compatibilidad con Pre-Nodo 01:** **INCOMPATIBLE / DESTRUCTIVA.** Rompe la inmutabilidad de Pre-Nodo 01.
  - **Impacto en Controladores B2C:** Rompe consultas en `serviceController.js`, `providerController.js`, `bookingController.js` y modelos Sequelize.
  - **Impacto en `bookings`:** Rompe la lógica de reserva que asume `service.provider_id == booking.provider_id`.
  - **Complejidad y Riesgo:** **Crítica / Alto Riesgo de Quiebre de Regresión en Producción.**
  - **Reversibilidad:** Baja.

---

### OPCIÓN D: Instanciación Automática por Coincidencia Temática / Category Matching (Eager Replication)

- **Descripción:** Al recibir el Handover, iterar sobre el personal activo cuyas `capabilities` coincidan con la categoría del servicio y crear automáticamente una fila en `public.services` para cada uno (o asignarlo automáticamente al `OWNER`).
- **Evaluación Técnica:**
  - **Compatibilidad con HBC v1.0:** **VIOLACIÓN DIRECTA DE CONTRATO.** Viola HBC-DEC-003 y R03/R05.
  - **Preservación de Principio:** Destruye la separación `identity ≠ capability ≠ assignment`. Asume erróneamente que una aptitud equivale a una obligación operativa.
  - **Complejidad y Riesgo:** Alta (crea registros fantasma en la base de datos sin consentimiento del profesional).
  - **Reversibilidad:** Baja.

---

## 5. MATRIZ COMPARATIVA DE EVALUACIÓN

| Criterio de Evaluación | OPCIÓN A (Instanciación Tardía) | OPCIÓN B (Tabla Puente) | OPCIÓN C (Mutar `public.services`) | OPCIÓN D (Category Matching) |
| :--- | :---: | :---: | :---: | :---: |
| **Conformidad con HBC v1.0** | **TOTAL 🟢** | TOTAL 🟢 | PARCIAL 🟡 | **VIOLACIÓN 🔴** |
| **Inmutabilidad de Pre-Nodo 01** | **TOTAL 🟢** | PARCIAL 🟡 | **VIOLACIÓN 🔴** | PARCIAL 🟡 |
| **Preservación de Principios** | **TOTAL 🟢** | TOTAL 🟢 | PARCIAL 🟡 | **VIOLACIÓN 🔴** |
| **Impacto en `bookings`** | **CERO 🟢** | MEDIO 🟡 | **ALTO (ROTO) 🔴** | MEDIO 🟡 |
| **Migraciones DDL Requeridas** | **0 (CERO) 🟢** | 2+ Tablas 🟡 | Alteraciones DDL 🔴 | 0 🟢 |
| **Economía Arquitectónica** | **MÁXIMA 🟢** | MEDIA 🟡 | MÍNIMA 🔴 | BAJA 🔴 |
| **Riesgo Operativo** | **NULO 🟢** | MEDIO 🟡 | **CRÍTICO 🔴** | ALTO 🔴 |

---

## 6. DELIMITACIÓN DE DEPENDENCIAS (PROHIBICIÓN DE RESOLVER DEC-SE-002)

Se deja constancia explícita de que este análisis **NO resuelve ni prejuzga `DEC-SE-002`** (Estrategia de Sincronización de Ubicación y Horarios):
- La ubicación física (`Point`) y los horarios semanales de la sede (`operating_hours`) continúan perteneciendo exclusivamente al contexto del establecimiento.
- La determinación de cómo y cuándo se sincronizan estos datos con `perfiles_prestador` se abordará en su propio ciclo normativo.

---

## 7. RECOMENDACIÓN TÉCNICA (NO APROBADA)

```text
RECOMENDACIÓN TÉCNICA — NO APROBADA (PENDIENTE DE DECISIÓN DEL DIRECTOR):

Se recomienda adoptar la OPCIÓN A (Instanciación Tardía / Asignación Explícita Bajo Demanda).

FUNDAMENTO:
1. Es la única alternativa que respeta simultáneamente la inmutabilidad absoluta de Pre-Nodo 01 y la soberanía semántica de HBC v1.0.
2. No requiere migraciones DDL ni introduce tablas intermedias innecesarias.
3. Mantiene intacto el modelo transaccional de bookings.
4. Garantiza que jamás se cree un registro en public.services sin una decisión operativa consciente y explícita.
```

---

## 8. DECISIÓN REQUERIDA AL DIRECTOR

```text
================================================================================
DEC-SE-001:
STATUS: PENDING DIRECTOR DECISION 🟡

PUNTOS SOMETIDOS A DECISIÓN FORMAL DEL DIRECTOR:
1. ¿Se aprueba formalmente la OPCIÓN A (Instanciación Tardía Bajo Demanda) como la
   estrategia canónica de instanciación para DEC-SE-001?
2. ¿Se ratifica que el Handover inicial NO debe ejecutar inserciones en public.services
   mientras assignment.status sea NOT_ESTABLISHED?
3. ¿Se autoriza proceder posteriormente con el análisis de DEC-SE-002?
================================================================================
```