# Entrega — Sistema de agentes y base de conocimiento (O-006)

**Fecha:** 2026-09-24 · **Autor:** Hermes (Arquitecto) · **Rama:** `docs/sistema-agentes` desde `main = f5a1b4fc`
**Encargo del Dueño:** «crea un sistema de agentes que estructuren el desarrollo, con plena autonomía, en sistema GOAL, sin intervención humana, priorizando la conservación de la información relevante».

---

## 1. Qué se entregó

| # | Artefacto | Qué resuelve |
|---|---|---|
| 1 | `docs/agents/SISTEMA.md` | Los 4 agentes + el Dueño: autoridad, prohibiciones, ciclo de ronda, 4 contratos de entrega, 10 reglas duras, tabla de autonomía y escalado |
| 2 | `docs/agents/COLA.md` | 7 órdenes y 4 decisiones del Dueño con estado, artefacto y bloqueo; registro de lo cerrado |
| 3 | `docs/agents/PLANTILLA-ORDEN.md` | Orden en GOAL: contexto medido, criterios falsables, mutación obligatoria, NO TOCAR, evidencia exigida |
| 4 | `docs/agents/PLANTILLA-AUDITORIA.md` | Veredicto por criterio, hallazgos con `archivo:línea`, retracciones, decisión de cierre o ronda siguiente |
| 5 | `docs/knowledge/README.md` | Índice y regla de oro: la información relevante vive en el repositorio |
| 6 | `docs/knowledge/ARQUITECTURA.md` | 403 líneas, 183 citas `archivo:línea`: arranque, componentes, capa de datos, integraciones reales vs simuladas, runner de migraciones, trampas, y 6 puntos `NO VERIFICADO` |
| 7 | `docs/knowledge/DEUDA.md` | 181 filas trazables (ID · defecto · evidencia · clase · dueño · criterio de aceptación falsable · estado) + cerrados con evidencia + decisiones del dueño + no verificado + 10 ambivalencias entre fuentes |
| 8 | `docs/knowledge/TRAMPAS.md` | 40 trampas medidas (síntoma · causa raíz · cómo se detectó · falso veredicto · regla) + 5 trampas de razonamiento del propio auditor + 7 reglas transversales |
| 9 | `docs/knowledge/ESTADO-ACTUAL.md` | Estado con evidencia, criterios S1-S4 de la Fase A, compuertas, suites rojas heredadas y **bloque máquina** autogenerado |
| 10 | `docs/knowledge/DECISIONES.md` | 14 ADR con contexto, decisión y alternativa descartada |
| 11 | `docs/policies/ramas.md` | Política de ramas y veredictos (9 secciones) |
| 12 | `backend/scripts/estadoKB.js` | El **Guardián**: vigila R1-R5 y falla con `exit 1` |
| 13 | `docs/audit/` (50 archivos) · `docs/agents/ordenes/` (15) | Todas las auditorías, informes y órdenes que vivían en una carpeta local: **ya versionadas** |
| 14 | `docs/agents/ordenes/PR-FASE-A-cuerpo.md` | Cuerpo listo para pegar del PR de `fase-a`, con la advertencia de verde-por-exclusión |
| 15 | Cron «Guardián de estado — Belleza App» + `~/AppData/Local/hermes/scripts/guardian-belleza.sh` | El sistema se revisa solo los lunes 9:00 y entrega el parte |

## 2. Verificación ejecutada (no declarada: medida)

| Qué | Cómo | Resultado |
|---|---|---|
| El Guardián **puede** fallar | `git branch tmp-zombi main` y `node backend/scripts/estadoKB.js --check` | **exit 1** con la regla R3 violada ✓ (rama zombi borrada después) |
| El Guardián aprueba lo sano | `--check` tras el commit | **exit 0**, «0 desalineaciones» ✓ |
| El bloque máquina se regenera | `--write` | bloque refrescado dentro de los marcadores ✓ |
| Citas de `ARQUITECTURA.md` | conteo de `archivo:línea` | 183 citas en 403 líneas ✓ |
| Filas sin dueño en `DEUDA.md` | `awk` sobre la tabla consolidada | **0** filas sin dueño A/H/D ✓ |
| Trampas obligatorias | grep de 11 claves (`branch -d`, `origin/HEAD`, `merge-base`, `svglib`, `refs/remotes`, `331`, `worktree remove`…) | todas presentes ✓ |
| **Auditoría de la propia KB** | contraste de 5 afirmaciones contra el código | **1 defecto encontrado y corregido** (ver §3) |

## 3. Defecto encontrado **dentro de la entrega** y corregido

La fila `SEG-11` de `DEUDA.md` (TLS sin verificar) citaba `db.js:23` y `db.js:667`, que **hoy no contienen `rejectUnauthorized`**: eran citas heredadas de auditorías del 22-sep sobre **otra revisión** del árbol.

- Verificación: `grep -rn "rejectUnauthorized" backend/ --include=*.js` → 8 apariciones reales: incondicionales en `index.js:278`, `config/config.js:13,26`, `knexfile.js:8`, `runMigrations.js:84`; condicionales (solo desactivan con `DB_SSL_REJECT_UNAUTHORIZED='false'`) en `src/config/db.js:21` y `src/config/database.js:31`; correcta en `services/biometric/youcam.client.js:9`.
- Corrección aplicada: la fila lleva ahora las 8 citas verificadas, la severidad real (5 sitios incondicionales, no 3) y la fecha de corrección.
- Lección registrada como trampa `R-05 · Citar una línea que ya no dice eso`: **consolidar no es medir; toda cita heredada se re-verifica antes de publicarse.**

## 4. Conservación de la información (lo que pidió el Dueño)

Antes: arquitectura, deuda, trampas y decisiones existían dispersas en 27 archivos de una carpeta local (`C:/Users/Compu casa/auditorias/belleza-app/`) más el historial del chat. **Nada de eso estaba en el repositorio** y el chat se compacta.
Ahora: `docs/knowledge/` + `docs/audit/` + `docs/agents/ordenes/` están versionados en la misma rama que el código que describen, con fecha, fuente y comando por número. La carpeta local pasa a ser borrador.

## 5. Estado de la autonomía

| Pieza | Estado |
|---|---|
| Bucle de agentes definido (Arquitecto → Ejecutor → Guardián → Auditor → Dueño) | **listo** |
| Cola con las órdenes siguientes (O-001…O-005) | **listo** |
| Guardián automático (scripts + CI por PR + cron semanal) | **armado**; el cron corre en el gateway recién instalado (lunes 9:00, primer parte 2026-09-28) |
| Ejecución autónoma del **desarrollo** | **bloqueada por una decisión del Dueño (D-001)**: sin PR de `fase-a` no existe ningún run de CI que el sistema pueda vigilar |

## 6. Lo que NO se pudo verificar

- `MOCK_MODE` está declarado en `railway.yml:45-46` y **no tiene consumidor** en el repo (grep sin resultados): se desconoce qué servicio lo lee.
- Las 7 migraciones `.js` de `backend/migrations/` no las referencia ningún require ni script; `runMigrations.js` lista 6 `.sql`.
- Si `backend/public` corresponde al HEAD de `frontend/` (los artefactos no llevan referencia al commit; `.last_build_id` es un hash opaco).
- Estado real de las variables de entorno de producción y del `schema_migrations` desplegado: requiere acceso al entorno.
- 10 ambivalencias entre auditorías listadas en `DEUDA.md` §«Ambivalencias de las fuentes» (conteos de suites rojas no deterministas, estado de la academia, mocks biométricos del frontend, etc.).

## 7. Lo que hace falta del Dueño para que el sistema ejecute solo

1. **D-001** · Abrir el PR de `fase-a/verdad-operativa` (cuerpo listo en `docs/agents/ordenes/PR-FASE-A-cuerpo.md`).
2. **D-002** · `delete_branch_on_merge = on`.
3. **D-003** · Decidir sobre los 331 commits del fósil (sin publicar por riesgo de secretos).
4. Mergear esta rama (`docs/sistema-agentes`) para que la KB y el Guardián vivan en `main`.
