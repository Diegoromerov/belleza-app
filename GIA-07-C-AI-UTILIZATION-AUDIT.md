# GIA-07-C — AI & Agents Utilization Audit Report

## 1. FLUJO DE DATOS POR COMPONENTE DE IA

| Componente | INPUT | PROCESSING | DECISION | OUTPUT |
|---|---|---|---|---|
| **YouCam** | Imagen facial | Detección bio-óptica | N/A | Puntuaciones numéricas (hidratación, manchas, etc.) |
| **Gemini** | Imagen de manos / piel | Inferencia multimodal | N/A | Diagnóstico cualitativo de textura / tono |
| **Atena** | Scores numéricos | Mapeo dermatológico | Selección de principios activos | Plan estructurado AM/PM y motivos |
| **Chronos** | Fecha de inicio del ciclo | Cálculo temporal de días | Estado en máquina de continuidad | Recordatorio canónico y próximo hito |
| **Transformation Engine** | Delta $\Delta$ y Adherencia $A$ | Comparación determinista | `maintain` / `intensify` / `modify` / `completed` | Rutina adaptada para el ciclo |
| **Hestia** | Activos recomendados | Búsqueda en catálogo | Sugerencia subordinada opcional | SKUs pertinentes de GlowStore |
| **Hermes** | Severidad dérmica alta | Geolocalización PostGIS | Derivación a profesional | Servicios locales de Marketplace |

## 2. BALANCE DE COMPLEJIDAD
Se cumple la regla de **máxima inteligencia con mínima complejidad**: cero llamadas LLM para matemáticas, cero alucinaciones en el cálculo del Delta y trazabilidad absoluta.
