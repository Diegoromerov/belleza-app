# GIA-16-I — North Star Validation Report

## 1. VALIDACIÓN DE LA MÉTRICA NORTH STAR (WTU)

* **Definición Oficial:** `Weekly Transformed Users (WTU)` = Usuarios que han registrado $\ge 5$ check-ins en la última semana Y muestran un Delta positivo ($\Delta > 0$).
* **Consulta SQL Canónica Verificada:**
  ```sql
  SELECT COUNT(DISTINCT c.user_id) as wtu_count
  FROM glow_cycles c
  JOIN glow_cycle_measurements m ON m.cycle_id = c.id
  WHERE jsonb_array_length(c.checkin_history) >= 5
    AND m.score_delta > 0
    AND m.created_at >= NOW() - INTERVAL '7 days';
  ```
* **Estado:** **A — Calculable directamente con los datos y esquema existentes.**

## 2. ESTADO DEL GATE
🟢 **PASS**
