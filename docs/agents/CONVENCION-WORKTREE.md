# Convención — worktree real por tarjeta

Decisión del Dueño, registrada como **D-021**. Aplica a toda tarjeta trabajada desde el tablero
`glowapp` del gateway de Hermes: los seis agentes de línea y el Orquestador.

## Dónde vive el código

- **Staging (bare local):** `~/AppData/Local/hermes/kanban/boards/glowapp/repo.git`. Su `main` es la
  de producción y su `origin` apunta a sí mismo: **no hay a dónde empujar hacia GitHub**.
- **Worktree de una tarjeta:** `.../kanban/boards/glowapp/worktrees/<task_id>`, en la rama
  `agent/<task_id>-<slug>`, nacida de `main`.
- Crear una tarjeta con worktree:
  `hermes kanban create … --workspace worktree --branch agent/<id>-<slug>`.

## Reglas duras

1. Se trabaja **sólo** dentro del worktree de la tarjeta y **sólo** en su rama. Nunca `main`.
2. **Nunca** push a GitHub, **nunca** usar credenciales, **nunca** `--force` ni `--force-with-lease`,
   **nunca** `gc`.
3. Un fix nace de un test que **primero falla**: se publica el rojo, después el fix, después el verde.
   Un fix se declara por el run, no por su razonamiento.
4. El entregable es la **rama con commit** + la salida cruda del test en la tarjeta + `Procedencia:`
   con el sha del commit. **El PR lo abre el Dueño.**
5. Nada se aplica a producción desde el tablero.

## Por qué

Un agente sin aislamiento trabaja sobre un checkout compartido y su daño es invisible: la primera
corrida del worker del webhook agotó **60/60 iteraciones** sin poder tocar el código (run 16,
`timed_out`). Con worktree, el cambio de un agente no puede pisar el banco de otro, y con el `origin`
neutralizado **el peor caso de un agente comprometido es un commit en un repositorio local**.

## Enforcement (medido, no confiado)

La compuerta `estadoTablero.py` marca `sin-aislamiento` a toda tarjeta en `ready`/`running`/`review`
asignada a un bot que no tenga rama declarada ni worktree en disco. Probada en los dos sentidos:

| Caso | Resultado |
| --- | --- |
| bot en `running`, sin worktree ni rama | **muerde** (`sin-aislamiento`) |
| bot en `running`, con rama declarada | calla |
| bot en `running`, con worktree en disco | calla |
| tarjeta de un agente que no es bot | no aplica |
