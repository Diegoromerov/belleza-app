# PQRSF en el panel admin — plan de construcción

**Meta:** que un PQRSF creado en la app (a) llegue a una bandeja en el dashboard, (b) recorra toda la línea de
gestión desde ahí, (c) notifique al implicado por correo, (d) deje la respuesta también dentro de la app,
(e) mida los tiempos de respuesta, y (f) quede listo para que un agente automatice respuestas en el futuro.

**Hecho medido, no supuesto:** el panel no tiene **ni una** referencia a PQRSF
(`grep -rli "pqrsf|pqrs" admin-dashboard/src` → 0 resultados). La app sí los crea. El backend tiene el modelo
y 4 endpoints, pero **ningún endpoint de administración** (cambiar estado/prioridad, responder como operador,
métricas) y **ningún envío de correo** en este flujo.

---

## 1. Estado real (con evidencia `archivo:línea`)

| Capa | Estado | Evidencia |
|---|---|---|
| Esquema | ✅ Existe | `migrations/007_soporte_y_pqrsf.sql` — `tickets` + `ticket_mensajes` |
| Tipos | ✅ 6, incluye legal | `007:7` + `045:11` añade `ARCO_SUPRESION` (Ley 1581/2012) |
| Estados | ✅ 5 | `007:11` — `ABIERTO`, `EN_PROCESO`, `ESPERANDO_RESPUESTA_USUARIO`, `RESUELTO`, `CERRADO` |
| Prioridades | ✅ 4 | `007:12` — `BAJA`, `MEDIA`, `ALTA`, `EMERGENCIA` |
| Dueños del esquema | ✅ Uno solo | `tickets` no se crea en `init.sql` ni en el DDL de `index.js`: solo en migraciones (sin la deriva de 4 dueños) |
| Crear desde la app | ✅ | `POST /api/tickets` → `ticketController.createTicket:6` |
| Listar el usuario | ✅ | `GET /api/tickets/my-tickets` → `:47` |
| **Listar como admin** | ✅ **ya funciona, sin UI** | `:50` `is_admin = req.user.role === 'admin'` → sin `WHERE` devuelve **todos** |
| Hilo de mensajes | ✅ con rama admin | `GET/POST /api/tickets/:id/messages` → `:82`, `:127` |
| Cambiar estado / prioridad | ❌ **no existe endpoint** | el estado solo cambia implícito al responder (`:168`) |
| Correo al implicado | ❌ **nada** | no hay un solo `sendEmail` en el flujo de tickets |
| Tiempos de respuesta | ⚠️ derivables, no explícitos | `ticket_mensajes.fecha_envio` + `tickets.fecha_creacion`, sin columnas ni métricas |
| UI en el dashboard | ❌ **cero** | — |
| "Agente que responda" | ❌ | no hay nada que distinga autor humano de automático |

**Por qué la rama de admin sí funciona** (cadena verificada, porque de esto depende todo):
`usuarios.rol = 'ADMIN'` (seed `src/config/db.js:123`, comprobación `src/controllers/adminAuthController.js:60`)
→ `toApiRole('ADMIN')` devuelve `'admin'` (`src/config/jwt.js:49`) → `req.user.role === 'admin'` es `true`
(`src/middleware/auth.js:79`) → el guard de `ticketController:50` se activa. Y `requireRol('admin')`
(`src/middleware/roles.js:21`) ya existe para gatear endpoints nuevos.

---

## 2. Defectos encontrados de paso (con evidencia)

| # | Defecto | Evidencia | Impacto |
|---|---|---|---|
| A | **La validación de respuesta nunca rechaza un mensaje vacío** | `ticketController.js:134` `mensaje.trim().isEmpty` — `isEmpty` no existe en JS, así que evalúa `undefined` (falsy) y el `400` no salta | Se pueden insertar respuestas en blanco. Es LA ruta que vamos a usar |
| B | **Correo de carrito abandonado revienta** | `src/services/emailService.js:16` hace `require('nodemailer')` y `nodemailer` **no está en `package.json` ni en `node_modules`** | Ese cron falla en runtime |
| C | **Todo el correo del sistema está en modo simulación** | `email.service.js:79-85`: sin `RESEND_API_KEY` ni `SENDGRID_API_KEY` imprime en consola y devuelve `success:true` **sin enviar** | Cualquier correo que construyamos no sale. Afecta también al OTP de recuperación de contraseña |
| D | `createTicket` no valida `tipo` ni `categoria` | `:11` valida solo que vengan; los valores los valida el `CHECK` de la tabla | Un valor inválido da **500 genérico** en vez de 400 (misma familia que el bug de `'ATENDIDO'`) |
| E | No se puede nacer un ticket con prioridad | `:16` no inserta `prioridad` | Todo entra como `MEDIA`; una EMERGENCIA no se puede marcar |

**Sobre C, importante:** las claves **no están en el `.env` local** (comprobado solo su presencia, sin leer
valores: `RESEND_API_KEY`, `SENDGRID_API_KEY`, `EMAIL_FROM`, `EMAIL_FROM_NAME` → ninguna aparece). En
producción **no lo di por supuesto**: busqué los marcadores del servicio en los logs de Railway
(`EMAIL SERVICE SIMULATION` / `Correo enviado exitosamente vía Resend`) y hay **0 de ambos**, o sea que no hay
evidencia de que se haya enviado ni de que se haya simulado (nadie disparó un correo en la ventana de log).
**Hay que confirmarlo, y es bloqueante para la fase 3.**

---

## 3. Decisiones tomadas (confirmadas por el Dueño)

- **D1 — Proveedor de correo: se deja en simulación por ahora.** No se configura clave ni dominio todavía.
  **Consecuencia que hay que arreglar igualmente:** `email.service.js` devuelve `{success:true}` cuando cae al
  modo simulación (`:79-85`) **sin haber enviado nada**. Eso es una mentira en la API del servicio: quien lo
  llame no puede distinguir "enviado" de "simulado". La fase 3 cambia ese contrato a
  `{success, provider: 'simulation'|'resend'|'sendgrid', enviado: boolean}` y **registra `enviado=false` en la
  base**, para que el panel muestre la verdad. Es requisito previo para poder afirmar cualquier cosa sobre
  notificaciones.
- **D2 — SLA: el tramo estricto.** `EMERGENCIA 30 min · ALTA 2 h · MEDIA 8 h · BAJA 48 h`.
  **Primera respuesta = primer mensaje de un `OPERADOR` o `AGENTE`** (no cuenta el eco del usuario).
- **D3 — `ARCO_SUPRESION`: flujo aparte con plazo legal visible.** Se calcula su fecha límite a **15 días
  hábiles** (Ley 1581/2012) y se avisa al vencer. **Detalle a decidir en la fase 1:** los días hábiles
  excluyen fines de semana, pero **no los festivos colombianos** salvo que añadamos un calendario. Se
  implementa "sin festivos" y se deja la puerta abierta (tabla de festivos) — no quiero que un plazo legal
  dependa de un cálculo que parece correcto y no lo es.
- **D4 — Agente: solo la costura.** `ticket_mensajes.autor_tipo` + `POST /admin/tickets/:id/sugerencia`, que
  guarda un **borrador** y **nunca envía** hasta que un operador lo aprueba. Sin integración con `ai_worker`
  todavía.
- **D5 — Correo saliente: primero solo a una dirección de prueba.** Toda la fase 3 sale con un interruptor de
  modo: `TICKETS_EMAIL_MODO=prueba` + `TICKETS_EMAIL_PRUEBA_TO=<tu dirección>`, y **solo envía a esa
  dirección** mientras esté en modo prueba. La variable la defines tú (no necesito saber la dirección); sin
  ella, el modo por defecto es simulación.

---

## 4. Fases propuestas

Cada fase es desplegable por sí sola y no deja el sistema a medias.

### Cómo se aplican las migraciones (verificado, define el riesgo de F1)

`index.js:1613-1683`: al arrancar, el backend lee `migrations/*.sql` en orden alfabético, **salta los
`.down.sql`** (un rollback solo lo corre un humano) y aplica lo que no esté en `schema_migrations`. Consecuencias:

- Un `.sql` nuevo en la carpeta **se aplica solo en producción al desplegar**, sin paso manual.
- Se registra con un **checksum**: si después editas el archivo, avisa de la deriva y **no lo re-aplica**.
  Por eso: si algo hay que corregir, va en una migración NUEVA, nunca editando la ya aplicada.
- **Si falla, NO se registra** → se reintenta en cada arranque. Y el archivo entero va en una sola llamada, así
  que un fallo revierte el conjunto (no deja esquema a medias).
- Todo debe ser **idempotente** (`IF NOT EXISTS`) porque el modo sin registro re-aplica todo.

### Fase 1 — Cimiento: tiempo de respuesta explícito · **HECHA** (`b08951417`)

**Verificación de cierre:** backend en producción sirviendo `b08951417` y el arranque
registró `✅ Base de datos: Migración 081_pqrsf_sla_y_autor.sql aplicada exitosamente.`
Guards: `backend/tests/pqrsfSla.test.js` 19/19 con 5 mutaciones probadas, guard de
numeración de migraciones 7/7, panel 66/66. La migración se ejecutó además contra un
Postgres 16 real (esquema `007`+`045` + datos sintéticos): backfill correcto, idempotente
(re-aplicar no cambia ningún dato) y rollback que no toca la conversación.

Añadir a `tickets` (migración `08x`, idempotente) las columnas que hoy hay que deducir, y poblarlas **al
escribir** (no calculadas al leer, para que el reporte sea una consulta trivial y no un `JOIN` frágil):

- `primera_respuesta_en TIMESTAMPTZ` — primer mensaje de operador/agente
- `resuelto_en`, `cerrado_en TIMESTAMPTZ`
- `sla_vencido BOOLEAN` derivado, o mejor un helper puro `slaDe(prioridad)` con los plazos de D2
  (`EMERGENCIA 30 min · ALTA 2 h · MEDIA 8 h · BAJA 48 h`)
- `ticket_mensajes.autor_tipo VARCHAR(10) CHECK (autor_tipo IN ('USUARIO','OPERADOR','AGENTE'))`

**Backfill** de lo existente: `primera_respuesta_en` = `MIN(fecha_envio)` de los mensajes no del usuario;
`resuelto_en` para los ya `RESUELTO`. Sin backfill, el reporte de tiempos arranca mintiendo.

Tests: helper de SLA puro (probado con valores), y aserción de que el backfill cuadra contra los datos reales.

### Fase 2 — Endpoints de gestión (gateados con `requireRol('admin')`)

- `GET /api/admin/tickets` — bandeja: filtros `estado`, `tipo`, `categoria`, `prioridad`, `sin_respuesta`,
  `vencidos`; paginación con `{success,page,limit,total,data}` (convención de casa); orden por antigüedad.
- `GET /api/admin/tickets/:id` — detalle + hilo + tiempos y si el SLA está vencido.
- `PATCH /api/admin/tickets/:id` — `estado` y `prioridad`, validando **contra los valores reales de los CHECK**
  leídos del esquema, no contra una lista del controlador (la lección de `'ATENDIDO'`).
- `POST /api/admin/tickets/:id/respuesta` — mensaje + transición de estado + **envío de correo** + escritura de
  `primera_respuesta_en` si es la primera.
- `GET /api/admin/tickets/metricas` — tiempo medio de primera respuesta y de resolución, por prioridad, y
  cuántos vencidos.

Arreglo incluido del defecto **A** (`:134`), porque es la ruta de respuesta.

Tests de contrato: el guardián de rutas ya compara **(método, camino)** — añadir estos endpoints hará que
cualquier `fetch` del panel sin contraparte real salga rojo.

### Fase 3 — Correo (D1: simulación ahora · D5: solo dirección de prueba)

- Plantillas de PQRSF en `email.service.js` (el servicio que **sí** funciona), con `sendTicketReply`.
- Envío en la respuesta y en el cierre, **registrando el resultado real en la base**
  (`correo_enviado BOOLEAN`, `correo_proveedor TEXT`, `correo_error TEXT`). Primero hay que arreglar la mentira
  del servicio (`success:true` en simulación) o el registro diría "enviado" siempre.
- **Interruptor de modo** (`TICKETS_EMAIL_MODO=prueba` + `TICKETS_EMAIL_PRUEBA_TO`): en modo prueba el correo
  sale SOLO a esa dirección, y cada envío bloqueado se registra como tal (no como fallo silencioso).
- **Que el fallo de correo no tumbe la respuesta**: se guarda el mensaje, se marca el correo como fallido y se
  muestra en la bandeja. Un correo caído no puede perder la gestión.
- Arreglo del defecto **B** (el `require` de `nodemailer`): o se declara la dependencia, o ese servicio se
  reescribe sobre `email.service.js`. Recomendación: **eliminar el servicio duplicado** y unificar en uno.

### Fase 4 — UI del panel

- `/admin/pqrsf` — bandeja con: contadores por estado y prioridad, semáforo de SLA (vencido / por vencer),
  filtros, y paginación (la de `/admin/precios` ya enseña el patrón).
- Detalle con el hilo completo, caja de respuesta, cambio de estado y prioridad, y botón de cierre.
- Enlace en `Sidebar.tsx` (grupo admin, junto a "Alertas SOS").
- Estados vacíos y errores explícitos: **nada dentro de un `if (res.ok)` silencioso** (fue la causa de que el
  catálogo pareciera otro sistema).

### Fase 5 — Cierre y verificación

- Métricas visibles en el dashboard raíz (junto a los contadores actuales).
- Tests: contrato de rutas, contrato de forma de la respuesta, y el cálculo de SLA por mutación.
- Actualizar `docs/` con el flujo y los estados (la base de conocimiento del repo).

### Fase 6 — Costura para el agente (D4: solo la costura)

- `POST /api/admin/tickets/:id/sugerencia` → devuelve un **borrador** que se guarda como `autor_tipo='AGENTE'`
  en estado borrador (`es_borrador BOOLEAN`), **nunca envía solo**; un operador aprueba y recién ahí sale el
  correo. Sin integración con `ai_worker` en esta ronda.
- `autor_tipo` y las métricas de SLA son también el instrumento para medir si el agente mejora los tiempos.

---

## 5. Archivos que se prevé tocar

- `backend/migrations/08x_pqrsf_sla_y_autor.sql` (nuevo)
- `backend/src/controllers/ticketController.js` (arreglo A, y/o un `adminTicketController.js` nuevo)
- `backend/src/routes/ticketRoutes.js` + `backend/src/routes/adminTicketRoutes.js` (nuevo) + montaje en `backend/index.js`
- `backend/src/services/email.service.js` (plantillas) y unificación con `emailService.js` (defecto B)
- `backend/src/utils/ticketSla.js` (nuevo, helper puro y testeable)
- `admin-dashboard/src/app/(dashboard)/admin/pqrsf/page.tsx` + detalle; `components/dashboard/Sidebar.tsx`
- `admin-dashboard/src/app/api/[...path]/route.ts` (**allowlist del BFF**: sin esto la pantalla nueva da 404 del portero — es el error documentado que ya costó una ronda)
- Tests: `admin-dashboard/tests/api-routes-contract.test.mjs` (se extiende solo), y un contrato de forma nuevo

## 6. Riesgos

- **El correo real es el punto delicado**: es un efecto externo e irreversible, y hoy el servicio devuelve
  `success:true` sin enviar. Hay que arreglar esa mentira antes de confiar en cualquier métrica de notificación.
- **SLA y ARCO son decisiones de negocio y legales**: no las invento (D2, D3).
- **Tercer dueño del esquema**: las columnas nuevas van en migración, y el proyecto ya arrastra el problema de
  los 4 dueños del esquema — no añado un quinto (nada de DDL en `index.js`).
- **Árbol compartido**: el HEAD vive en la rama de otro agente. Todo commit irá con rutas explícitas y a `main`
  por worktree, verificando `git ls-remote origin main` después.

## 7. Verificación de cada fase

```bash
node --check <archivos backend> && npx tsc --noEmit && npm test && npm run build
# y mutación del helper nuevo: reponer el cálculo viejo y ver el test fallar
```

Cierre de fase: backend desplegado (commit vivo en `/api/health`) y frontend con el tamaño de ruta nuevo en la
tabla del build de Railway — no basta el push.
