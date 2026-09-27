# ORDEN A-07 — RONDA 3 · «La evidencia o no cuenta»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-26
**Rama:** seguí en **`fix/gate-clasificado`**. Reglas de siempre: un worktree = un agente, sin `--force` ni `--force-with-lease`, sin merge, sin borrar ramas del remoto.
**Leé primero:** `docs/audit/AUDITORIA-ENTREGA-A-07-RONDA-2-2026-09-26.md`.

**Tu ronda 2 está bien donde revertiste** (lo verifiqué por diff: `membership.middleware` y `businessController` volvieron a la base, el validador quedó estricto, la matriz de permisos idéntica, ningún archivo de §3 tocado). Y bajó el rojo de verdad: **10 suites / 59 tests → 6 / 28**. Lo que falta es lo demás.

## Cargo 1 — Cargo 4 de la ronda 2: el crash del worker (bloqueante)

No lo re-midas: **está atribuido y reproducido**. El error de **timeout de `execSync`** no es serializable; lo lanza `src/tests/ciRagEvaluation.test.js` (dos `--help` con `{ timeout: 5000 }`), y por eso desaparecen exactamente **sus 8 tests** (551 → 543). Reproducción de una línea:

```
node -e "const{execSync}=require('child_process');try{execSync('node -e \"setTimeout(()=>{},9000)\"',{timeout:400})}catch(e){JSON.stringify(e)}"
⇒ TypeError: Converting circular structure to JSON  --> starting at object with constructor 'Error'  --- property 'error' closes the circle
```

Hacé:
1. **En la suite:** timeouts realistas (30 s) para los `--help`; **un timeout para `bash -n`** (hoy no tiene ninguno y puede colgar el gate); y un helper que, si el comando falla o vence, **rethrow un `Error` nuevo con el mensaje en string** (serializable) en vez de dejar propagar el error crudo de `execSync`.
2. **En el arnés (CI-37):** un `setupFiles` que convierta rechazos no manejados y excepciones en errores **serializables**, para que ningún test pueda volver a matar un worker.
3. **Prueba determinista (no estadística):** mutá el timeout a `1` ms y mostrá **dos textos**: (a) antes del fix, el worker muere con `Converting circular structure to JSON` y la suite figura «failed to run»; (b) después, el mismo vencimiento se reporta como un **fallo legible dentro de la suite**. Restaurá con `sha256`.

**Y no vuelvas a proponer una causa que no mediste.** «Fuga de concurrencia por no aislar bases por worker» no tiene ni una corrida detrás, y contradice la reproducción de arriba.

## Cargo 2 — Las 5 suites `business*`: que las fixtures satisfagan al middleware

Con las reversiones, el rojo cambió de naturaleza: **ya no hay 500s, hay 403s** (19 × «esperado 200 / recibido 403» en mi corrida). O sea: el middleware deniega **correctamente** y lo que falta son **perfiles/membresías reales** sembrados en la base de test que satisfagan su comprobación.

Hacé que las fixtures (perfil + membresía + tenant) cumplan la condición **en base limpia**, y si el 403 **persiste** después de sembrar lo que el middleware pide, **pará y reportá**: es un hallazgo de producción. En ese caso traé: (1) el SQL exacto que sembraste, (2) la consulta que ejecuta el middleware, (3) el resultado de esa consulta. **No fuerces el verde**: un test que pasa por un atajo ya nos costó una ronda.

## Cargo 3 — `adminPreciosRoutes`: causa raíz

Sigue con 4 tests rojos (`403 esperado → 400`, `200 esperado → 400`) — y en la ronda 1 esta misma suite fue declarada «5/5 PASS, medido y verificado». Decidí: ¿falta el **rol admin** en la base de test (fixture), o la ruta exige un permiso que la matriz oficial no concede (contrato)? Traé la causa con la evidencia que la sostenga.

## Cargo 4 — Reporte con salida cruda (obligatorio de acá en adelante)

Cada afirmación de comportamiento se acompaña de:
- la **salida cruda** (`Tests:` / `Test Suites:`), pegada tal cual;
- la **receta declarada**: checkout LF, base limpia, cómo la preparaste;
- por cada fix, **la mutación que lo voltea**, ejecutada y restaurada con `sha256`.

Sin eso no hay verificación, y sin verificación no hay aceptación. «Documentado» sin documento no es evidencia.

## Compuertas antes de empujar

1. `git status --porcelain` + `git log -1 --format='%h %s'`.
2. Las 10 suites aisladas (`--runInBand`), **antes y después**, en tabla.
3. `node --check` de todo archivo tocado.
4. Lo que no puedas medir: se declara **«no medido»** con el motivo. Nunca se rellena con una hipótesis.
