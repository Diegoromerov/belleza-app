# Plantilla de ORDEN (work order) — para el Ejecutor

> Copia, rellena y encola en `COLA.md`. Una orden = una rama = un PR. Rellena **todos** los campos: una orden con huecos produce una entrega con huecos.

---

## ORDEN-<n> · <título corto, imperativo>

**Goal (una frase, medida por su resultado):** <qué debe ser verdad al terminar, no qué hay que hacer>

**Rama:** `tipo/slug` · **Nace de:** `origin/main` (`git fetch origin && git switch -c <rama> origin/main`)
**Caducidad:** <fecha> (5 días sin PR ⇒ se archiva)
**Dueño de la decisión si aparece un conflicto:** <Dueño | Arquitecto>

### Contexto medido (no lo re-descubras: reprodúcelo)
| Hecho | Valor | Comando que lo produjo |
|---|---|---|
| | | |

> Estos números son de la medición del <fecha> sobre <rama> @ <sha>. Si tu medición no coincide, **detente y repórtalo**: la lista cambió.

### Alcance
1. <paso 1>
2. <paso 2>

### Criterios de aceptación (falsables: escritos como un test que puede fallar)
| # | Criterio | Cómo se comprueba (comando + salida esperada) |
|---|---|---|
| C1 | | |

### Verificación por mutación (obligatoria)
| Mutación en un clon temporal | Resultado exigido |
|---|---|
| | |

### NO TOCAR
- <archivos, ramas o sistemas prohibidos en esta orden>
- Sin dependencias nuevas sin declararlas en el PR.

### Evidencia que debe venir en la ENTREGA
- Salida **cruda** de cada comando de los criterios (rojo antes, verde después).
- `git log -1 --format='%h %ci %s'` y `git status --porcelain` de la rama entregada.
- Qué **no** se pudo verificar y por qué.
- Desviaciones del plan: qué hiciste distinto y con qué fundamento.
