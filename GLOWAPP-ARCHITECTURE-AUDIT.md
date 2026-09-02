# GLOWAPP — ARCHITECTURE AUDIT & CODEBASE STRUCTURE

## 1. MAPA DE ARQUITECTURA REAL

```text
┌────────────────────────────────────────────────────────┐
│                   FRONTEND FLUTTER                     │
│  - Screens (Auth, Home, AURA, Store, Booking, Chat)    │
│  - Widgets (AuraMultiAgentChat, GlowGlassCard, etc.)   │
│  - Services (ApiService, AuthService, BiometricService)│
│  - SOUL Design Tokens (tokens.dart, AppTheme, Icons)   │
└───────────────────────────┬────────────────────────────┘
                            │ HTTP / REST & WebSockets
┌───────────────────────────▼────────────────────────────┐
│                    BACKEND (EXPRESS)                   │
│  - Middleware: Auth JWT, Zod Validation, Idempotency,  │
│    Biometric Consent Guard, Rate Limiter               │
│  - Routes / Controllers (34 módulos de ruta)           │
└───────┬───────────────────────────────┬────────────────┘
        │                               │
┌───────▼────────────────┐      ┌───────▼────────────────┐
│   CORE BUSINESS LOGIC  │      │  AI & RAG MULTI-AGENT  │
│  - BookingService      │      │  - AIOrchestrator      │
│  - ProfileService      │      │  - Swarm Agents        │
│  - WompiService        │      │  - RagService & PgVec  │
│  - B2BCoPilotService   │      │  - ContextCompressor   │
└───────┬────────────────┘      └───────┬────────────────┘
        │                               │
┌───────▼───────────────────────────────▼────────────────┐
│            RESILIENCE & INTEGRATION ENGINE             │
│  - ResilienceService (Retry, Backoff, Timeout, Trace)  │
│  - CircuitBreakerService (YouCam, Gemini, DeepSeek)    │
│  - BiometricOrchestrator                               │
└───────┬───────────────────────────────┬────────────────┘
        │                               │
┌───────▼────────────────┐      ┌───────▼────────────────┐
│   EXTERNAL PROVIDERS   │      │    STORAGE & DATA      │
│  - YouCam S2S API      │      │  - PostgreSQL / Supabase│
│  - Gemini Vision / Pro │      │  - pgvector (1024 dims) │
│  - DeepSeek Chat API   │      │  - Redis (Cache/Limiter)│
│  - OpenUV / Wompi      │      │  - S3 Storage (Images)  │
└────────────────────────┘      └────────────────────────┘
```

## 2. HALLAZGOS Y EVALUACIÓN DE CALIDAD ARQUITECTÓNICA
1. **Acoplamiento:** Muy bajo en la capa de resiliencia (patrón wrapper desacoplado con inyección de funciones async).
2. **Puntos de Falla Únicos (SPOF):** Totalmente mitigados en proveedores de IA/Biometría mediante Circuit Breakers y fallbacks locales.
3. **Deuda Técnica Identificada:**
   - Limpieza de scripts auxiliares de migración en la raíz (`clean_duplicates.py`, `do_replace.py`, `migrate_menu.py`, etc.).
   - Deprecación final de componentes visuales legacy no compatibles con SOUL en pantallas periféricas de provider.
