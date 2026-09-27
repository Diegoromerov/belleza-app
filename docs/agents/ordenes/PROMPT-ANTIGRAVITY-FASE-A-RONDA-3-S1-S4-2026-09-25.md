# ORDEN Fase A · RONDA 3 — S1 (ninguna superficie miente con 2xx) y S4 (el guardián deja de dar verde)

**Qué es esto:** la orden vieja `PROMPT-ANTIGRAVITY-FASE-A-RONDA-3-2026-09-24.md`, **depurada**. Su **B1** (el PR) lo cerró D-001 — el PR #16 existe; su **B2** (el bloque de montajes `537-561`) lo cerró **A-03**; su **B4** toca formularios de tarjeta = **C-02**, prohibido en Fase A; su **B5/B6** quedaron absorbidos por **A-05**. **Lo que sigue vivo es su B3 (= S4) y el hallazgo S1**, y lo he re-medido hoy sobre `fase-a/verdad-operativa @ c1069e9f`. Las citas viejas (`f5a1b4fc`, `537-561`) ya no valen.

## Lo que hay hoy (medido hoy, no heredado)

| Hecho | Cita |
|---|---|
| El header de degradación lo pone **un middleware para toda la app** | `index.js:218-224` — `if (getDbStatus().servingFabricatedData === true) res.setHeader('X-GlowApp-Degraded','memory-fallback')` |
| **Solo `/api/health`** traduce «degradado» a **503** | `index.js:428-438`; el cálculo está en `:430` (`db.servingFabricatedData \|\| db.pgAvailable === false`) |
| **No existe helper** para que una ruta de datos responda 503 al estar degradada | único productor del header: `:221`; único 503: el de health |
| El guardián decide **por ruta, no por clase** | `smokeSurfaces.js:78-82` (`/api/providers`) y `:85-87` (`/api/health`) |
| Deriva el estado del endpoint que vigila | `smokeSurfaces.js:55-56` → `/api/health` |
| `empty_like` se calcula y **no decide nada** | `:72` (cálculo) vs `:98` (solo se guarda) |
| `wrote_to_db` está **hardcodeado** en `false` | `:100` |
| **No escribe informe** | no hay `writeFile`; `docs/audit/smoke-*` = **0** archivos |
| Inventario que consume | `docs/audit/routes-2026-09-24.json` = **308** rutas |

## Cargo 1 — S1: una superficie de datos no puede responder 2xx si su consulta falló

`/api/products` (servida por `productRoutes`, montada en `index.js:392`) responde **200** con el cuerpo de la capa de memoria cuando la base no está. El header de degradación está, pero **el código de estado miente** — y eso es exactamente lo que la Fase A llama «la app dice la verdad».

1. Toda **ruta de datos** responde **503 + `X-GlowApp-Degraded: memory-fallback`** mientras la capa de datos esté degradada. Se prefiere **un solo mecanismo** (middleware de bloqueo) antes que cuarenta parches.
2. Si usas middleware, lleva **allowlist explícita y motivada** (p. ej. `/api/health`; los estáticos no son «datos»).
3. **No rompas lo que ya es honesto:** `/api/providers` (503 + `PROVIDER_SEARCH_DEGRADED`), `/api/health` (503 `DEGRADED`) y el middleware del header.
4. Si alguna superficie **debe** seguir dando 2xx sin base, va en la allowlist **con el motivo escrito al lado**; si el motivo es de producto, **se escala al Dueño en el PR** en vez de decidirlo tú.

## Cargo 2 — S4: el guardián debe fallar **por clase**, no por ruta

1. La condición de fallo pasa a ser de clase: **2xx en `/api/**` mientras la capa de datos está degradada ⇒ `faked_success`**, con la única excepción de la allowlist motivada del Cargo 1.
2. El estado degradado se captura **una vez al inicio** y **no se deriva de `/api/health`** para decidir. Seguir leyendo health para informar está bien; **que no decida**.
3. `empty_like` **decide** (un 200 con `data: []` estando degradado es el defecto original) o se elimina del resultado. Calcularlo y no usarlo no vale.
4. `wrote_to_db` **real** (derivado de lo observado) o fuera del informe: publicar `false` hardcodeado es una métrica fabricada por el propio guardián antifabricación.
5. El informe se escribe **siempre** en `docs/audit/smoke-<fecha>.json`, verde y rojo.

**La prueba de que el guardián sirve (obligatoria, es la que faltaba):** añade una ruta temporal que finja éxito — `app.get('/api/__smoke_fake', (req,res)=>res.json({success:true,data:[{id:1}]}))` — corre el smoke con la base caída y demuestra que **la nombra sin haber tocado el código del guardián**. Después retírala. Eso separa un guardián de una lista de dos rutas.

## Criterios de cierre

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | Base caída: `npm run smoke:surfaces` **≠ 0** y su salida nombra las superficies que fingen (incluida `/api/products` si sigue en 200) | salida completa pegada |
| C2 | Base arriba: **`exit 0`** | salida completa pegada |
| C3 | El informe existe en `docs/audit/smoke-<fecha>.json` en **las dos** corridas y `wrote_to_db` no es constante | los dos archivos |
| C4 | El guardián ve un caso **nuevo** (la ruta plantada) sin tocar su código | salida de la corrida + `git diff` del guardián |
| C5 | `/api/products` con base caída ⇒ **503 + `X-GlowApp-Degraded`**; con base arriba ⇒ **200** | dos `curl` pegados |
| C6 | Prueba de **comportamiento** (no de texto): la superficie bloqueada da 503 degradada y 200 sana | el test, con su nombre, corriendo |
| C7 | La allowlist, si existe, con motivo escrito y **sin prefijos comodín** | el código de la allowlist, pegado |
| C8 | PR contra `main` (o el commit dentro de `fase-a`) con la URL | enlace del PR |

**Expectativa de CI (medida):** con PR el run existirá, pero **morirá en el paso 7** mientras no aterricen A-06 2a+2b y las 5 líneas de prosa (**CI-14**). ⇒ La evidencia de esta orden es **local** y va pegada; no la busques en el CI.

## Prohibiciones

Tocar los montajes de `index.js` (eso es **A-03**) · migraciones o esquema · `paymentRoutes.js`, wallet, disputas, OTP (**C-01/C-02/C-03**) · el bundle `backend/public` · ampliar `testPathIgnorePatterns` · eximir la proyección de secretos · **recortar el universo de superficies probadas** para poner el smoke verde: si el inventario tiene 308 rutas, el guardián las recorre.

## Terminado = (falsable)

Los 8 criterios con su salida pegada, y **las dos corridas** del smoke —roja con la base caída, verde con la base arriba— con sus dos informes en `docs/audit/`.
