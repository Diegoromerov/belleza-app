# Plantilla de AUDITORÍA — para el Auditor

> Se audita **la rama real**, nunca el walkthrough. Toda cifra lleva su comando. Las retracciones se publican.

---

## AUDITORÍA — <orden> · ronda <n>

**Fecha:** <fecha> · **Auditor:** Hermes
**Objeto auditado:** rama `<rama>` @ `<sha>` · `git status --porcelain` = <n entradas> · repositorio `<ruta>`
**Método:** <qué leí, qué corrí, qué muté — en una línea por sonda>
**Procedencia de la entrega:** `git log -1 --format='%h %ci %s'` ⇒ <salida>

### Veredicto por criterio
| # | Criterio de la orden | ✓/✗/~ | Evidencia (comando + salida cruda) |
|---|---|---|---|
| C1 | | | |

Leyenda: ✓ cumple · ✗ no cumple · ~ parcial o no verificable en este entorno.

### Hallazgos
| # | Gravedad | Hallazgo | Evidencia `archivo:línea` | Defecto que causa |
|---|---|---|---|---|
| H-1 | alta/media/baja | | | |

### Lo verificado a favor
<lista de lo que sí se comprobó, con su evidencia — no todo es defecto>

### Retracciones del Auditor
<afirmaciones propias que resultaron falsas, con la medición que lo demostró>

### Decisión
- [ ] Cierra: <qué queda cerrado y con qué evidencia>
- [ ] Siguiente ronda: ORDEN-<n+1> con los hallazgos H-x..H-y
- [ ] Escala al Dueño por: <dinero | seguridad | producción | excepción | dos rondas sin progreso>

### Cobertura de la base de conocimiento
Qué entradas de `docs/knowledge/` deben actualizarse con esta ronda (ESTADO-ACTUAL, DEUDA, TRAMPAS, DECISIONES).
