# Auditoría — CI-52 bis ronda 4 (rama `fix/ci49-credencial-no-publicada`)

**Auditor:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
**Procedencia:** tip **`9d52aed1b`** (4 commits sobre `main`), merge-base **`8ad61234a`**. Worktree propio, banco intacto.
**Veredicto:** **ACEPTADA**. La regresión está cerrada y la serie CI-49/CI-52 queda completa.

---

## 1. Lo pedido vs lo medido

| Criterio | Medido |
|---|---|
| Alcance | ✅ 2 archivos, `11+/3-` y `4+/2-`, sin ruido |
| Sonda de los dos sentidos | ✅ **20/20** — 7 defectos detectan, 13 legítimos no ⇒ 0 FP / 0 FN |
| **El caso de la regresión** | ✅ `const X_PASSWORD = process.env.X_PASSWORD \|\| 'letmein';` ⇒ **DETECTA** (en la ronda 3 no lo hacía) |
| Sacrificios aceptados, siguen igual | ✅ los 5 casos declarados en la ronda 3 siguen sin detectarse, a propósito |
| Comentarios en el código | ✅ `verifyNoVersionedSecrets.js:106,113,114` — los tres, con la nota «sacrificio aceptado (CI-52)» |
| Compuerta sobre el árbol | ✅ `exit 0` |
| Tests del escáner | ✅ **16/16** |
| Gate, dos líneas | ✅ (declaradas; verificación propia abajo) |

## 2. Estado final de la serie

| ronda | qué cerró | estado |
|---|---|---|
| 1 | `seed.sql` deja de publicar la credencial; siembra fail-closed (`SEED_PASSWORD`) | aceptada parcialmente ⇒ residuo al hueco del default literal |
| 2 | 13 literales fuera del árbol (diff mínimo: se va el literal, queda la variable); la compuerta **ve** la forma `\|\|`/`??` y `.env` | aceptada; dejó CI-52 (falsos positivos preexistentes) |
| 3 | CI-52: el valor decide, no el nombre — 7 negativos y 6 positivos con su caso | aceptada; introdujo la regresión del filtro de entropía |
| 4 | la regresión, acotando el filtro al patrón de asignación directa | **aceptada** |

**Cierre de clase:** ninguna credencial que autentique queda publicada en el árbol (los literales de `seed.sql`, los 13 defaults y el de `socialService.js`), la compuerta detecta las formas del defecto **y** no marca el código legítimo, y el gate del CI no agrega rojos. Los dos sacrificios declarados (sufijos `_NAME`/`_TYPE`, y minúsculas <12 en asignación directa) quedan **escritos en el código y en la ficha** como deuda consciente, no como olvido.

## 3. Evidencia cruda

`scratch/ci49/`: `aud12.sh` (procedencia, árbol, sonda de 20 casos, sonda de filtros, tests, comentarios), `probe3.js`, `probe4.js`, `gate_r4.txt`.
