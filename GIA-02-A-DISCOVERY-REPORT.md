# GIA-02-A — Discovery & Asset Mapping Report

## 1. OBJETIVO
Mapear y auditar la totalidad de componentes relacionados con la formulación de planes, rutinas adaptativas, agentes de recomendación (Hestia/Hermes/Atena), base de conocimiento RAG y catálogo de productos/servicios.

## 2. MATRIZ DE CAPACIDADES Y ASSET MAPPING (E0)

| Capacidad / Componente | Existe | Reutilizable | Adaptable | Crear | Riesgo | Justificación |
|---|:---:|:---:|:---:|:---:|:---:|---|
| **Motor de Ciclos (`glowCycleService.js`)** | SÍ | SÍ | SÍ | - | Bajo | Núcleo validado en GIA-01. Almacena `am_routine`, `pm_routine` y productos/servicios recomendados. |
| **Agente Atena (`atenaAgent.js`)** | SÍ | SÍ | SÍ | - | Bajo | Provee diagnóstico y formulación de ingredientes activos objetivo. |
| **Agente Hestia (`hestiaAgent.js`)** | SÍ | SÍ | SÍ | - | Bajo | Personal shopper: consulta SKUs reales de `productos` con stock disponible. |
| **Agente Hermes (`hermesAgent.js`)** | SÍ | SÍ | SÍ | - | Bajo | Logística: busca servicios y prestadores cercanos vía PostGIS. |
| **Agente Chronos (`chronosAgent.js`)** | SÍ | SÍ | SÍ | - | Bajo | Gestión de cadencia temporal y seguimiento de hábitos. |
| **RAG Cosmetológico (`ragService.js`)** | SÍ | SÍ | - | - | Muy Bajo | Base de conocimiento vectorial (1024d) para compatibilidad dérmica. |
| **Adaptive Transformation Engine (`transformationEngine.js`)** | NO | - | - | SÍ | Bajo | **Núcleo GIA-02:** Convierte diagnóstico + meta en plan de intervención, rutina estructurada AM/PM y adaptación progresiva. |

## 3. ESTADO DEL GATE
🟢 **PASS**
