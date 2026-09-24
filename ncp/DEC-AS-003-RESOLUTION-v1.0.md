# DEC-AS-003 — RESOLUCIÓN DE DECISIÓN ARQUITECTÓNICA v1.0 (RECONCILIADA R2)
## ACTO DE AUTORIZACIÓN DE MATERIALIZACIÓN SaaS → B2C

**DECISION ID**: `DEC-AS-003`  
**ESTADO ANTERIOR**: `ARCHITECTURAL STOP / OPEN`  
**ESTADO RECONCILIADO**: `PROPOSED — DIRECTOR CONFIRMATION REQUIRED 🟡`  
**FECHA DE RECONCILIACIÓN**: 2026-09-11  
**ROL**: Senior Architecture Auditor / Decision Analyst  
**AUTORIDAD**: Director del Proyecto GlowApp SaaS  
**CLASIFICACIÓN**: ANÁLISIS DE DECISIÓN FORMAL — PURAMENTE SEMÁNTICO (CERO CÓDIGO)  
**AUTORIZACIÓN DE IMPLEMENTACIÓN**: `NOT GRANTED 🛑`

---

## 1. PRINCIPIO DIRECTOR Y ALCANCE DE LA DECISIÓN

`DEC-AS-003` define **exclusivamente la semántica y la autoridad del acto de autorización de materialización SaaS → B2C**.

> **Principio Rector:**  
> La materialización de capacidades operativas desde SaaS hacia B2C requiere un **acto explícito de autorización** emitido por una identidad autenticada con autoridad **OWNER o MANAGER** dentro del **Active Context** correspondiente.

### Delimitación Estricta de Alcance:
- **QUÉ CIERRA ESTA DECISIÓN:**
  1. Quién posee la autoridad para autorizar la proyección hacia B2C.
  2. Qué acto semántico constituye dicha autorización (acto explícito de voluntad).
  3. Cuáles son las precondiciones mínimas del dominio SaaS requeridas.
  4. La prohibición absoluta de materialización automática o implícita derivada de estados internos SaaS.
- **QUÉ NO CIERRA ESTA DECISIÓN (Diferido a fases posteriores):**
  - No define endpoints, URLs, métodos HTTP ni DTOs.
  - No define interfaces de usuario (UI/UX) ni pantallas.
  - No define mecanismos técnicos de ejecución (workers, cron jobs, colas o eventos).
  - No define cómo se resuelve o aprovisiona físicamente `perfiles_prestador` o `provider_id`.
  - No define persistencia física ni políticas de sincronización o rollback.

---

## 2. SEPARACIÓN RIGUROSA DE TRES CONCEPTOS

Para garantizar la pureza arquitectónica y evitar el acoplamiento conceptual entre dominios, se establece la distinción formal e irreductible entre:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       TRES DIMENSIONES DISTINTAS                            │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. ASSIGNMENT (Estado Durable en SaaS)                                      │
│    • Vinculación operativa formal: SERVICE_OFFER ↔ ACTIVE PROFESSIONAL.     │
│    • Confinado 100% al dominio SaaS (service_assignments).                  │
│    • ASSIGNMENT NO MATERIALIZA FÍSICAMENTE NI AUTORIZA PROYECCIÓN.          │
│                                                                             │
│ 2. MATERIALIZATION AUTHORIZATION (Acto Semántico de Autoridad)              │
│    • Expresión explícita y deliberada de voluntad emitida por un actor      │
│      con rol OWNER o MANAGER en Active Context.                             │
│    • Autoriza que un par (Oferta, Profesional) sea elegible para B2C.       │
│    • LA AUTORIZACIÓN NO CONSTITUYE POR SÍ MISMA LA PERSISTENCIA FÍSICA.     │
│                                                                             │
│ 3. B2C MATERIALIZATION (Ejecución Técnica Downstream)                       │
│    • Transformación y persistencia posterior en el esquema B2C.             │
│    • Responsabilidad técnica de un adaptador desacoplado downstream.        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. PROHIBICIÓN EXPRESA DE AUTOMATISMO

Se clausura cualquier posibilidad de inferencia automática o materialización implícita:

```text
================================================================================
                    INEXISTENCIA DE MATERIALIZACIÓN AUTOMÁTICA
================================================================================
Ninguno de los siguientes eventos o estados internos de SaaS constituye,
por sí mismo, autorización ni causa de materialización física en B2C:

  ❌ Creación de un SERVICE_OFFER.
  ❌ Actualización comercial de un SERVICE_OFFER.
  ❌ Creación de un ASSIGNMENT (service_assignments).
  ❌ Modificación de un ASSIGNMENT.
  ❌ Eliminación de un ASSIGNMENT (Desasignación).
  ❌ Creación o actualización de un STAFF_SCHEDULE (staff_schedules).
  ❌ Creación o activación de una MEMBERSHIP (memberships).

La materialización jamás ocurrirá como efecto secundario implícito de la
operación interna de un salón.
================================================================================
```

---

## 4. CONDICIONES Y MATRIZ DE AUTORIDAD EVALUADA

Para que un acto de autorización de materialización sea semánticamente válido, deben cumplirse rigurosamente las siguientes precondiciones en el dominio SaaS:

| # | Precondición SaaS | Calificación | Justificación Arquitectónica |
|---|---|---|---|
| **1** | **Identidad Autenticada** | **OBLIGATORIA** | Toda acción en GlowApp requiere un usuario autenticado (`req.user.id`). |
| **2** | **Active Context Válido** | **OBLIGATORIA** | El actor debe operar bajo un contexto activo resuelto (`tenant_id`, `establishment_id`). |
| **3** | **Autoridad OWNER / MANAGER** | **OBLIGATORIA** | La decisión de proyectar capacidades comerciales hacia el exterior corresponde privativamente a la dirección del establecimiento (`DEC-AS-001`). |
| **4** | **Service Offer Válido** | **OBLIGATORIA** | La oferta debe existir, pertenecer al establecimiento activo y tener parámetros válidos (`duration > 0`, `price >= 0`). |
| **5** | **Assignment Válido** | **OBLIGATORIA** | La oferta debe estar formalmente asignada al colaborador dentro del establecimiento activo (`service_assignments`). |
| **6** | **Membership ACTIVE PROFESSIONAL** | **OBLIGATORIA** | El colaborador asignado debe poseer una membresía con `role = 'PROFESSIONAL'` y `status = 'ACTIVE'`. |

---

## 5. EVIDENCIA CONOCIDA DEL MODELO PROVIDER EN B2C

Se registra exclusivamente la evidencia física existente en la base de datos PostgreSQL:

1. **Restricción Física en `public.services`:**
   ```sql
   FOREIGN KEY (provider_id) REFERENCES perfiles_prestador(id) ON DELETE CASCADE
   ```
2. **Restricción Física en `public.perfiles_prestador`:**
   ```sql
   FOREIGN KEY (id) REFERENCES usuarios(id) ON DELETE CASCADE
   ```

### Delimitación de Incertidumbre y No Anticipación:
`DEC-AS-003` reconoce esta restricción física existente, pero **NO decide ni anticipa**:
- Cómo se obtendrá o asignará `provider_id`.
- Si `memberships` tendrá una relación física con `perfiles_prestador`.
- Si se creará un perfil de prestador, si se reutilizará uno existente, o si se requerirá un paso previo.
- Cómo se resolverá la identidad B2C del colaborador.

Dichas decisiones pertenecen al diseño del adaptador downstream y no condicionan la semántica de la autorización.

---

## 6. EVALUACIÓN CONCEPTUAL DE ALTERNATIVAS

```text
================================================================================
                    EVALUACIÓN DE ALTERNATIVAS SEMÁNTICAS
================================================================================
```

### OPCIÓN A — ACTO EXPLÍCITO DEL OPERADOR (Recomendada)
- **Semántica:** La materialización requiere un acto deliberado y explícito emitido por un `OWNER` o `MANAGER`.
- **Autoridad:** 100% administrativa y controlada por el establecimiento.
- **Trazabilidad:** Totalmente auditable.
- **Determinismo:** Absoluto (cero mutaciones imprevistas en B2C).
- **Alineación:** Conforme 100% con `DEC-SE-001`, `DEC-AS-001..014`, `DEC-PUB-001`.

### OPCIÓN B — AUTOMATISMO DERIVADO DE ASIGNACIÓN (Rechazada)
- **Semántica:** La asignación en SaaS dispara automáticamente la materialización en B2C.
- **Motivo de Rechazo:** Viola `DEC-SE-001` (instanciación tardía), genera acoplamiento indeseado, provoca escrituras en caliente de borradores y asume automatismos no demostrados.

### OPCIÓN C — MATERIALIZACIÓN LIGADA AL ONBOARDING (Insuficiente)
- **Semántica:** La materialización ocurre únicamente como paso final del onboarding inicial.
- **Motivo de Rechazo:** Insuficiente para la vida útil del sistema; no resuelve la creación o reasignación continua de servicios en el día a día.

---

## 7. TEXTO NORMATIVO DE LA DECISIÓN DEC-AS-003

Se somete a confirmación del Director la siguiente resolución normativa:

```text
================================================================================
                    RESOLUCIÓN FORMAL PROPUESTA: DEC-AS-003
================================================================================

DEC-AS-003: LA MATERIALIZACIÓN SaaS → B2C REQUIERE UN ACTO EXPLÍCITO DE AUTORIZACIÓN.

1. AUTORIDAD Y ACTO AUTORIZADOR:
   La proyección o materialización de una oferta de servicio asignada
   (SERVICE_OFFER + ASSIGNMENT) desde el dominio SaaS hacia el esquema
   transaccional B2C requiere un ACTO EXPLÍCITO DE AUTORIZACIÓN emitido por
   una identidad autenticada con rol OWNER o MANAGER dentro de su Active Context.

2. INMUTABILIDAD DE DOMINIOS Y NO AUTOMATISMO:
   La existencia, creación, actualización o desasignación de un ASSIGNMENT
   es un estado durable exclusivo de SaaS y NO autoriza ni ejecuta por sí misma
   ninguna materialización física en B2C.

3. PRECONDICIONES NORMATIVAS EN SAAS:
   Para que la autorización sea válida se requiere:
   - Identidad autenticada en Active Context.
   - Rol OWNER o MANAGER en el establecimiento activo.
   - SERVICE_OFFER válido del establecimiento activo.
   - ASSIGNMENT válido hacia un MEMBERSHIP con rol PROFESSIONAL y status ACTIVE.

4. DELIMITACIÓN DE EJECUCIÓN DOWNSTREAM:
   El acto de autorización define exclusivamente la validez semántica de la
   voluntad de proyección. Los mecanismos de persistencia física, resolución
   de provider_id, aprovisionamiento de perfiles y endpoints quedan
   delimitados al diseño del adaptador downstream correspondiente.
================================================================================
```

---

## 8. CONSECUENCIAS ARQUITECTÓNICAS

1. **Soberanía y Desacoplamiento SaaS:** Los establecimientos pueden configurar su catálogo, asignar personal y definir turnos libremente sin impactar el marketplace B2C hasta emitir una autorización explícita.
2. **Cero Supuestos Físicos:** No se crean tablas, columnas ni dependencias artificiales entre `memberships` y `perfiles_prestador` en esta decisión.
3. **Desbloqueo de NODO-04:** Queda claramente delimitado el mandato conceptual para que el futuro `NODO-04` diseñe exclusivamente el adaptador técnico downstream.

---

## 9. CONFIRMACIÓN DE CERO MUTACIÓN Y ESTADO FINAL

```text
================================================================================
AUTOPERITAJE DE GOBERNANZA:
- Código de producto modificado:     0 líneas
- Archivos de backend tocados:       0 archivos
- Base de datos / DDL modificado:    0 tablas
- Migraciones creadas / ejecutadas:  0 migraciones
- Contratos cerrados modificados:    0 contratos
- Foundation alterada:               0 alteraciones
- Endpoint / UI / Worker diseñado:   0 (Ninguno)

ESTADO FORMAL:
DEC-AS-003: PROPOSED — DIRECTOR CONFIRMATION REQUIRED 🟡

AUTORIZACIÓN DE IMPLEMENTACIÓN:
NOT GRANTED 🛑
================================================================================
```
