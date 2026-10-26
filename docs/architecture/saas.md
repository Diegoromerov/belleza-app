# Arquitectura SaaS (CRM)

```mermaid
flowchart TD
    subgraph Backend
        B1[API Gateway] --> B2[Auth Middleware]
        B2 --> B3[Lead & Opportunity Controllers]
        B3 --> B4[Sequelize (PostgreSQL)]
        B4 --> B5[Wompi Integration]
    end
    subgraph Frontend
        F1[Flutter App] --> F2[Provider Screens]
        F2 --> F3[Lead Form]
        F2 --> F4[Opportunity List]
        F2 --> F5[Opportunity Detail]
    end
    B1 -.-> F1
    style Backend fill:#f9f,stroke:#333,stroke-width:2px
    style Frontend fill:#bbf,stroke:#333,stroke-width:2px
```
