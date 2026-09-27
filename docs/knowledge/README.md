# Base de conocimiento — Belleza App / GlowApp

**Para qué existe:** para que nadie tenga que volver a descubrir qué hace esta app, qué está roto y por qué se decidió lo que se decidió. Un agente (o una persona) nuevo debe poder trabajar leyendo **solo el repositorio**.

**Regla de oro:** la información relevante vive aquí. Un hallazgo que no llega a este directorio es un hallazgo que se perderá cuando se compacte la conversación donde se descubrió.

---

## Índice

| Documento | Qué responde | Estado |
|---|---|---|
| [`ARQUITECTURA.md`](ARQUITECTURA.md) | ¿Cómo está construida y por dónde entra cada flujo? Con `archivo:línea`. | generado 2026-09-24 |
| [`ESTADO-ACTUAL.md`](ESTADO-ACTUAL.md) | ¿Qué funciona y qué no, hoy? Incluye un bloque máquina que se regenera con `node backend/scripts/estadoKB.js --write`. | bloque máquina: se regenera solo |
| [`DEUDA.md`](DEUDA.md) | ¿Qué está roto, con qué evidencia, quién lo arregla y cómo se sabe que quedó arreglado? | consolidada 2026-09-24 |
| [`TRAMPAS.md`](TRAMPAS.md) | ¿Qué trampas ya nos costaron tiempo y cómo se detectan? | consolidada 2026-09-24 |
| [`DECISIONES.md`](DECISIONES.md) | ¿Qué se decidió, cuándo y por qué? (registro tipo ADR) | 2026-09-24 |

## Documentos vecinos (no son KB, son proceso)

| Documento | Para qué |
|---|---|
| [`../agents/SISTEMA.md`](../agents/SISTEMA.md) | El sistema de agentes: roles, contratos, reglas duras, autonomía |
| [`../agents/COLA.md`](../agents/COLA.md) | Qué está pedido, en curso, bloqueado y cerrado |
| [`../agents/PLANTILLA-ORDEN.md`](../agents/PLANTILLA-ORDEN.md) | Plantilla de orden de trabajo (GOAL) |
| [`../agents/PLANTILLA-AUDITORIA.md`](../agents/PLANTILLA-AUDITORIA.md) | Plantilla de auditoría (veredicto con procedencia) |
| [`../policies/ramas.md`](../policies/ramas.md) | Política de ramas y veredictos |
| `../audit/` | Auditorías e informes crudos, archivados con su fecha |
| `../agents/ordenes/` | Las órdenes (prompts) entregadas, para que no se pierdan entre rondas |

## Cómo se mantiene

1. **Al cerrar cada ronda** el Arquitecto actualiza: `ESTADO-ACTUAL.md` (qué cambió), `DEUDA.md` (qué se cerró y qué se abrió), `TRAMPAS.md` (si apareció una trampa nueva) y `DECISIONES.md` (si hubo una decisión no obvia). `COLA.md` siempre.
2. **Cada afirmación lleva su fuente**: `archivo:línea` para el código, documento + sección para las auditorías, y el **comando** para cualquier número.
3. **Si algo no se pudo verificar, se escribe `NO VERIFICADO`.** El silencio no es una opción; el relleno plausible es peor que el hueco.
4. **Ningún dato se copia sin su fecha.** Un número sin fecha de medición es un rumor con buenos modales.
