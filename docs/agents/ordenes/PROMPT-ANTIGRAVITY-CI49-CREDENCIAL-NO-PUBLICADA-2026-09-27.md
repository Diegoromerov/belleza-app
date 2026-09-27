# Orden para Antigravity — CI-49: que el repositorio no publique credenciales que funcionan

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Excepción del Dueño:** autorizó (2026-09-27) el arreglo de código de esta clase. Si algo de este documento encaja con C-02 (dinero/identidad), **parás y preguntás** en vez de decidirlo.

---

## 1. ROL

Hacé **una sola cosa**: que ninguna credencial que **funcione** quede publicada en el repositorio, y que la compuerta que vigila eso sea capaz de **verla** si vuelve. No abras ningún otro frente.

## 2. CONTEXTO (medido, no heredado)

**Procedencia:** `C:/beauty-app`, rama de trabajo `main` (verificá con `git rev-parse --abbrev-ref HEAD` y `git rev-parse HEAD`; **no confíes en ningún SHA escrito acá** — esta carpeta tiene varios clones y worktrees y el mismo path relativo es otra revisión en cada uno). Declará en tu informe el `git status --porcelain` de tu copia al empezar.

Hechos medidos hoy:

1. `backend/seed.sql:1-2` publica, en claro, «contraseña para todos es: password123» **y** el hash bcrypt de esa contraseña. Líneas 3-11: siete cuentas (IDs 1-7) con ese hash, incluida `admin@beautyapp.com` con `rol='ADMIN'`.
2. **Censo hecho por contraseña, no por hash** (bcrypt lleva sal ⇒ dos cuentas con la misma contraseña tienen hashes distintos, y un censo por hash las pierde): en producción **20 cuentas autentican con `password123`**, de las cuales **14 siguen activas** (roles PRESTADOR y CLIENTE: `carolina.hair@`, `cliente_demo@`, `demo1@demo.com`, `diana.facials@`, `mi-salon@demo.com`, `misalon@demo.com`, `mi_salon_saas@`, `prov_nails_001@`, `salon_demo@`, `salondemo@demo.com`, `salon_owner@`, `santiago.barber@`, `sonia.herrera@`, `valeria.makeup@` — todas `@bellezaapp.com` salvo las `.demo.com`). Las 6 que se desactivaron el 2026-09-27 siguen desactivadas, y `admin@beautyapp.com` está entre las 20 (tenía la contraseña, con otra sal). **Ese censo de producción ya está hecho: no lo repitas ni toques datos de producción.**
3. **La compuerta no lo ve:** `node backend/scripts/verifyNoVersionedSecrets.js` sale **exit 0** («✅ Sin credenciales versionadas…») con esa credencial a la vista. Reglas actuales: `file:21-112`. Motivo exacto por el que cada forma se escapa:
   - La contraseña está **documentada en prosa** («contraseña para todos es: …») ⇒ la regla «valor por defecto literal para variable sensible» (`:74-98`) exige un **nombre** de variable sensible antes del `=`/`:`; «es» no lo es ⇒ no matchea.
   - El **hash bcrypt** (`$2a$10$…`) no lo busca ninguna regla.
   - Ojo con la lista de comentarios que esa regla saltea (`:80`: `//`, `/*`, `*`, `#`): **`--` (SQL) no está**, pero eso no la salva, porque igual no hay nombre de variable.
4. `index.js:1694-1711` ejecuta `seed.sql` **entero, en una sola consulta** (`:1706`), y sólo si `NODE_ENV !== 'production'` (`:1700-1701`) y `SEED_DATABASE === 'true'` (`:1702`). Es el único punto del repo que siembra.
5. Tests de la compuerta que ya existen (extendelos, no crees otros): `backend/src/tests/verifyNoVersionedSecrets.test.js`, `backend/src/tests/verifyNoVersionedSecretsEtiqueta.test.js`, y `backend/src/tests/audit360-remediation.test.js:205` que la corre **como subproceso**.

## 3. ALCANCE

| Acción | Archivo | Nota |
|---|---|---|
| **Editar** | `backend/seed.sql` | el archivo de la credencial; debe dejar de publicar algo que funcione |
| **Editar** | `backend/scripts/verifyNoVersionedSecrets.js` | añadir las formas que hoy no ve (sin tocar las existentes) |
| **Editar** | `backend/src/tests/verifyNoVersionedSecrets.test.js` | casos nuevos, uno por forma nueva |
| **Crear** | `backend/scripts/audit/ci49-guardian-red.txt` y `backend/scripts/audit/ci49-guardian-ok.txt` | evidencia RED y GREEN, commiteadas, **un archivo por estado** (si compartís un nombre, la segunda corrida pisa la primera y perdés el RED) |
| **Editar (declarado)** | `backend/index.js`, **sólo** el bloque `:1694-1711` | únicamente si el mecanismo que elijas lo exige (p. ej. leer una variable de entorno y pasarla al seed). Si lo tocás, decilo en el PR con la razón |
| **NO TOCAR** | `backend/src/routes/paymentRoutes.js` | ya tiene su arreglo en `fix/ci48-sin-email-en-admin`, aprobado; tocarlo acá duplica la orden |
| **NO TOCAR** | `.github/workflows/ci.yml` (ni sus `testPathIgnorePatterns`) | ensanchar la lista de exclusiones es la forma de comprar verde que esta orden prohíbe |
| **NO TOCAR** | `backend/public/**`, migraciones, `backend/src/config/*`, `backend/scripts/verifyTenantIsolation.js`, otros worktrees/clones | |

## 4. LO QUE HAY QUE LOGRAR (el cómo es tuyo; el invariante no)

**Invariante:** *ninguna credencial que autentique contra la base puede estar publicada en un archivo versionado* — ni en claro, ni hasheada, ni como valor por defecto de una variable.

Concretamente, y sin elegir por el Dueño:

- `backend/seed.sql` **no puede** seguir conteniendo `password123` ni un hash de ella. Las cuentas del seed siguen existiendo (el flujo de desarrollo depende de ellas); lo que desaparece es la credencial publicada.
- El mecanismo es decisión tuya **dentro de este marco**: la contraseña del seed entra por variable de entorno (`SEED_PASSWORD`) **obligatoria y sin valor por defecto**, o se genera aleatoria y se imprime **una sola vez** al operador. Las dos sirven; elegí una, escribí en el PR por qué, y **no dejes un default**. **Fail-closed**: sin esa entrada, el seed **no corre** y lo dice — no siembra con una contraseña inventada.
- Dejá **una pregunta abierta en el PR** (no la decidas vos): la decisión de producto es *cómo quiere el Dueño que el equipo siembre en desarrollo*. Enunciá las dos opciones con su costo y su consecuencia; no las resuelvas por él.

## 5. LA COMPUERTA (guardian) — tres formas nuevas, todas con su caso

Añadí a `REGLAS` (`verifyNoVersionedSecrets.js:21-112`) las formas que hoy se escapan, **cada una con su validador y su caso en el test**:

1. **Contraseña documentada en prosa o comentario.** Una línea que declara la contraseña de un conjunto de cuentas («contraseña…: X», «password for all users is X»), en `.sql`, `.md` fuera de `docs/`, `.js`, `.yml`. No debe dispararse con marcadores (`PLACEHOLDER`, `REDACTED`, `<...>`, `example.com`, `***`): usá `ALLOW_MARKERS` (`:19`).
2. **Hash de contraseña débil conocida.** Literal `$2a$`/`$2b$`/`$2y$` (bcrypt) o `$argon2` en un archivo versionado ⇒ señalalo; si querés endurecerlo, **verificá el hash contra una lista corta de contraseñas débiles conocidas** (`password123`, `123456`, `admin`, `admin123`, `demo`, `test1234`…) con `bcryptjs` (ya está en las dependencias) y reportá sólo el caso afirmativo. No imprimas nunca el hash ni la contraseña.
3. **Valor por defecto literal en variable sensible** — la forma `const p = process.env.X_PASSWORD || 'Literal123!'` **ya está cubierta** por la regla `:74-98`; no la reescribas. Lo que falta verificar es que **siga** cubierta después de tu cambio: dejá su caso en el test.

Reglas de la compuerta, no negociables:
- **No amplíes `EXENTAS` (`:115`) ni `VENDOR` (`:123`)**. Si creés que un archivo debería quedar exento, es una **pregunta abierta** en el PR, no una ampliación.
- La compuerta **no puede tomar su veredicto del archivo que juzga**: cada regla debe re-verificar su propio patrón (eso ya está resuelto en `:157-160`; mantené esa invariante).
- El exit dice si encontró, no si pudo medir: si `git grep` falla por algo que no sea «0 coincidencias», la compuerta **tiene que** salir ≠ 0 y decirlo.

## 6. VERIFICACIÓN OBLIGATORIA (con los números que medí; si no coinciden, PARÁ y reportá)

Corré **el comando del CI, no uno parecido** (`ci.yml:99`), desde `backend/`:

```
npm test -- --coverage --testPathIgnorePatterns="geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|api.cors"
```

**Línea base medida en `main` (misma máquina, mismas variables, workers por defecto):** `Test Suites: 4 failed, 74 passed, 78 total` · `Tests: 23 failed, 573 passed, 596 total`. Suites rojas (por nombre, no por número): `backend/tests/business.integration.test.js`, `businessAdminDocs.integration.test.js`, `businessHardening.integration.test.js`, `businessSystem.integration.test.js` — son deuda **heredada** (ficha CI-43), no tuya.
**Tu criterio es el delta, no ese absoluto:** tu rama sale de `origin/main`, así que tiene que dar **esas 4 suites y no una más**, y **ningún** test rojo nuevo. Compará **nombres**, no conteos: un worker distinto cambia el conteo. Si tu número difiere del mío, pegalo crudo y explicá la diferencia; no lo maquilles.

**Cuidado con dos suites que pueden voltearse a causa de tu cambio (y está bien que lo hagan, con prueba):** `audit360-remediation.test.js:205` corre la compuerta como subproceso ⇒ si la compuerta empieza a encontrar algo en el árbol, esa suite cambia de veredicto. Si eso pasa, el hallazgo es real: no toques la suite para taparlo; arreglá el árbol o reportá.

**La compuerta, corrida sobre el árbol real (esto es lo central):**
- **Antes** de tu arreglo, sobre `main`: `node backend/scripts/verifyNoVersionedSecrets.js` ⇒ **exit 0** (medido hoy; la credencial está a la vista ⇒ la compuerta es ciega). Pegá la salida.
- **Después**, sobre tu rama: ⇒ **exit 0** porque ya no queda ninguna credencial que funcione. Pegá la salida.
- **RED de la compuerta (obligatorio, y no basta un unit test):** plantá en un archivo **versionado** (temporal, se borra) una de las formas nuevas —por ejemplo una línea `-- password para todos: password123`— y corré la compuerta ⇒ **exit ≠ 0** con el hallazgo por `archivo:línea`, sin imprimir el valor. Pegá la salida. **Después borralo del árbol Y del índice** y probá las dos cosas: `git diff --cached -- <archivo>` vacío **y** `git show :<archivo> | grep -c '<patrón>'` = `0` (una prueba RED que deja el patrón en el índice llega rota a la rama siguiente).
- **GREEN de la compuerta** (`ci49-guardian-ok.txt`) y **RED** (`ci49-guardian-red.txt`), commiteadas.

**Test que ejerce comportamiento, no texto.** Prohibido cerrar esto con `expect(fuente).toContain('…')` o contando ocurrencias en el fuente (`TRAMPAS.md` R-07). La prueba del seed tiene que **ejecutar** el camino:
- sin `SEED_PASSWORD` (o la entrada que elijas): el seed **falla cerrado** — no inserta filas, sale ≠ 0 y lo dice;
- con una contraseña dada: las cuentas se crean y **ninguna** autentica con `password123` — la aserción es `bcrypt.compare('password123', hash) === false`, no una comparación de cadenas contra el texto del archivo.

## 7. ENTREGA

- Rama: **`fix/ci49-credencial-no-publicada`**, cortada de `origin/main` **recién fetcheado** (`git fetch origin main` y después `git rev-parse origin/main`; no de una ref cacheada de tu copia).
- **PR contra `main`** (no contra una rama intermedia: el workflow filtra `branches: [main, staging]` y un PR abierto contra otra rama no dispara el job).
- **Secuencia del CI, que decide si tu gate corre:** mientras `fix/ci46-segunda-causa` no esté mergeado, el paso «Preparar el esquema multi-tenant y los roles RLS» falla y el paso de tests queda **`skipped`** ⇒ en ese caso tu verificación en GitHub **no puede** correr y lo que cuenta es la corrida local pegada. **Decí en el PR cuál de los dos casos te tocó** (mirá el run y pegame su URL). No toques `ci.yml` para destrabarlo.
- Cuerpo del PR: qué cambió y por qué, las dos líneas del gate (base y tu rama), el RED y el GREEN de la compuerta, el bloque de la contraseña documentada como **evidencia antes/después**, y la pregunta abierta del §4.
- Si algo no lo pudiste medir, escribí **«no pude medirlo»** con el motivo. Eso es un cierre válido; inventar el resultado, no.

## 8. PROHIBICIONES

1. **No toques datos de producción.** El censo y las desactivaciones ya están hechos. Esta orden es sólo código.
2. **Nada de `NODE_TLS_REJECT_UNAUTHORIZED=0`, `-SkipCertificateCheck` ni `curl -k`.** Si una llamada falla por TLS, se reporta.
3. **Nada de `--force` ni `--force-with-lease`; no borres ramas del remoto; no `gc`.**
4. **No hagas push directo a `main`**: rama + PR (lo dice `AGENTS.md`).
5. **No reescribas el historial** (`filter-repo`, `rebase` sobre `main`, purgas): la credencial **ya está quemada** y limpiarla del historial es decisión del Dueño, no tuya.
6. **No imprimas** contraseñas, hashes, tokens ni cadenas de conexión, ni en el código, ni en los logs, ni en la evidencia. Ni siquiera la que ya es pública.
7. **No amplíes** `EXENTAS`/`VENDOR`/`testPathIgnorePatterns`, no marques tus propios hallazgos como falsos positivos, no borres ni saltes tests para bajar conteos.
8. **No toques** los archivos de la tabla NO TOCAR, ni ramas de otros agentes.

## 9. DEFINICIÓN DE TERMINADO

1. `backend/seed.sql` no contiene `password123` ni el hash que hoy publica.
2. Sembrar sin la entrada requerida **falla cerrado** (pegar salida) y no inserta filas.
3. Sembrar con una contraseña dada crea las cuentas y **ninguna** autentica con `password123` (`bcrypt.compare` = false, pegado).
4. Las tres formas nuevas tienen caso en `verifyNoVersionedSecrets.test.js` y cada caso **falla** si se quita su regla (mutación: quitá la regla, corré, pegá el fallo, restaurá).
5. La compuerta sobre el árbol real: **exit 0** después del arreglo, y **exit ≠ 0** con el patrón plantado (RED), con el patrón restaurado también en el índice.
6. `ci49-guardian-red.txt` y `ci49-guardian-ok.txt` commiteados.
7. El gate con el comando del CI: **4 suites rojas y 23 rojos, sin agregar ninguna** (o el número distinto pegado crudo con su explicación).
8. PR contra `main` con su URL, el URL del run (o la razón por la que quedó `skipped`), y la pregunta abierta del §4.

---

**Lo que esta orden NO decide (y por eso no lo escribo como instrucción):** cómo siembra el equipo en desarrollo (variable obligatoria vs contraseña generada e impresa una vez), qué se hace con las **14 cuentas demo activas en producción** que autentican con la contraseña publicada, y si se purga el historial. Las tres son del Dueño; van al PR como preguntas abiertas o a su lista, no a tu criterio.
