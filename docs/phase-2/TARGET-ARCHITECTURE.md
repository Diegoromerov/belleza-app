# 🎯 Target Architecture — Modular Monolith

## 1. Decisión de Arquitectura: Modular Monolith
Para la Fase 2 de GlowApp, se adopta formalmente la arquitectura de **Modular Monolith**. 
Se rechaza la migración prematura a microservicios distribuidos para evitar complejidad operativa innecesaria, problemas de latencia y sobrecostos de infraestructura.

## 2. Estructura Objetivo del Frontend (`admin-dashboard`)
```
src/
├── app/                  # Next.js App Router (Routing & Layouts)
│   ├── (auth)/           # Rutas de autenticación
│   ├── (dashboard)/      # Rutas protegidas del panel
│   └── api/              # Proxy local o BFF
├── components/           # Componentes compartidos de UI
│   ├── ui/               # Botones, Modales, Cards, Skeletons
│   ├── navigation/       # Sidebar, Header, Breadcrumbs
│   └── feedback/         # Toast, Alerts, Modals
├── features/             # Módulos encapsulados por Dominio
│   ├── bookings/
│   ├── providers/
│   ├── clients/
│   ├── inventory/
│   ├── academy/
│   └── safety/
├── services/             # API Client Unificado e Integraciones
├── hooks/                # Custom React Hooks
├── contexts/             # Global Context Providers
└── types/                # Definiciones TypeScript
```

## 3. Estructura Objetivo del Backend (`backend/src`)
```
src/
├── modules/              # Módulos de Dominio aislados
│   ├── auth/
│   ├── users/
│   ├── bookings/
│   ├── payments/
│   ├── inventory/
│   ├── kyc/
│   ├── safety/
│   └── academy/
├── shared/               # Recursos compartidos cruzados
│   ├── middleware/
│   ├── errors/
│   ├── security/
│   └── events/
└── infrastructure/       # Capa de infraestructura y adaptadores
    ├── database/
    ├── redis/
    └── notifications/
```
