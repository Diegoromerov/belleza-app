# GLOWAPP PHASE 2 — CLIENT DOMAIN ARCHITECTURE

## 1. Client Architecture Overview
The Client domain establishes the consumer-facing product layer across Flutter mobile (`frontend/lib/screens/`) and Next.js web (`admin-dashboard/src/app/(dashboard)/cliente/`).

```
CLIENT UI LAYER (Flutter / Next.js React 19)
   ↓
CLIENT API CLIENT LAYER (Goal 04 REST & Async Contracts)
   ↓
BACKEND CONTROLLER LAYER (Express.js / Node.js)
   ↓
APPLICATION SERVICE LAYER (Goal 02 Modular Monolith)
   ↓
REPOSITORY LAYER (Goal 03 PostgreSQL Persisted Data)
```

## 2. Client Domain Scope
- **Discovery & Home:** Hero search, categories, featured services, provider cards.
- **Service & Provider Detail:** Portfolio, reviews, rating, progressive disclosure of pricing & location.
- **3-Step Booking Journey:** 1. Cuándo/Dónde -> 2. Productos/Add-ons -> 3. Pago.
- **Booking Tracking & History:** Real-time appointment tracker and history tabs.
- **Profile, Support & Safety:** Client profile settings, incident reporting, support tickets.
