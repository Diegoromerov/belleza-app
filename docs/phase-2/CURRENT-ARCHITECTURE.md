# 🏗️ Current Architecture Audit — GlowApp Platform

## 1. Visión General del Sistema Actual
GlowApp opera bajo una arquitectura híbrida compuesta por:
- **Frontend Admin Dashboard:** Next.js 15 (App Router), React 19, Tailwind CSS, Lucide React, TypeScript. Deployed en Railway (`admin-dashboard-production-4183.up.railway.app`).
- **Backend Core API:** Node.js, Express, Sequelize ORM, PostgreSQL, Redis, Socket.io. Deployed en Railway (`beauty-app-production-bfd4.up.railway.app`).
- **Frontend App Client:** Flutter (Web/Mobile) para consumidores y prestadores (Servidor local `http://localhost:3000`).
- **AI Microservice Worker:** Python FastAPI, LangChain, Uvicorn (Servidor local `http://localhost:8000`).

## 2. Diagrama de Arquitectura Actual
```
[ Frontend Next.js Admin ]  <--->  [ Backend API Core (Express/Postgres) ]  <--->  [ AI Worker (FastAPI) ]
           ^                                       ^
           |                                       |
    [ Flutter Mobile/Web ] <-----------------------+
```

## 3. Fortalezas Identificadas
- Autenticación JWT funcional con manejo de roles (`ADMIN`, `PRESTADOR`, `CLIENTE`).
- Estructura limpia de App Router en Next.js con soporte de alias `@/`.
- Rutas clave respondiendo `HTTP 200 OK` en producción.
