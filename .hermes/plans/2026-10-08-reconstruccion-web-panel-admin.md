# Plan de construcción — hacer funcional la web (panel admin Glow)

**Fecha:** 2026-10-08
**Alcance auditado:** `admin-dashboard/` (Next.js 15 App Router) + `backend/` (Node/Express) + `backend/migrations/` (PostgreSQL)
**Método:** inventario mecánico sobre el código (no lectura anecdótica) + verificación contra producción con `curl`.
**Regla de evidencia:** cada hallazgo cita `archivo:línea`. Lo no verificado se marca **HIPÓTESIS**.

---

## 0. Resumen ejecutivo

El panel no está "a medio hacer": está **casi terminado pero desconectado**. Hay 18 pantallas, 256 rutas de backend y 107 tablas. El problema no es falta de código, es **falta de empalme** entre tres capas que se escribieron contra supuestos distintos:

| Capa | Estado | Evidencia |
|---|---|---|
| Panel (18 pantallas) | Escrito, compila | `npm run build` → 21 rutas; `tsc` limpio |
| Backend (256 rutas) | Escrito, arranca | `GET /api/health` → `OK`, `commit` vivo |
| Base de datos (107 tablas) | Creada, con dueños múltiples | `migrations/*.sql` + DDL en `index.js` |

**Los tres bloqueantes que impiden que la web funcione hoy:**

1. **La pantalla raíz `/` no tiene fuente de datos.** Sus 3 endpoints existen pero en un módulo que nunca se monta. → §2.A
2. **`/admin/productos` no puede poblar categorías.** Endpoint y tabla inexistentes. → §2.B
3. **El esquema no tiene un dueño único**, así que cualquier "arreglo" de tablas es inestable. → §2.C

---

## 1. Inventario de funcionalidades (lo que la web promete hacer)

### 1.1 Pantallas reales (App Router; los grupos `(dashboard)`/`(auth)` no aparecen en la URL)

| URL | Archivo | Líneas | Endpoints que consume | Estado |
|---|---|---|---|---|
| `/` | `app/page.tsx` | 419 | 3 | **ROTO (3/3)** |
| `/login` | `app/(auth)/login/page.tsx` | 155 | — | OK |
| `/register` | `app/(auth)/register/page.tsx` | 115 | — | OK |
| `/admin/business` | `…/admin/business/page.tsx` | 391 | 4 | OK |
| `/admin/precios` | `…/admin/precios/page.tsx` | 1040 | 7 | OK (arreglado `788a0f449`) |
| `/admin/productos` | `…/admin/productos/page.tsx` | 798 | 6 | **PARCIAL (2/6 roto)** |
| `/admin/academia` | `…/admin/academia/page.tsx` | 356 | 2 | OK |
| `/admin/academia/[id]` | `…/admin/academia/[id]/page.tsx` | 1484 | — | sin verificar |
| `/admin/academia/nuevo` | `…/admin/academia/nuevo/page.tsx` | 263 | — | sin verificar |
| `/admin/vto` | `…/admin/vto/page.tsx` | 185 | 0 | **sin fetch: datos hardcodeados** |
| `/chat` | `…/chat/page.tsx` | 157 | 0 | sin verificar |
| `/perfil` | `…/perfil/page.tsx` | 111 | 0 | sin verificar |
| `/cliente` | `…/cliente/page.tsx` | 151 | 0 | **¿por qué en panel admin?** |
| `/cliente/citas` | `…/cliente/citas/page.tsx` | 109 | 0 | ídem |
| `/cliente/nueva-cita` | `…/cliente/nueva-cita/page.tsx` | 135 | 0 | ídem |
| `/prestador` | `…/prestador/page.tsx` | 131 | 0 | ídem |
| `/prestador/citas` | `…/prestador/citas/page.tsx` | 117 | 0 | ídem |
| `/business` | `app/business/page.tsx` | 123 | 0 | **fuera del layout dashboard** |

### 1.2 Mapa endpoint → backend (verificado, no supuesto)

**`app/page.tsx` (dashboard raíz) — 3/3 sin contraparte:**
```
/api/admin/dashboard/financial-summary   app/page.tsx:130   → NO EXISTE en esa ruta
/api/admin/sos/active                    app/page.tsx:131   → NO EXISTE en esa ruta
/api/admin/provider/pending              app/page.tsx:132   → NO EXISTE en esa ruta
```

**`admin/productos/page.tsx` — 2/6 sin contraparte:**
```
/api/admin/products         OK   (implementado en b520803cc0)
/api/admin/products/:id     OK
/api/admin/precios/:id      OK
/api/categorias             ✗    no existe endpoint ni tabla
/api/admin/upload/presigned ✗→OK falso negativo: montado inline en index.js:443 (prod: 401)
/api/admin/upload/confirm   ✗→OK ídem
```

**`admin/business` · `admin/precios` · `admin/academia` — todos sus endpoints montados.** ✅

---

## 2. Bloqueantes (causa raíz, no síntoma)

### 2.A — Módulo `admin-glow` completo pero huérfano ⛔ CRÍTICO

**Hecho.** Existe un módulo entero en `backend/src/modules/admin-glow/`:
`admin.routes.js`, `admin.controller.js`, `admin.model.js`, `CertifiedKYCProvider.js`, `financial.helper.js`.

Declara **9 endpoints** (`admin.routes.js:11,17,23,29,35,41,47,53,59`), y su propio JSDoc dice bajo qué prefijo deben vivir:

```
@route GET    /api/glow-admin/sos/active              ← app/page.tsx:131 pide /api/admin/sos/active
@route GET    /api/glow-admin/provider/pending        ← app/page.tsx:132 pide /api/admin/provider/pending
@route GET    /api/glow-admin/dashboard/financial-summary ← app/page.tsx:130 pide /api/admin/dashboard/...
@route PATCH  /api/glow-admin/sos/resolve/:id
@route POST   /api/glow-admin/provider/approve
@route POST   /api/glow-admin/provider/reject
@route POST   /api/glow-admin/provider/verify
@route POST   /api/glow-admin/provider/verify-auto
@route POST   /api/glow-admin/payout/approve
```

**Pero el router nunca se monta.** Verificado por tres vías independientes:
- `grep -c admin-glow backend/index.js` → **0**
- `grep -c glow-admin backend/index.js` → **0**
- **Producción:** `GET /api/glow-admin/sos/active` → **404** (no 401; ni siquiera lo alcanza el portero de `/api/admin`)

Del módulo solo se usa `authAdmin.middleware` (`adminAuthRoutes.js:7`).

**Impacto.** El dashboard raíz pide datos a rutas que no existen → siempre cae al estado parcial. Las 9 funciones de administración (resolver SOS, aprobar/rechazar/verificar prestadores, aprobar pagos, resumen financiero) están **implementadas y son inalcanzables**.

**Causa raíz.** El módulo se movió a `src/modules/` pero se perdió el `app.use()` en el punto de entrada. Es el patrón "funciona en aislamiento" — hay tests que lo prueban sin pasar por el servidor real (`backend/src/tests/kyc-verification.test.js:63`, que hace `require` del controller directo, saltándose el routing).

**Nota adicional.** El BFF del panel (`admin-dashboard/src/app/api/[...path]/route.ts`) tiene allowlist de prefijos y **`glow-admin/` NO está** en ella:
`['admin/','metrics/','services/','portfolio/','users/','precios/','productos/','vto/','business/','academia/']`
Así que arreglar solo el frontend no basta: el proxy lo bloquearía igual.

**DECISIÓN REQUERIDA (elige una):**
- **A1 (recomendada).** Montar el router como está: `app.use('/api/glow-admin', require('./src/modules/admin-glow/admin.routes'))` + añadir `'glow-admin/'` a la allowlist del BFF + cambiar las 3 URLs en `app/page.tsx`. *Mínimo cambio, respeta el diseño del módulo, deja el prefijo coherente con `glow-pro`/`glow-cycle` ya montados.*
- **A2.** Montarlo en `/api/admin` y dejar el frontend quieto. *Menos cambios en frontend, pero mete un cuarto router en `/api/admin` donde ya conviven 3 (`index.js:442,443,1068`) y agrava el solapamiento.*
- **A3.** Retirar el módulo y reimplementar esas 9 funciones dentro de `adminRoutes`. *Solo si el módulo está obsoleto; hoy no hay evidencia de eso.*

---

### 2.B — `/api/categorias`: ni endpoint ni tabla ⛔

**Hecho.** `admin/productos/page.tsx:118` llama a `GET /api/categorias`.
- No existe esa ruta en el backend (ningún router la declara).
- **Producción: `GET /api/categorias` → 404.**
- No existe tabla `categorias` en `migrations/` ni en el DDL de runtime.
- No existe columna `categoria_id` en `productos`.

**Causa raíz (inspección de campo, no hipótesis).** `categoria_id` es un **campo fantasma en 5
sitios** del panel:

| Línea | Qué hace |
|---|---|
| `:72`, `:145`, `:167` | `categoria_id: ''` en el estado del formulario (alta, reset, edición) |
| `:303` | Lo envía en el payload: `categoria_id: formData.categoria_id ? parseInt(...) : null` |
| `:502` | **La columna Categoría de la tabla lo lee por fila:** `categorias.find(c => c.id === parseInt(formData.categoria_id \|\| '0'))?.nombre \|\| 'N/A'` |
| `:625-633` | `<select name="categoria_id">` alimentado por el `categorias` que nunca llega |

Dos problemas distintos, no uno:
1. El `<select>` (625-633) se alimenta de `categorias`, que viene del endpoint inexistente → sin
   opciones.
2. La columna de la tabla (502) usa `formData.categoria_id` — el estado del **formulario**, no del
   producto — para **cada fila**. Y `interface Producto` (`:27-36`) **no tiene** `categoria_id`.
   Aunque el endpoint existiera, la columna mostraría siempre 'N/A' (o la categoría del formulario
   repetida en todas las filas).
3. El backend **descarta** `categoria_id` en silencio: el `INSERT` de
   `productController.js:156` no incluye esa columna.

**`tag_especialidad` sí es la categoría real, y ya está en producción:**

| Evidencia | Detalle |
|---|---|
| `migrations/009_create_productos_table.sql:9` | `tag_especialidad VARCHAR(50) NOT NULL` |
| `migrations/032_fix_011_insert.sql` | Valores sembrados: `Barba & Bigote`, `Corte & Capilar`, `Skincare Masculino`, `Grooming` |
| `productController.js:25` | Ya es filtro del servidor: `AND p.tag_especialidad = $2` |
| `page.tsx:32` | Ya está en `interface Producto` |
| `page.tsx:497` | Ya se pinta por fila: `Tag: {prod.tag_especialidad}` |
| `page.tsx:616-617` | Ya hay input funcional de `tag_especialidad` |

**Impacto.** La columna Categoría muestra 'N/A' en todas las filas y el selector está vacío. Es
**imposible de cumplir** con el esquema actual, no un bug de cableado.

**DECISIÓN REQUERIDA — la evidencia decide:**
- **B1 ✅** — `tag_especialidad` es la taxonomía real (NOT NULL, sembrada, filtrable, ya pintada).
  B2 implicaría **construir una taxonomía paralela** a la que ya está en producción. Queda
  **confirmado con evidencia**, ya no es HIPÓTESIS.
  - B1a: borrar el fantasma `categoria_id` y dejar `tag_especialidad` como campo de texto (el
    `<select>` desaparece).
  - B1b *(recomendada)*: además, `GET /api/admin/categorias` → `SELECT DISTINCT tag_especialidad
    FROM productos ORDER BY 1`, para que el `<select>` tenga opciones reales. Bajo `/api/admin`,
    que el BFF ya permite, reutilizando `authMiddleware + requireRol('admin')`.
- **B2 ❌** — crear tabla `categorias` + FK `productos.categoria_id`. Descartada salvo que negocio
  pida taxonomía jerárquica y editable; hoy no hay evidencia de eso.

---

### 2.C — El esquema tiene CUATRO dueños (deuda estructural)

> **Corrección:** la primera versión de este plan decía "tres dueños". Al investigar SOS apareció el
> cuarto, que es además **el canónico**: `backend/init.sql`.

**Hecho.** Las tablas no las define un solo sitio:

| Dueño | Qué crea | Evidencia |
|---|---|---|
| **`backend/init.sql`** *(canónico)* | 10 tablas base: `usuarios`, `perfiles_prestador`, `services`, `bookings`, `reviews`, `portfolio_items`, `messages`, `transactions`, `nail_tryon_jobs` | `index.js:1337` lo ejecuta al arrancar: `Esquema inicializado/verificado desde init.sql (fuente canónica)` |
| `backend/migrations/*.sql` | 107 tablas | runner en `src/config/migrationRunner.js` |
| **DDL en runtime** | 27 tablas: `usuarios`, `productos`, `sos_alerts`, `disputas`, `admin_actions`, `tenants`… | `grep -E "CREATE TABLE" backend/index.js` → 50 sentencias |
| Servicios | más DDL | `src/config/pgMemory.js`, `src/services/corpusAutoIngest.js` |

`migrations/068_force_rls_strict_isolation.sql:115` lo confirma por escrito: *"la fuente única de
verdad del esquema es `init.sql` + ..."*. Es decir, el proyecto **ya decidió** cuál es el dueño, pero
los otros tres siguen escribiendo. `bookings` y `perfiles_prestador` — las dos tablas de las que
depende medio backend — **no están en migraciones**: solo existen en `init.sql`.

Consecuencias observadas:
- `admin_actions` se crea **solo en runtime**, no en migraciones → si el arranque falla, la tabla no existe.
- El log de arranque en producción muestra 78–83 migraciones con advertencias en 035/046/048/054 y **drift** en 056/058/068/079.
- Tablas usadas en código sin migración que las cree: `provider_loyalty`, `user_loyalty` (ambas solo en runtime).

**Impacto.** Ningún "arreglo de tablas" es reproducible: el estado real depende del orden de arranque. Cualquier entorno nuevo puede diferir del actual sin que nadie lo note.

**No es un bloqueante de hoy, pero sí la deuda que hace que los otros arreglos no se sostengan.** → Fase 4.

---

### 2.D — Otros hallazgos (menor severidad, verificados)

| # | Hallazgo | Evidencia | Severidad |
|---|---|---|---|
| 1 | `/admin/vto` no hace ningún `fetch`: datos hardcodeados | `admin/vto/page.tsx` (185 líneas, 0 llamadas) | Media |
| 2 | 5 pantallas de **cliente/prestador** viven dentro del panel admin (`/cliente`, `/cliente/citas`, `/cliente/nueva-cita`, `/prestador`, `/prestador/citas`) | 5 archivos, 0 fetch cada uno | Media (arquitectura) |
| 3 | `/business` está **fuera** del layout `(dashboard)`: sin sidebar | `app/business/page.tsx` | Baja |
| 4 | El Sidebar declara 14 enlaces en 4 grupos de rol, con duplicados (`/chat` y `/perfil` aparecen 3 veces) | `components/dashboard/Sidebar.tsx` | Baja |
| 5 | 4 suites de test del backend en rojo (12 fallos), **preexistentes** | confirmado con `git stash` | Media |
| 6 | Crash `Cannot read properties of undefined (reading 'length')` sin localizar | 57 accesos a `.length` auditados; recharts descartado por reproducción con jsdom; traza ya instrumentada (`8c443f7b0`) | Alta hasta que aparezca la traza |

---

### 2.E — La superficie `admin-glow` NO tiene interfaz (SOS, prestadores, payouts) ⛔

**Hecho.** El módulo expone 9 endpoints. El panel usa **3**, y solo como contadores del dashboard.
Los otros **6 no tienen ninguna pantalla**:

| Endpoint | UI en el panel |
|---|---|
| `GET /sos/active` | Solo un contador (`page.tsx:360-362`: "Alertas SOS — N activas") |
| `PATCH /sos/resolve/:id` | **ninguna** |
| `GET /provider/pending` | Solo alimenta una lista del dashboard |
| `POST /provider/approve` · `/reject` · `/verify` · `/verify-auto` | **ninguna** |
| `POST /payout/approve` | **ninguna** |

**Evidencia de que SOS no tiene ruta:** `admin-dashboard/src/app/(dashboard)/admin/` contiene solo
`academia`, `business`, `precios`, `productos`, `vto` — no hay `sos`. Y el Sidebar
(`components/dashboard/Sidebar.tsx:54-59`) ofrece: Cumplimiento Business, Gestión de Precios,
Catálogo Productos, Academia Glow, Mensajes, Mi Perfil. **Nunca hubo enlace a SOS**: no es una
regresión de la Fase 1.

**Consecuencia:** un administrador puede ver *cuántas* alertas SOS hay activas, pero **no puede ver
ninguna ni atenderla**. Igual con la verificación de prestadores y los retiros.

**Defecto adicional encontrado en el camino** — `admin.model.js:44`:

```sql
UPDATE sos_alerts SET estado = $1, creado_en = NOW() WHERE id = $2;
```

Resolver una alerta **sobrescribe su fecha de creación**. Como `sos_alerts` no tiene columna
`resuelto_en` (DDL en `index.js:1401-1409`), el momento en que ocurrió el SOS se pierde al
atenderlo — justo el dato que se audita después.

**DECISIÓN REQUERIDA:**
- **E1 ✅ HECHO** (commit `abb26231c`) — `/admin/sos` creado: lista alertas activas (cliente, teléfono,
  prestador, coordenadas con enlace a mapas, antigüedad) + acción "Atender"
  (`PATCH /api/glow-admin/sos/resolve/:id`), refresco cada 30 s, y enlace "Alertas SOS" en el Sidebar
  (primero del grupo ADMIN). Usa las clases del sistema de diseño, no colores sueltos.
  Verificado: `tsc` limpio, `npm test` 52/52 (el test de contrato cubre las 2 llamadas nuevas),
  build con la ruta `/admin/sos` (4.2 kB).
  **No verificado desde fuera:** el middleware redirige a `/login` toda ruta de página sin sesión,
  así que la existencia de la ruta solo se confirma entrando con un ADMIN. Requiere confirmación
  visual del usuario.
- **E3 ✅ HECHO** (commits `abb26231c` y `18406189a`) — `updateSOSAlertStatus` ya no sobrescribe
  `creado_en`, y ahora persiste `resolucion`, `resuelto_en` y `resuelto_por`.

**CAUSA RAÍZ del botón "Atender" que no hacía nada (resuelta en `18406189a`).** No era que no
estuviera construido: estaba construido contra un valor que la tabla rechaza.

```
index.js (DDL de sos_alerts)   estado VARCHAR(20) CHECK (estado IN ('ACTIVO','RESUELTO'))
admin.controller.js:44         updateSOSAlertStatus(id, 'ATENDIDO')
```

`'ATENDIDO'` no existe en el `CHECK`, así que Postgres **abortaba el `UPDATE` con violación de
constraint**. El `catch` del controlador lo convertía en un 500 genérico y la alerta nunca se
atendía. Clase de bug idéntica a las anteriores: **un valor inválido de enum no da 404, da error en
runtime**, y el mensaje genérico lo disfraza. Hay test de regresión que lo detecta (probado por
mutación: reintroducir `'ATENDIDO'` lo hace fallar) y el arranque en producción confirma las
columnas nuevas:

```
✅ Tabla e índices sos_alerts inicializados/verificados.
✅ Columnas de resolución de sos_alerts verificadas.
```
- **E2 ⏳ PENDIENTE** — `/admin/prestadores` (cola de verificación con aprobar/rechazar/verificar) y
  `/admin/payouts` (aprobar retiro). Completa la superficie del módulo: 6 endpoints siguen sin UI.

**SQL del módulo validado contra el esquema real (2026-10-08).** Se comprobó cada tabla, columna y
literal de enum que usa `admin.model.js`, porque un enum inválido no da 404 sino error en runtime:

| Consulta | Comprobación | Resultado |
|---|---|---|
| `getActiveSOSAlerts` | `usuarios.nombre`/`phone`, `bookings.provider_id`, `sos_alerts` | ✅ |
| `getPendingProviders` | `perfiles_prestador.estatus_verificacion = 'PENDIENTE'` ⊂ enum | ✅ |
| `getConsolidatedFinancialMetrics` | `estado_cita` incluye `COMPLETADA` y `FINALIZADA_PRESTADOR` | ✅ |
| `getDailyFinancialHistory` | idem + `bookings.scheduled_at` | ✅ |
| `getCategoryPopularity` | `services.category` | ✅ |
| `setProviderVerifiedStatus` | `'APROBADO'`/`'RECHAZADO'` ⊂ `estado_verificacion` | ✅ |
| `getProviderWalletBalance` | `provider_wallet.saldo_disponible` | ✅ |
| `processWalletWithdrawal` | `tipo_wallet_tx` incluye `DEBITO_RETIRO`; `estado` admite `COMPLETADO` | ✅ |
| `hasActiveDisputes` | `estado_disputa` incluye `ABIERTA` y `EN_REVISION` | ✅ |
| `logKYCEvidence` | `kyc_audit_logs` existe (`migrations/073`) | ✅ |

Conclusión: el módulo no solo está montado, **su SQL es correcto**, así que E2 se puede construir
sobre un backend sano. Riesgo de E2 = solo el de escribir la UI.

**Defecto colateral detectado en `src/middleware.ts` (severidad baja, latente):** la línea 47
(`if (/\.[a-zA-Z0-9]+$/.test(pathname)) return NextResponse.next()`) **esquiva la autenticación** para
cualquier ruta que termine en `.ext`. Demostrado en producción: `/admin/zzz-noexiste.txt` → **404**
(pasa el middleware), mientras `/admin/zzz-noexiste` → **307** (redirige a login). Hoy no es
explotable porque ninguna ruta de página termina en extensión, pero es una primitiva de bypass: si
algún día se añade una ruta con punto (p. ej. un informe en `/reportes/octubre.csv`), quedaría
pública. La línea existe para dejar pasar los estáticos de `public/`; el arreglo correcto es
restringirla a una lista de extensiones de assets en vez de a cualquiera.

---

## 3. Plan de construcción por fases

Cada fase es **verificable de forma independiente** y deja la web en un estado funcional mejor que el anterior. No se abre la siguiente sin cerrar la anterior.

### Fase 1 — Desbloquear el dashboard raíz (§2.A) ✅ CERRADA — commit `93f0f6eff`

> **Cerrada el 2026-10-08.** Montado `/api/glow-admin` (`index.js:448`), añadidos `glow-admin/` y
> `v1/business/` al allowlist del BFF, reescritas las 3 URLs de `app/page.tsx:130-132`, y
> corregida la **forma** de la respuesta (el panel leía `data.alerts`/`data.pending`; el backend
> devuelve `data` como la colección, así que habrían salido listas vacías en silencio).
> Nuevo `tests/api-routes-contract.test.mjs`. Verificado: `npm test` 52/52, `tsc` limpio, build 21
> rutas, y en producción `/api/glow-admin/sos/active` **404 → 401** (backend y a través del BFF).
>
> **Hallazgo extra durante la fase:** el test destapó que `/admin/business` también estaba roto —
> llama a `/api/v1/business/*` y el BFF solo permitía `business/`. Corregido en el mismo commit.
>
> **Pendiente de confirmación visual:** los 401 prueban que la ruta vive y exige auth; la
> verificación con datos reales exige sesión de administrador (no se usó). La forma de la respuesta
> se comprobó ejecutando los controladores con el modelo stubeado: `data` es array en SOS y
> prestadores, y `data.{consolidated,dailyHistory,categoryPopularity}` en el resumen.

**Objetivo:** que `/` muestre datos reales de SOS, prestadores pendientes y resumen financiero.

1. Montar el router huérfano (decisión A1/A2/A3).
2. Añadir `'glow-admin/'` a la allowlist del BFF.
3. Alinear las 3 URLs de `app/page.tsx:130-132`.
4. **Test de contrato:** extender el patrón de reflexión ya usado en `tests/precios-coherencia-contract.test.mjs` para que **toda** llamada del panel tenga contraparte en el backend (evita que este bug vuelva con otra pantalla).
5. Verificación: `/` con sesión admin → los 3 bloques con datos; sin sesión → 401.
6. Verificación en producción tras deploy: `GET /api/glow-admin/sos/active` ya no da 404.

**Criterio de cierre:** el dashboard muestra datos y un test falla si se introduce una llamada sin ruta.

### Fase 2 — Productos completo (§2.B) 🟠
1. Resolver la decisión B1/B2 sobre categorías.
2. Implementar lo decidido.
3. Verificar `/admin/productos`: listar, buscar, crear, editar, subir imagen (`upload/presigned` + `confirm`).
4. Añadir cobertura al test de contrato de Fase 1.

**Criterio de cierre:** el CRUD completo de productos funciona y la columna Categoría se puebla.

### Fase 3 — Contratos frontend↔backend 🟠
1. Generalizar el test de reflexión: **todas** las pantallas contra **todas** las rutas.
2. Cubrir también la **forma** de la respuesta (no solo la ruta), como ya se hizo en `precios` — ese fue el bug de `coherencia`.
3. Decidir qué hacer con las 5 pantallas de cliente/prestador dentro del panel (§2.D.2): moverlas o separar el rol.

**Criterio de cierre:** ninguna pantalla puede llamar a un endpoint inexistente o leer un campo que el backend no devuelve, sin que un test falle.

### Fase 4 — Un solo dueño del esquema (§2.C) 🟡
1. Migrar el DDL de runtime a migraciones versionadas.
2. Reconciliar el drift detectado (056/058/068/079).
3. Verificar en base de datos limpia: `migrations` solas reproducen el esquema actual.
4. Eliminar el DDL de `index.js` y `pgMemory.js`.

**Criterio de cierre:** levantar un entorno desde cero con solo migraciones da el mismo esquema que producción.

### Fase 5 — Verificación de extremo a extremo 🟡
1. Suite por pantalla: carga, estado vacío, estado con datos, error, sin permiso.
2. Cerrar el pendiente del crash `.length` con la traza real.
3. Poner en verde (o borrar) las 4 suites rojas preexistentes.

---

## 4. Orden recomendado y por qué

```
Fase 1  ← desbloquea la pantalla principal. Sin esto, el panel no demuestra nada.
Fase 2  ← cierra el segundo bloqueante de datos.
Fase 3  ← convierte "arreglado" en "no se puede volver a romper".
Fase 4  ← hace que todo lo anterior sea reproducible en cualquier entorno.
Fase 5  ← confirma el conjunto.
```

Fases 1 y 2 son las que hacen la web **funcional**. Fase 3 es la que impide que volvamos al bucle de arreglar pantalla por pantalla (que es exactamente el bucle en el que hemos estado: `coherencia`, `.length`, `products` — tres síntomas del mismo desempalme).

---

## 5. Decisiones que necesito de ti antes de tocar código

| # | Decisión | Opciones | Mi recomendación |
|---|---|---|---|
| D1 | Prefijo del módulo `admin-glow` | A1 montar en `/api/glow-admin` · A2 montar en `/api/admin` · A3 retirarlo | **A1** |
| D2 | Origen de las categorías | B1 derivar de `tag_especialidad` · B2 crear tabla `categorias` | **B1** si `tag_especialidad` ya es la taxonomía; B2 si negocio necesita editarla |
| D3 | Las 5 pantallas cliente/prestador en el panel admin | moverlas · separar roles · dejarlas | **separar roles** |
| D4 | Alcance de este plan | solo Fases 1–2 (hacerla funcional) · Fases 1–3 · completo | **Fases 1–3** |

---

## 6. Lo que NO he verificado (honestidad de alcance)

- No he ejecutado el panel contra una base de datos real: las conclusiones de "OK" significan **la ruta existe y está montada**, no que devuelva datos correctos con sesión real. Eso se cierra en cada fase.
- `/admin/academia/[id]` (1484 líneas) y `/admin/academia/nuevo` no los he leído en profundidad.
- `/chat`, `/perfil` no hacen `fetch` directo (usan `apiClient`): su cableado no está auditado.
- El crash `.length` sigue sin causa raíz confirmada.
- No he usado credenciales de producción en ningún momento; todas las comprobaciones remotas son sin autenticar (401/404 como sonda de existencia).
