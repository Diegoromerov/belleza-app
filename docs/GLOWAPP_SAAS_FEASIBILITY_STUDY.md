# DICTAMEN ARQUITECTÓNICO: VIABILIDAD Y PLAN DE EJECUCIÓN GLOWAPP SAAS
## Capacidades Avanzadas de Benchmark Internacional (Zenoti / Koibox / Fresha / Boulevard)

**Destinatario:** Capa de Arbitraje y Planificación Técnica  
**Autor:** Antigravity (Arquitecto de Software Senior)  
**Fecha de Emisión:** 2026-09-08  
**Estado:** Documento de Diseño y Viabilidad Previa (Sin código de implementación)

---

## 1. RESUMEN EJECUTIVO Y CONTEXTO

GlowApp opera como plataforma B2B/multi-tenant (Flutter, Node.js/Express, PostgreSQL con PostGIS en Railway) con componentes de misión crítica en producción:
- Entidad `salones` (Tenants) con geolocalización PostGIS (`Point EPSG:4326`, índice espacial `GIST`).
- Staff y roles operativos en `salon_miembros` (`ADMINISTRADOR`, `PRESTADOR_INDEPENDIENTE`, `EMPLEADO`, `RECEPCIONISTA`).
- Motor de capacidades desacoplado (`saasEntitlements.js`) con flags atómicos (`MAP_VISIBILITY`, `ONLINE_BOOKING`, `TEAM_MANAGEMENT`, `ADVANCED_ANALYTICS`, `CUSTOM_BRANDING`).
- Ciclo de vida empresarial y compliance en `business_profiles` (`compliance_score`, `lifecycle_stage`, generador documental legal SHA-256).
- Patrón de concurrencia y bloqueo atómico anti-overselling validado en `productos` (`FOR UPDATE` condicional).
- Roadmap activo: Fase 0 cerrada, `productService` (T-101), `consentService` (T-103 con deuda conocida de mismatch `UUID` vs `INTEGER`), y migración incremental de Citas a PG crudo (Decisión **D-01**).

Este dictamen evalúa la viabilidad técnica, riesgos de concurrencia, dependencias, complejidad, secuencia y posibles conflictos de **cuatro capacidades avanzadas**.

---

## 2. AUDITORÍA DETALLADA POR CAPACIDAD

### CAPACIDAD 1: Recurso Reservable Doble (Staff + Cabina/Silla/Equipo Concurrente)

#### 1.1 Viabilidad Técnica sobre la Base Actual
- **Compatibilidad con Schema:** Parcialmente compatible. La tabla actual de reservas asume una tupla `(prestador_id, slot_temporal, salon_id)`. No modela recursos físicos como entidades reservables independientes (ej. sillón de lavado, cabina estética, máquina láser).
- **Componentes a Reutilizar:** 
  - Transacciones atómicas en PG crudo (`pool.connect()`, `BEGIN ... COMMIT`) bajo la decisión **D-01**.
  - Catálogo de servicios para mapear tiempos de ocupación.
  - Roles de `salon_miembros` para resolver al profesional humano.
- **Componentes Nuevos Requeridos:**
  - Tabla `salon_recursos` (`id UUID/INT`, `salon_id INT REFERENCES salones(id)`, `nombre VARCHAR`, `tipo_recurso VARCHAR` ['SILLA', 'CABINA', 'EQUIPO'], `activo BOOLEAN`).
  - Tabla puente `servicio_recursos_requeridos` (ej. 1 Estilista + 1 Silla de Corte + 1 Lavacabezas por 15 min).
  - Tabla de asignación `cita_recursos_ocupacion` con rangos de tiempo `tstzrange`.

#### 1.2 Riesgos de Concurrencia y de Datos
- **Riesgo de Overselling de Aparatología:** Si dos clientes agendan a las 10:00 AM con dos estilistas distintos para un tratamiento que requiere la *única Cabina Láser* del salón, una validación simple a nivel de staff permite ambas citas, provocando una colisión física en el local.
- **Mitigación Arquitectónica (Constraint Nativo `btree_gist`):**
  - Instalar extensión `btree_gist` en PostgreSQL.
  - Implementar constraint de exclusión temporal:
    ```sql
    ALTER TABLE cita_recursos_ocupacion 
      ADD CONSTRAINT no_solapamiento_recurso 
      EXCLUDE USING gist (recurso_id WITH =, rango_horario WITH &&);
    ```
  - Bloqueo simultáneo en la transacción ordenando los identificadores por clave primaria (`SELECT ... FOR UPDATE`) para evitar **Deadlocks**.

#### 1.3 Dependencias y Orden respecto al Roadmap
- **Dependencia Crítica:** Es una extensión directa y profunda de **D-01** (Migración de Citas a PG crudo).
- **Orden:** **Estrictamente posterior a T-101 y a la consolidación de D-01**. No debe anticiparse porque añade complejidad combinatoria al cálculo de disponibilidad (`freeSlots = staffSlots ∩ resourceSlots`).

#### 1.4 Estimación de Complejidad
- **Complejidad:** **ALTA**.
- **Impacto / Esfuerzo:** Impacto estratégico muy alto (ventaja competitiva frente a Fresha/Koibox), pero esfuerzo sustancial en backend (algoritmo de slots compuestos) y en UI Flutter (vista de agenda por columnas de recursos).

#### 1.5 Plan de Ejecución Propuesto
- **`T-301-A`**: DDL de `salon_recursos`, `servicio_recursos` y constraint `btree_gist` sobre `tstzrange` en PG crudo.
- **`T-301-B`**: Algoritmo de intersección de disponibilidad multi-recurso.
- **`T-301-C`**: Transacción de reserva compuesta con captura de excepción `23P01` (`exclusion_violation`).
- **`T-301-D`**: Adaptación visual en Flutter (`SalonDashboardScreen`).

#### 1.6 Contradicciones con Decisiones Previas
- **D-01:** No hay contradicción; confirma la necesidad de PG crudo y descarta definitivamente Sequelize para esta capa transaccional.

> **VEREDICTO:** **REQUIERE DECISIÓN ARQUITECTÓNICA PREVIA** (Consolidación de D-01 antes de abordar recursos compuestos).

---

### CAPACIDAD 2: Ledger de Bonos de Sesiones (Append-Only Transaccional)

#### 2.1 Viabilidad Técnica sobre la Base Actual
- **Compatibilidad con Schema:** Alta compatibilidad conceptual. Requiere schema nuevo sin alterar los flujos actuales de cobro directo en marketplace.
- **Componentes a Reutilizar:**
  - Patrón de concurrencia y validación atómica ya probado en `productos` (`FOR UPDATE`).
  - Pasarela Wompi para la compra del bono matriz.
  - Aislamiento multi-tenant garantizado por `salones(id)`.
- **Componentes Nuevos Requeridos:**
  - Tabla `bonos_cliente` (contrato matriz: `id UUID`, `salon_id INT`, `cliente_id`, `servicio_id INT`, `total_sesiones INT`, `vencimiento TIMESTAMPTZ`, `estado VARCHAR`).
  - Tabla inmutable `bonos_ledger_movimientos`:
    - `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
    - `bono_id UUID REFERENCES bonos_cliente(id)`
    - `cita_id INT/UUID NULL REFERENCES citas(id)`
    - `tipo_movimiento VARCHAR(30)` (`COMPRA_INICIAL`, `CONSUMO_CITA`, `REVERSION_CANCELACION`, `AJUSTE_ADMINISTRATIVO`, `REEMBOLSO`)
    - `delta_sesiones INT NOT NULL` (+5, -1, +1, -1...)
    - `saldo_resultante INT NOT NULL`
    - `idempotency_key VARCHAR(100) UNIQUE`
    - `creado_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`
  - Servicio `bonoLedgerService.js` en PG crudo.

#### 2.2 Riesgos de Concurrencia y de Datos
- **Riesgo de Doble Consumo / Saldo Negativo:** Intentos simultáneos de redención de la última sesión desde app y recepción.
- **Mitigación:** 
  - Lock exclusivo sobre el encabezado del bono (`SELECT ... FROM bonos_cliente WHERE id = $1 FOR UPDATE`).
  - Inserción condicional validando que `saldo_resultante >= 0`.
  - Reversión automática idempotente mediante hook de cancelación en la máquina de estados de Citas.

#### 2.3 Dependencias y Orden respecto al Roadmap
- **Dependencias:** Independiente de T-101 y T-103. Requiere que los estados de transición de citas (`CANCELADA`, `COMPLETADA`) estén formalizados en PG crudo.
- **Orden:** **Posterior a T-101 y T-103**.

#### 2.4 Estimación de Complejidad
- **Complejidad:** **MEDIA**.
- **Impacto / Esfuerzo:** Excelente ratio; incrementa el LTV y flujo de caja del salón eliminando disputas por conteos manuales.

#### 2.5 Plan de Ejecución Propuesto
- **`T-302-A`**: DDL e índices `(bono_id, creado_at DESC)`.
- **`T-302-B`**: Servicio `bonoLedgerService.js` (`adquirirBono`, `consumirSesion`, `revertirSesionPorCancelacion`).
- **`T-302-C`**: Conexión con ciclo de vida de Citas.
- **`T-302-D`**: Test suite de estrés de concurrencia.

#### 2.6 Contradicciones con Decisiones Previas
- Respeta íntegramente `FISCAL-BOUNDARY.md` (manejo de saldos operativos sin asumir facturación tributaria DIAN en Fase 1).

> **VEREDICTO:** **VIABLE CON PRERREQUISITO** (Prerrequisito: formalizar hooks de cancelación en Citas en PG crudo).

---

### CAPACIDAD 3: Consentimiento Ligado a Sesión de Bono (Resolución de Mismatch UUID/INT)

#### 3.1 Viabilidad Técnica sobre la Base Actual
- **Compatibilidad con Schema:** Condicionada al saneamiento del identificador. Actualmente `biometric_consents` (T-103) usa `user_id UUID` mientras que tablas de usuarios/perfiles en ramas legacy operan con `INTEGER`.
- **Componentes a Reutilizar:**
  - Lógica criptográfica y sellado SHA-256 de `consentService.js` y `documentGeneratorService.js`.
- **Componentes Nuevos Requeridos:**
  - Migración DDL unificadora de identificadores canónicos.
  - Tabla `session_treatment_consents` enlazada a `bonos_ledger_movimientos(id)` y `citas(id)`.

#### 3.2 Riesgos de Concurrencia y de Datos
- **Riesgo de Incompatibilidad SQL:** Consultas fallidas (`operator does not exist: uuid = integer`), deshabilitación de índices B-tree y degradación de rendimiento.
- **Riesgo Jurídico-Sanitario (Ley 1581 / Ley 711 de 2001):** Un consentimiento general de cuenta no cubre cambios en condiciones de salud (embarazo, medicación, exposición solar) entre sesiones sucesivas de un mismo bono.
- **Mitigación:** 
  - Saneamiento definitivo de tipos en la migración de T-103 antes de crear la relación.
  - Firma y congelación de hash SHA-256 de contraindicaciones en cada consumo de sesión.

#### 3.3 Dependencias y Orden respecto al Roadmap
- **Dependencias:** **Dependencia absoluta de T-103 y de la Capacidad 2**.
- **Orden:** **Estrictamente posterior a la resolución formal de T-103**.

#### 3.4 Estimación de Complejidad
- **Complejidad:** **MEDIA-ALTA** (por la migración de datos delicados preexistentes).
- **Impacto / Esfuerzo:** Blindaje legal de primer nivel para salones de estética avanzada y aparatología.

#### 3.5 Plan de Ejecución Propuesto
- **`T-303-A`**: Migración DDL de unificación de tipos en tablas de consentimiento.
- **`T-303-B`**: DDL de `session_treatment_consents` ligada al ledger de bonos.
- **`T-303-C`**: Componente Flutter de firma ágil pre-sesión en cabina.
- **`T-303-D`**: API de auditoría de consentimientos históricos por tratamiento.

#### 3.6 Contradicciones con Decisiones Previas
- Exige resolver la deuda técnica reconocida en T-103 sin evasiones de código (`CAST` implícitos).

> **VEREDICTO:** **VIABLE CON PRERREQUISITO** (Prerrequisito: finalización de T-103 y saneamiento canónico de tipos).

---

### CAPACIDAD 4: Certificado de Cumplimiento Vivo en el Marketplace

#### 4.1 Viabilidad Técnica sobre la Base Actual
- **Compatibilidad con Schema:** **100% compatible y nativo**.
- **Componentes a Reutilizar:**
  - `business_profiles` (`compliance_score`, `lifecycle_stage`).
  - Geolocalización de `salones` (`064_add_salon_location_and_visibility.sql`).
  - Motor de capacidades de `saasEntitlements.js`.
  - Catálogo de proveedores y vistas de detalle en Flutter.
- **Componentes Nuevos Requeridos:**
  - Vista/Query enriquecida en `salonController.js` y `providerController.js` para exponer el badge de verificación normativa.
  - Modal informativo de garantías de bioseguridad en el frontend.

#### 4.2 Riesgos de Concurrencia y de Datos
- **Riesgos de Concurrencia:** **Nulos** (Lectura cacheada).
- **Riesgo de Falso Positivo (False Trust):** No exponer un puntaje basado únicamente en autodeclaración del dueño.
- **Mitigación:** La insignia pública solo se activa si las tareas críticas de sanidad y bioseguridad están en estado `VERIFICADO` con evidencia aprobada.

#### 4.3 Dependencias y Orden respecto al Roadmap
- **Dependencias:** **Ninguna**. Es ortogonal e independiente de T-101 y T-103.
- **Orden:** **1º (Inmediato / Quick-Win)**.

#### 4.4 Estimación de Complejidad
- **Complejidad:** **BAJA**.
- **Impacto / Esfuerzo:** Retorno comercial inmediato con mínimo esfuerzo técnico.

#### 4.5 Plan de Ejecución Propuesto
- **`T-304-A`**: Exposición de flags de cumplimiento verificado en APIs públicas de catálogo.
- **`T-304-B`**: Insignia interactiva *Belleza Luxe* en `ProviderDetailScreen` y tarjetas de mapa.
- **`T-304-C`**: Modal público de verificación de bioseguridad.

#### 4.6 Contradicciones con Decisiones Previas
- Ninguna. Armoniza completamente con la arquitectura actual.

> **VEREDICTO:** **VIABLE AHORA**.

---

## 3. MATRIZ COMPARATIVA Y DE PRIORIZACIÓN

| # | Capacidad Evaluada | Complejidad | Secuencia Recomendada | Prerrequisito Crítico | Conflicto con Roadmap Actual | Veredicto Técnico |
|---|---|:---:|:---:|---|:---:|:---:|
| **4** | **Certificado de Cumplimiento Vivo** | **Baja** | **1º** | Ninguno (Schema y PostGIS listos). | Ninguno | **VIABLE AHORA** |
| **2** | **Ledger de Bonos de Sesiones** | **Media** | **2º** | Formalizar hooks de estado en Citas PG crudo. | Ninguno (sigue patrón `productos`). | **VIABLE CON PRERREQUISITO** |
| **3** | **Consentimiento Ligado a Sesión** | **Media-Alta** | **3º** | Culminar T-103 + saneamiento DDL UUID/INT + Capacidad 2. | Choca con deuda técnica T-103 si no se sanea. | **VIABLE CON PRERREQUISITO** |
| **1** | **Recurso Reservable Doble** | **Alta** | **4º** | Culminar migración D-01 + `btree_gist`. | Incompatible con ORM Sequelize. | **REQUIERE DECISIÓN PREVIA** |

---

## 4. SECUENCIA CRONOLÓGICA RECOMENDADA

$$\boxed{\text{T-101 (productService)}} \longrightarrow \boxed{\text{Capacidad 4 (Sello Marketplace)}} \longrightarrow \boxed{\text{T-103 (consentService Saneado)}} \longrightarrow \boxed{\text{Capacidad 2 (Bonos Ledger)}} \longrightarrow \boxed{\text{Capacidad 3 (Consentimiento Sesión)}} \longrightarrow \boxed{\text{D-08 / Capacidad 1 (Recursos Dobles)}}$$

Este orden garantiza que ninguna tarea adelante dependencias inestables, maximiza el valor inmediato de cara al usuario final y mantiene blindada la concurrencia en la base de datos PostgreSQL.
