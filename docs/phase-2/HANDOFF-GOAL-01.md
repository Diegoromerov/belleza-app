# 🤝 Handoff Document — Handoff Obligatorio para GOAL 01

## 1. Resumen del Descubrimiento (GOAL 00)
El agente del **GOAL 00** ha completado la auditoría integral de GlowApp Platform. La aplicación se encuentra en un estado funcional estable con todas las rutas principales de producción respondiendo **`HTTP 200 OK`**. Se han corregido las ambigüedades de imports usando el alias `@/` y se ha establecido la arquitectura objetivo de **Modular Monolith**.

## 2. Instrucciones Precisas para el Agente del GOAL 01
- **Objetivo del GOAL 01:** Consolidación del Dominio `AUTH` y `USERS` (Arquitectura de Autenticación Unificada, JWT Refresh, Roles y Permisos).
- **Archivos Bajo Ownership:** `backend/src/controllers/authController.js`, `admin-dashboard/src/contexts/AuthContext.tsx`, `admin-dashboard/src/components/auth/ProtectedRoute.tsx`, `admin-dashboard/src/app/(auth)/*`.
- **Lo que DEBE Hacer GOAL 01:**
  1. Estandarizar la emisión y validación de tokens JWT.
  2. Asegurar el manejo unificado de refresco de sesión sin deslogueos inesperados.
  3. Validar la protección de rutas por roles tanto en frontend como en el middleware de backend.
- **Lo que NO DEBE Hacer GOAL 01:**
  1. No crear una segunda base de datos ni alterar los modelos de `User` de forma destructiva.
  2. No romper el soporte de login para los tres usuarios de prueba (`admin@glow.app`, `valia@glow.app`, `cliente@glow.app`).
