# NODO-05 — TIMEZONE ARCHITECTURAL DECISION ANALYSIS v1.0
## Focused Temporal Model, Forensics & Timezone Strategy for Availability Projection

**DOCUMENT IDENTIFIER:** `NODO-05-TIMEZONE-DECISION-ANALYSIS-v1.0`  
**STATUS:** `TIMEZONE DECISION: OPEN / DIRECTOR DECISION REQUIRED 🟡`  
**IMPLEMENTATION AUTHORIZATION:** `NOT AUTHORIZED 🛑`  
**DATE:** 2026-09-11  
**ROLE:** Senior Architectural Auditor & Governance Agent  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GOAL — NODO-05 TIMEZONE ARCHITECTURAL DECISION ANALYSIS v1.0`  
**METHODOLOGY:** DEFINIR → RELACIONAR → INTEGRAR → VALIDAR → CERRAR → AVANZAR  

---

## 1. OBJECTIVE (OBJETIVO)

Proveer un análisis arquitectónico exhaustivo, forense y estrictamente de solo lectura sobre cómo `NODO-05` debe interpretar temporalmente:
- `target_date` (Fecha objetivo en formato ISO `YYYY-MM-DD`),
- `staff_schedules.start_time` y `staff_schedules.end_time` (`TIME WITHOUT TIME ZONE`),
- `establishments.operating_hours` (`JSONB` con horas de reloj nominales),
- `bookings.scheduled_at` (`TIMESTAMPTZ` en UTC),

sin alterar código ni ejecutar mutaciones físicas, a fin de que el Director disponga de toda la evidencia para sancionar la política de zona horaria del sistema.

---

## 2. EXISTING TEMPORAL MODEL (MODELO TEMPORAL EXISTENTE)

El ecosistema GlowApp opera actualmente bajo un modelo temporal híbrido compuesto por tres dimensiones:

```text
================================================================================
                    MODELO TEMPORAL ACTUAL EN GLOWAPP
================================================================================
  1. POSTGRESQL ENGINE:       TimeZone = 'Etc/UTC' (Servidor en UTC puro)
  2. DOCKERFILE / RUNTIME:    ENV TZ = 'America/Bogota' (UTC-5 fijo, sin DST)
  3. HORARIOS DECLARATIVOS:   TIME WITHOUT TIME ZONE (Hora local de pared '08:00')
  4. CITAS B2C (bookings):    TIMESTAMPTZ (Instantes absolutos en UTC)
  5. ESTABLECIMIENTOS:        city = 'Bogotá' (Sin columna timezone en BD)
================================================================================
```

---

## 3. FORENSIC EVIDENCE (EVIDENCIA FORENSE EN EL REPOSITORIO)

### 3.1. Configuración de Base de Datos PostgreSQL
- **Consulta Ejecutada:** `SHOW timezone;`
- **Resultado Factual:** `TimeZone = 'Etc/UTC'`.
- **Comportamiento:** PostgreSQL almacena todas las columnas `TIMESTAMPTZ` en UTC universal.

### 3.2. Configuración de Entorno y Contenedor
- **Archivo:** `backend/Dockerfile` (L4).
- **Evidencia:** `ENV TZ=America/Bogota`.
- **Comportamiento:** El proceso Node.js interpreta la fecha local como hora de Colombia (UTC-5).

### 3.3. Manejo de Fechas en el Motor de Reservas B2C
- **Archivo:** `backend/src/controllers/bookingController.js` (L116-121).
- **Código Factual:**
  ```javascript
  // 🇨🇴 Filtrar citas del mismo día considerando la zona horaria de Colombia (America/Bogota UTC-5)
  const baseDate = new Date(scheduled_at);
  // 05:00 UTC corresponde a 00:00:00 hora Colombia del mismo día
  const startOfDay = new Date(Date.UTC(baseDate.getUTCFullYear(), baseDate.getUTCMonth(), baseDate.getUTCDate(), 5, 0, 0, 0));
  // 04:59:59 UTC del día siguiente corresponde a 23:59:59 hora Colombia
  const endOfDay = new Date(Date.UTC(baseDate.getUTCFullYear(), baseDate.getUTCMonth(), baseDate.getUTCDate() + 1, 4, 59, 59, 999));
  ```
- **Hallazgo:** La ventana de citas del día aplica un desfase manual fijo de $+5\text{ horas UTC}$ para alinear el día calendario gregoriano con la medianoche de Colombia.

### 3.4. Esquema Físico de Horarios de Personal
- **Migración:** `069_staff_schedules.sql` (L17-18).
- **Definición:** `start_time TIME WITHOUT TIME ZONE NOT NULL`, `end_time TIME WITHOUT TIME ZONE NOT NULL`.
- **Significado:** Representa "hora de reloj de pared" (ej. 08:00:00 a 17:00:00) en el establecimiento, sin offset de zona horaria incrustado.

### 3.5. Esquema Físico de Establecimientos
- **Migración:** `065_saas_foundation_core.sql` (L42).
- **Definición:** `city VARCHAR(100) DEFAULT 'Bogotá'`, `operating_hours JSONB NOT NULL DEFAULT '{}'::jsonb`.
- **Hallazgo:** No existe columna `timezone VARCHAR` en la tabla `establishments` ni en `tenants`.

---

## 4. CURRENT SYSTEM BEHAVIOR (RESPUESTAS A LAS 9 PREGUNTAS CLAVE)

1. **¿Cómo opera la zona horaria del sistema actualmente?**  
   Opera de facto en `America/Bogota` (UTC-5 fijo, sin cambio de horario de verano / DST), con PostgreSQL almacenando en UTC.
2. **¿PostgreSQL opera en UTC?**  
   **SÍ.** La variable `TimeZone` es `'Etc/UTC'`.
3. **¿Los valores TIMESTAMPTZ se guardan en UTC?**  
   **SÍ.** `bookings.scheduled_at` se almacena como instante UTC absoluto.
4. **¿Cómo traducen las reservas existentes `scheduled_at` a fechas locales?**  
   El controlador B2C traslada el inicio del día local a las `05:00:00 UTC` del mismo día gregoriano.
5. **¿Cómo se interpreta `TIME WITHOUT TIME ZONE`?**  
   Como hora nominal de pared en la sede activa (ej. `08:00` significa las 8:00 AM del salón).
6. **¿Los establecimientos tienen atributo de zona horaria?**  
   **NO.** La tabla `establishments` carece de columna `timezone`.
7. **¿Pueden diferentes sedes operar hoy en diferentes zonas horarias?**  
   **NO actualmente.** Todo el backend asume operaciones en Colombia (`Bogotá / UTC-5`).
8. **¿Puede NODO-05 operar bajo el modelo actual sin nueva columna?**  
   **SÍ.** Aplicando la misma convención de `bookingController.js` (corte a `05:00 UTC`), NODO-05 opera de forma determinística con cero cambios de esquema.
9. **¿El comportamiento UTC-5 es un detalle, política o deuda técnica?**  
   Es una **convención de facto consistente** (Dockerfile, bookingController, Foundation default city), pero constituye una **informalidad arquitectónica** al no haber sido formalizada mediante un Decision Record explícito.

---

## 5. ARCHITECTURAL OPTIONS (OPCIONES EVALUADAS)

```text
+----------+-------------------------------------------------------------+-----------------------+
| Opción   | Denominación                                                | Mecanismo Técnico     |
+----------+-------------------------------------------------------------+-----------------------+
| OPCIÓN A | Platform Timezone Standard (America/Bogota UTC-5 de facto)  | Constante de servidor |
| OPCIÓN B | Establishment-Specific Timezone Attribute (Evolución DDL)   | Nueva columna en DB   |
| OPCIÓN C | Request-Supplied Timezone Parameter                         | Parámetro en request  |
+----------+-------------------------------------------------------------+-----------------------+
```

### Detalle de Opciones:

- **OPCIÓN A: Estándar de Plataforma `America/Bogota` (UTC-5) para v1.0 [RECOMENDADA]**  
  NODO-05 formaliza que la plataforma opera bajo la zona horaria `America/Bogota` (UTC-5, sin DST). El cálculo de límites de `target_date` convierte `YYYY-MM-DD` a `[YYYY-MM-DD 05:00:00Z, YYYY-MM-DD+1 04:59:59.999Z]`.
- **OPCIÓN B: Atributo Físico de Zona Horaria por Sede (`establishments.timezone`)**  
  Crear una migración física `071` para agregar `timezone VARCHAR(50) DEFAULT 'America/Bogota'` en `establishments`.
- **OPCIÓN C: Zona Horaria provista en el Request (`tz=America/Bogota`)**  
  Permitir que el cliente envíe la zona horaria deseada como parámetro de consulta.

---

## 6. OPTION IMPACT ANALYSIS (ANÁLISIS COMPARATIVO DE IMPACTO)

| Dimensión de Impacto | Opción A: Platform Standard (UTC-5) | Opción B: Atributo en Sede (DDL) | Opción C: Parámetro en Request |
| :--- | :--- | :--- | :--- |
| **`target_date` y `day_of_week`** | Inequívoco ($00:00\text{ COT} = 05:00\text{ UTC}$) | Inequívoco según sede | Variable según cliente |
| **`staff_schedules`** | Se alinea directamente a hora local | Se alinea a hora local | Requiere conversión |
| **`operating_hours`** | Se alinea directamente a hora local | Se alinea a hora local | Requiere conversión |
| **`public.bookings`** | 100% compatible con `bookingController.js` | Requiere refactor de B2C | Puede generar desalineación |
| **Impacto en DDL / Migraciones** | **CERO DDL (0 tablas / 0 columnas)** | Requiere migración DDL (071) | CERO DDL |
| **Afectación NODO-04 / Anteriores**| **CERO impacto** | Requiere actualizar 065/Hub | CERO impacto |
| **Soporte Multi-País Futuro** | Requiere evolución posterior | Nativo | Dependiente de frontend |

---

## 7. RISKS (MATRIZ DE RIESGOS)

1. **Riesgo de Desalineación con B2C (si se usa otra zona horaria distinta a UTC-5):**  
   Si NODO-05 utilizara UTC puro (`00:00 UTC`) para calcular el día, una cita a las `8:00 PM COT` (que es `01:00 AM UTC` del día siguiente) caería en un día calendario distinto, produciendo slots falsos o colisiones erróneas.  
   *Mitigación:* Usar estrictamente el corte a `05:00 UTC` (medianoche COT).
2. **Riesgo de Horario de Verano (DST):**  
   Colombia (`America/Bogota`) no aplica DST, por lo que el offset UTC-5 es constante los 365 días del año.

---

## 8. DIRECTOR RECOMMENDATION (RECOMENDACIÓN AL DIRECTOR)

Se recomienda al Director ratificar formalmente la **OPCIÓN A (Platform Timezone Standard: `America/Bogota` UTC-5)** para `NODO-05 v1.0`:

1. **Fidelidad al Ecosistema Existente:** Es 100% coherente con `bookingController.js` (L116) y `Dockerfile` (L4).
2. **Economía de Desarrollo:** Permite implementar NODO-05 con **CERO migraciones DDL** y sin modificar las tablas de Foundation (`065`).
3. **Determinismo Absoluto:** Al no existir DST en Colombia, el mapeo entre hora nominal (`HH:MM`) e instantáneas UTC es matemáticamente biyectivo y constante.
4. **Camino de Evolución Claro:** Si en el futuro GlowApp expande operaciones a México o España, la adición de `establishments.timezone` (Opción B) podrá abordarse como un nodo independiente de internacionalización sin romper NODO-05.

---

## 9. DECISION REQUIRED (DECISIÓN REQUERIDA DEL DIRECTOR)

Se eleva al Director la siguiente formulación para su pronunciamiento:

```text
================================================================================
                    DECISIÓN ELEVADA AL DIRECTOR GATE
================================================================================
  DECISION_ID: N05-DEC-01-TZ
  TÍTULO:      POLÍTICA DE ZONA HORARIA PARA PROYECCIÓN DE DISPONIBILIDAD
  
  PROPUESTA:
  Ratificar que NODO-05 opera bajo la zona horaria estándar de plataforma
  America/Bogota (UTC-5 constante), calculando los límites del target_date
  entre 05:00:00.000Z del día objetivo y 04:59:59.999Z del día siguiente,
  sin alterar el esquema físico de PostgreSQL ni requerir migraciones DDL.
================================================================================
```

---

## 10. IMPLEMENTATION STATUS

```text
================================================================================
                         DIRECTOR GATE STATUS
================================================================================
  TIMEZONE DECISION:
  OPEN / DIRECTOR DECISION REQUIRED 🟡

  ESTADO DE ARQUITECTURA FÍSICA:
  READY FOR DIRECTOR RATIFICATION (Pendiente resolución de N05-DEC-01-TZ)

  AUTORIZACIÓN DE IMPLEMENTACIÓN:
  NOT AUTHORIZED 🛑 (Discovery & Decision Analysis Only)
================================================================================
```
