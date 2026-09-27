# Auditoría — entrega de A-06 ronda 2 (2a + 2b)

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia verificada:** 2a `origin/fix/compuerta-secretos-reproducible` @ **`b73f96fb`** (2 commits sobre `fase-a/verdad-operativa` @ `c1069e9f`); 2b `origin/fix/jwt-sin-respaldo` @ **`bc4ec2af`** (**3** commits ⇒ **contiene 2a**, encadenadas por construcción ✓). 2a: script + test + `DEUDA.md`; 2b: + `jwt.js` + `biometricCryptoService.js` + 2 tests.

## Veredicto: **ACEPTADA EN SUSTANCIA** · 3 residuos · 1 corrección estructural **de mi orden**

El objetivo de la orden —que la compuerta vuelva a ver los secretos **del propio proyecto**— **está cumplido y lo probé con mi propia mutación**. Lo que no está: C5 como se pidió, C7 completo y C8. Y C6 era **imposible** tal como lo escribí.

---

## 1. El mapa real del escáner (sondas mías, copia descartable del worktree)

Baseline **sin plantar nada** en `b73f96fb`: **2 hallazgos reales** — `backend/src/config/jwt.js:2` y `backend/src/services/biometricCryptoService.js:18`. Cada sonda es un archivo nuevo con `git add`, y cuento sólo los hallazgos que la nombran:

| Sonda | ¿La ve? |
|---|---|
| `process.env.JWT_SECRET \|\| 'glowapp_jwt_production_secure_secret_key_at_least_32_chars'` | **SÍ** ⇒ el **C1 cumplido**: el prefijo del propio proyecto ya no la esconde |
| `process.env.TOKEN \|\| 'ghp_…'` | SÍ ⇒ C2 ✓ |
| `process.env.DB_PASS \|\| 'admin_root_secure_key_…'` | SÍ ⇒ `admin` no quedó exento (sólo `admin123`) |
| `const API_KEY = 'sk-live-…'` (sin `process.env`) | SÍ ⇒ un prefijo conocido se ve igual |
| secreto `ghp_…` dentro de `.github/workflows/*.yml` | SÍ ⇒ la exención de directorio se retiró de verdad |
| `process.env.API_KEY \|\| 'test_secret_live_…'` | **NO** ⇒ el prefijo `test` sigue exento |
| `process.env.K \|\| 'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff9a1b2c3d4e5f6a7b8'` (40 chars) | **NO** ⇒ un literal opaco sin prefijo conocido no se ve |
| `const JWT_SECRET = 'glowapp_…'` (sin `process.env`) | **NO** ⇒ la regla de «valor por defecto» exige la forma `process.env.X \|\| '…'` |
| `sk-…` dentro de un `.md` cualquiera | **NO** ⇒ `EXENTAS` sigue con `/\.md$/i` **global** |

## 2. C1 ✓ · C2 ✓ — lo que la orden buscaba

La allowlist de prefijos `glowapp_ | dev_ | default` salió y los marcadores estándar (`PLACEHOLDER`, `REPLACE_ME`, `TU_`, `REDACTED`, `***`, `dummy`, `example.com`) se conservaron — que es lo correcto: esos **no** son convenciones de nombre de secretos del proyecto. Mi mutación con `glowapp_…` ahora sale **detectada**.

## 3. C3 ✓ / C4 ✓ — con un residuo que hay que cerrar

`jwt.js` (2b): no queda `DEFAULT_PROD_SECRET` (leído), fuera de `NODE_ENV=test` **lanza**, en test devuelve un literal. `biometricCryptoService.js`: lanza si faltan las claves.

**El residuo:** ese literal de test —`test_secret_glowapp_jwt_token_key_at_least_32_chars`— está en `jwt.js:7` **y** como semilla del hash en `biometricCryptoService.js:27`, y la compuerta **no puede verlo** (sonda `test_`: 0 hallazgos) sólo porque empieza con `test`. Es la clase de **CI-08** en versión estrecha: el arreglo introdujo el prefijo que lo esconde. La salida limpia es que **no haya literal**: en test, generar la clave en tiempo de ejecución (`crypto.randomBytes`) o leerla del entorno de test — y entonces el prefijo `test` puede salir de la lista de exenciones y la clase queda cerrada.

## 4. C5 ✗ como se pidió

Su «prueba de mutación» es un test que **pasa** y asevera una *desigualdad* con un flag `normalize=false`. Lo que pedí era el test **rojo** al quitar la normalización del camino real, con la salida del fallo pegada. No está — y no lo puedo dar por bueno yo: mi mutación de la normalización exige correr su suite, y su propia evidencia no la incluye.

## 5. C6 ✗ — y la culpa es de mi orden, no suya

Medido en su rama: el escáner sale con **`exit 1` y 2 hallazgos reales**. Es decir: **el paso 7 seguirá rojo en el CI** — ahora por un motivo honesto (dos literales que existen de verdad) en vez de por los finales de línea, que es una mejora real de fondo. Pero la consecuencia es que **el paso 7 no puede ponerse verde mientras esos literales existan**, y eximirlos está prohibido.

⇒ Al partir Cargo 2 en «2a la compuerta / 2b el arreglo» escribí un C6 **imposible de cumplir**: la compuerta es verde sólo cuando el arreglo está dentro. **2a y 2b tienen que aterrizar juntas**, y sólo después de la confirmación del Dueño en Railway. Corrección registrada; la entrega de Antigravity no tiene culpa aquí.

## 6. C7 ✗ parcial

Fuera `^\.github/workflows/` ✓ (medido: sí escanea los `.yml` de ahí) y fuera los prefijos de iniciales ✓. Pero `EXENTAS` quedó con **`/\.md$/i` global** en vez del `docs/**/*.md` que pedí: cualquier `.md` del repo —incluidos el `README` de la raíz y los informes— queda fuera del escaneo, y en prosa estaban **25 de los 39** hallazgos del run [#1681](https://github.com/Diegoromerov/beauty-app/actions/runs/36072881287).

## 7. C8 ✗ — y también es mi fallo

Crearon un **`DEUDA.md` nuevo en la raíz** del repo (esquema distinto) en vez de actualizar la KB. No fue capricho: `docs/knowledge/DEUDA.md` vive en la rama `docs/sistema-agentes`, que **no es su base** ⇒ le pedí algo que no podía hacer. La KB la mantengo yo; la fila TEC-53 queda actualizada en mi rama (TEC-53 sigue **abierto**, y su corrección de código ya existe en 2b, bloqueada por la confirmación).

## 8. C9 ✓

2b va en rama aparte, sin fusionar, con la **advertencia al Dueño escrita**, y —bien hecho— **construida sobre 2a**, así que las dos aterrizan juntas por construcción. La condición que puse (primero el secreto existe, después se retira el respaldo) está respetada.

## 9. Lo que se conserva

La normalización de fin de línea, la exclusión de prosa (a acotar), los marcadores estándar, la exportación de funciones para poder testear —que es justo lo que me permitió mutar— y **el huso del arreglo**: la compuerta volvió a ver el convenio de secretos del proyecto.

## 10. Límites de esta auditoría

1. **No corrí su suite con jest:** la prueba roja que pide C5 no existe en su reporte, y mi re-corrida exigiría modificarla; queda declarada como pendiente, no como verde.
2. **No verifiqué Railway** (ni lo intento: sin permiso ahí).
3. Las sondas corrieron sobre una **copia descartable** del worktree; las ramas quedan intactas y el árbol auditado, limpio.
