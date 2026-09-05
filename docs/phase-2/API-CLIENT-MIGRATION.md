# 🚀 API Client Migration Plan — Frontend

## 1. Objetivo
Migrar todas las solicitudes HTTP del frontend (`admin-dashboard` y `frontend` Flutter) hacia un cliente unificado con interceptores.

## 2. Reglas del API Client
- **Base URL Dinámica:** Detecta automáticamente el dominio en Railway o localhost.
- **Intercepción de Errores:** Captura automática de respuestas `401 Unauthorized` deslogueando al usuario sin romper el renderizado.
- **Cabeceras Automáticas:** Adjunta automáticamente `Authorization: Bearer <glow_token>`.
