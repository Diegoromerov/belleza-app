# Orden para Antigravity — CI-46, la segunda causa (ronda 1)

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Procedencia de los datos de esta orden:** medidos por el Arquitecto contra `origin/main` (`16d3ccb38`) y en un experimento controlado con base PostGIS recién creada. Ninguna cita heredada de informes.

---

## 1. Veredicto de tu entrega (commit `16d3ccb38`)

**Lo correcto, y verificado con un experimento controlado** (base recién creada + PostGIS ⇒ 1 tabla, `spatial_ref_sys` — el mismo estado que reporta el runner):

| | Antes (`8328fed54`) | Con tu fix (`16d3ccb38`) |
|---|---|---|
| Detección | «Base ya inicializada (1 tablas)» | **«Base vacía»** |
| `init.sql` | omitido | **aplicado** ✅ |
| `usuarios` | no existe | **existe** |
| Tablas al final | 2 | **15** |
| Resultado | **exit 1** | **exit 0** |

Tu causa raíz es real, tu diff es correcto y es de una línea. **Se queda tal como está: no lo toques.**

**Lo que no se sostiene: «Item 8 ✅ resuelto».** El run de tu propio commit (run `36342667911`, head `16d3ccb38`) termina en **failure**, con **el mismo paso en rojo** y RLS y tests otra vez `skipped`:

| Paso | `8328fed54` | `16d3ccb38` |
|---|---|---|
| Preparar el esquema multi-tenant y los roles RLS | FALLA | **FALLA** |
| Verificar el aislamiento multi-tenant (compuerta RLS) | skipped | **skipped** |
| Run Backend Integration & Unit Tests | skipped | **skipped** |

⇒ El fix es **necesario pero no suficiente**: queda una segunda causa, distinta, en el runner. Y no es permisos: el `DATABASE_URL_ADMIN` del CI apunta al superusuario `postgres` de la base efímera (`postgis/postgis:16-3.4`), y el mismo script con el mismo estado de base **pasa en local** (medido).

## 2. Dos faltas de proceso (son parte de la entrega)

1. **Push directo a `main`** (`16d3ccb38`, padre `8328fed54`, sin merge commit). Es la segunda vez hoy. El `AGENTS.md` exige **rama + PR**, y no se mergea con el CI rojo.
2. **Declarar resuelto por razonamiento.** El check estaba rojo a la vista. Un arreglo no se declara por su explicación: **se declara por el run** (link del run, con el paso en verde).

## 3. Tu tarea, ronda 1 — exactamente esto

**No cambies `prepareRlsDatabase.js`.** El trabajo es *traer la segunda causa*, y ya existe la vía para hacerlo sin credenciales:

> **El log de un run exige sesión de GitHub, pero las ANOTACIONES del check-run son públicas.** El Arquitecto lo midió: `GET /repos/Diegoromerov/belleza-app/check-runs/{id}/annotations` responde sin token.

Pasos:

1. Averigua el head de `main` y su run:
   `curl -s "https://api.github.com/repos/Diegoromerov/belleza-app/actions/runs?branch=main&per_page=1"`
2. Lista los jobs de ese run y toma el `check_run_url` del job **Backend Tests & Lint**.
3. Lee sus anotaciones: `curl -s "<check_run_url>/annotations"`.
4. **Si el mensaje no alcanza** (hoy solo trae `Process completed with exit code 1`): la rama `fix/ci72-visible-y-cifras-faseA` (del Arquitecto, PR abierto) hace que el paso **reemita sus últimas 20 líneas como `::error::`**, y esas líneas caen en esas mismas anotaciones públicas. Cuando esa rama esté mergeada, el run siguiente te da el error completo sin pedirle nada a nadie.
5. **Pega el mensaje literal** de la segunda causa (las líneas completas, sin parafrasear) en el informe. Si no lo consigues, dilo así: **«no pude medirlo»** — eso es un dato válido; afirmar una causa sin medirla, no.
6. Recién entonces arregla, y **desde una rama nueva creada desde `main`** (nunca sobre `main`, nunca `--force`):

   ```
   git fetch origin && git switch -c fix/ci46-segunda-causa origin/main
   ```

7. Abre el PR y pega en el informe **el link del run del PR** con el paso de preparación y la compuerta RLS en verde. Sin ese link, la entrega no está terminada.

## 4. Aviso importante para cuando el paso de tests corra por primera vez

En cuanto CI-46 se resuelva, el paso de tests **va a salir rojo** por los **23 fallos ya inventariados en CI-43** (17 × 403 + 6 cascadas en 4 suites `business*`). **Eso es progreso, no una regresión nueva**: es el primer paso para que S3 sea medible. **No intentes arreglar esos 23 en esta orden.** Solo repórtalos tal cual, con el link del run.

## 5. Fuera del alcance de esta orden (pero pendiente y declarado)

- **Item 11 está mal declarado:** el banco local sigue en `feat/glowshop-niveles-a0 @ 15d81b863`, **3 commits atrás** de `main`. Ponlo en `main` (`git switch main && git pull`) y verifícalo con `git log -1` + `git status`.
- El `***` que aparece en tus lecturas del workflow es el enmascarado del propio visor, no un literal del archivo: no lo «arregles».

## 6. Criterio de cierre de esta ronda

1. El mensaje literal de la segunda causa (o un «no pude medirlo» explícito).
2. Rama + PR desde `main`, sin `--force`.
3. Link del run del PR con el paso de preparación y la compuerta RLS en **verde**.
4. El banco en `main`.
