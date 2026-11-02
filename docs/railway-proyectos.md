# Railway: dos proyectos independientes

Este repositorio es la **matriz** (backend + migraciones). Lo despliega el proyecto
Railway **`glowapp`**, y aquí se desarrolla todo.

## `glowapp` — el proyecto vivo

| Servicio | Qué es | Se despliega desde |
|---|---|---|
| `glowapp-api` | Backend Node + migraciones | este repo, rama `main`, root `/backend` |
| `postgres-postgis-prod` | Base de datos de producción | imagen Docker |
| `Redis` | Cola y caché | imagen Docker |

Las apps Flutter **no** pasan por Railway: `glowapp-client` y `glowapp-provider` se
publican en Firebase Hosting desde el repositorio privado `glowapp-firebase`
(workflow `apps-ci.yml`).

## `grateful-harmony` — muestra viva, congelada

Es el proyecto de la etapa monolítica. Se conserva como **muestra funcional** y
como archivo de consulta: de ahí se extrae código o partes que sirvan a `glowapp`.
**No se desarrolla en él.**

- Tiene su propio Postgres, su propio Redis y sus propias llaves de Wompi
  (sandbox). No comparte datos ni secretos con `glowapp`.
- Los servicios con fuente GitHub tienen `autoDeploy` desactivado: un push a
  `main` **no** los reconstruye.
- `glowapp-frontend` construye desde la rama congelada
  `feat/split-client-provider-apps`, porque su `rootDirectory` es `/frontend`, una
  carpeta que ya no existe en `main`.

### Regla

Todo desarrollo, toda creación de tablas (migraciones) y todo despliegue se
ejecuta en `glowapp`. Si algo de la muestra es útil, se **extrae** hacia este
repositorio; no se toca el proyecto congelado.
