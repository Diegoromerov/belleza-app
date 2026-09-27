# Auditoría — Grafo de ramas `grafo-ramas-2026-09-24`

**Fecha:** 2026-09-24 · **Auditor:** Hermes · **Entrega:** commit `c1069e9f` en `fase-a/verdad-operativa` (script + SVG + PNG), **verificado en el remoto** (`git ls-remote` → `c1069e9f`).
**Método:** leí el generador completo, corrí el script dos veces, comparé hashes, contrasté cada `merge-base` contra `git`, y extraje los `<path>` del SVG para verificar los puntos de nacimiento. Restauré el worktree a limpio tras mi corrida (`git checkout --` del SVG), y lo declaro.

## Veredicto

| Dimensión | Resultado |
|---|---|
| Entrega formal | **✓** commit, pusheado, árbol limpio, mensaje correcto |
| Datos: aristas de nacimiento | **parcial — 3 correctas, 6 falsas** (fondo del tronco) |
| Reproducibilidad | **✗** el SVG commiteado no se reproduce; el PNG no se puede regenerar en este entorno |
| Autoconsistencia de los números | **✗** leyenda y caja del fósil con literales hardcodeados |
| Legibilidad | **parcial** — texto del tronco cortado por la izquierda y arcos cruzando etiquetas |

**Es el mejor artefacto de esta serie y está a un paso de ser evidencia en vez de ilustración.** Los tres defectos que lo bloquean son concretos y pequeños.

---

## Lo verificado a favor

| Punto | Evidencia |
|---|---|
| Script versionado, sin dependencias nuevas en el repo | `backend/scripts/branchGraph.js` (448 líneas, 21.324 bytes) |
| El punto de nacimiento sale de git, no de una heurística | `git merge-base main <ref>` en la línea 138; `rev-list --count main..<ref>` en la 135 |
| Panel de GitHub con comparación real | `git ls-remote --heads origin` (línea 45) cruzado con el tip local; badge `=` / `≠ (diverge)` |
| Determinismo **interno** | dos corridas seguidas → `c841710137356b3d…` idéntico, y el script imprime el SHA-256 del SVG |
| Conteos calculados en consola | `Refs totales leídas: 44 · Nombres ×: 26 · BASE=2, ACTIVA=5, HUERFANA=4, MUERTA=15` |
| Los arcos de las ramas cuya base está en el tramo visible son **correctos** | `fase-a/verdad-operativa` nace en `M 520 190` = `f5a1b4fc` (nodo de cabecera del tronco) ✓ · `feat/glowshop-niveles-a0` en `y=850` (`e6e116bd`) ✓ · `feat/glowshop-precios-csv` en `y=806` (`accba403`) ✓ |
| Estructura pedida | tronco, bandas por color, muñones de las muertas pegados al tronco, panel de GitHub, caja del fósil con conector discontinuo, leyenda con la regla explícita y pie con los comandos reproducibles |

---

## Defectos

### D1 · Seis ramas se dibujan naciendo del **fondo del tronco** (arista falsa) — grave
Cuando el `merge-base` no está entre los últimos 40 commits de `main`, el código hace `mbY = trunkEndY` (líneas 260-263): dibuja el arco desde la **base del tronco**, sin avisar. Verificado contrastando cada merge-base real contra `git log main -n 40` y contra los `<path>` del SVG:

| Rama | merge-base real | ¿en los últimos 40 de main? | Arco dibujado |
|---|---|---|---|
| `audit/hermes` | `5334c31b` | NO | `M 520 1906` (fondo) ✗ |
| `audit_glowapp_architecture_integrity` | `b67b4c48` | NO | `M 520 1906` ✗ |
| `backup/linea-base-osm-modifications` | `b67b4c48` | NO | `M 520 1906` ✗ |
| `codex/rag-aura-r1-r4` | `a5cc3214` | NO | `M 520 1906` ✗ |
| `origin/diegoromerov-feature-biometric-hub` | (remota) | NO | `M 520 1906` ✗ |
| `feature/ai-nail-tryon-legacy` | `5334c31b` | NO | `M 520 1906` ✗ |

`trunkEndY = 190 + 39×44 = 1906` ✓ (coincide con los seis arcos). El resultado: el gráfico **afirma que `audit/hermes` (que se separó en julio, `5334c31b`) nace al final del tronco visible** — exactamente la "arista inventada para que el dibujo quede bonito" que el encargo prohibía.

### D2 · La leyenda del PNG lleva los conteos hardcodeados
Líneas 370-373: `'ACTIVAS (5 ramas)'`, `'HUÉRFANAS (4 ramas)'`, `'MUERTAS (15 ramas)'`, `'BASE (2 referencias)'` son **literales**. Hoy coinciden con el cálculo por casualidad; en la próxima corrida, con una rama más o menos, la imagen mentirá aunque los datos cambien. La consola sí calcula (`classified.*.length`): el número creíble está en el log y el que se publica en la imagen es una constante.

### D3 · La caja del fósil son literales, y su `catch` está vacío
Línea 66: `fossilInfo = { sha:'4f803a0b', date:'2026-08-04', ahead:'1363', deletedFiles:'22036' }` — el `try` de las líneas 67-73 solo refresca `sha/date/subject`; **`1.363` y `22.036` nunca se recalculan** (líneas 352 y 355 los imprimen tal cual) y `ahead` no se usa. Si el clon fósil no responde, `catch (e) {}` deja los valores viejos sin decirlo. Son dos cifras fabricadas-en-potencia dentro de una imagen sobre datos fabricados: el chiste se cuenta solo.

### D4 · `refs/remotes/origin/HEAD` aparece como una rama llamada `origin`
`%(refname:short)` abrevia `refs/remotes/origin/HEAD` a **`origin`**. El script lo toma como nombre de rama, lo clasifica `BASE` y la leyenda lo describe con otro literal: *"main trunk y referencia suelta local origin"* (línea 373). No existe ninguna rama local `origin` (lo comprobé: `refs/heads` = 23, `refs/remotes/origin` = 21). Es una **entidad falsa** en el gráfico, y contamina el conteo (`BASE=2`, `26 nombres`).

### D5 · El PNG no se puede regenerar aquí y el fallo se traga
```
Error al renderizar PNG con Python: ModuleNotFoundError: No module named 'svglib'
SHA-256 del SVG: c8417101…   ← el script sigue como si nada
```
El `try/catch` (líneas 428-437) es **no fatal**: si `svglib`/`reportlab` no están, el PNG commiteado se queda como está y el script igual imprime "SVG generado". Además el mensaje promete *"PNG renderizado a 2x escala"* mientras el factor real es **1.5x** (lienzo 1920 → PNG 2880). Es el artefacto que la gente mira: su regeneración depende de un paquete que no está declarado en el repo.

### D6 · El artefacto commiteado **no se reproduce** (y documenta el estado anterior a su propio commit)
Dos corridas hoy dan el mismo hash (`c8417101…`), pero **el SVG commiteado tiene otro** (`17e8e6bc…`). El diff son exactamente dos líneas:
```diff
-<text … >cfec993a · +5 commits ⌂ setup_glowguide_architecture</text>
+<text … >c1069e9f · +6 commits ⌂ setup_glowguide_architecture</text>
-…>cfec993a · 2026-09-24 · fix(frontend): remove PAN/CVV/Nequi form on s
+…>c1069e9f · 2026-09-24 · audit: add deterministic branch graph generat
```
El gráfico se generó **antes** del commit que lo introduce, así que la imagen que estás mirando muestra `fase-a` en `cfec993a · +5 commits` cuando la rama entregada ya está en `c1069e9f · +6`. La auto-referencia queda obsoleta en el mismo commit.

### D7 · La fecha de referencia está fija
`const refDate = new Date('2026-09-24')` (línea 113): la regla "≤ 14 días" se congela. Corrido en octubre, `feat/glowshop-precios-csv` (24-sep) pasará a `HUÉRFANA` sin que nada haya cambiado.

### D8 · Legibilidad (visto en el PNG y explicado en el código)
- Los mensajes del tronco se dibujan con `text-anchor="end"` en `x = trunkX − 180 = 340` (línea 239) y se truncan a 48 caracteres (~330 px a 12 px mono) → **se salen por la izquierda del lienzo**: en la imagen se lee `erge branch`, `x(glowshop)`, `at (glowshop) : WO B-01 - Platform admin provisi…`.
- Los arcos verdes atraviesan esa misma franja de texto (las tarjetas de rama van de x=80 a 390 y el texto ocupa de 10 a 340): hay solapamiento real, no solo estético.
- El conector discontinuo del fósil cruza el centro del cuadro y varias etiquetas; `database_audit_read_only` y `beauty-fixxa-aura` quedan cortados contra el borde derecho del panel.

---

## Mis propias correcciones (retracciones)

1. **"Faltan el script, el SVG y el PNG"** → **falso**. Los revisé en `C:/beauty-app`, que está en `feat/glowshop-niveles-a0`; los artefactos viven en el commit `c1069e9f` de `fase-a/verdad-operativa` y están pusheados. Fue un error de checkout mío, no de la entrega.
2. **"3 activas / 6 huérfanas"** → bajo la regla **que yo mismo escribí** (worktree cuenta como activa) el resultado correcto es **ACTIVA=5, HUERFANA=4, MUERTA=15, BASE=2**, que es lo que dice la imagen. Mi clasificador ignoró la cláusula del worktree. Ahora bien: la regla es mala para decidir una poda — pinta de verde `audit_glowapp` (19 días sin tocar) y `backup/osm` (17 días) solo porque les quedó un worktree abandonado. Recomiendo **regla solo-fecha** (`≤14d`), con el worktree como icono informativo: entonces son 3 activas y 6 huérfanas.
3. **"Existe una rama local llamada `origin` / desapareció"** → **falso**. Esa fila es `refs/remotes/origin/HEAD` abreviada; nunca hubo rama local `origin` (locales = 23, estable). El "desaparecida" salió de una lista que yo escribí a mano con ese nombre.
4. Mi primera comprobación de `merge-base` para `diegoromerov-feature-biometric-hub` falló (`fatal: Not a valid object name`) porque omití el prefijo `origin/`: error de mi sonda, no del script.

---

## Recomendaciones (convertibles en orden de trabajo)

| # | Arreglo | Verificación |
|---|---|---|
| R1 | D1: extender el tronco hasta el merge-base más antiguo **o** dibujar el arco saliendo del borde con la etiqueta `fork anterior al tramo visible: <sha> (<fecha>)`; y que el script imprima `n aristas con nacimiento fuera del tramo visible` | Los 6 arcos de la tabla D1 nacen en su sha real o llevan etiqueta; cero `M 520 1906` para ramas cuyo merge-base no es del tramo |
| R2 | D2+D3: derivar **todos** los números (`classified`, `git -C <fósil> rev-list --count`, `git -C <fósil> status --porcelain \| wc -l`) y eliminar el `catch` vacío: si el fósil no responde, la caja debe decir `no verificado` | Cambiar un conteo a mano en el código y ver que la imagen **no** cambia |
| R3 | D4: excluir `refs/remotes/origin/HEAD` del inventario (o rotularlo `origin/HEAD (symref)`) | `BASE=1` (solo `main`) y `nombres únicos` baja en 1 |
| R4 | D5: declarar la dependencia del render o renderizar sin ella; el fallo del PNG debe **abortar** con ≠0 | Con `svglib` ausente, la corrida falla en vez de dejar un PNG rancio; y el mensaje dice el factor real (1.5x o 2x) |
| R5 | D6: commitear el script primero y generar los artefactos después (commit siguiente), o rotular `estado medido en <sha>`; y en el PR pegar `sha256` commiteado == `sha256` regenerado | `sha256sum` del SVG commiteado == el de una corrida nueva |
| R6 | D7: `refDate` = fecha real de la corrida y el título con el momento de medición | Corrido mañana, el título cambia y las clases no |
| R7 | D8: mover el tronco a `x ≥ 700` o truncar el asunto al ancho disponible; subir el ancho del lienzo; llevar el conector del fósil por el margen inferior | Ningún `<text>` con `x_texto − ancho_estimado < 0`; sin solape con las tarjetas |
| R8 | Añadir `id="branch-<nombre>"` a cada `<path>` y a su tarjeta | Un auditor puede mapear arco↔rama sin adivinar (hoy hay que reconstruirlo por orden) |

**Con R1, R4 y R5 arreglados, la imagen pasa a ser evidencia**: reproducible contra el estado que documenta, sin entidades falsas y sin aristas inventadas.
