# ⚡ Auth API Matrix — Catálogo y Protección de Endpoints

| Método | Endpoint | Autenticación | Roles Permitidos | Rate Limit |
| :--- | :--- | :---: | :--- | :---: |
| `POST` | `/api/auth/register` | Pública | Todos (`PRESTADOR`/`CLIENTE`) | 30 req / 15 min |
| `POST` | `/api/auth/login` | Pública | Todos | 30 req / 15 min |
| `POST` | `/api/auth/logout` | `Bearer JWT` | Todos | Estándar |
| `POST` | `/api/auth/forgot-password` | Pública | Todos | 30 req / 15 min |
| `POST` | `/api/auth/reset-password` | Pública | Todos | 30 req / 15 min |
| `PATCH` | `/api/auth/onboarding` | `Bearer JWT` | `CLIENTE` / `PRESTADOR` | Estándar |
| `PATCH` | `/api/auth/change-password` | `Bearer JWT` | Todos | Estándar |
| `DELETE` | `/api/auth/delete-account` | `Bearer JWT` | Todos | Estándar |
