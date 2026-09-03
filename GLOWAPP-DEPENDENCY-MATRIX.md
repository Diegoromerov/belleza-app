# GLOWAPP — DEPENDENCY MATRIX

## 1. DEPENDENCIAS EXTERNAS Y SDKs

| Dependencia / Servicio | Propósito | Estado | Criticidad |
|---|---|:---:|:---:|
| **YouCam S2S API** | Biometría facial & diagnóstico dermatológico | 🟢 Integrado & Resiliente | Alta (con Fallback) |
| **Gemini 3.1 Flash-Lite** | Diagnóstico multimodal de manos & Recomendaciones | 🟢 Integrado & Estandarizado | Alta (con Fallback) |
| **DeepSeek Chat API** | Análisis cosmetológico profundo & VTO Matching | 🟢 Integrado & Resiliente | Media (con Fallback Gemini) |
| **NVIDIA Embeddings** | Vectorización semántica de conocimiento RAG | 🟢 Integrado en pgvector | Alta |
| **Wompi API** | Pasarela de pagos & suscripciones | 🟢 Integrado | Crítica |
| **OpenUV API** | Consulta de índice de radiación solar ambiental | 🟢 Integrado | Baja (Opcional) |
| **PostgreSQL + pgvector**| Almacenamiento relacional y vectorial principal | 🟢 En Producción | Crítica |
| **Redis** | Caché semántico, Rate Limiting y Abuso | 🟢 En Producción | Alta |
