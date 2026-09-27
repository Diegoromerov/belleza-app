# Informe porcentual — Fase A «Verdad operativa»

**Fecha:** 2026-09-27 (tarde) · **Autor:** Hermes (Arquitecto) · **Cálculo:** `docs/knowledge/scripts/avanceFaseA.js` (versionado; se ejecuta, no se transcribe)

---

## 1. Los tres números

| Número | Valor | Qué mide |
|---|---|---|
| **Trabajo técnico hecho** | **97,5 %** | Todo lo comprometido en la fase, con los pesos acordados |
| Criterios firmables | **97,5 %** | 3 de 4 criterios de aceptación en 1,00 |
| Aterrizaje | **1,00 de 1,00** | El trabajo está en `main` y verificado contra el remoto |

Con A-04 aceptado y A-07 incorporado al denominador por autorización del Dueño: **97,5 %**.

## 2. Cómo se compone

| Componente | Peso | Valor | Aporte |
|---|---|---|---|
| Criterios de aceptación | 0,50 | 97,5 % | 48,75 |
| Entregables A-01…A-07 | 0,30 | 95,7 % | 28,71 |
| Aterrizaje | 0,20 | 100,0 % | 20,00 |
| **Total** | **1,00** | | **97,46 ⇒ 97,5 %** |

## 3. Criterios (peso 0,50) ⇒ 97,5 %

| | Valor | Estado |
|---|---|---|
| S1 | **1,00** | Con la base caída, `/api/products` responde `503 DATA_LAYER_DEGRADED`. Medido por el Auditor en vivo |
| S2 | **1,00** | `/api/health` da `503 DEGRADED` con `pgAvailable:false` y `200` con `true` |
| S3 | **0,90** | El gate dice la verdad medido (10 suites / 55 rojos, 0 `failed-to-run`, «rojo fantasma» atribuido). **No llega a 1,00 por una razón externa**: el criterio literal «romper un test ⇒ run rojo **en GitHub**» no se puede observar porque el paso de tests nunca corre allí (queda `skipped` detrás del paso de preparación de la base) |
| S4 | **1,00** | `smoke:surfaces` sale `≠0` si algo finge; verificado con mutación |

## 4. Entregables (peso 0,30) ⇒ 79,2 % · sin A-04 ⇒ 95,0 %

| | Valor | Estado |
|---|---|---|
| A-01 | **1,00** | Aislamiento multi-tenant: 22 pruebas ejecutadas, 0 omitidas (13 tablas con RLS+FORCE, escritura ajena `42501`, trigger de `tenant_id`) |
| A-02 | **1,00** | CI-18 cerrada: el mes proyectado ya no salta un mes |
| A-03 | **1,00** | 57 rutas muertas retiradas (308→252), 0 pérdidas; mutaciones A/B en rojo |
| A-04 | **0,00** | `backend/public`: 192 archivos versionados pese a `.gitignore:68`. **Bloqueada por decisión del Dueño** — es 5,0 pp del total y van a seguir faltando hasta que se decida |
| A-05 | **0,85** | Documenta la procedencia del recuento; robusto al CRLF (misma salida en CRLF y LF). Sin auditoría propia ⇒ no 1,00 |
| A-06 | **0,90** | Escáner nuevo: 8 hallazgos en CRLF y 8 en LF (el viejo: 1 vs 39 ⇒ CI-31) ⇒ el gate dice lo mismo en Windows y en el CI. Residuos que esperan a terceros (Railway, decisión del Dueño) |

## 5. Fuera del denominador: A-07 «el gate tiene que decir la verdad» ⇒ 0,95

Nació después de declarados los criterios. Cerró CI-41 y arregló el crash del worker con prueba determinista. Queda 0,95 porque CI-37 es una mitigación **sin demostración** (ninguna de las dos mutaciones disparó el arnés).

**Si el Dueño decide incorporarlo:** entregables ⇒ **81,4 %** · total ⇒ **93,2 %**.

## 6. Qué falta, y cuánto mueve cada cosa

| Pieza pendiente | Valor | Mueve |
|---|---|---|
| **A-04** (decisión del Dueño sobre `backend/public`) | 0,00 → 1,00 | **+5,00 pp** |
| S3 (paso de tests corriendo en GitHub) | 0,90 → 1,00 | **+1,25 pp** |
| A-05 (auditoría propia) | 0,85 → 1,00 | **+0,75 pp** |
| A-06 (cerrar sus residuos) | 0,90 → 1,00 | **+0,50 pp** |
| | | **+7,50 pp ⇒ 100,0 %** |

**La pieza más grande no es técnica:** son 5 de los 7,5 puntos que faltan, y están esperando una decisión, no trabajo.

Bloqueos que **no** mueven el número pero sí el cierre: la firma de **D-017** (alcance del candado), y los tres hallazgos del CI que impiden que los tests corran en GitHub — **CI-46** (el paso de preparación falla en el runner), **CI-43** (la base del CI no tiene el esquema del subsistema de negocio: 23 rojos = 17 × 403 + 6 cascadas, cero 500) y **CI-45** (el guard anti-marcadores no ve `.github/`). **CI-47** (`rag-evaluation.yml`) es ajeno a la fase.

## 7. Cómo se mide (para que el número sea auditable)

- Todo veredicto se corre con **el comando exacto del CI**, sobre base real y **no** sobre el respaldo de memoria (`NODE_ENV=test` del `pool` fabrica respuestas).
- Los tests se ejecutan con **LF**, para que el veredicto no dependa del final de línea del checkout.
- Ningún veredicto se firma sin **mutación**: si el test no falla cuando el comportamiento se rompe, el test no prueba nada.
- Cada afirmación viaja con **procedencia** (`git log -1`, `git status --porcelain`), y lo retractado **se registra, no se borra**.

## 8. Lo que este número NO dice

- **No dice que los tests pasen en GitHub.** El paso de tests sigue sin correr en el runner (CI-46); los 23 rojos se midieron **en local con la base del CI**, no allí.
- **No dice que todo esté auditado por mí.** A-05 0,85 y A-06 0,90 están ahí precisamente porque su auditoría no está hecha.
- **No dice que no queden hallazgos.** CI-37 (arnés sin demostración), CI-45 y CI-47 están abiertos; ninguno resta al porcentaje porque el porcentaje mide lo comprometido, no la deuda descubierta por el camino.

---

*La deuda completa está en `DEUDA.md`; el estado largo, en `ESTADO-ACTUAL.md`; el número se reproduce con `node docs/knowledge/scripts/avanceFaseA.js`.*
