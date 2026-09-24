# DEC-AS-003 — ANÁLISIS DE DECISIÓN ARQUITECTÓNICA v1.0
## Análisis de Autoridad y Disparador de Materialización en B2C (Materialization Trigger Authority Analysis)

**DECISION_ID:** `DEC-AS-003`  
**ESTADO:** `DEC-AS-003 — ARCHITECTURAL STOP — DIRECTOR DECISION REQUIRED 🛑`  
**TIPO:** Architectural Decision Analysis  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-003-001`  
**CONTRATOS Y ACTIVOS PROTEGIDOS:** `065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`, `HUB-SALON-NODE-CONTRACT-v1.0.md`, `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`, `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`, `NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001-DECISION-RECORD-v1.0.md`, `DEC-SE-002-DECISION-RECORD-v1.0.md`, `DEC-AS-001-DECISION-RECORD-v1.0.md`, `DEC-CAT-001-DECISION-RECORD-v1.0.md`, `DEC-AS-002-DECISION-RECORD-v1.0.md`, `DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`  
**FECHA:** 2026-09-10  

---

## 1. EXECUTIVE FINDING (HALLAZGO EJECUTIVO)

La investigación exhaustiva de los activos físicos y normativos del repositorio sobre el mecanismo de materialización concluye:

1. **[FACT] Inexistencia de un Acto de Materialización SaaS en el Código:** En el backend actual (`serviceRoutes.js`, `serviceController.js`, `hubSalonRoutes.js`, `nodo01Service.js`) **no existe ningún endpoint, función, evento ni comando** para materializar ofertas de catálogo SaaS en `public.services`.
2. **[FACT] El Acto B2C Existente es Exclusivamente Individual:** El único mecanismo físico existente en B2C es `POST /api/services`, el cual está restringido a un prestador individual creando sus propios servicios (`req.user.role IN ('provider', 'PRESTADOR')` con `provider_id = req.user.id`). No existe soporte para que una sede o administrador cree servicios para terceros.
3. **[EVIDENCE] Segregación de Autoridad:** La autoridad de asignación de `OWNER`/`MANAGER` en SaaS (`DEC-AS-001`) no confiere por sí misma una autorización automática de inserción física en `public.services` sin una política de disparo formalmente sancionada.
4. **[DICTAMEN / STOP]** Se emite un **`ARCHITECTURAL STOP`**. No existe en el sistema actual un acto operacional legítimamente definido para la materialización; por ende, corresponde al Director seleccionar entre las opciones de gobernanza evaluadas antes de autorizar el diseño de `NODO-02`.

---

## 2. PRECEDENTES CERRADOS Y MARCO NORMATIVO

```text
================================================================================
MARCO NORMATIVO CERRADO:

1. DEC-CAT-001: SERVICE_OFFER = OPERATIONAL STATE POST-HANDOVER (Identity Demonstrated).
2. DEC-AS-001:  ASSIGNMENT AUTHORITY = OWNER/MANAGER en activeContext.
3. DEC-AS-002:  ASSIGNMENT = DURABLE SAAS STATE (Ref Oferta + Ref Profesional).
4. DEC-PUB-001: PUBLICATION = NOT PRESENT.
                ACTIVATION = NOT PRESENT (Independent Workflow).
                B2C AVAILABILITY = services.is_active = TRUE.
5. DEC-SE-001:  SERVICE_OFFER ≠ public.services (Instanciación Tardía).
                assignment NOT_ESTABLISHED => NO public.services.
6. DEC-SE-002:  Autonomía de ubicación y horarios en perfiles_prestador.
================================================================================
```

---

## 3. INVESTIGACIÓN EXHAUSTIVA DE EVIDENCIA

### 3.1. Auditoría del Mecanismo de Creación B2C Existente [FACT]:
En `backend/src/routes/serviceRoutes.js` (L8) y `backend/src/controllers/serviceController.js` (L34-55):
* **Endpoint:** `POST /api/services`
* **Autorización:** `req.user.role === 'provider' || req.user.role === 'PRESTADOR'`
* **Semántica:** Creación manual individual por un prestador independiente para su propia cuenta (`provider_id = req.user.id`).
* **Integridad:** Exige que `req.user.id` exista en `public.perfiles_prestador`.
* **Conclusión:** Este acto no representa ni soporta la materialización de catálogo de un establecimiento SaaS.

### 3.2. Auditoría de Contratos SaaS [FACT]:
* **`HUB-SALON-NODE-CONTRACT-v1.0`:** Cero endpoints de materialización o aprovisionamiento.
* **`CREAR-DESDE-CERO-NODE-CONTRACT-v1.0`:** Entrega DTO transitorio a la frontera downstream (`NEW TABLES = 0`).
* **`HANDOVER-BOUNDARY-CONTRACT-v1.0`:** Transporta ofertas no asignadas (`assignment = NOT_ESTABLISHED`).
* **`NODO-01-NODE-CONTRACT-v1.0`:** Adaptador neutral en memoria. No escribe en base de datos.
* **Conclusión:** Ningún activo SaaS existente implementa o define el acto de materialización.

### 3.3. Auditoría de Autoridad de Actores [EVIDENCE]:
* **`OWNER` / `MANAGER`:** Poseen autoridad de asignación (`DEC-AS-001`) sobre el catálogo y personal de la sede, pero no tienen un comando formalizado para invocar la inserción en B2C.
* **`PROFESSIONAL`:** Posee su identidad (`usuarios.id`) y eventual perfil B2C, pero no gobierna el catálogo de la sede.
* **`SYSTEM / AUTOMATION (Adapter Downstream)`:** No posee mandato formalizado de disparo automático.

---

## 4. SEPARACIÓN RIGUROSA DE LAS TRES ETAPAS

```text
================================================================================
SEPARACIÓN CONCEPTUAL OBLIGATORIA:

[ETAPA 1: ASSIGNMENT] (DEC-AS-001 / DEC-AS-002 🔒)
  SERVICE_OFFER ──(OWNER/MANAGER)──> ACTIVE PROFESSIONAL
  (Estado durable en el dominio SaaS de la sede).

[ETAPA 2: MATERIALIZATION] (DEC-AS-003 - OBJETO DE ESTE ANÁLISIS 🛑)
  SERVICE_OFFER + ASSIGNMENT ──(TRIGGER AUTORIZADO)──> public.services
  (Inserción técnica downstream con provider_id = profesional.user_id).

[ETAPA 3: AVAILABILITY] (DEC-PUB-001 🔒)
  public.services (is_active = TRUE) + perfiles_prestador activo
  (Servicio operable y agendable por clientes en bookings).
================================================================================
```

---

## 5. EVALUACIÓN DE HIPÓTESIS DE DISPARADORES (TRIGGERS)

```text
================================================================================
HIPÓTESIS EVALUADAS:

[OPTION A: EXISTING B2C CREATION ACT]
  Reutilizar POST /api/services para la materialización.
  *Objeción:* Incompatible. El endpoint exige rol 'provider' del propio usuario y
  no soporta aprovisionamiento delegado por administradores de sede.

[OPTION B: EXPLICIT SAAS MATERIALIZATION COMMAND]
  Un nuevo comando operacional invocado por OWNER/MANAGER en el Cockpit
  (ej. "Aprovisionar Catálogo en B2C").
  *Ventajas:* Soberanía total del salón; evita inserciones prematuras.
  *Requisito:* Requiere definir el nuevo comando/endpoint en la capa SaaS.

[OPTION C: AUTOMATIC MATERIALIZATION AFTER ASSIGNMENT]
  La asignación válida dispara automáticamente la creación/upsert en public.services
  siempre que el colaborador posea perfiles_prestador.
  *Ventajas:* Máxima fluidez operativa (cero pasos adicionales).
  *Riesgo:* Inserción inmediata sin fase previa de borrador/revisión de catálogo.

[OPTION D: DOWNSTREAM OPERATIONAL WORKFLOW (NODO-02)]
  Un adaptador downstream recibe la asignación durable y ejecuta la materialización
  según un flujo de preparación operativa desacoplado.
  *Ventajas:* Aísla la complejidad técnica en el adaptador de aprovisionamiento.

[OPTION E: EVIDENCE INSUFFICIENT / ARCHITECTURAL STOP]
  Concluir formalmente que no existe trigger demostrado y requerir decisión del Director.
================================================================================
```

---

## 6. MATRIZ DE DECISIÓN COMPARATIVA

```text
+------------------------------------+------------+------------------+---------------------+-------------------+---------------------+
| Criterio                           | OPTION A   | OPTION B         | OPTION C            | OPTION D          | OPTION E (Factual)  |
|                                    | (B2C Act)  | (Comando SaaS)   | (Auto en Assign)    | (Downstream Flow) | (Stop / Decisión)   |
+------------------------------------+------------+------------------+---------------------+-------------------+---------------------+
| Evidencia física existente         | Inadecuada | NOT PRESENT      | NOT PRESENT         | NOT PRESENT       | SUPPORTED ✅        |
| Autoridad demostrada               | No aplica  | Coherente (Owner)| Coherente (Sistema) | Coherente (Adapter| DEMOSTRADA (Stop) ✅|
| Compatibilidad DEC-SE-001          | Nula       | TOTAL ✅         | TOTAL (Tardía) ✅   | TOTAL ✅          | TOTAL ✅            |
| Compatibilidad DEC-AS-001/002      | Invalida   | TOTAL ✅         | TOTAL ✅            | TOTAL ✅          | TOTAL ✅            |
| Compatibilidad DEC-PUB-001         | Total      | TOTAL ✅         | TOTAL ✅            | TOTAL ✅          | TOTAL ✅            |
| Necesidad de nuevo concepto        | Inviable   | Sí (Comando)     | No (Automatismo)    | No (Adapter)      | NINGUNO ✅          |
| Riesgo de automatismo no deseado   | Alto       | NULO ✅          | MEDIO               | BAJO              | NULO ✅             |
| Economía arquitectónica            | Pobre      | Buena            | EXCELENTE           | EXCELENTE         | MÁXIMA RIGUROSIDAD ✅|
+------------------------------------+------------+------------------+---------------------+-------------------+---------------------+
```

---

## 7. PROHIBICIONES Y NO-AUTORIZACIONES

Este documento es **exclusivamente analítico**.

**NO autoriza:**
- Creación de endpoints, tablas, columnas ni migraciones.
- Creación de entidades como `published`, `activated` o `materialization_status`.
- Modificación de código B2C ni esquemas PostgreSQL.
- Diseño o redacción del Node Contract de NODO-02.

---

## 8. ARCHITECTURAL STOP (EMISIÓN FORMAL)

En estricto cumplimiento de la directiva del Director, se emite formalmente un **ARCHITECTURAL STOP**:

```text
================================================================================
🛑 ARCHITECTURAL STOP — DEC-AS-003:

PROBLEMA:
No existe en la arquitectura actual ningún acto, comando, endpoint ni evento que
autorice formalmente cuándo un SERVICE_OFFER asignado debe materializarse físicamente
en public.services.

EVIDENCIA:
1. POST /api/services pertenece al prestador individual, no a la administración SaaS.
2. Hub Salón v1.0, CDC y Nodo 01 no contienen comandos de materialización.
3. DEC-AS-001 formalizó la autoridad de asignación, pero no el trigger de persistencia B2C.
4. DEC-PUB-001 demostró que no existe un workflow independiente de publicación.

IMPACTO:
Diseñar NODO-02 sin definir el disparador de materialización obligaría a asumir
arbitrariamente un automatismo no autorizado o a inventar comandos inexistentes.

OPCIONES PARA EL DIRECTOR:
1. DISPARO AUTOMÁTICO POR ADAPTADOR (Option C/D): La materialización se ejecuta
   automáticamente por NODO-02 cuando confluyen (Oferta + Asignación + Elegibilidad B2C).
2. DISPARO MANUAL EXPLÍCITO (Option B): Se crea un comando formal en Hub Salón
   ("Aprovisionar / Sincronizar Servicios") invocado por OWNER/MANAGER.

RECOMENDACIÓN:
Se recomienda la OPCIÓN 1 (Disparo Automático por NODO-02 condicionado a la
elegibilidad en perfiles_prestador), por su máxima economía arquitectónica y fluidez.

DECISIÓN REQUERIDA:
El Director debe formalizar si el trigger es AUTOMÁTICO CONDICIONADO (NODO-02)
o si requiere un COMANDO EXPLÍCITO en el Hub Salón.
================================================================================
```

---

## 9. ESTADO FINAL

```text
================================================================================
DEC-AS-003

MATERIALIZATION TRIGGER AUTHORITY ANALYSIS

STATUS: DEC-AS-003 — ARCHITECTURAL STOP — DIRECTOR DECISION REQUIRED 🛑

NO IMPLEMENTATION AUTHORIZED BY THIS ANALYSIS
================================================================================
```

---
*Fin del documento de Análisis de Decisión Arquitectónica DEC-AS-003.*
