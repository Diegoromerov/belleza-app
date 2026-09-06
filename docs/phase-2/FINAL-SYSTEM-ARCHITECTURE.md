# GLOWAPP PHASE 2 — FINAL SYSTEM ARCHITECTURE

```mermaid
graph TD
    subgraph Clients["Client Layer"]
        FlutterApp["Flutter Mobile App (iOS / Android)"]
        NextAdmin["Next.js 15 App Router Admin Dashboard"]
    end

    subgraph Gateway["API & Security Layer"]
        ExpressCore["Express.js Core Monolith (/api/v1)"]
        AuthMiddleware["JWT & RBAC Middleware"]
        IdempotencyGuard["Idempotency & Rate Limiter"]
    end

    subgraph Services["Domain Services Layer"]
        AuthSvc["Auth & User Service"]
        BookingSvc["Booking & Availability Engine"]
        PaymentSvc["Payment & Payout Engine"]
        KYCSvc["KYC & Verification Service"]
        SafetySvc["Trust & Safety Audit Service"]
        AcademySvc["Academy & Certification Service"]
        TelemetrySvc["Product Telemetry Service"]
    end

    subgraph AIWorker["Intelligence Layer"]
        FastAPIWorker["FastAPI Aura AI Worker (:8000)"]
        RAGEngine["pgvector Vector Search & RAG"]
    end

    subgraph DataStore["Data & Persistence Layer"]
        PostgreSQL[("PostgreSQL 16 (Core Relational + pgvector)")]
        RedisCache[("Redis (Session, Idempotency Locks, Webhook Hashes)")]
    end

    FlutterApp --> ExpressCore
    NextAdmin --> ExpressCore
    ExpressCore --> AuthMiddleware
    AuthMiddleware --> IdempotencyGuard
    IdempotencyGuard --> AuthSvc
    IdempotencyGuard --> BookingSvc
    IdempotencyGuard --> PaymentSvc
    IdempotencyGuard --> KYCSvc
    IdempotencyGuard --> SafetySvc
    IdempotencyGuard --> AcademySvc
    IdempotencyGuard --> TelemetrySvc

    ExpressCore <--> FastAPIWorker
    FastAPIWorker --> RAGEngine

    AuthSvc --> PostgreSQL
    BookingSvc --> PostgreSQL
    PaymentSvc --> PostgreSQL
    KYCSvc --> PostgreSQL
    SafetySvc --> PostgreSQL
    AcademySvc --> PostgreSQL
    TelemetrySvc --> PostgreSQL
    RAGEngine --> PostgreSQL

    PaymentSvc --> RedisCache
    IdempotencyGuard --> RedisCache
```

## 1. Architectural Highlights
- **Pattern:** Modular Monolith with isolated domain modules.
- **Data Isolation:** Single PostgreSQL database with strict schema segregation and RLS capabilities.
- **AI RAG Integration:** FastAPI dedicated worker communicating over HTTP with pgvector embeddings for rapid domain knowledge lookup without blocking core web server loop.
