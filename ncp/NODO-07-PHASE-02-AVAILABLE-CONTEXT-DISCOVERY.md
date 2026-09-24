# NODO-07 — FASE 2 — AVAILABLE CONTEXT CONTRACT CLOSURE & DISCOVERY
## Canonical Contract Definition & Physical Architecture Specification

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto  
NODE IDENTIFIER: NODO-07  
PHASE: FASE 2 — Available Context  
DOCUMENT VERSION: v1.1.0 (CONTRACT CLOSED & APPROVED)  
CLASSIFICATION: FORMAL CONTRACT CLOSURE & SPECIFICATION — ZERO CODE IMPLEMENTED  
BASELINE CONTRACT: ncp/NODO-07-SAAS-SCREEN-FLOW-CONTRACT-v1.0.md (CLOSED / IMMUTABLE)  
PHYSICAL ARCHITECTURE: ncp/NODO-07-PHYSICAL-ARCHITECTURE-v1.0.md (APPROVED)  
INFRASTRUCTURE BASE: NODO-07 FASE 1 (CLOSED / IMMUTABLE)  
DIRECTOR DECISION: DEC-N07-AC-001 (FORMALIZED & ADOPTED)  
STATUS: CONTRACT CLOSED & APPROVED / AWAITING IMPLEMENTATION AUTHORIZATION 🟡  
================================================================================

---

## 1. EXECUTIVE SUMMARY

El presente documento formaliza el **cierre contractual definitivo** y el discovery técnico para la capa de **Available Context** en GlowApp SaaS.

### Conclusiones y Decisiones Directivas Clave:
1. **Directiva DEC-N07-AC-001 (Mandatoria):** Queda formalmente ratificado que el estado `ONE_CONTEXT` **requiere selección explícita**. Se prohíbe terminantemente la auto-fijación o auto-navegación directa al Hub Salón.
2. **Definición Canónica de Available Context:** Representa el conjunto de membresías que el backend determina que la identidad autenticada puede utilizar como contexto SaaS. El único identificador técnico de selección es `membership_id`.
3. **Definición Canónica de Active Context:** Representa exclusivamente el `membership_id` elegido de forma explícita por el usuario y mantenido temporalmente en la memoria RAM del cliente mediante `ActiveContextHolder`.
4. **Backend Maduro y Cerrado:** El endpoint `GET /api/v1/saas/context/available` se encuentra verificado, probado (180/180 tests green en base de datos) y no requiere modificaciones.
5. **Preservación de Bloqueos:** El subsistema **`JOURNEY` continúa en ARCHITECTURAL STOP** pendiente de formalización directiva. Cero modificaciones en Login, Register, main.dart o UI.

---

## 2. DIRECTOR DECISION — DEC-N07-AC-001

```
================================================================================
                    DIRECTOR DECISION: DEC-N07-AC-001
            SELECCIÓN EXPLÍCITA OBLIGATORIA PARA ONE_CONTEXT
================================================================================
FECHA DE ADOPCIÓN: 2026-09-12
AUTORIDAD: Director del Proyecto GlowApp SaaS
ESTADO: RATIFICADO / INMUTABLE / OBLIGATORIO

MANDATO:
Cuando el backend responda con:
  resolution_status = 'ONE_CONTEXT'
  available_contexts_count = 1

El cliente Flutter NO DEBE:
- auto-seleccionar el contexto;
- auto-fijar el membership_id;
- llamar a ActiveContextHolder.setActiveMembershipId(...) automáticamente;
- navegar automáticamente al Hub Salón;
- persistir el contexto en almacenamiento local;
- restaurar contextos previos de sesiones anteriores.

El cliente Flutter DEBE:
1. Presentar en la interfaz el único contexto/sede disponible;
2. Esperar una acción explícita y consciente del usuario (ej. pulsar "Ingresar a Sede");
3. Solamente después de dicha acción explícita:
   ActiveContextHolder().setActiveMembershipId(membership_id);
4. Continuar posteriormente hacia el contexto SaaS activo (Hub Salón).

JUSTIFICACIÓN ARQUITECTÓNICA:
Garantiza el consentimiento explícito del operador antes de inicializar la sesión
operativa SaaS, previene saltos ciegos de navegación, homogeniza la máquina de
estados y refuerza la frontera entre Identidad y Operación de Sede.
================================================================================
```

---

## 3. CANONICAL DEFINITIONS

### 3.1. Available Context (Definición Canónica)
- **Concepto:** Es el conjunto de membresías activas que la autoridad backend determina que la identidad autenticada tiene derecho a utilizar dentro del tenant SaaS.
- **Identificador Técnico:** Exclusivamente `membership_id` (UUID v4).
- **Invariantes Prohibitivas:**
  - Prohibido crear una tabla o entidad "Context" en backend o base de datos.
  - Prohibido crear nuevos DTOs o columnas sintéticas.
  - Prohibido crear nuevos endpoints.

### 3.2. Active Context (Definición Canónica)
- **Concepto:** Representa exclusivamente el `membership_id` seleccionado explícitamente por el usuario y mantenido temporalmente en la memoria RAM del cliente mediante `ActiveContextHolder`.
- **Invariantes de Desacoplamiento:**
  $$	ext{ACTIVE CONTEXT} \equiv 	ext{membership\_id (RAM)}$$
  $$	ext{ACTIVE CONTEXT} 
eq 	ext{Tenant} 
eq 	ext{Establishment} 
eq 	ext{Salón} 
eq 	ext{Organization} 
eq 	ext{Role} 
eq 	ext{Journey} 
eq 	ext{Account} 
eq 	ext{Persona}$$

---

## 4. CANONICAL STATES MODEL

Se formalizan los 3 estados canónicos deterministas de Available Context:

```
+───────────────────────────────────────────────────────────────────────────────+
|                               ESTADOS CANÓNICOS                               |
+───────────────────────────────────────────────────────────────────────────────+

1. NO_CONTEXT
   ├── Condición: resolution_status == 'NO_CONTEXT' && available_contexts_count == 0.
   ├── Significado: La identidad carece de membresías activas en el subsistema SaaS.
   ├── Restricción de Cliente:
   │   ├── NO inventa membership_id.
   │   ├── NO selecciona establishment ni tenant.
   │   ├── NO ingresa al Hub Salón.
   │   └── NO concede acceso SaaS.
   └── Experiencia: Presentar vista informativa ("Sin sedes asignadas") y CTA para
       "Crear Salón Desde Cero" (Fase 4 Onboarding) o volver a B2C.

2. ONE_CONTEXT
   ├── Condición: resolution_status == 'ONE_CONTEXT' && available_contexts_count == 1.
   ├── Significado: La identidad posee exactamente 1 membresía activa.
   ├── Regla Directiva (DEC-N07-AC-001): Selección explícita obligatoria.
   ├── Comportamiento:
   │   ├── Muestra la sede disponible en pantalla.
   │   ├── Usuario presiona explícitamente "Ingresar a Sede".
   │   ├── Se ejecuta ActiveContextHolder.setActiveMembershipId(membership_id).
   │   └── Navega hacia /saas/hub (Hub Salón Cockpit).
   └── Invariante: CERO auto-avance o auto-fijación.

3. MULTIPLE_CONTEXTS
   ├── Condición: resolution_status == 'MULTIPLE_CONTEXTS' && available_contexts_count >= 2.
   ├── Significado: La identidad posee 2 o más membresías activas en distintas sedes.
   ├── Comportamiento:
   │   ├── Despliegue obligatorio de AvailableContextSelectorScreen.
   │   ├── Usuario elige explícitamente la sede donde desea operar.
   │   ├── Se ejecuta ActiveContextHolder.setActiveMembershipId(selected_membership_id).
   │   └── Navega hacia /saas/hub (Hub Salón Cockpit).
   └── Prohibiciones Estrictas:
       ├── CERO selección automática.
       ├── CERO selección por primer elemento del arreglo.
       ├── CERO selección por rol más alto (ej. OWNER sobre PROFESIONAL).
       ├── CERO selección por establecimiento o tenant.
       └── CERO selección por "último contexto utilizado".
```

---

## 5. SEPARATION OF RESPONSIBILITIES

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                             RESPONSABILIDAD BACKEND                           │
│  - Determina y devuelve membresías disponibles (GET /context/available).      │
│  - Valida identidad autenticada (JWT) y resuelve tenant vía SQL.              │
│  - Valida pertenencia de membership al usuario y establecimiento.             │
│  - Aplica políticas de seguridad RLS y autorización en PostgreSQL.            │
└───────────────────────────────────────┬───────────────────────────────────────┘
                                        │ (HTTP 200 JSON Payload)
                                        ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                            RESPONSABILIDAD FRONTEND                           │
│  - Solicita Available Context mediante ApiService.get('/context/available').  │
│  - Presenta las opciones y el estado visual al usuario.                       │
│  - Espera SIEMPRE la interacción y selección EXPLÍCITA del usuario.           │
│  - Invoca ActiveContextHolder.setActiveMembershipId(id) tras la acción.       │
│  - Transporta el header x-active-membership-id en llamadas a /api/v1/saas/*.  │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. BACKEND ENDPOINT SPECIFICATION (FORENSICALLY VERIFIED)

- **Ruta:** `GET /api/v1/saas/context/available`
- **Controlador:** [`backend/src/controllers/contextController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/contextController.js)
- **Servicio:** [`backend/src/services/contextResolutionService.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/contextResolutionService.js)
- **Headers Requeridos:** `Authorization: Bearer <JWT>`, `Content-Type: application/json`.
- **Frontera Transaccional:** **No requiere Active Context** (opera sin `x-active-membership-id`).

### Estructura de Respuesta HTTP 200 OK:
```json
{
  "status": "success",
  "data": {
    "resolution_status": "NO_CONTEXT" | "ONE_CONTEXT" | "MULTIPLE_CONTEXTS",
    "identity_id": 123,
    "tenant_id": 1,
    "available_contexts_count": 2,
    "available_contexts": [
      {
        "membership_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "tenant_id": 1,
        "tenant_name": "Glow Hair Salon Group",
        "organization_id": "b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e",
        "organization_legal_name": "Glow Hair S.A.S.",
        "establishment_id": "c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f",
        "establishment_name": "Sede Chicó Norte",
        "establishment_slug": "sede-chico-norte",
        "establishment_is_active": true,
        "role": "PROFESIONAL",
        "relation_type": "EMPLOYEE",
        "membership_status": "ACTIVE"
      }
    ]
  }
}
```

---

## 7. FLUTTER INTEGRATION & SELECTION FLOW

```
[AvailableContextSelectorScreen / Confirmación]
                     │
                     ▼ (Usuario presiona "Ingresar a Sede" o selecciona tarjeta)
[ActiveContextHolder().setActiveMembershipId(item.membership_id)]
                     │
                     ├──> Asigna en RAM volátil (Cero FlutterSecureStorage / Cero SharedPreferences)
                     └──> Notifica a oyentes reactivos vía ChangeNotifier
                     │
                     ▼
[Navigator.pushReplacementNamed(context, '/saas/hub')]
                     │
                     ▼
[HubSalonScreen realiza peticiones operacionales]
  └── ApiService.get('/api/v1/saas/hub/summary')
        ├── Inyecta Authorization: Bearer <JWT>
        └── Inyecta x-active-membership-id: <item.membership_id>
```

---

## 8. JOURNEY BOUNDARY (ARCHITECTURAL STOP)

```
================================================================================
                           ARCHITECTURAL STOP A
================================================================================
ESTADO: ARCHITECTURAL STOP VIGENTE / NO AUTORIZADO
El mecanismo físico de resolución de Journey post-login (conmutación deliberada
entre Marketplace B2C y Plataforma SaaS) permanece pendiente de definición por
el Director.

PROHIBICIONES ACTIVAS:
- NO modificar Login (login_screen.dart).
- NO modificar Register (register_screen.dart).
- NO modificar main.dart.
- NO alterar la navegación actual ni asumir redirecciones automáticas.
================================================================================
```

---

## 9. IMPLEMENTATION PROJECTION (AWAITING AUTHORIZATION)

Para la siguiente subfase de implementación (cuando sea expresamente autorizada por el Director):

| Componente Proyectado | Tipo | Propósito y Responsabilidad | Estado |
| :--- | :---: | :--- | :---: |
| `frontend/lib/models/saas/available_context_model.dart` | `NEW` | Modelo DTO inmutable para tipar la respuesta de `GET /context/available`. | `PENDING AUTHORIZATION` |
| `frontend/lib/services/saas_context_service.dart` | `NEW` | Servicio que consume `ApiService.get('/api/v1/saas/context/available')`. | `PENDING AUTHORIZATION` |
| `frontend/lib/screens/saas/available_context_screen.dart`| `NEW` | Pantalla UI para presentar los estados (`NO_CONTEXT`, `ONE_CONTEXT`, `MULTIPLE_CONTEXTS`) con interacción explícita. | `PENDING AUTHORIZATION` |
| `frontend/test/available_context_test.dart` | `NEW` | Suite de pruebas unitarias para DTO, servicio y selección explícita. | `PENDING AUTHORIZATION` |

---

## 10. PROTECTED / IMMUTABLE BOUNDARIES

- **NODO-07 FASE 1:** `active_context_holder.dart`, inyección en `api_service.dart` y `saas_client_infrastructure_test.dart` (IMMUTABLE).
- **Backend N01..N06:** Controladores, rutas, servicios, migraciones y PostgreSQL (IMMUTABLE).
- **Subsistema B2C:** `home_screen.dart`, `provider_dashboard_screen.dart`, `booking_tracking_screen.dart` (IMMUTABLE).

---

## 11. FINAL STATUS

```
================================================================================
NODO-07 FASE 2 CONTRACT: CLOSED & APPROVED (DEC-N07-AC-001 ADOPTED)
ZERO CODE IMPLEMENTED (FASE DE ESPECIFICACIÓN Y CONTRATO)
JOURNEY STATUS: ARCHITECTURAL STOP
IMPLEMENTATION STATUS: AWAITING DIRECTOR IMPLEMENTATION AUTHORIZATION 🟡
================================================================================
```
