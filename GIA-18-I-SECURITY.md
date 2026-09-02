# GIA-18-I — SECURITY VERIFICATION

## Authentication
- JWT-based via Authorization: Bearer header
- Token blacklisting via Redis (beauty:token_blacklist:<token>)
- User role and tenant_id loaded from database on every request

## Authorization
- verifyToken middleware on all Glow Cycle routes
- adminMiddleware for admin-only routes
- Role-based access control (client, admin, provider)

## Multi-Tenant Isolation
- tenant_id column on core tables
- Row-Level Security (RLS) policies enabled (migration 058)
- Anti-IDOR: user ID from JWT, not from request body

## CORS
- Strict origin whitelist (14 origins including localhost:3000)

## Rate Limiting
- express-rate-limit applied globally

## Known Development Notes
- ALLOW_MOCK_AUTH=true is set (development mode)
- JWT secret is a development placeholder
- PostgreSQL password admin123 must be changed for production
