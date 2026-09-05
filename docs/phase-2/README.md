# 🏛️ GlowApp Phase 2 — Master Governance & Architecture Suite

Bienvenido a la suite oficial de **Gobernanza, Arquitectura y Control Maestro** para la **Fase 2 de GlowApp Platform**.

Este conjunto de documentos establece las reglas contractuales, técnicas, funcionales, operativas y de seguridad que rigen la evolución del sistema y garantizan la ejecución segura, incremental y paralelizable a través de múltiples agentes de desarrollo.

---

## 📚 Índice de la Suite de Gobernanza (`/docs/phase-2/`)

1. [**GOVERNANCE.md**](./GOVERNANCE.md) — Principios absolutos de desarrollo, refactorización, regla de no destrucción y ownership.
2. [**CURRENT-ARCHITECTURE.md**](./CURRENT-ARCHITECTURE.md) — Diagnóstico forense y arquitectura actual del ecosistema (Frontend Next.js/Flutter, Backend Express, AI Worker FastAPI, DB PostgreSQL/Redis).
3. [**TARGET-ARCHITECTURE.md**](./TARGET-ARCHITECTURE.md) — Arquitectura objetivo Modular Monolith organizada por características (`features/*` y `modules/*`).
4. [**DOMAIN-MAP.md**](./DOMAIN-MAP.md) — Mapa de los 14 dominios funcionales oficiales del negocio (Auth, Bookings, Payments, Inventory, KYC, Safety, Academy, Growth, etc.).
5. [**ROUTE-MAP.md**](./ROUTE-MAP.md) — Inventario completo de rutas web (Next.js) y móviles (Flutter), verificadas con su estado HTTP en producción.
6. [**API-MAP.md**](./API-MAP.md) — Catálogo exhaustivo de endpoints REST, WebSockets, parámetros y manejo de errores.
7. [**DATA-MAP.md**](./DATA-MAP.md) — Mapeo de entidades Sequelize, esquemas PostgreSQL, relaciones, índices y análisis de concurrencia.
8. [**COMPONENT-MAP.md**](./COMPONENT-MAP.md) — Inventario de componentes UI, Design System, tokens de diseño y detección de duplicados.
9. [**SECURITY-BASELINE.md**](./SECURITY-BASELINE.md) — Auditoría de seguridad baseline (P0 a P3), gestión de credenciales, JWT, CORS, XSS y PII.
10. [**TECH-DEBT.md**](./TECH-DEBT.md) — Inventario de deuda técnica, parches temporales, FIXME/TODOs y recomendaciones de remediación.
11. [**MOCK-INVENTORY.md**](./MOCK-INVENTORY.md) — Inventario de datos simulados y mocks (Clasificación A, B, C, D) para su reemplazo por APIs reales.
12. [**NAVIGATION-MAP.md**](./NAVIGATION-MAP.md) — Matriz de navegación basada en Rol + Permiso + Feature Flag + Contexto.
13. [**UX-AUDIT.md**](./UX-AUDIT.md) — Auditoría de UX, estados de interfaz (Loading, Empty, Error, Success) y especificación de componentes Glow.
14. [**AGENT-CONTRACT.md**](./AGENT-CONTRACT.md) — Contrato contractual para ejecución multiagente (Dominios permitidos, archivos bajo ownership y archivos prohibidos).
15. [**GOAL-DEPENDENCIES.md**](./GOAL-DEPENDENCIES.md) — Matriz de dependencias y plan de ejecución en paralelo (GOAL 00 al GOAL 15).
16. [**CHANGE-POLICY.md**](./CHANGE-POLICY.md) — Políticas de control de cambios, Git workflow y estándares de commits.
17. [**HANDOFF-GOAL-01.md**](./HANDOFF-GOAL-01.md) — Documento oficial de traspaso (Handoff) para la ejecución del **GOAL 01**.

---

## ⚡ Regla de Oro
> **ENTENDER ANTES DE MODIFICAR. REUTILIZAR ANTES DE CREAR. NO REESCRIBIR LO QUE YA FUNCIONA SIN JUSTIFICACIÓN TÉCNICA.**
