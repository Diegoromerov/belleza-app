# Auditoría de funcionamiento — Orquestador AURA y agentes (ATENA, HERMES, CHRONOS, HESTIA, VALKYRIE)

**Fecha:** 2026-10-24 · **Rama:** `feature/salon-redesign` · **HEAD:** `ce708d999`
**Alcance:** `backend/src/services/auraToolExecutor.js`, `geminiService.js` (bucle AURA), `services/agents/*.js`, `controllers/chatController.js`, `services/biometric/orchestrator.js`
**Método:** lectura del código real + ejecución de las 5 suites de agentes (34 pruebas, **34 PASS**) + sonda con base de datos simulada ([backend/scripts/auditAgentsBehaviour.js](<backend/scripts/auditAgentsBehaviour.js>)).
**Regla de este informe:** *observado* = leído o ejecutado aquí; *hipótesis* = razonado desde el código y pendiente de reproducción contra PostgreSQL real.

---

## 0. Resumen ejecutivo

El "orquestador" no es un orquestador: es un **despachador de 14 herramientas por nombre**. No enruta, no valida argumentos, no aplica permisos por rol, no encadena agentes y no reintenta; ejecuta una sola ronda de *tool calls* y sintetiza.

De los cinco agentes, **dos son sólidos** (ATENA, HERMES-geo), **uno funciona con defectos** (CHRONOS), **uno está degradado a catálogo por precio** (HESTIA) y **uno no es operativo en los términos que la documentación le atribuye** (VALKYRIE: "autoriza" un 15% que ningún checkout puede consumir).

El hallazgo más grave no es de comportamiento sino de **alcance**: `get_provider_b2b_insights` acepta cualquier `providerId` de cualquier usuario autenticado, y el parámetro `userRole` que recibe el ejecutor **no se usa para autorizar nada** (única aparición: la firma de la función).

Y hay un desfase sistemático entre lo que los informes GIA certifican ("100% operativo", "subordinación estricta a los activos del plan") y lo que el código hace.

---

## 1. Quién orquesta a quién (as-built)

```
chatController.sendMessage  (POST /api/chat/messages)
  └─ responde 201 y DESPUÉS, sin await, llama:
       processAssistantMessage(userId, texto, img, req.user.rol, tenant_id)   [geminiService.js:329]
         ├─ RAG beauty + caché semántico + historial 20 mensajes
         ├─ DeepSeek (circuit breaker) con tools=AURA_TOOLS_DEFINITIONS (14)
         ├─ UNA ronda de tool_calls → executeAuraTool(nombre, args, userId, userRole, tenantId)
         │     ├─ ATENA      query_user_biometric_profile
         │     ├─ HERMES     search_nearby_services · check_provider_availability
         │     ├─ CHRONOS    evaluate_user_rebooking
         │     ├─ HESTIA     recommend_glowstore_products   (llama a ATENA por dentro)
         │     ├─ VALKYRIE   get_provider_b2b_insights
         │     └─ RAG/tools de negocio: search_*_knowledge_rag, get_business_*, get_provider_*, get_salon_*
         └─ segunda llamada al LLM SIN tools → respuesta final
```

**Confusión de nombres, primero:** `services/aiOrchestrator.js` **no orquesta agentes** — es un cliente HTTP de 29 líneas hacia el worker de Python (`POST /api/v1/analyze-skin`). Quien audite "el orquestador" leyendo ese archivo audita otra cosa. El orquestador real son `auraToolExecutor.js` (despacho) + `geminiService.js` (bucle).

**Segundo orquestador, este sí real:** `services/biometric/orchestrator.js` (364 líneas) — puerta de geometría, control de calidad de imagen, huella de foto, caché de escaneo, circuit breakers por proveedor, delta contra baseline y versión de consentimiento. Es de otra calidad: nada que ver con el despachador del chat.

---

## 2. Veredicto por componente

| Componente | Qué hace de verdad | Contrato documentado | Veredicto |
|---|---|---|---|
| **Orquestador** (`auraToolExecutor`) | Despacha por `switch`, 14 tools, sin validación de args ni RBAC | "multi-agente con autoridad por agente" ([GLOWAPP_GOVERNANCE_CONTRACTS.md](<docs/governance/GLOWAPP_GOVERNANCE_CONTRACTS.md>):350) | **Parcial** — funciona, no gobierna |
| **ATENA** | Lee `beauty_profiles`, descifra, enriquece con umbrales fijos, cachea 30 d en Redis | "diagnóstico biométrico" | **Operativo** (caché rancia, A-12) |
| **HERMES** | PostGIS parametrizado + conteo de citas del día | "agenda inteligente evitando colisiones" | **Parcial** — no calcula huecos reales (A-07) |
| **CHRONOS** | Máquina de estados por días + re-booking por cadencia fija | "continuidad D1→D30 blindada" | **Operativo con defectos** (A-06) |
| **HESTIA** | `SELECT ... FROM productos WHERE stock>0 ORDER BY precio ASC LIMIT 4` | "subordinación estricta a los activos del plan" | **Degradado** — no personaliza (A-04) |
| **VALKYRIE** | `COUNT` por día de la semana → `authorized: true`, 15% fijo, código con tilde | "propone, no autoriza" (D-05) | **No operativo** (A-02, A-03) |
| **RAG regulatorio** | Filtros que no pueden devolver filas, con `status:'success'` | "normativa colombiana aplicable" | **No operativo** (A-05) |

---

## 3. Hallazgos

### A-01 · P0 · `get_provider_b2b_insights` no verifica propiedad
El ejecutor valida propiedad solo para dos herramientas biométricas. VALKYRIE usa `args.providerId` en crudo:

```js
// auraToolExecutor.js:344-348
case 'get_provider_b2b_insights': {
  return await valkyrieAgent.getProviderInsights({ providerId: args.providerId });
}
```

**Reproducido** (sonda P2): `userId=1` pidiendo `providerId=777` → `status: success`, promo `GLOW-MIÉRCOLES-15`.
La suite lo **codifica como correcto**: [sprint4_agents.test.js](<backend/src/tests/sprint4_agents.test.js>):63 llama `executeAuraTool('get_provider_b2b_insights', { providerId: 10 }, 1)` y espera que funcione.

*Matiz medido:* el `authMiddleware` sí monta contexto de tenant ([auth.js](<backend/src/middleware/auth.js>):131-133), así que RLS acota el daño **entre** inquilinos. **No** lo acota **dentro** del inquilino: un cliente del mismo salón ve la distribución de reservas del negocio.

### A-02 · P0 · `userRole` se recibe y nunca se usa
```js
// auraToolExecutor.js:262  — única aparición en todo el archivo
async function executeAuraTool(toolName, args, userId, userRole = 'provider', tenantId = null) {
```
El rol solo cambia el texto del *system prompt* ([geminiService.js](<backend/src/services/geminiService.js>):417-428). Las 14 herramientas se ofrecen a todos los roles por igual (`tools: AURA_TOOLS_DEFINITIONS`, sin filtro) y el modelo decide. No hay allowlist por rol, ni comprobación de que un `CLIENTE` pueda pedir métricas financieras.

### A-03 · P0 · VALKYRIE "autoriza" sin poder hacerlo (y su código no es consumible)
- `authorized: true` y `discountPercentage: 15` son **constantes**; la única entrada es un `COUNT` por día ([valkyrieAgent.js:59-66](<backend/src/services/agents/valkyrieAgent.js>): con **1 reserva en 30 días** ya "autoriza" (sonda P1).
- No hay tope, vigencia, aprobación del salón ni registro. Contradice la decisión **D-05** escrita en [PROPUESTA_REINGENIERIA_360.md](<docs/glowshop/PROPUESTA_REINGENIERIA_360.md>):122: *"Propone, no autoriza"*.
- El `promoCode` **no lo consume nadie**: `createApplyPromoCheckoutAction` ([agentActionPayloads.js:45](<backend/src/services/agentActionPayloads.js>)) no tiene un solo llamador.
- El código generado lleva **tilde**: `GLOW-MIÉRCOLES-15` (sonda P1), así que ni cableándolo funcionaría con una validación `[A-Z0-9-]`.

**Conclusión:** hoy es teatro de autorización que se le cuenta al prestador como si fuera real; si alguien cablea `APPLY_PROMO_CHECKOUT` tal cual, se convierte en descuento de autoservicio para cualquiera.

### A-04 · P1 · HESTIA no personaliza: devuelve los 4 productos más baratos
```sql
-- hestiaAgent.js:28-43  (SQL real capturado por la sonda)
SELECT id, nombre, descripcion, precio, tag_especialidad AS categoria, stock, imagen_url
FROM productos WHERE stock > 0
[AND LOWER(tag_especialidad) LIKE $1]   -- solo si llega category
ORDER BY precio ASC LIMIT 4;
```
`targetIngredients` se calcula con ATENA y se **devuelve en la respuesta**, pero **nunca entra en la consulta**. Sonda P3b: ATENA dice `['Niacinamida 10%', 'Ácido Salicílico']` → HESTIA responde `['Esmalte rojo', 'Shampoo anticaspa']`.

Esto invalida, en código, la afirmación repetida en GIA-09-H, GIA-15-K, GIA-16-M, GIA-17-L y GIA-14-D sobre "subordinación estricta a los activos del plan". Lo que hay es un sesgo al más barato, que es exactamente lo contrario del contrato comercial declarado.

*(Lo que sí se corrigió: ya no fabrica `prod-001`/`prod-002`; devuelve `no_products`.)*

### A-05 · P1 · El RAG regulatorio no puede devolver nada y dice `success`
- `jurisdiction` filtra por `metadata->>'jurisdiction'`, que **no existe** en el corpus (0 de 5.619 según el propio comentario de [ragService.js:135-141](<backend/src/services/ragService.js>)).
- `domain: 'BUSINESS'` se compara contra la categoría canónica; si no está en el vocabulario, se usa el literal → 0 filas.

Resultado: `{ status: 'success', knowledge: [] }`. El modelo recibe "la búsqueda funcionó y no hay nada" y responderá con su memoria, sin señal de que faltan datos. Es el peor modo de fallo posible para una herramienta cuyo propósito es impedir cifras inventadas.

### A-06 · P1 · CHRONOS: hueco de estado y ciclo vencido sin escalado
Sonda P4, sobre `evaluateCycleContinuity`:

| día | estado | comentario |
|---|---|---|
| 15-17 | `DAY_15_RESCAN_DUE` | correcto |
| **18-29** | `IN_PROGRESS_AM_PM` | **regresión**: el hito del día 15 desaparece sin haberse cumplido |
| 30+ | `DAY_30_FINAL_RESCAN` | se queda ahí para siempre |

Un ciclo vencido hace 15 días sigue reportando `actionRequired: 'final_rescan_and_graduation'`, sin urgencia ni escalado. Además `nextMilestoneDay` es un ternario con la misma rama dos veces ([chronosAgent.js:140](<backend/src/services/agents/chronosAgent.js>)) y siempre vale `durationDays`.

### A-07 · P2 · HERMES no calcula disponibilidad, cuenta citas
`checkAvailability` ignora `serviceId` (el tool lo declara y se descarta), no usa `duration_minutes` ni el horario del prestador, y con 0 citas concluye "disponibilidad completa" aunque el local esté cerrado. No detecta colisiones; solo informa cuántas citas hay ese día.

### A-08 · P2 · El bucle es de un solo salto y no valida argumentos
Tras ejecutar las herramientas, `geminiService` hace **una** llamada de síntesis y termina ([geminiService.js:643-720](<backend/src/services/geminiService.js>)). Las cadenas que la documentación describe como orquestadas (ATENA → HESTIA) están **hardcodeadas dentro de HESTIA**, no orquestadas. Y los `args` del modelo no se validan contra el JSON Schema: `trigger_ui_redirection` con `moduleKey: 'no-existe'` devuelve `success` (sonda P6).

### A-09 · P2 · La telemetría miente
```js
// geminiService.js:667-672
toolCalls.push({ name: functionName, args: functionArgs, latency_ms: toolLatency, success: true });
```
`success: true` es literal: se registra igual cuando el tool devolvió `{ error: ... }`. Todo análisis de calidad construido sobre `toolCalls` (incluido el evaluador RAG) hereda esa falsedad.

### A-10 · P2 · El fallo del agente es invisible para el usuario
[chatController.js:164-177](<backend/src/controllers/chatController.js>): se responde `201` y luego `processAssistantMessage(...).catch(console.error)`. Si el LLM, el RAG o el agente fallan, el usuario ve su mensaje enviado y **nunca** una respuesta ni un error.

### A-11 · P2 · 14 herramientas, sin presupuesto ni límite
No hay tope de `tool_calls` por turno ni coste máximo; `tool_choice: 'auto'` deja que el modelo encadene las que quiera en una sola ronda.

### A-12 · P3 · Caché de ATENA 30 días sin invalidación
`beauty:profile:<userId>` con TTL de 30 días ([atenaAgent.js:71](<backend/src/services/agents/atenaAgent.js)). Un re-escaneo no invalida: HESTIA puede recomendar durante un mes ingredientes de un diagnóstico ya superado. (Ya está declarado como "invalidación manual" en el mapa funcional.)

### A-13 · P3 · Argumentos de usuario en claro en los logs
```js
// auraToolExecutor.js:263
console.log(`🛠️ [AURA Orchestration] Ejecutando herramienta: ${toolName}, Args:`, args);
```
Con `queryText` libre del usuario y herramientas biométricas en la lista, esto es una vía de PII a los logs.

---

## 4. Discrepancia documentación ↔ código

| Afirmación en el repo | Dónde | Qué hace el código |
|---|---|---|
| "Hestia: subordinación estricta a los activos del plan" | GIA-14-D, GIA-15-K, GIA-16-M, GIA-17-L, GIA-09-H | Ordena por precio, ignora los activos (A-04) |
| "VALKYRIE propone, no autoriza" | PROPUESTA_REINGENIERIA_360 §D-05 | Devuelve `authorized: true` (A-03) |
| "Cada agente con alcance (*scoped*)" | GLOWAPP_GOVERNANCE_CONTRACTS:350 | `userRole` no se usa; sin allowlist (A-02) |
| "Hestia VERIFIED: filtrado de productos por ingredientes" | GIA-11-C | Filtro por categoría/texto, no por ingrediente (A-04) |
| "Chronos 100% operativo" | GIA-10-K | Hueco de estado 18-29 y sin escalado (A-06) |
| "`search_regulatory_knowledge_rag` responde normativa" | Prompt de AURA, [geminiService.js:426] | Siempre vacío con `success` (A-05) |

Ninguna de estas afirmaciones es una mentira deliberada: son informes que se escribieron mirando el nombre de la función y su descripción, no su `WHERE`.

---

## 5. Hipótesis a verificar (no medida)

**H-A · Las herramientas del chat corren fuera de la transacción de tenant.**
`tenantContext` abre `BEGIN` + `SET LOCAL app.tenant_id` y hace `COMMIT` en `res.on('finish')` ([tenantContext.js:44-48](<backend/src/middleware/tenantContext.js>)). El chat responde `201` **antes** de llamar al LLM, y la ejecución de herramientas ocurre **segundos después** de ese `finish`. Si el `AsyncLocalStorage` de `tenantRouting` sigue apuntando al cliente ya liberado, las consultas de los agentes corren (a) fuera de la transacción —sin `app.tenant_id`, luego 0 filas para un rol sin `BYPASSRLS`— o (b) sobre una conexión devuelta al pool que puede estar sirviendo otra petición.

**Por qué importa:** explicaría por qué los agentes pueden responder "no hay datos" en producción con datos existentes, y sería un problema de aislamiento, no solo de calidad.

**Reproducción propuesta (1 test de integración):** arrancar con PostgreSQL real y `app_rls_user`, invocar `POST /api/chat/messages` hacia AURA con una tool que consulte `bookings`, y registrar `current_setting('app.tenant_id', true)` dentro de la tool. Si devuelve vacío o NULL, la hipótesis queda confirmada.

---

## 6. Lo que sí está bien (para no tirar lo que sirve)

1. **Puerta de consentimiento y propiedad biométrica** ([auraToolExecutor.js:266-305](<backend/src/services/auraToolExecutor.js>)): `ownership_required` + `checkConsent` + `logAccess` antes de tocar el perfil. Es el patrón que falta en VALKYRIE.
2. **Herramienta desconocida rechazada** explícitamente (`default:` → error), probado en `businessRAG.integration.test.js`.
3. **HERMES parametriza todo** el SQL espacial: sin concatenación, con `ST_DWithin` sobre `geography`. Correcto.
4. **HESTIA ya no fabrica productos** cuando la tabla está vacía: `no_products` honesto.
5. **CHRONOS es determinista y barato** ($0/proceso, sin LLM): la decisión de no gastar tokens en aritmética de fechas es acertada.
6. **El orquestador biométrico** es un ejemplo de lo que debería ser el resto: puertas, caché, circuit breakers y trazabilidad.
7. **34/34 pruebas verdes** en las suites de agentes: la infraestructura de pruebas existe y corre rápido (6,4 s).

---

## 7. Plan de corrección (cada fix con su rojo primero)

| # | Fix | Cambio | Test que debe fallar antes |
|---|---|---|---|
| 1 | **A-01** propiedad en VALKYRIE | derivar `providerId` del JWT (como ya hacen las tools de negocio) o exigir `providerId === userId` | `executeAuraTool('get_provider_b2b_insights', {providerId: 777}, 1)` → `ownership_required` |
| 2 | **A-02** RBAC | mapa `rol → tools permitidas`; filtrar también la lista enviada al modelo | cliente pidiendo `get_provider_financial_metrics` → rechazo |
| 3 | **A-03** VALKYRIE honesta | `proposed: true` + `requires_approval` + vigencia y tope; retirar `authorized`; código sin tilde y normalizado | la promo nace `proposed` y con `promoCode` que cumple `^[A-Z0-9-]+$` |
| 4 | **A-04** HESTIA | filtrar por ingrediente (o `JOIN` a la tabla de composición) y no ordenar por precio; si no hay match, `no_match` | con ingredientes de ATENA, un producto sin ellos no aparece |
| 5 | **A-05** RAG regulatorio | devolver `status:'no_data'` cuando el corpus no puede satisfacer los filtros | tool → `no_data`, no `success` vacío |
| 6 | **A-06** CHRONOS | cerrar el hueco 18-29 (`currentDay >= 15 && currentDay < durationDays`) y añadir `CYCLE_OVERDUE` | día 20 → `DAY_15_RESCAN_DUE` o `OVERDUE`, nunca `IN_PROGRESS` |
| 7 | **A-09** telemetría | `success: !toolResult.error` | tool con error → `success: false` |
| 8 | **A-08** validación | `zod` (ya es dependencia) por tool antes del `switch` | `moduleKey:'no-existe'` → error de validación |
| 9 | **A-10** UX de fallo | emitir `notifyUserAuraStatus({state:'error'})` en el `.catch` | test de que un fallo notifica |
| 10 | **H-A** | mover la ejecución de AURA dentro del ciclo de la petición, o abrir contexto de tenant explícito para el trabajo asíncrono | `current_setting('app.tenant_id')` no vacío dentro de la tool |

**No tocar todavía:** el orquestador biométrico (funciona y está bien probado) ni el esquema de tools, hasta cerrar A-01/A-02 — cambiar la superficie antes de cerrar el alcance solo mueve el agujero de sitio.

---

## 8. Cómo reproducir esta auditoría

```bash
# 1. Suites de agentes (34 pruebas)
cd backend
NODE_ENV=test JWT_SECRET=audit_only_secret_key_at_least_32_characters_long \
  npx jest src/tests/atenaAgent.test.js src/tests/sprint2_agents.test.js \
           src/tests/sprint3_agents.test.js src/tests/sprint4_agents.test.js \
           src/tests/auraToolExecutor.test.js --runInBand --forceExit

# 2. Sonda de comportamiento (sin base de datos: inyecta un pool falso)
NODE_ENV=test JWT_SECRET=audit_only_secret_key_at_least_32_characters_long \
  node backend/scripts/auditAgentsBehaviour.js

# 3. El rol del ejecutor no se usa
grep -n "userRole" backend/src/services/auraToolExecutor.js

# 4. El promo no lo consume nadie
grep -rn "createApplyPromoCheckoutAction" backend/src
```
