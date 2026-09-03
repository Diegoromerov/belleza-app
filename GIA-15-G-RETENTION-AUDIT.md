# GIA-15-G — Retention Audit Report

## 1. COHORTES Y SUPERVIVENCIA DEL CICLO
* **Cohortes Observables en Base de Datos:**
  - **D1 Retention:** Creación de ciclo $\rightarrow$ Primer check-in matutino/nocturno.
  - **D15 Retention:** Retorno en Día 15 y ejecución de re-scan $S_1$.
  - **D30 Retention:** Retorno en Día 30, ejecución de re-scan $S_2$ y graduación del ciclo.
* **Consulta SQL Canónica:**
  ```sql
  SELECT status, COUNT(*) FROM glow_cycles GROUP BY status;
  ```

## 2. ESTADO DEL GATE
🟢 **PASS**
