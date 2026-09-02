# GIA-12-I — Product Value Metrics Report

## 1. FORMULACIÓN Y FUENTE DE MÉTRICAS CLAVE
* **Activation Rate:** $\frac{\text{Ciclos creados con baseline}}{\text{Usuarios registrados}} \times 100$ (Fuente: `glow_cycles`).
* **Check-in Adherence:** $\frac{\text{Días con check-in}}{\text{Días transcurridos}} \times 100$ (Fuente: `checkin_history`).
* **Day-15 Rescan Rate:** $\frac{\text{Mediciones en día 15}}{\text{Ciclos activos con } \ge 15\text{ días}} \times 100$ (Fuente: `glow_cycle_measurements`).
* **Transformation Rate:** $\frac{\text{Ciclos con } \Delta > 0}{\text{Ciclos re-escaneados}} \times 100$ (Fuente: `score_delta`).
* **Cycle Graduation Rate:** $\frac{\text{Ciclos con status 'completed'}}{\text{Ciclos totales iniciados}} \times 100$.

## 2. ESTADO DEL GATE
🟢 **PASS**
