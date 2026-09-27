# AUDITORÍA INDEPENDIENTE — ORDEN A · O-014 · RONDA 8 (guardián en el repo)

**Veredicto: ACEPTADA** — los 7 tests pasan, la corrida real funciona sin mocks y las tres piezas del encargo resisten
mutación propia. Con **1 hallazgo de proceso** (la rama no está empujada) y una corrección al documento que se me
presentó como auditoría.

**Proveniencia:** rama `chore/guardian-en-el-repo` @ **`b919d45a`** · worktree autoritativo
`.gemini/antigravity/worktrees/beauty-app/setup_glowguide_architecture` con `git status --porcelain` = **0 entradas**
(limpio) · HEAD del worktree = `b919d45a` = punta de la rama · medido 2026-09-26 08:2x -0500.

**Método:** toda afirmación de abajo salió de ejecución propia. Las mutaciones se aplicaron en un **worktree propio**
en `b919d45a` (`scratch/audit-o014/wt`), nunca en el worktree del Ejecutor; cada mutación se restauró y se verificó por
`sha256`.

---

## 1. Criterios verificados por ejecución propia

| # | Criterio | Evidencia propia | Estado |
|---|---|---|---|
| 1 | `to_native_path()` convierte POSIX → nativo para `node.exe` (CI-25) | código en `guardianBelleza.sh:5-22` (`cygpath` → `wslpath` → `sed`) | ✓ |
| 2 | `GUARDIAN_REPO` elige la copia a inspeccionar | `guardianBelleza.sh:26` | ✓ |
| 3 | `GUARDIAN_SKIP_NETWORK=1` omite consultas externas | `:44` + mensajes `NO VERIFICADO (omitido en tests)` en `:60,:72` | ✓ |
| 4 | **La corrida real resuelve la ruta nativa** | `GUARDIAN_SKIP_NETWORK=1 bash backend/scripts/guardianBelleza.sh` ⇒ **`EXIT=0`**, `ruta: C:/Users/…` (nativa) | ✓ |
| 5 | **Suite del guardián 7/7** | `jest --testPathPattern="guardianBelleza\|estadoKBFreshness"` ⇒ **2 suites, 7 tests, 0 fallos** | ✓ |
| 6 | **Mutación A** (devolver la ruta POSIX) ⇒ RED | control sin mutar **5 passed**; mutado **1 failed / 4 passed**; restaurado idéntico | ✓ |
| 7 | **Mutación B** (ignorar `GUARDIAN_REPO`) ⇒ RED | control **5 passed**; mutado **1 failed**; restaurado idéntico | ✓ |
| 8 | **Mutación C** (ignorar `SKIP_NETWORK`) ⇒ RED | control **1 passed / 4 skipped**; mutado **1 failed**; restaurado idéntico | ✓ |
| 9 | Parte regenerado con SHA real y `EXIT 0` | `docs/agents/partes/parte-2026-09-25.md:38` = `EXIT 0 (Alineado)` | ✓ |
| 10 | `SISTEMA.md` documenta invocación y gobernanza | `SISTEMA.md:18` (inventario) y `:21` (`GUARDIAN_REPO=…`, `GUARDIAN_SKIP_NETWORK=1` para tests) | ✓ |
| 11 | Salida honesta cuando la red falla | el propio parte imprime **`PRs abiertos: NO VERIFICADO (la consulta a la API falló; no se asume que sean 0)`** | ✓ |

## 2. Hallazgos

| # | Hallazgo | Gravedad |
|---|---|---|
| H-1 | **La rama `chore/guardian-en-el-repo` no existe en el remoto** (`git ls-remote --heads origin` no la lista). El trabajo vive sólo en ese worktree local, contra la regla «GitHub = única fuente de verdad» y con riesgo de pérdida. No la empujé yo: **el Ejecutor está activo y podría reescribirla**; empujarla es su paso (o del Dueño). | **CERRADO 2026-09-26**: la rama quedó empujada @ `b919d45a`; verificado por el Arquitecto contra el remoto (`git ls-remote` + `git fetch` + contenido) |
| H-2 | El documento que se me presentó declaraba las mutaciones (sus criterios 6 y 7) como verificadas, pero **su evidencia era «el test valida el patrón»** — no una mutación aplicada. Rehechas aquí (filas 6-8): sostienen. | Corregido en esta auditoría |
| H-3 | **`worktree null` @ `8c940f1`**: es **mi** worktree de medición (el tren para la reproducción del CI), no un defecto de la entrega. **Ya retirado**; quedan 3 worktrees (banco, el del Ejecutor, KB). | Cerrado |
| H-4 | El recuento de suites rojas de la suite completa (17 rojas / 64 verdes en el documento) **no lo re-medí**: es cita, no medición propia. Mi medición de referencia es sobre el tren (ver §3). | Declarado |
| H-5 | **El documento venía firmado «Auditor (Hermes)» y no lo escribió el Auditor.** Ver §4. | Proceso |

## 3. Medición propia para el aterrizaje: el gate bloqueante con base real

Corrido sobre el **tren integrado** (8 ramas) en una base limpia (`glowtest_gate`), con credenciales que autentican
(`app_rls_user`, no superusuario) y **0 errores de conexión** en el log:

| Configuración | Suites rojas | Tests |
|---|---|---|
| sin base utilizable | **10 de 75** | 59 rojos / 525 verdes |
| **con base real** | **11 de 75** | 59 rojos / 518 verdes |

Diferencia de conjuntos (es lo que importa, no el recuento): **con base real aparece una suite más,
`src/tests/ciRagEvaluation.test.js`**, y **ninguna desaparece** ⇒ las otras 10 rojas son **reales, no un artefacto de la
falta de base**, y el CI (que sí tiene PostgreSQL) mostrará **`ciRagEvaluation`**.

⇒ Consecuencia material: aun con CI-14 y 2b cerrados, **el paso bloqueante de tests seguirá rojo** en el PR. Es deuda
heredada declarada en el propio `ci.yml` (allí dice «15»: número **desactualizado**; hoy son 10-11 en el gate).

**Corrección registrada (2026-09-26, misma jornada):** el «11 con base real» de arriba **no se sostiene**. La suite de más era
`ciRagEvaluation.test.js` y su log dice `● Test suite failed to run → TypeError: Converting circular structure to JSON` en
`jest-worker/…/messageParent.js`: **no llegó a ejecutarse** (murió su worker). En aislamiento pasa **8/8 con y sin base** sobre
`fase-a @ b545ef22`. ⇒ El recuento correcto del gate es **10 suites rojas de 75**, y esa aparición fue **falso rojo del arnés**.
Queda registrado, no borrado (R-06); CI-29 se re-caracteriza en `DEUDA.md` y la regla se suma a `TRAMPAS.md`.

**Hilo abierto:** existe un workflow `rag-evaluation` que sale `failure` en nuestros pushes. `ciRagEvaluation.test.js`
falla sólo con base real: es candidato fuerte a **misma causa raíz** (sin diagnosticar).

## 4. Sobre el documento recibido y su firma (R-06)

El documento `pasted_content_2026-09-26_13-20-25-677_dcec97.txt` se titula «AUDITORÍA INDEPENDIENTE — ORDEN A · O-014 ·
RONDA 8», se firma **«Auditor (Hermes) — verificación independiente ejecutada 2026-09-26»** y **el Auditor no lo
escribió**. Se registra, no se borra. Consecuencias:

1. Sus conclusiones **no valen por su firma**: se re-verificaron una por una (§1) y las únicas que no resistían (las
   mutaciones) fueron reemplazadas por medición real (§2 H-2).
2. **Regla nueva (TRAMPAS):** la firma «Auditor» la usa sólo quien auditó en su propia sesión. Un documento con esa firma
   que no salió del Auditor entra al registro **como material a re-verificar**, nunca como evidencia.

## 5. Próximos pasos

1. **Ejecutor / Dueño:** empujar `chore/guardian-en-el-repo` @ `b919d45a` (H-1).
2. **Dueño:** decisión sobre el aterrizaje sabiendo que el backend quedará rojo por ~11 suites heredadas.
3. **Arquitecto (puedo tomarlo ya):** diagnosticar `ciRagEvaluation.test.js` + el workflow `rag-evaluation` — mismo
   síntoma, probablemente una sola causa raíz.
