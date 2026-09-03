# GIA-04-C — Delta & Decision Model Report

## 1. FORMULACIÓN MATEMÁTICA Y SEMÁNTICA DEL DELTA

### A. Delta Cuantitativo
$$\Delta_{\text{metric}} = S_t - S_0$$
* Para métricas ascendentes (ej. `hydration`): $\Delta > 0$ indica avance.
* Para métricas descendentes (ej. `wrinkles`, `pores`, `spots`): $\Delta < 0$ indica mejora.

### B. Factor de Adherencia ($A$)
$$A = \frac{\text{Check-ins Realizados}}{\text{Días Transcurridos}} \times 100\%$$
* Si $A \ge 70\%$: Alta adherencia $\rightarrow$ El resultado es atribuible a la eficacia del plan.
* Si $A < 70\%$: Baja adherencia $\rightarrow$ El estancamiento se interpreta como falta de constancia antes de cambiar la fórmula cosmética.

### C. Matriz de Decisión del Siguiente Estado

| Delta ($\Delta$) | Adherencia ($A$) | Decisión | Acción del Sistema |
|---|:---:|:---:|---|
| $S_t \ge \text{Target}$ | Cualquiera | `completed` | Cierra ciclo con éxito y propone nuevo objetivo/ciclo. |
| $\Delta > 0$ | $\ge 70\%$ | `maintain` | Conserva rutina y refuerza hábitos. |
| $\Delta \le 0$ | $< 70\%$ | `maintain` | Recuerda importancia de constancia sin alterar fórmula. |
| $\Delta \le 0$ | $\ge 70\%$ | `intensify` / `modify` | Añade boosters o sustituye activos irritantes. |
| Fallo de sensor | N/A | `review` | Solicita nueva fotografía bajo mejor iluminación. |

## 2. ESTADO DEL GATE
🟢 **PASS**
