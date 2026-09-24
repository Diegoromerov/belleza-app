# GOAL — Grafo de ramas, ronda 2: de ilustración a evidencia

**Goal:** que `grafo-ramas-2026-09-24` sea **reproducible contra el estado que documenta**, sin entidades falsas y sin aristas inventadas. Nada más: la estructura está bien y no se rediseña.

**Dónde:** commit sobre `fase-a/verdad-operativa` (ya contiene el generador y los artefactos en `c1069e9f`).
**Auditoría de la ronda 1 con comandos y salidas:** `C:/Users/Compu casa/auditorias/belleza-app/AUDITORIA-GRAFO-RAMAS-2026-09-24.md`.

---

## 0. Lo que ya está bien (no lo toques)

- `git merge-base main <ref>` para el nacimiento y `rev-list --count main..<ref>` para `±AHEAD` (líneas 135-141): los arcos de `fase-a/verdad-operativa` (`f5a1b4fc`), `feat/glowshop-niveles-a0` (`e6e116bd`) y `feat/glowshop-precios-csv` (`accba403`) son **correctos** — verificado extrayendo los `<path>` del SVG.
- Determinismo interno: dos corridas seguidas dan el mismo SHA-256.
- El panel de GitHub con `=` / `≠ (diverge)`, la tabla de correlación en consola y el pie con los comandos: se quedan.

## 1. Correcciones obligatorias

### C1 · El punto de nacimiento nunca puede ser el fondo del tronco · M
Medido: cuando el `merge-base` no está entre los últimos 40 commits de `main`, tu código hace `mbY = trunkEndY` (líneas 260-263) y dibuja el arco desde la base (`M 520 1906`). Hoy **seis** ramas salen mal:
```
audit/hermes                            merge-base 5334c31b   → dibujado en 1906
audit_glowapp_architecture_integrity    merge-base b67b4c48   → dibujado en 1906
backup/linea-base-osm-modifications     merge-base b67b4c48   → dibujado en 1906
codex/rag-aura-r1-r4                    merge-base a5cc3214   → dibujado en 1906
origin/diegoromerov-feature-biometric-hub                     → dibujado en 1906
feature/ai-nail-tryon-legacy            merge-base 5334c31b   → dibujado en 1906
```
El gráfico **afirma hoy que `audit/hermes` se separó del final del tronco visible**. Es la arista inventada que el encargo prohibía.
**Arreglo (elige uno y dilo):** (a) extender el tronco hacia atrás hasta el `merge-base` más antiguo (subiendo el lienzo), o (b) dibujar el arco saliendo del **borde inferior** con la etiqueta `fork anterior al tramo visible: <sha> (<fecha>)`. Y el script debe imprimir `n aristas con nacimiento fuera del tramo visible` junto a los demás conteos.
**Verificación:** ninguna rama de esa lista tiene un `<path>` que empiece en la y del último nodo del tronco; y para las tres correctas el `y` sigue siendo el mismo.

### C2 · Cero números hardcodeados en la imagen · S
- Leyenda (líneas 370-373): `'ACTIVAS (5 ramas)'`, `'HUÉRFANAS (4 ramas)'`, `'MUERTAS (15 ramas)'`, `'BASE (2 referencias)'` son literales. Hoy coinciden por suerte; con una rama más, la imagen miente aunque los datos cambien. **Derívalos de `classified`** (la consola ya los calcula bien).
- Caja del fósil (líneas 66, 352, 355): `+1.363 commits` y `22.036 archivos eliminados` **nunca se recalculan**. Calcúlalos: `git -C "C:/Users/Compu casa/belleza-app" rev-list --count HEAD..main` (o el equivalente correcto — decide y justifícalo) y `git -C "<fósil>" status --porcelain | wc -l`.
- **Elimina el `catch (e) {}` vacío** (línea 73). Si el clon fósil no responde, la caja debe decir `no verificado` en vez de mostrar cifras viejas.
- **Verificación:** cambia un conteo a mano en el código y comprueba que la imagen **no** cambia; y con el clon fósil renombrado temporalmente, la caja dice `no verificado`.

### C3 · `refs/remotes/origin/HEAD` no es una rama · S
`%(refname:short)` lo abrevia a **`origin`**, y tu script lo trata como nombre de rama, lo clasifica `BASE` y la leyenda lo describe con otro literal (*"main trunk y referencia suelta local origin"*, línea 373). No existe ninguna rama local `origin` (verificado: `refs/heads` = 23, `refs/remotes/origin` = 21).
**Arreglo:** exclúyelo del inventario (o rotúlalo explícitamente `origin/HEAD (symref)` si prefieres mostrarlo).
**Verificación:** `BASE=1` (solo `main`) y `nombres únicos` baja de 26 a 25.

### C4 · El PNG debe regenerarse o la corrida debe fallar · M
Hoy el render depende de `svglib`/`reportlab`, no están declarados en el repo, y el `try/catch` (líneas 428-437) **se traga el fallo**: en mi entorno salió `ModuleNotFoundError: No module named 'svglib'` y el script igual terminó diciendo "SVG generado", dejando un PNG rancio como artefacto publicado. Además el mensaje promete `2x` cuando el factor real es **1.5x** (lienzo 1920 → PNG 2880).
**Arreglo:** o declaras la dependencia y la instalas de forma reproducible, o renderizas sin ella (el repo ya tiene Chrome/Flutter disponibles; o genera el PNG desde el propio Node). Y si el PNG no se regenera, **`process.exit(1)`**.
**Verificación:** pega la salida de dos casos: (a) render OK con el factor real declarado; (b) render imposible ⇒ exit ≠0 y el mensaje diciendo qué falta.

### C5 · El artefacto commiteado debe ser el que se reproduce · M
Dos corridas hoy dan `c8417101…`; **el SVG commiteado es `17e8e6bc…`**. El diff son dos líneas: el gráfico muestra `cfec993a · +5 commits` mientras la rama entregada ya está en `c1069e9f · +6`. Se generó **antes** del commit que lo introduce, así que la imagen queda obsoleta en su propio commit.
**Arreglo:** commitear el **script** primero y generar los artefactos en un commit **posterior** (o rotular `estado medido en <sha>` en el título). Pega en el PR: `sha256` del SVG commiteado == `sha256` de una corrida nueva.
**Verificación:** `sha256sum docs/audit/grafo-ramas-2026-09-24.svg` == el de `node backend/scripts/branchGraph.js` recién corrido.

### C6 · Fecha real, no congelada · S
`const refDate = new Date('2026-09-24')` (línea 113) congela la regla de 14 días: corrido en octubre, `feat/glowshop-precios-csv` pasará a `HUÉRFANA` sin que nada haya cambiado. Usa la fecha real de la corrida y ponla en el título.
**Decisión que debes tomar y justificar:** la regla de clase. Hoy `worktree || ≤14d` pinta de verde `audit_glowapp` (19 días sin tocar) y `backup/osm` (17 días) solo porque les quedó un worktree abandonado — malo para decidir una poda. **Recomendación: ACTIVA = ≤14 días; el worktree pasa a ser solo un icono.** Con eso son 3 activas / 6 huérfanas. Si mantienes la regla vieja, escríbelo en la leyenda y asume que la imagen llama "activa" a ramas muertas en la práctica.

### C7 · Legibilidad (medido en el PNG entregado) · M
- Los mensajes del tronco se dibujan con `text-anchor="end"` en `x = trunkX − 180 = 340` y se truncan a 48 caracteres (~330 px a 12 px mono) ⇒ **se salen del lienzo**: se lee `erge branch`, `x(glowshop)`, `at (glowshop) : WO B-01 - Platform admin provisi…`. Mueve el tronco a `x ≥ 700` o trunca al ancho disponible.
- Los arcos verdes cruzan esa franja de texto y las etiquetas de las tarjetas van de x=80 a 390: hay solapamiento real. Sube el ancho del lienzo y separa columnas.
- El conector discontinuo del fósil cruza el centro y varias etiquetas: llévalo por el margen inferior. `database_audit_read_only` y `beauty-fix-aura` se cortan contra el borde del panel.
- **Verificación:** ningún texto con `x − ancho_estimado < 0`; y en el PNG se leen completos los mensajes del tronco y los dos nombres de worktree del panel.

### C8 · Identificabilidad de cada arco · S
Los `<path>` no llevan identificador: hoy hay que reconstruir qué arco es de qué rama por el orden del bucle. Añade `id="branch-<nombre>"` al `path` y a su tarjeta.
**Verificación:** `grep -c 'id="branch-' grafo-ramas-2026-09-24.svg` = número de ramas dibujadas.

---

## 2. NO TOCAR

- No se borran ni etiquetan ramas en esta tarea; el generador es **solo lectura** sobre el repositorio (nada de `gc`, `prune`, `fetch --prune`, `push --force`).
- No se cambia la estructura visual aprobada (tronco, bandas, muñones, panel de GitHub, caja del fósil, leyenda, pie con comandos).
- No se toca `main`, ni `ci.yml`, ni las rondas 3 de la Fase A.
- No se agregan dependencias al `package.json` sin declararlo en el PR.

## 3. Terminado = (falsable)

1. Los seis arcos de C1 nacen en su `sha` real o llevan la etiqueta de tramo no visible; el script imprime ese conteo.
2. Cero literales numéricos en leyenda y caja del fósil: cambiarlos en el código no cambia la imagen, y con el clon fósil inaccesible la caja dice `no verificado`.
3. `BASE=1` y 25 nombres únicos (C3).
4. `exit ≠0` si el PNG no se regenera, con el factor real declarado (C4).
5. `sha256` del SVG commiteado == el de una corrida nueva (C5), con el diff vacío.
6. La regla de clase declarada en la leyenda coincide con la implementada, y `refDate` es la fecha real (C6).
7. En el PNG: mensajes del tronco completos, sin solapes, worktrees legibles (C7).
8. `grep -c 'id="branch-'` = ramas dibujadas (C8).
9. `git status` limpio tras correr; `refs/heads` sigue en 23 antes y después.
