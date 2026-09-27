# GOAL — Grafo gráfico de ramas: local vs GitHub (imagen)

**Goal:** producir **una imagen legible del árbol de ramas y su historia** —dónde nace cada rama desde `main`, cuántos commits aporta, en qué copia vive y qué worktree la tiene— generada por un script **versionado y determinista** que lee `git`; nada dibujado a mano.

**Repo:** `C:\beauty-app` · **Base:** `origin/main` = `f5a1b4fc` · **Fecha de la medición:** 2026-09-24.
**No crear rama nueva para esto** (sería irónico dado el tema): commit en `fase-a/verdad-operativa`; si esa rama ya está cerrada, usa `docs/mapa-ramas-2026-09-24` desde `origin/main`.
**Tarea de solo lectura sobre el repositorio**: se leen ramas, nunca se crean, mueven ni borran.

---

## 0. Por qué existe esta tarea

Hay **43 referencias de rama** (24 locales + 19 remotas) y **26 nombres únicos** para **3 tareas vivas**. La lista de texto ya existe; lo que falta es la **forma**: dónde se separa cada rama de `main`, qué tan lejos llegó y qué es ruido colapsado sobre el tronco. Eso es lo que un listado no muestra.

## 1. Datos obligatorios (todos con comando, prohibido inventar)

```bash
cd C:/beauty-app
# 1. inventario de refs con tip y fecha
git for-each-ref --format='%(refname:short)|%(objectname:short)|%(committerdate:short)|%(subject)' refs/heads refs/remotes/origin
# 2. punto de nacimiento real de cada rama (la arista del árbol)
git merge-base main <rama>          # y su fecha: git log -1 --format=%ci <merge-base>
# 3. commits que aporta
git rev-list --count main..<rama>
# 4. historia del tronco, para dibujar el eje de main
git log main --date=short --pretty='%h|%ad|%s' -n 40
# 5. worktrees registrados
git worktree list --porcelain
# 6. la otra copia (clon fósil) — es OTRO clon, no refs de este repo
git -C "C:/Users/Compu casa/belleza-app" log -1 --format='%h|%ci|%s'
git -C "C:/Users/Compu casa/belleza-app" rev-list --count 4f803a0b..main   # si el objeto existe localmente
```

**Clasificación determinista** (así los colores son reproducibles, no un criterio tuyo). Con `AHEAD = git rev-list --count main..<rama>` y `FECHA` = fecha del último commit:

| Clase | Regla | Cuántas debe dar hoy |
|---|---|---|
| `MUERTA` | `AHEAD = 0` (ya está en `main`) | **15** |
| `ACTIVA` | `AHEAD > 0` y tiene worktree **o** `FECHA` ≤ 14 días de 2026-09-24 | **3** |
| `HUERFANA` | `AHEAD > 0` y `FECHA` > 14 días | **6** |
| `BASE` | `main` y la ref suelta `origin` | 2 |

Al terminar, la tabla de correlación que imprima tu script **debe cuadrar con esos números**. Si alguno no cuadra, **repórtalo crudo** en el PR con la salida del comando; no lo ajustes para que cierre.

## 2. Cómo debe verse la imagen

Un **solo** lienzo, con estas decisiones ya tomadas:

1. **Tronco vertical = `main`**, con sus últimos 40 commits (sha corto, fecha, mensaje truncado a 60 caracteres). El tronco es lo único continuo.
2. **Cada rama sale de su `merge-base` real** con una arista curva hacia su tip. Etiqueta al final de la arista: `nombre · tip · ±AHEAD` y, si tiene worktree, un icono `⌂` con el nombre de la carpeta.
3. **Tres bandas horizontales por clase**, con el color de la clase y rótulo de banda: `ACTIVAS` (verde `#1a7f37`), `HUÉRFANAS` (ámbar `#9a6700`), `MUERTAS` (gris `#57606a`). Las 15 muertas se dibujan **como muñones cortos pegados al tronco** (su tip ya está en `main`): deben verse apiladas y claramente inofensivas, no compitiendo en espacio con las vivas.
4. **Panel separado a la derecha: `GITHUB · origin`** con las 19 ramas publicadas y una marca `= local` o `≠ local` según coincida el tip (compara `%(objectname:short)` local contra `git ls-remote --heads origin`). Este panel es lo que responde "¿el repo de GitHub está alineado?".
5. **Caja aparte abajo: `COPIA FÓSIL`** — `C:/Users/Compu casa/belleza-app`, `main = 4f803a0b` (2026-08-04) separada del tronco por una línea **discontinua** rotulada con la distancia real (`1.363 commits`, `22.036 archivos borrados`). Es otro clon: no debe aparecer mezclada con las refs del repo bueno.
6. **Leyenda** con: color de clase, iconos (`⌂` worktree, `≠` desalineada, `— —` discontinuo = otra copia) y la definición de `±`.
7. **Título y pie con procedencia**: fecha, `origin/main = f5a1b4fc`, y la lista de comandos usados. La imagen debe poder defenderse sola: quien la mire sabe de dónde salió cada número.
8. **Legibilidad mínima**: fuente ≥ 12 px a escala 1x, sin etiquetas solapadas, sin cruces de aristas ilegibles. Si 26 ramas no caben sin solaparse, **aumenta el lienzo** (alto libre) — nunca reduzcas la tipografía para que quepa.

## 3. Formato y artefactos

- **Script generador versionado**, sin dependencias nuevas: `backend/scripts/branchGraph.js` (Node) o `scripts/branchGraph.py`. Debe ser **determinista**: dos corridas seguidas producen **el mismo sha256** del SVG. Si usas Graphviz/Mermaid, instálalos localmente y **no** los agregues a `package.json`/`pubspec.yaml`; decláralo en el PR.
- **Salida obligatoria:** `docs/audit/grafo-ramas-2026-09-24.svg` (vectorial, texto nítido y diffeable) y **`docs/audit/grafo-ramas-2026-09-24.png`** derivado del SVG a 2x. La imagen entregable es el PNG; el SVG es la fuente.
- El script imprime además la **tabla de correlación** a stdout: `rama | tip | fecha | merge-base | ±AHEAD | clase | worktree | =≠ remoto`.
- Comando re-ejecutable declarado en el PR, p. ej. `node backend/scripts/branchGraph.js`.

## 4. Verificación obligatoria (pega las salidas crudas)

1. `node backend/scripts/branchGraph.js && sha256sum docs/audit/grafo-ramas-2026-09-24.svg` **dos veces** → el hash debe repetirse.
2. Conteo desde el propio grafo: el script reporta cuántas aristas dibujó y cuántas refs leyó; **deben ser 26 y 43** (o reporta la diferencia con su causa).
3. `file docs/audit/grafo-ramas-2026-09-24.png` + tamaño en píxeles; y **pega la imagen en el PR** (no basta la ruta).
4. `git status --porcelain` tras correr el script: solo los artefactos declarados; **ninguna rama creada, movida ni borrada** (compruébalo también con `git for-each-ref --count=999 refs/heads | wc -l` antes y después: debe ser 24 → 24).
5. Chequeo de verdad de la arista: para `fase-a/verdad-operativa`, `feat/glowshop-niveles-a0` y `audit/hermes`, imprime `merge-base main <rama>` y comprueba que la arista nace en **ese** commit (no en el tip de `main` ni en un punto inventado).

## 5. Trampas

- **`feat/glowshop-niveles-a0` tiene 1 commit único** (`3337aadb`) y es la rama del árbol de trabajo de `C:/beauty-app`: no la dibujes como muerta ni como parte del tronco.
- **`fix/audit-360-remediation`** tiene dos tips distintos (local `3052ebae`, remoto `fa549f46`) y **ambos ya están en `main`**: va en `MUERTA`, no es una divergencia.
- Existe una **rama local llamada `origin`** (sí, con el nombre del remoto): dibújala como `BASE`, no la confundas con `origin/main`.
- Las refs `origin/pr9` y `origin/diegoromerov-feature-biometric-hub` son ramas **del remoto** (`refs/heads`), no `refs/pull`: van en el panel de GitHub.
- Si un `merge-base` falla (historia sin base común), dibuja el nodo **suelto** con la etiqueta `sin base común`. **Prohibido** inventar una arista para que el dibujo quede bonito.
- **Prohibido** pintar datos decorativos: cada color debe estar en la leyenda y venir de la tabla de la sección 1. Sin gradientes, sin tamaños de nodo "según importancia" que no salgan de un comando.

## 6. NO TOCAR

- No se borran, renombran ni etiquetan ramas en esta tarea (la poda es otra tarea, con sus propios tags de archivo).
- No se hace `git gc`, `git prune`, `fetch --prune` ni `push --force`.
- No se toca `main`, ni las ramas de otros agentes, ni los worktrees ajenos.
- No se modifica `AGENTS.md` ni `ci.yml` aquí.
- Nada de credenciales: los comandos son locales; el `ls-remote` es lectura pública, sin token.

## 7. Terminado = (falsable)

1. Existen `branchGraph.js` (versionado, sin deps nuevas), `grafo-ramas-2026-09-24.svg` y `.png`.
2. Dos corridas → mismo sha256 del SVG.
3. La tabla de correlación cuadra: 26 nombres, 43 refs, 15/6/3/2, 6 worktrees.
4. El PNG se ve y se lee: tronco, tres bandas de clase, panel de GitHub, caja de la copia fósil con línea discontinua rotulada, leyenda, título con procedencia.
5. Las tres aristas verificadas nacen en su `merge-base` real.
6. `git for-each-ref refs/heads | wc -l` = 24 antes y después; `git status` sin cambios fuera de los artefactos.
7. Imagen pegada en el PR + comando para regenerarla.
