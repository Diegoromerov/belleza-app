# NODO-05 — SEMANTIC DECISION BUNDLE v1.0
## Availability Projection & Booking Slot Engine — Formal Architectural Decision Record

**DOCUMENT IDENTIFIER:** `NODO-05-SEMANTIC-DECISION-BUNDLE-v1.0`  
**STATUS:** `DECISION BUNDLE READY FOR DIRECTOR APPROVAL 🟡`  
**DATE:** 2026-09-11  
**ROLE:** Senior Architectural Governance Agent  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GOAL — NODO-05 SEMANTIC DECISION BUNDLE v1.0`  
**CLASSIFICATION:** READ-ONLY ARCHITECTURAL DECISION BUNDLE — ZERO IMPLEMENTATION  
**METHODOLOGY:** DEFINIR → RELACIONAR → INTEGRAR → VALIDAR → CERRAR → AVANZAR  
**IMPLEMENTATION AUTHORIZATION:** NOT GRANTED 🛑 (Decision Bundle Only — Requires Director Approval)

---

## 1. EXECUTIVE SUMMARY

El presente **Semantic Decision Bundle** resuelve y formaliza las 9 decisiones arquitectónicas y semánticas requeridas para convertir la definición conceptual de **`NODO-05` (Availability Projection & Booking Slot Engine)** en un contrato de implementación ejecutable (`Implementation Contract`).

### Principios Rectores Ratificados:
1. **Naturaleza Funcional Pura:** `NODO-05` es un **motor de proyección determinístico de solo lectura en memoria**. No persiste slots, no crea tablas, no ejecuta DDL y no genera efectos secundarios en la base de datos.
2. **Preservación Estricta de Fronteras:** `NODO-05` no crea reservas (`bookings`), no administra agendas de citas (`appointments`), no publica servicios y no activa servicios en B2C.
3. **Desacoplamiento de Identidad y Disponibilidad:** La disponibilidad proyectada es efímera y calculada *on-demand*. Un `Slot` es una ventana de oportunidad matemática $[t_{\text{start}}, t_{\text{end}}]$, no un registro físico ni una promesa transaccional bloqueada.
4. **Viabilidad de Lectura de Ocupación:** La consulta de intervalos ocupados contra `public.bookings` (Pre-Nodo 01) es semánticamente consistente y opera de forma estrictamente de solo lectura (`SELECT`).

---

## 2. DECISION INVENTORY (INVENTARIO DE DECISIONES)

```text
+------------+------------------------------------------+------------------------------------+--------------------------------+
| Código     | Título de la Decisión                    | Estado de Decisión                 | Impacto Arquitectónico         |
+------------+------------------------------------------+------------------------------------+--------------------------------+
| N05-DEC-01 | Temporal Granularity & Step Increment    | OPEN — RECOMENDACIÓN FORMULADA 🟡  | Generación de candidate starts |
| N05-DEC-02 | Establishment Hours Intersection Policy  | OPEN — RECOMENDACIÓN FORMULADA 🟡  | Truncamiento vs Warning Flag   |
| N05-DEC-03 | Booking Occupancy Read Semantics         | APPROVED 🟢                        | Lectura de busy intervals      |
| N05-DEC-04 | Semantic Definition of Slot              | APPROVED 🟢                        | Intervalo continuo sin estado  |
| N05-DEC-05 | Multi-Professional Projection Semantics  | APPROVED 🟢                        | Targeted vs Aggregated Queries |
| N05-DEC-06 | Zero Assignments Semantic Result         | APPROVED 🟢                        | Retorno determinístico vacío   |
| N05-DEC-07 | Zero Persistence & Transient Runtime     | APPROVED 🟢                        | Cero DDL / Cero tablas         |
| N05-DEC-08 | Booking Write Boundary Preservation      | APPROVED 🟢                        | Cero mutación en bookings      |
| N05-DEC-09 | Publication & Activation Non-Equivalence | APPROVED 🟢                        | Invariante DEC-PUB-001         |
+------------+------------------------------------------+------------------------------------+--------------------------------+
```

---

## 3. N05-DEC-01 — TEMPORAL GRANULARITY (GRANULARIDAD TEMPORAL)

### 3.1. Pregunta Arquitectónica
¿Cómo se determinan los momentos de inicio candidatos ($t_{\text{start}}$) para la generación de slots dentro de un intervalo disponible?

### 3.2. Evidencia y Hechos Demostrados
- **`067_service_offers.sql` (L17):** Define `base_duration INTEGER NOT NULL CHECK (base_duration > 0)`. La duración del servicio es exacta en minutos (ej. 30, 45, 60, 90).
- **`069_staff_schedules.sql` (L17-18):** Define `start_time TIME`, `end_time TIME`. Las ventanas de jornada son continuas.
- **`bookingController.js` (L112-148):** El motor B2C evalúa colisiones en tiempo continuo ($t_{\text{start}} < b_{\text{end}} \land t_{\text{end}} > b_{\text{start}}$).
- **Hecho:** Ningún contrato o migración cerrada impone una cuadrícula fija (ej. "obligatoriamente cada 15 min" o "obligatoriamente cada 30 min").

### 3.3. Opciones Evaluadas
- **Opción A (Paso Fijo Harcodeado):** Fijar `step_minutes = 15` o `30` en el código.
- **Opción B (Derivado de Duración / Back-to-Back):** El paso es igual a `base_duration` ($t_{n+1} = t_n + \text{duration}$).
- **Opción C (Parámetro Configurable con Default Seguro):** `NODO-05` acepta `step_minutes` como parámetro opcional en el request (ej. 15, 30, 60 min), adoptando **15 minutos como valor por defecto estándar**.

### 3.4. Recomendación y Estado
- **Recomendación:** **Opción C**. Permite flexibilidad para interfaces que deseen cuadrículas de 15 o 30 minutos sin acoplar rígidamente el backend a un único tamaño de paso.
- **ESTADO:** `OPEN — PENDING DIRECTOR RATIFICATION 🟡`

---

## 4. N05-DEC-02 — ESTABLISHMENT HOURS INTERSECTION (POLÍTICA DE INTERSECCIÓN CON SEDE)

### 4.1. Pregunta Arquitectónica
¿Cómo se comporta NODO-05 cuando el horario declarado de un colaborador (`staff_schedules`) se extiende fuera del horario comercial general del establecimiento (`establishments.operating_hours`)?

### 4.2. Evidencia y Hechos Demostrados
- **`065_saas_foundation_core.sql`:** `establishments.operating_hours JSONB` almacena la jornada de la sede.
- **`NODO-03A-NODE-CONTRACT-v1.0.md` (Cláusula 5.7 & 6.4):** Sancionó formalmente que un horario de personal fuera del horario de sede produce únicamente una **advertencia no bloqueante (`out_of_operating_hours_warning`)**, permitiendo la persistencia del horario.
- **Hecho:** La regla de NODO-03A prohíbe el truncamiento físico destructivo en la declaración de horarios.

### 4.3. Opciones Evaluadas
- **Opción A (Intersección Estricta — Truncamiento en Proyección):**
  $$\text{Ventana Proyectable} = \text{StaffSchedule}(D) \cap \text{EstablishmentHours}(D)$$
  Los slots solo se generan donde ambas condiciones son verdaderas. No se generan slots fuera del horario comercial de la sede.
- **Opción B (Prevalencia de Staff con Metadata Informativa):**
  Se generan slots en toda la jornada del staff, pero aquellos que caen fuera de los horarios de sede se marcan con `out_of_operating_hours: true`.
- **Opción C (Ignorar Horarios de Sede en Cálculo):**
  La proyección solo lee `staff_schedules`.

### 4.4. Recomendación y Estado
- **Recomendación:** **Opción A (Intersección Estricta por Defecto)** para el agendamiento estándar de clientes, ya que un salón comercial cerrado físicamente no puede admitir citas de clientes. Sin embargo, para no violentar NODO-03A, esta es una decisión que debe sancionar el Director.
- **ESTADO:** `OPEN — PENDING DIRECTOR RATIFICATION 🟡`

---

## 5. N05-DEC-03 — BOOKING OCCUPANCY SEMANTICS (SEMÁNTICA DE LECTURA DE OCUPACIÓN)

### 5.1. Pregunta Arquitectónica
¿Provee el esquema y runtime existente de `public.bookings` (Pre-Nodo 01) la información fáctica suficiente para que NODO-05 sustraiga intervalos ocupados de forma determinística y segura?

### 5.2. Evidencia Forense de `public.bookings`
1. **Inicio de Cita:** `scheduled_at TIMESTAMPTZ NOT NULL`.
2. **Duración / Fin de Cita:** `bookings` no tiene columna `duration_minutes`. La duración se obtiene resolviendo `service_id` contra `public.services.duration_minutes` (o `saas_service_materializations` $\to$ `service_offers.base_duration`).
3. **Identidad del Prestador:** `provider_id INTEGER NOT NULL`. Corresponde unívocamente a `usuarios.id ≡ memberships.user_id` (Invariante Provider Resolution ratificado en NODO-04).
4. **Aislamiento Multi-Tenant:** `bookings.tenant_id INTEGER` está presente en el esquema.
5. **Estado y Cancelación:** `estado` (enum). Citas canceladas poseen `estado = 'CANCELADA'`. Citas activas poseen `estado != 'CANCELADA'`.
6. **Cálculo de Intervalo Ocupado:**
   $$[b_{\text{start}}, b_{\text{end}}] = [\text{scheduled\_at}, \text{scheduled\_at} + \text{service.duration\_minutes}]$$

### 5.3. Dictamen de Compatibilidad
- `public.bookings` contiene **toda la información necesaria** para calcular colisiones temporales de un colaborador en una fecha dada.
- La consulta de ocupación es una operación `SELECT` pura, filtrada por `provider_id = membership.user_id` y fecha en zona horaria local.
- **ESTADO:** `APPROVED 🟢`

---

## 6. N05-DEC-04 — SLOT SEMANTICS (DEFINICIÓN CANÓNICA DE SLOT)

### 6.1. Definición Formal Ratificada
En el ecosistema GlowApp SaaS, un **`Slot` (Franja de Agendamiento)** queda definido axiomáticamente como:

$$\mathbf{SLOT} = \Big\langle t_{\text{start}}, \ t_{\text{end}}, \ \text{service\_offer\_id}, \ \text{available\_memberships} \Big\rangle$$

Donde se cumplen obligatoriamente las siguientes 5 condiciones:
1. **Longitud Exacta:** $t_{\text{end}} - t_{\text{start}} = \text{service\_offers.base\_duration}$.
2. **Alineación Temporal:** $t_{\text{start}}$ es múltiplo del `step_minutes` dentro del bloque disponible.
3. **Inclusión en Jornada:** $[t_{\text{start}}, t_{\text{end}}] \subseteq \text{StaffSchedule}(\text{membership}, \text{target\_date})$.
4. **Ausencia de Ocupación:** $[t_{\text{start}}, t_{\text{end}}] \cap \bigcup [b_{\text{start}}, b_{\text{end}}] = \emptyset$ para las membresías reportadas como disponibles.
5. **Inexistencia de Estado:** Un slot no posee ID en base de datos, no tiene ciclo de vida, no se almacena y no reserva exclusividad transaccional.

- **ESTADO:** `APPROVED 🟢`

---

## 7. N05-DEC-05 — MULTI-PROFESSIONAL PROJECTION SEMANTICS (PROYECCIÓN MULTI-COLABORADOR)

### 7.1. Pregunta Arquitectónica
Dado que una oferta de servicio puede tener múltiples profesionales asignados en `service_assignments`, ¿cómo debe responder la proyección?

### 7.2. Reglas Semánticas Aprobadas
1. **Modo Específico (Targeted Request):**
   - Invocación: `GET /availability?service_offer_id=X&membership_id=Y&target_date=Z`.
   - Proyecta los slots de la membresía $Y$.
   - Si la membresía $Y$ no está asignada al servicio $X$: Retorna error `422 UNASSIGNED_PROFESSIONAL`.
2. **Modo Agregado de Sede (Aggregated Request):**
   - Invocación: `GET /availability?service_offer_id=X&target_date=Z` (sin `membership_id`).
   - El motor evalúa a **todos los colaboradores activos asignados** en `service_assignments`.
   - Fusiona (*union*) los slots de inicio disponibles.
   - En cada slot resultante, incluye la lista `available_memberships: [UUID_1, UUID_2, ...]`.
3. **Prohibición de Lógica de Selección:**
   - `NODO-05` **NUNCA selecciona un profesional por el usuario**.
   - Cero algoritmos de "mejor estilista", "menor carga" o "prioridad". La selección corresponde al cliente final o al recepcionista en capas downstream.

- **ESTADO:** `APPROVED 🟢`

---

## 8. N05-DEC-06 — ZERO ASSIGNMENTS SEMANTIC RESULT (CERO ASIGNACIONES)

### 8.1. Pregunta Arquitectónica
¿Qué retorna NODO-05 cuando una oferta de servicio válida no tiene ningún colaborador asignado en `service_assignments`?

### 8.2. Regla Aprobada
- Si `service_assignments` no contiene filas para `(establishment_id, service_offer_id)`:
  - `NODO-05` retorna un conjunto de slots vacío: `slots: []`.
  - Atributo de metadata: `availability_state: "NO_STAFF_ASSIGNED"`.
  - Código HTTP: `200 OK`.
- **Justificación:** Cero asignaciones es un estado comercial válido (servicio temporalmente sin personal capacitado), no un error de infraestructura del servidor.

- **ESTADO:** `APPROVED 🟢`

---

## 9. N05-DEC-07 — ZERO PERSISTENCE & TRANSIENT RUNTIME (CERO PERSISTENCIA)

### 9.1. Decisión Formal de Arquitectura
1. **`NODO-05` es 100% transitorio y computado en memoria (*On-Demand Calculation Engine*).**
2. **Cero Tablas Nuevas:** No se crea tabla `slots`, `availability_slots` ni `availability_cache`.
3. **Cero Migraciones SQL:** No se requiere migración DDL para `NODO-05`.
4. **Caching Diferido:** Cualquier optimización de caché (Redis / en memoria) queda fuera de alcance de v1.0 y supeditada a necesidades de telemetría futuras.

- **ESTADO:** `APPROVED 🟢`

---

## 10. N05-DEC-08 — BOOKING WRITE BOUNDARY (FRONTERA DE ESCRITURA EN RESERVAS)

### 10.1. Aislamiento Transaccional Estricto
1. `NODO-05` tiene **PROHIBICIÓN ABSOLUTA de escribir o mutar** filas en `public.bookings`, `public.services`, `saas_service_materializations` o `staff_schedules`.
2. La relación de NODO-05 con las reservas es **unidireccional y de solo lectura (`READ-ONLY INGESTION`)**:
   $$\text{NODO-05} \xrightarrow{\text{SELECT / READ}} \text{public.bookings}$$
   $$\text{NODO-05} \xleftrightarrow{\text{WRITE / MUTATION}} \text{ZERO}$$

- **ESTADO:** `APPROVED 🟢`

---

## 11. N05-DEC-09 — PUBLICATION / ACTIVATION BOUNDARY (PRESERVACIÓN DE INVARIANTES)

### 11.1. No Equivalencia de Dominios
En estricta observancia de `DEC-PUB-001`, `DEC-AS-003` y `DEC-AS-014`:

$$\text{DISPONIBILIDAD PROYECTADA} \neq \text{PUBLICACIÓN B2C} \neq \text{ACTIVACIÓN B2C}$$

1. Que un servicio genere slots disponibles en NODO-05 **NO significa** que el servicio esté publicado en el marketplace B2C.
2. Que un servicio esté materializado en `public.services` **NO significa** que tenga disponibilidad si no hay staff asignado con horario.
3. `NODO-05` no modifica flags `is_active` ni estados de visibilidad.

- **ESTADO:** `APPROVED 🟢`

---

## 12. CONSISTENCY CHECK (CHEQUEO DE CONSISTENCIA Y COMPATIBILIDAD)

| Invariante Protegido | Estado de Consistencia en NODO-05 |
| :--- | :--- |
| **Aislamiento Multi-Tenant (065, 066)** | Garantizado. Toda consulta filtra por `tenant_id` y `establishment_id` inyectados en contexto. |
| **Catálogo Inmutable SaaS (067)** | Garantizado. `service_offers.base_duration` se consume como lectura inmutable. |
| **Matriz de Asignación M:N (068)** | Garantizado. Solo colaborares en `service_assignments` son proyectados. |
| **Disponibilidad Declarativa (069)** | Garantizado. Se respetan los bloques $1..7$ de `staff_schedules` sin mutarlos. |
| **Materialización B2C (070)** | Garantizado. `saas_service_materializations` se mantiene desacoplado; la proyección opera sobre entidades SaaS y lee reservas por `provider_id`. |
| **Regresión 123/123 PASS** | Inmune. Cero cambios en código o base de datos existente. |

---

## 13. OPEN DECISIONS (DECISIONES ABIERTAS PARA EL DIRECTOR GATE)

Quedan formalmente elevadas al Director las siguientes **2 decisiones de política**:

```text
================================================================================
                    DECISIONES ABIERTAS PARA EL DIRECTOR
================================================================================

1. [N05-DEC-01] GRANULARIDAD TEMPORAL (STEP INCREMENT):
   • Opción Recomendada: Parámetro opcional en request con valor por defecto de 15 min.
   • Alternativas: Fijo 15 min | Fijo 30 min | Contiguo (igual a duración).

2. [N05-DEC-02] INTERSECCIÓN CON HORARIOS DE SEDE:
   • Opción Recomendada: Intersección Estricta (Staff ∩ Sede) por defecto.
   • Alternativas: Staff Prevalente con flag out_of_operating_hours.
================================================================================
```

---

## 14. ARCHITECTURAL STOPS EVALUATION (CONDICIONES DE PARADA)

Se evaluaron todas las condiciones de parada obligatorias:
1. *¿Las semánticas de reservas son ambiguas o incompatibles?* $\to$ **NO.** `public.bookings` provee `scheduled_at`, `duration` vía `service`, y `provider_id` coincidente con `memberships.user_id`.
2. *¿Existe ambigüedad en la identidad prestador/miembro?* $\to$ **NO.** Ratificada en N04 Director Gate: `memberships.user_id ≡ usuarios.id ≡ perfiles_prestador.id`.
3. *¿Se requiere una nueva entidad física?* $\to$ **NO.** Motor 100% en memoria.
4. *¿Se requiere modificar código o arquitectura aprobada?* $\to$ **NO.**

**Resultado:** **CERO BLOQUEADORES. NO APLICA ARCHITECTURAL STOP.**

---

## 15. DIRECTOR GATE

```text
================================================================================
                         DIRECTOR GATE STATUS
================================================================================
  ESTADO DEL BUNDLE:
  DECISION BUNDLE READY FOR DIRECTOR APPROVAL 🟡

  DICTAMEN:
  1. Las 9 decisiones semánticas de NODO-05 han sido analizadas y estructuradas.
  2. 7 decisiones quedan APROBADAS en el bundle (DEC-03 a DEC-09).
  3. 2 decisiones de política quedan ABIERTAS para ratificación del Director (DEC-01, DEC-02).
  4. No existe impedimento técnico para proceder a la emisión del Node Contract.

  AUTORIZACIÓN DE IMPLEMENTACIÓN:
  NOT GRANTED 🛑 (Esperando resolución del Director Gate)
================================================================================
```
