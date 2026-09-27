# ORDEN A-06 · RONDA 4 (corta) — el autotest tiene que poder caer

**Rama:** `fix/compuerta-secretos-reproducible` (2a). **2b (`fix/jwt-sin-respaldo`) sigue encadenada: 2a y 2b aterrizan juntas**, y 2b **no se mergea** hasta que el Dueño confirme en Railway que `JWT_SECRET` y `BIOMETRIC_ENCRYPTION_KEY` están provisionadas.
**Auditoría que la origina:** `docs/audit/AUDITORIA-ENTREGA-A-06-RONDA-3-2026-09-25.md` §C1 y §Retracción.
**Ya aceptado en la ronda 3 (no se toca):** `EXENTAS` acotado a `docs/**/*.md`, `test` fuera de las tres reglas, el literal eliminado y la clave de test generada en runtime, `DEUDA.md` de la raíz fuera.

## El problema, medido por mí

- Retirar la normalización global de **`:140`** deja la compuerta **MUDA**: `exit 0` con **8 credenciales en el árbol**.
- Los **9** `replace(/\r$/, '')` de los sitios de llamada **no cambian ni un hallazgo**: medido retirándolos todos (8 = 8) ⇒ son **decorativos**.
- **Ningún test se pone rojo en ninguno de los dos casos**, porque el autotest actual prueba `validarLinea(..., normalize)` pasando **él mismo** el flag: prueba el flag, no el pipeline.

## Cargo 0 — rebasa antes de tocar

`merge-base` con `fase-a` = `c1069e9f`; la punta es **`3cef7f88`**. Rebasa (sin conflictos esperados: los commits nuevos de `fase-a` tocaron `index.js`, `smokeSurfaces.js`, `degradedLock.js` y `adminMetricsService.js`, no el escáner). Si aparece un conflicto, **párate y avísame**. Criterio: `merge-base` = `3cef7f88`.

## Cargo 1 — separa el pipeline de la salida del proceso

Hoy `runScanner()` llama `process.exit()` **dentro** (`:192`, `:200`) y `gitGrep()` es quien normaliza (`:140`): por eso el único test posible es el del helper. Separa:

1. `gitGrep()` devuelve la salida **cruda** (sin normalizar).
2. Nueva función **pura y exportada** — p. ej. `analizarSalida(rawOutput, { repoRoot })` — que hace la **normalización** y devuelve `{ hallazgos, exitCode }`: **sin `process.exit`, sin `console.log`, sin invocar git**.
3. `runScanner()` queda: `gitGrep` → `analizarSalida` → imprimir → `process.exit(exitCode)`.
4. Exporta `analizarSalida` junto a `validarLinea`.

## Cargo 2 — el test que puede caer (esto es lo que se pide)

En `backend/src/tests/verifyNoVersionedSecrets.test.js`, **por el pipeline** y no por `validarLinea`:

1. **CRLF = LF:** la misma línea con secreto, una con `\r\n` y otra con `\n`, entran por `analizarSalida` y producen **el mismo conjunto de hallazgos**, y **no vacío**.
2. **No está mudo:** para una entrada conocida, la lista de hallazgos tiene **exactamente N** elementos (una compuerta que devuelva `[]` siempre falla aquí).
3. **La mutación, pegada:** neutraliza la normalización dentro de la función pura (`return rawOutput;`) ⇒ el test 1 y/o el 2 se ponen **ROJOS**. Pega la salida del fallo, restaura, y demuestra que vuelven a verde. **Si no se pone rojo, la tarea no está hecha.**
4. **Los 9 strips decorativos:** elimínalos o demuestra con un test por qué alguno importa (medí que no cambian ni un hallazgo; dejarlos sugiere una cobertura de CRLF que no existe).
5. El test que ya tienes con `validarLinea(..., false)` puede quedarse, pero **no cuenta** como prueba del pipeline.

## Cargo 3 — CONDICIONAL: solo si el Dueño lo autoriza en el mismo mensaje

Las **5 líneas de prosa** que bloquean el paso 7 (**CI-14**): `AUDITORIA_PREPRODUCCION_MASTER.md:84`, `BLOQUE_TRABAJO_1_BASELINE.md:144`, `auditoria-belleza-app.md:232` y `:233`, `scripts/COMO_EJECUTAR.md:35`. Sustituir **solo el valor** por `***`, sin reescribir el texto del informe, y volver a correr el escáner para pegar el conteo nuevo.
**Sin autorización explícita del Dueño, no toques esos archivos**: quedan fuera de esta orden y el paso 7 sigue rojo.

## Criterios de cierre

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | `analizarSalida` exportada, pura (sin `process.exit`, sin `console.log`, sin git) | lectura + `grep -n "module.exports"` |
| C2 | CRLF y LF ⇒ **el mismo conjunto** de hallazgos, y no vacío | salida del test |
| C3 | Entrada conocida ⇒ **exactamente N** hallazgos | salida del test |
| C4 | **Mutación pegada**: `return rawOutput` ⇒ test **rojo** | salida del fallo + restauración |
| C5 | Los 9 strips: fuera, o justificados con un test | grep + salida |
| C6 | `git merge-base origin/fase-a/verdad-operativa HEAD` = `3cef7f88…` | comando |
| C7 | `npm test` con su resumen (failed/passed/total), incluida esta suite | salida |
| C8 | 2a y 2b encadenadas (2b rebasada en el mismo paso) | SHAs de las dos ramas |

## Prohibiciones

Llamar `runScanner()` desde un test (sale del proceso) · dejar `process.exit` dentro de la función pura · «lo probé a mano» sin salida pegada · tocar `EXENTAS` o las tres reglas (ya aceptadas) · eximir por **prefijo** en vez de por valor exacto · tocar los 5 archivos de prosa **sin autorización** · abrir una rama nueva para esta ronda · mergear 2b antes de la confirmación del Dueño.
