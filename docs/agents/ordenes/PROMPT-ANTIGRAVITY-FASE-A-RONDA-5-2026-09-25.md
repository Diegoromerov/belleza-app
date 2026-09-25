# ORDEN FASE A · RONDA 5 (corta) — el guardián no puede callarse, y el caso sano tiene que ser reproducible

**Rama:** `fase-a/verdad-operativa` (commit directo, como en las rondas 3 y 4 — el PR #16 es el vehículo). Si prefieres rama nueva desde `fase-a`, avísame antes: cambia la evidencia de CI (CI-10).
**Lo aceptado en la ronda 4 no se toca:** el descubrimiento dinámico de rutas del stack vivo (`extractRoutes`), la regla de clase sobre `/api`, los informes por sufijo (`-ok.json` / `-degraded.json`), `empty_like` fuera y la declaración de alcance en el cuerpo del commit.

## Residuo 1 (el que importa) — el respaldo al inventario es un silencio, no un fallo

Medido sobre `3cef7f88` (`smokeSurfaces.js:118-135`):

```js
118  if (app) {
119    routes = extractRoutes(app);            // stack vivo
120    console.log(`🔍 Descubiertas dinámicamente ${routes.length} rutas…`);
121  }
123  // Respaldo de inventario si el stack vivo está vacío
124  if (!routes || routes.length === 0) {
126    if (fs.existsSync(routesFile)) {
127      routes = JSON.parse(fs.readFileSync(routesFile, 'utf-8'));
128      console.log(`📄 Usando ${routes.length} rutas desde inventario respaldado ${routesFile}`);
```

Si `require('../index')` **falla** (app = null), el guardián **no se detiene**: se sirve del inventario commiteado del 2026-09-24 y termina en verde. Es exactamente el defecto de CI-15 por otra puerta: la cobertura la vuelve a decidir un artefacto, y esta vez **en silencio**.

**Qué se pide:**
1. Si no hay stack vivo (app nulo **o** 0 rutas descubiertas) ⇒ **`process.exit(1)`** nombrando el motivo (`no se pudo cargar el entry; el inventario NO sustituye la medición`). El inventario puede seguir leyéndose **solo para el mensaje de diagnóstico**, nunca para decidir.
2. Si alguna vez se usa como respaldo, el informe debe declarar `routes_source: "inventario"` **y** la corrida salir ≠ 0.
3. Saca la decisión a una **función pura exportada** (p. ej. `decidirRutas({ app, inventario }) → { rutas, fuente, exitCode }`) para poder probarla.
4. **Test que pueda caer:** con `app = null` y con `app` sin rutas ⇒ `exitCode = 1` y `fuente ≠ 'inventario'`; con rutas ⇒ `exitCode = 0`. **Mutación pegada:** devuelve el respaldo silencioso ⇒ el test **rojo**; pega la salida y restaura.

## Residuo 2 — el caso sano es reproducible, pero no como yo lo escribí

Mi criterio de la ronda 4 decía «`sslmode=disable`/`DB_SSL=false`». **Era falso** y lo corrijo aquí: `DB_SSL_REJECT_UNAUTHORIZED=false` **no apaga SSL**, solo relaja la verificación del certificado. La causa real está en `backend/src/config/db.js:14-24`: `getSslConfig(urlStr, hostStr)` compara **`DB_HOST`**, no el host de la `DATABASE_URL` ⇒ con la URL apuntando a `127.0.0.1` y `DB_HOST` sin definir, el pool **pide SSL** y muere.

**Comando verificado por mí (medido hoy, dos corridas):**

```
# sin DB_HOST -> el pool pide SSL y muere
DATABASE_URL="postgres://<rol>:<clave>@127.0.0.1:5435/beauty_db" NODE_ENV=test \
  node -e "require('./src/config/db.js').testConnection()"
#   ⚠️ PostgreSQL local no disponible (sin código: The server does not support SSL connections)

# con DB_HOST -> SSL apagado, llega a autenticar
DB_HOST=127.0.0.1 DATABASE_URL="postgres://<rol>:<clave>@127.0.0.1:5435/beauty_db" NODE_ENV=test \
  node -e "require('./src/config/db.js').testConnection()"
#   ⚠️ PostgreSQL local no disponible (28P01: password authentication failed for user "<rol>")
```

**Qué se pide:**
1. Documentar el comando **correcto** (el de `DB_HOST`) en `scripts/COMO_EJECUTAR.md` y en la cabecera de `smokeSurfaces.js`, con el error esperado sin él (para que nadie vuelva a perder dos intentos).
2. Pegar la corrida **sana** del guardián (base arriba, `exit 0`, *Faked Success: 0*, y **sin** la línea «Usando N rutas desde inventario respaldado») como evidencia.
3. **No toques la heurística de SSL ni `db.js`** (es el pool, no está en el alcance de esta ronda). El defecto de `getSslConfig` (ignora el host de la URL) se registra como deuda y lo documenta el auditor.
4. Nota que debes dejar escrita: `testConnection()` devuelve **`true`** también cuando falla (significa «modo memoria»), así que no sirve como comprobación de conexión; la comprobación es `getDbStatus()`.

## Residuo 3 — el rechazo sin dueño en el camino degradado

En la corrida degradada aparece `Unhandled Rejection: The server does not support SSL connections` con origen apuntado a `tenantRouting.js:170`. Puede ser tuyo (el guardián) o de la app.

**Qué se pide:** reproducirlo, **atribuirlo** (qué promesa, qué línea, qué consecuencia) y, si nace del guardián, silenciarlo **con motivo escrito**; si nace de código de la app, **no lo toques**: regístralo en el informe con su `archivo:línea` y su clase.

## Criterios de cierre

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | `app = null` ⇒ `exit 1` nombrando el motivo; **nunca** verde desde el inventario | test + salida de la corrida forzada |
| C2 | `decidirRutas` pura y exportada, con los tres casos cubiertos | lectura + test |
| C3 | **Mutación pegada**: respaldo silencioso ⇒ test **rojo** | salida del fallo + restauración |
| C4 | Comando `DB_HOST=127.0.0.1 …` documentado con el error esperado sin él | diff + pegado |
| C5 | Corrida sana pegada: `exit 0`, 0 fakes, sin la línea del inventario | salida cruda |
| C6 | `Unhandled Rejection` atribuido (reproducido + `archivo:línea`) o silenciado solo si es del guardián | salida |
| C7 | `npm run smoke:surfaces` sigue marcando una ruta plantada en `/api` (regresión de CI-15) | repetir mi sonda de la ronda 4 |

## Prohibiciones

Regenerar el inventario a mano · recortar superficies · revertir o mover el candado · tocar `db.js`/`getSslConfig` · tocar C-01/C-02/C-03 · ampliar `testPathIgnorePatterns` · declarar «verde» una corrida cuyo respaldo fue el inventario · volver a publicar un criterio de SSL sin el comando pegado.
