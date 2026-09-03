# GLOWAPP — FUNCTIONAL INVENTORY & PRODUCT UNITS

## 1. INVENTARIO DE CAPACIDADES POR DOMINIO

### 1.1. Core Authentication & Security
* **Módulos:** `backend/src/routes/authRoutes.js`, `backend/src/middleware/auth.js`, `frontend/lib/screens/auth/`
* **Estado:** 🟢 **COMPLETO / FUNCIONAL**
* **Capacidades:**
  - Registro, Login con JWT estricto.
  - Validación de esquemas Zod en backend.
  - Recuperación de contraseña y confirmación OTP.
  - Gestión de consentimiento biométrico inmutable (`biometricConsentGuard.js`).

### 1.2. Biometría Facial y Manos (AURA Vision)
* **Módulos:** `backend/src/services/biometric/`, `backend/src/routes/biometricRoutes.js`
* **Estado:** 🟢 **COMPLETO / PRODUCTION READY**
* **Capacidades:**
  - Pipeline YouCam S2S de 4 pasos (Upload slot -> S3 put -> Create task -> Polling).
  - Diagnóstico de manos con Gemini 3.1 Flash-Lite.
  - Circuit Breakers independientes, reintentos con backoff exponencial, timeouts y propagación de `traceId`.
  - Fallbacks deterministas seguros ante indisponibilidad de proveedores externos.

### 1.3. Inteligencia Artificial & RAG (AURA Multi-Agent Concierge)
* **Módulos:** `backend/src/services/ragService.js`, `embeddingService.js`, `aiOrchestrator.js`, `auraToolExecutor.js`, `agents/`
* **Estado:** 🟢 **FUNCIONAL / EN PRODUCCIÓN**
* **Capacidades:**
  - Ingesta y búsqueda vectorial en `pgvector` con embeddings NVIDIA `nv-embedqa-e5-v5` (1024 dimensiones).
  - Orquestador multi-agente: Atena (análisis dérmico), Hestia (recomendación de productos/rutinas), Apolo (análisis de color/estilo).
  - Compresor de contexto, caché semántico y observabilidad de RAG.

### 1.4. Marketplace & Reservas (Booking System)
* **Módulos:** `backend/src/routes/bookingRoutes.js`, `providerRoutes.js`, `serviceRoutes.js`, `frontend/lib/screens/provider/`, `frontend/lib/screens/booking_screen.dart`
* **Estado:** 🟡 **FUNCIONAL / REQUIERE HOMOLOGACIÓN SOUL**
* **Capacidades:**
  - Catálogo de profesionales, servicios y precios.
  - Agendamiento y tracking de citas.
  - Optimización de rutas de proveedores (`provider_route_screen.dart`).

### 1.5. GlowStore & Pasarela de Pagos
* **Módulos:** `backend/src/routes/productRoutes.js`, `paymentRoutes.js`, `wompiService.js`, `frontend/lib/screens/store/`
* **Estado:** 🟢 **FUNCIONAL**
* **Capacidades:**
  - Catálogo de productos, carrito de compras, cálculo de inventario.
  - Integración con pasarela Wompi (Checkout widget y webhook de confirmación).

### 1.6. Academia GlowApp
* **Módulos:** `backend/src/routes/academyRoutes.js`, `learningPathRoutes.js`, `frontend/lib/screens/academy/`
* **Estado:** 🟡 **PARCIAL / CONTENIDO EN DESARROLLO**
* **Capacidades:**
  - Rutas de aprendizaje, lecciones teóricas en markdown (círculo cromático, neutralización, etc.), tracking de progreso.

### 1.7. SaaS para Profesionales y Centros de Belleza (B2B CoPilot)
* **Módulos:** `backend/src/services/b2bCoPilotService.js`, `b2bCoPilotRoutes.js`, `provider_dashboard_screen.dart`
* **Estado:** 🟡 **PARCIAL / EXPERIMENTAL**
* **Capacidades:**
  - Dashboard de proveedor, métricas de retención automática (`AutomaticRetentionService.js`), gestión de agenda y CRM básico.
