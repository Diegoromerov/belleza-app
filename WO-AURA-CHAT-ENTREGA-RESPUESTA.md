# WORK ORDER — El chat de AURA entrega la respuesta sólo con un estímulo nuevo (fix + artefacto web desfasado)

> Pega todo este bloque en Antigravity. Es autocontenido: no depende de ninguna conversación previa.
> Trabaja sobre `C:\beauty-app` (clon autoritativo). Hay un segundo clon congelado en `C:\Users\Compu casa\belleza-app` (ago-2026): **no lo uses**.

---

## ROL

Eres el agente implementador del monorepo **Belleza App**. Tu tarea es **una**: que la respuesta de AURA en el chat llegue sola (sin que el usuario tenga que enviar otro mensaje), y que el artefacto web que sirve el backend deje de estar desfasado respecto a la fuente. No abras otros frentes: hay otros trabajos en curso en ramas `feat/glowshop-*` — no los toques.

Clase de fix: **entrega de mensajes en el cliente Flutter + sincronización del bundle web**. Los hallazgos de RAG/agentes/jobs que están al final de este documento son **otra orden**: no los arregles aquí.

## CONTEXTO — medido, no supuesto

Síntoma reportado por el dueño (usuario 7): escribe "Hola" al chat de AURA, la respuesta no aparece; al escribir un segundo mensaje aparece la respuesta del primero y el segundo se queda "pegado". Con preguntas simples o complejas, igual.

Todos los datos siguientes están **verificados**: los logs son de producción (Railway CLI, servicio `production`, deploy = `main@7ad01a0f` del 2026-09-24T06:14:33Z) y los conteos salen de ejecutar los comandos en `C:\beauty-app`.

**La respuesta de AURA sí se genera y se guarda.** Secuencia real de los logs del 2026-09-24:

```
14:26:36 🔌 Nuevo cliente WebSocket conectado.
14:26:36 WebSocket auth fallida: Falta el token JWT      ← la conexión NO queda registrada
14:26:36 🤖 Respuesta de AURA enviada con éxito al usuario 7.
14:26:56 ... 14:27:16 ... 14:27:37                        ← ~20 s entre cada una: el usuario reenviando
14:29:09 🔌 Nuevo cliente WS + "WebSocket auth fallida: Falta el token JWT"
14:29:28 / 14:29:48 / 14:30:38 (x2) / 14:30:44 🤖 Respuesta de AURA enviada con éxito al usuario 7.
06:15:28 👤 Conexión WS registrada para usuario: 7          ← sesión de esa mañana, con registro correcto
```

Latencia real del modelo, medida en los mismos logs: `14:30:40.060 Invocando DeepSeek API` → `14:30:44.576 Respuesta de AURA enviada con éxito` = **4,5 s**. No hay lentitud de AURA: cuando el usuario la ve "pegada", la respuesta ya lleva segundos guardada en `messages`.

Cadena causal, con anclas:

- `backend/src/controllers/chatController.js:143-176` — el POST inserta el mensaje, responde `201` y lanza `processAssistantMessage` en background. El cliente NO recibe la respuesta por HTTP.
- `backend/src/services/geminiService.js:1000-1012` — AURA inserta su respuesta en `messages` y luego llama a `notifyUserAuraStatus(idle)` y `notifyUserChatMessage(parsedUserId, formatted)`.
- `backend/src/services/websocketService.js:30-43` (y `:45-58`) — esos `notify*` son **no-op** si el userId no está en `wsClients`: sin registro no hay push, sin error.
- `backend/src/services/websocketService.js:69-87` — el `register` exige JWT (`:74-76` lanza `Falta el token JWT`). **Esto NO se revierte**: es la remediación A360-2026-09-22/C-04.
- `frontend/lib/screens/chat_screen.dart:207-226` (versión en `origin/main`) — el único sondeo de respaldo se activa **sólo** cuando la conexión WS falla (`_handleWebSocketFailure`). En producción la conexión **abre bien** (verificado: `101 Switching Protocols` contra `wss://belleza-app-production.up.railway.app/chat`), así que el respaldo nunca entra.
- `frontend/lib/screens/chat_screen.dart:152-155` — además cancela el sondeo con **cualquier** mensaje entrante (incluido el acuse o un error del servidor).
- `frontend/lib/screens/chat_screen.dart:438-439` — por eso el único refresco efectivo es el `_loadMessages()` que dispara el envío siguiente: explica exactamente el síntoma "responder la 1 al enviar la 2".
- **El bundle servido es viejo**: `backend/public/main.dart.js` (blob del commit `fc41905a`, 19-sep) es un artefacto **committeado**; `backend/Dockerfile` no compila Flutter (sólo `npm ci`). El archivo descargado de producción mide 5.752.502 bytes y coincide con ese blob. Dentro del JS compilado está el payload viejo: `["type","register","userId",this.x]` → de ahí el `Falta el token JWT`. La corrección de `chat_screen.dart` que hizo 451e538b (22-sep) **nunca llegó a producción** porque nadie reconstruyó el bundle.
- `frontend/lib/screens/chat_screen.dart` (main) — el `aura_status` se lee mal: el servidor envía `{type:'aura_status', data:{state:...}}` (`geminiService.js:348` y `:1011`) y el cliente lee `data['state']` (siempre `null`), así que el indicador "AURA está pensando" se apaga al instante. Confirmado también dentro del bundle desplegado.
- `frontend/lib/services/auth_service.dart:129-132` (main) — `getToken()` lee **sólo** `SecureStorageService().read('token')`, sin `try/catch` y sin el fallback a `SharedPreferences` que sí tiene `ApiService._getToken` (`frontend/lib/services/api_service.dart:187-202`). Si el almacenamiento cifrado no está o lanza (habitual en Flutter Web), devuelve `null` y el WS del chat no se registra **en silencio**.
- `backend/src/middleware/rateLimiter.js:32-42` — límite real de los endpoints de chat: **100 req / 15 min por usuario**. Un sondeo a 3 s gasta la cuota en ~2,5 min (el fallback actual se auto-sabotea).

**Bases medidas en `origin/main` @ `7ad01a0f` (mismo entorno y mismos comandos que usarás):**

- `cd frontend && flutter analyze lib` → **474 issues** (todos info/warning preexistentes).
- `cd frontend && flutter analyze lib/screens/chat_screen.dart lib/services/auth_service.dart` → **3 issues** (3 × `prefer_const_constructors`/`prefer_const_literals_to_create_immutables`).
- `cd frontend && flutter test` → **35 pasan / 4 fallan**. Fallos, con nombre exacto (son preexistentes y fallan igual sin tocar nada):
  - `test/golden/phase5_goldens_test.dart`: `Phase 5 Golden Tests (390x844) BookingScreen - Step 1 (Cuándo y Dónde)`, `Step 2 (Productos)`, `Step 3 (Confirmación / Pago)`
  - `test/widget_test.dart`: `BeautyApp carga correctamente`
- `backend/public/main.dart.js`: `grep -c '"type","register","userId"'` → **1**, `grep -c 'sin token'` → **0** (el bundle no tiene el fix).

**Aviso crítico sobre los tests actuales**: no existe ningún test que cubra el chat de AURA ni la entrega de la respuesta (no hay `test/` para `ChatScreen`; los 4 rojos de arriba son de BookingScreen y arranque de app). Nadie afirma el comportamiento defectuoso, pero **tampoco hay red**: por eso esta orden exige crear el guardián, no sólo arreglar.

**Implementación de referencia (no mergeada, no pusheada)**: rama local `fix/aura-chat-entrega-respuesta` (commit `3e7b8a35`, worktree `C:\beauty-fix-aura`) contiene el fix de cliente ya aplicado y verificado con los análisis/tests de arriba. Puedes usarla como referencia o descartarla; **el PR debe salir de `origin/main`** y la evidencia se exige igual.

## ALCANCE

### A. Borrar

| Ruta | Qué es |
|---|---|
| — | Nada. Esta orden no borra archivos. |

### B. Editar

1. `frontend/lib/screens/chat_screen.dart` — re-verifica los números de línea antes de editar (las anclas de texto son la verdad, están citadas abajo).
2. `frontend/lib/services/auth_service.dart` — sólo el método `getToken()`.
3. `backend/public/main.dart.js` — **no se edita a mano**: se reemplaza por el resultado de un `flutter build web` real (ver ENTREGA).

### C. Crear

1. `frontend/lib/services/reply_reconcile.dart` — mecanismo de espera de respuesta en una clase **testeable sin HTTP ni WebSocket** (recibe un callback de fetch y un reloj/timers inyectables o usa `Timer` con `fakeAsync` en el test).
2. `frontend/test/chat_reply_delivery_test.dart` — guardián unitario del punto 1.
3. Rama nueva desde `origin/main`: **`fix/aura-chat-entrega-respuesta`** (ya existe local con el commit de referencia: si la reutilizas, parte de `origin/main` y no arrastres nada más). Nunca commit a `main`.

### D. NO TOCAR

- ❌ `backend/src/services/websocketService.js` — el requisito de JWT en el `register` es decisión ya tomada (A360-2026-09-22/C-04). No lo relajes, no lo comentes con TODO, no aceptes `userId` sin token.
- ❌ `frontend/lib/screens/provider_dashboard_screen.dart` y `frontend/lib/screens/booking_tracking_screen.dart` — **usan el mismo patrón** `{'type':'register','token':...}` en otros dos sitios. Ahí ya está bien; no los refactorices ni los "unifiques".
- ❌ `backend/src/services/geminiService.js`, `ragService.js`, `auraToolExecutor.js`, `src/jobs/*`, `backend/migrations/*` — los errores de RAG/agentes/jobs son otra orden (listados al final a modo de contexto).
- ❌ ramas `feat/glowshop-*`, `.env`, credenciales, `frontend/build/**` (artefacto local regenerable; lo que sirve producción es `backend/public/main.dart.js`).
- ❌ No hagas `force-push`, no mergees, no toques `main`.

## CORRECCIONES EXACTAS

| Ancla actual (versión en `origin/main`) | Correcto | Nota / cómo verificarlo |
|---|---|---|
| `frontend/lib/screens/chat_screen.dart:207-226`: `// Fallback: Start 3-second auto-polling for messages if not running` + `Timer.periodic(const Duration(seconds: 3)` | Sondeo de respaldo a **10 s**, sin `_markAsRead()` en cada tick | El límite es 100/15 min por usuario (`rateLimiter.js:32-42`): a 3 s y con `_markAsRead` por tick se agota la cuota en ~2,5 min |
| `chat_screen.dart:152-155`: `// Stop polling timer if connected` + cancelación del timer dentro del listener | Cancelar el sondeo **sólo** con un push real `{"type":"chat_message"}`, nunca con el acuse ni con `{error}` | Hoy cualquier mensaje lo cancela, y el acuse `{status:'registered'}` es un mensaje |
| `chat_screen.dart:159-163`: `if (data is Map && data['type'] == 'aura_status') { final state = data['state'];` | Leer el estado **anidado**: `data['data'] is Map ? data['data']['state'] : null` | `websocketService.js:45-58` envía `{type,data:{state}}`; `geminiService.js:348` y `:1011` son los emisores |
| `chat_screen.dart:191-205`: `void _registerWebSocket()` que envía el token y **no** espera acuse | Tras enviar el `register`, armar un **watchdog de 6 s**; si no llega `{"status":"registered"}` (`websocketService.js:82`) o llega `{error}`, activar la reconciliación | El ack tarda ms; 6 s es margen sobre red móvil. Documenta el número elegido |
| `chat_screen.dart:438-439` (`_sendMessage`): `await ApiService.sendChatMessage(...); await _loadMessages(...)` | Tras el POST, si el socio es AURA (`_isAiPartner`), **arrancar la reconciliación** antes del `_loadMessages` | Es lo que garantiza la entrega cuando el push no existe |
| `chat_screen.dart:` `_loadMessages` → `if (isLastMsgAi) { stillThinking = false; _auraThinkingTimeout?.cancel(); }` | Añadir el **stop de la reconciliación** cuando el último mensaje es de AURA | Cierra el ciclo: si aterrizó, deja de sondear |
| `chat_screen.dart:` `_sendInitialMessage` (`await ApiService.sendChatMessage(widget.partnerId, text, imagePath: ...)`) | Igual que en `_sendMessage` (arrancar reconciliación si `_isAiPartner`) y pararla en el `catch` | El chat abierto con mensaje inicial es el mismo caso |
| `chat_screen.dart:` `dispose()` (`_pollingTimer?.cancel(); _reconnectTimer?.cancel(); _auraThinkingTimeout?.cancel();`) | Cancelar también los timers nuevos (watchdog y reconciliación) | Fuga de timers = setState tras dispose |
| `frontend/lib/services/auth_service.dart:129-132`: `static Future<String?> getToken() async { return await SecureStorageService().read('token'); }` | `try/catch` + fallback a `SharedPreferences` (`prefs.getString('token')`), devolviendo `null` sólo si tampoco hay | Réplica exacta del patrón ya existente en `api_service.dart:187-202` |
| `frontend/lib/services/reply_reconcile.dart` (nuevo) | Intervalo **4 s**, ventana máxima **90 s**, se detiene por: llegada de push, último mensaje de AURA, o deadline | 4 s × 90 s ≈ 23 fetches, dentro de la cuota; declara la aritmética en el PR |

**Valores que no debes inventar**: si el servidor cambia el nombre del acuse o de los tipos de mensaje, léelos en `websocketService.js` (`register`→`{status:'registered', userId}`; `notifyUserChatMessage`→`{type:'chat_message', data}`; `notifyUserAuraStatus`→`{type:'aura_status', data:{state}}`). Si dudas del intervalo, mide: envía un mensaje a AURA y cronometra con los logs.

## VERIFICACIÓN OBLIGATORIA

Ejecuta **cada** comando y pega su salida **real** (no la resumas, no la inventes):

```bash
# 1. Guardián unitario de la espera de respuesta — con su ANTES (ROJO) y su DESPUÉS (VERDE)
cd frontend && flutter test test/chat_reply_delivery_test.dart; echo "exit=$?"
#    ROJO la primera vez (el archivo no existe / el mecanismo no está extraído), VERDE al final.

# 2. El bundle servido ya no lleva el payload viejo
grep -c '"type","register","userId"' backend/public/main.dart.js     # esperado: 0
grep -o '"type","register","[a-zA-Z]*"' backend/public/main.dart.js | sort | uniq -c   # esperado: sólo "token"
grep -c 'sin token' backend/public/main.dart.js                      # esperado: >=1 (código nuevo presente)

# 3. Analyze: mismas cifras que la base
cd frontend && flutter analyze lib | tail -2                    # esperado: 474 issues (ni uno más)
cd frontend && flutter analyze lib/screens/chat_screen.dart lib/services/auth_service.dart | tail -2   # esperado: 3 issues

# 4. Suite completa — compara contra la base medida, no contra tu memoria
cd frontend && flutter test 2>&1 | tail -12
#    BASE = 35 pasan / 4 fallan (los 4 nombres están listados arriba).
#    Tu rama = ? Pega los dos números: +N pasan / 4 fallan (los mismos 4 nombres).
#    Si el conteo de rojos CAMBIA y no es por un test que reescribiste, NO lo escondas: repórtalo crudo.

# 5. Prueba E2E de la entrega (el síntoma del dueño, en las dos direcciones)
#    a) REPRODUCCIÓN DEL BUG (control): en una build de prueba, no envíes el `register`
#       (simula producción: el servidor no empuja). Manda "Hola" a AURA y NO mandes nada más.
#       → con el fix: la respuesta aparece sola en ≤8 s.
#       → sin el fix (main): no aparece hasta mandar otro mensaje.
#    b) CONTROL POSITIVO: con el register intacto, debe llegar {status:'registered'} y la
#       respuesta por push en <2 s, sin logs de reconciliación.
#    Evidencia: hora del mensaje y de la burbuja de respuesta (captura o log del cliente con
#    `WS chat: ...`), más la línea del servidor de esa misma ventana.
```

## GUARDIÁN

El guardián de esta orden son **tres capas**, y las tres deben verse ROJO antes y VERDE después. Pega ambas salidas.

1. **Capa unitaria** — `frontend/test/chat_reply_delivery_test.dart`: con timers falsos (`fakeAsync`), comprueba que (a) al arrancar consulta de inmediato y luego cada 4 s; (b) se detiene solo cuando el último mensaje es de AURA (`sender_id == '0'`); (c) se detiene al recibir un push `chat_message`; (d) se detiene al vencer los 90 s. Sin HTTP, sin WebSocket, sin backend.
2. **Capa artefacto** — los greps del punto 2 de la verificación, sobre `backend/public/main.dart.js`. Es la capa que responde "¿el fix llegó al usuario?": hoy está ROJO porque el bundle es del 19-sep.
3. **Capa E2E** — la prueba del punto 5, con sus dos direcciones y con la hora de cada evento.

**El guardián no debe ensuciar el estado compartido**: la capa E2E escribe mensajes reales. No uses la cuenta del dueño (usuario 7): crea/usa un usuario de prueba, y registra en el PR el conteo de `messages` de ese usuario **antes y después** de correr el guardián (y de `aura_knowledge_chunks`/`rag_query_logs` si tu corrida los toca). Si los conteos no coinciden con lo declarado, el guardián falla.

## ENTREGA

- Rama `fix/aura-chat-entrega-respuesta` cortada de **`origin/main`** (`7ad01a0f`), commits pequeños, mensajes en español.
- **Reconstrucción del artefacto web** (esto es parte de la entrega, no un extra):
  ```bash
  cd frontend && flutter build web --release        # requiere ≥3 GB libres en C:
  # copiar el contenido de build/web/* a backend/public/  (mismo procedimiento del commit fc41905a "synced web build")
  ```
  Prerrequisito medido: **C: está al 100 % (≈1,9 GB libres)** y `C:\beauty-app\frontend\build` ocupa **3,1 GB** (regenerable). Libera espacio antes; si el build falla por disco, repórtalo, no lo maquilles.
  Si el dueño prueba en Android, el APK también debe recompilarse: dilo en el PR y no publiques un APK sin pedirlo.
- PR contra `main` con: qué se cambió (`archivo:línea` antes/después), salida ROJA→VERDE de las tres capas del guardián, `BASE = 35/4` y `TU RAMA = ...` de la suite, la URL del PR (no "PR Link 1"), `git log -1 --format='%h padre=%p'` de la rama, y las preguntas abiertas.
- **Entregado ≠ usable**: declara explícitamente en el PR que el fix sólo es usable **después** de desplegar el bundle reconstruido (el backend sirve el artefacto committeado y el Dockerfile no compila Flutter).
- Formato de evidencia: `archivo:línea` + salida real del comando. Sin "todo funciona".

## PROHIBICIONES

- No inventes salidas de comandos ni conteos de tests. Si algo falla, repórtalo tal cual.
- No introduzcas datos de relleno bajo ningún nombre (`fallback`, `demo`, `sample`) ni "respuestas" simuladas de AURA para tapar una espera.
- No "arregles" el síntoma bajando la exigencia de token en el WebSocket ni aflojando el rate limiter en producción sin que el dueño lo decida: la entrega se arregla en el cliente.
- No edites `backend/public/main.dart.js` a mano (ni minifiques/parchees el JS): se reemplaza por un build real.
- No hagas migraciones de esquema ni toques la base de producción fuera del usuario de prueba del guardián.
- No toques `.env`, credenciales, ni las ramas `feat/glowshop-*`.
- Si encuentras otro consumidor del mismo patrón de registro WS que esta orden no lista, **párate y repórtalo** antes de arreglarlo.

## PREGUNTAS ABIERTAS QUE DEBES DEVOLVER EN EL PR

1. ¿El bundle web se sigue committeando a mano en `backend/public/` o entra el `flutter build web` a CI? Si entra, ¿con qué runner (hoy `ci.yml` sólo corre tests y no compila Flutter)? El artefacto lleva desfasado desde el 19-sep y esa es la causa de que el fix del 22-sep no llegara nunca.
2. Límite de chat 100 req/15 min por usuario: ¿se sube para permitir el sondeo de respaldo, o se mantiene y aceptamos que el respaldo sea más lento?
3. Conversaciones humano-humano: ¿se mantiene el sondeo continuo cuando el WS no está disponible (hoy propuesto a 10 s) o se prefiere sólo push con un aviso de "reintentando"?
4. ¿Se recompila y publica también el APK, y dónde (el `GlowApp-release.apk` de la raíz está fuera de git)?

## DEFINICIÓN DE TERMINADO

1. `chat_reply_delivery_test.dart` existe y pasa; su salida ROJA inicial está pegada.
2. `grep -c '"type","register","userId"' backend/public/main.dart.js` → 0, y el bundle reconstruido contiene el código nuevo (`sin token`).
3. `flutter analyze` de los dos archivos → 3 issues (los mismos de la base) y `flutter analyze lib` → 474.
4. `flutter test` → mismos 4 rojos con los mismos nombres; los dos números (BASE / tu rama) pegados en el PR.
5. Prueba E2E (a) y (b) ejecutada con horas reales: la respuesta de AURA aparece **sin** un segundo estímulo.
6. PR abierto contra `main` con URL, padre de rama, y "entregado vs usable" declarado (usa el bundle desplegado).

---

## Contexto fuera de alcance (otra orden — no lo toques aquí)

Medido en los mismos logs de producción del 2026-09-24, para que quede registrado y no se pierda:

- RAG degradado en cada consulta: `Request failed with status code 410` (embeddings NVIDIA EOL) y el fallback full-text muere con `column "tenant_id" does not exist` → `📚 Chunks RAG recuperados:` vacío: AURA responde sin corpus.
- `❌ Error escribiendo rag log: EACCES: permission denied, mkdir '/app/logs'` → no se escriben las trazas RAG.
- Herramientas de AURA con SQL roto: `column s.tag_especialidad does not exist` (`search_nearby_services`), `operator does not exist: estado_cita = character varying` (`check_provider_availability`).
- Jobs: `permission denied for table bookings` (notificaciones de retención), `permission denied for table platform_config` (retiros automáticos), `column "creado_en" does not exist` (pricing dinámico).
- 4 migraciones con warning en cada boot: 035 (`$libdir/vector`), 046 (`metadata`), 048 (`chunk_id`), 054 (`uuid_generate_v4`).
