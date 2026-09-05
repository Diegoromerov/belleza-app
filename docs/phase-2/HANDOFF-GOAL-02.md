# 🤝 Handoff Document — Handoff Obligatorio para GOAL 02

## 1. Logros de Identidad (GOAL 01)
Se ha completado la consolidación del dominio `AUTH` y `USERS`. Se ha endurecido el flujo de OTP con `crypto.randomInt`, se han sanitizado los logs de producción, se ha unificado la resiliencia del cliente API en el frontend y se han definido las matrices RBAC y de permisos.

## 2. Instrucciones para el Agente del GOAL 02
- **Objetivo del GOAL 02:** Consolidación de la Capa de Servicios y Abstracción de API Client Unificado (Frontend & Backend Middleware).
- **Archivos Bajo Ownership:** `admin-dashboard/src/services/*`, `admin-dashboard/src/hooks/*`.
- **Lo que DEBE Hacer GOAL 02:**
  1. Centralizar todas las invocaciones HTTP a través del API Client unificado.
  2. Implementar interceptores globales para manejo automático de respuestas de error `401`, `403` y `500`.
- **Lo que NO DEBE Hacer GOAL 02:**
  1. No alterar los modelos de usuario de la base de datos ni romper la autenticación establecida en GOAL 01.
