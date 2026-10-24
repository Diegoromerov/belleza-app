# Cierre FASE 4 y FASE 5 — SaaS

Fecha: 2026-10-23 · Commit de código: `bef3d19c` (PR #61) · Backend desplegado y verificado.

## FASE 4 — Consola SuperAdmin

### Construido y desplegado
| Pieza | Estado |
|---|---|
| Modelos, servicio y providers (`/api/superadmin/*`) | ✅ |
| Pantallas Tenants, Ingresos, Uso, Planes + shell con rail | ✅ |
| Gate de acceso: el 403 del backend decide, no el cliente | ✅ |
| Ruta `/superadmin` | ✅ |
| Fix de backend: 6 consultas con `users`/`owner_id` inexistentes | ✅ |
| `flutter analyze` **0 errores** · `flutter build web --release` **OK** | ✅ |
| Widget tests **7/7** (4 pantallas + gate 403) | ✅ |
| Deploy backend `SUCCESS` (`bef3d19c032a`) y frontend `SUCCESS` | ✅ |
| `/api/superadmin/{dashboard,tenants,revenue,usage}` → **401** sin token | ✅ |

### Bloqueo para usarla (configuración, no código)
`superAdminGuard` autoriza por `SUPER_ADMIN_EMAILS`, `SUPER_ADMIN_USER_IDS` o por rol
`SUPER_ADMIN` (con `SUPER_ADMIN_ROLE_ENABLED=true`). En Railway **ninguna está configurada**
y en `usuarios` no existe el rol: hay 17 CLIENTE, 14 PRESTADOR, 9 ADMIN, 2 sin rol.
Consecuencia: cualquier sesión recibe **403**.

Dos caminos, ambos requieren decisión del Director:
1. `SUPER_ADMIN_EMAILS=<email del Director>` — sin tocar datos.
2. `SUPER_ADMIN_ROLE_ENABLED=true` + elevar un ADMIN a `SUPER_ADMIN` en `usuarios` — es una
   escritura en producción y necesita autorización explícita.

### Dato relevante
`business_profiles`, `memberships`, `subscriptions`, `usage_metrics` e `invoices` están
**vacías**: la consola mostrará ceros hasta provisionar el primer tenant. Es el estado real,
no un fallo de pantalla. El `POST /api/saas/bootstrap` existe y es idempotente, pero nunca se
ejecutó con una cuenta real.

## FASE 5 — Integración y QA

### Lo que ya está cubierto de forma automática
- **43 tests backend**: retrieval RAG (híbrido, fusión, tenant, fallback), config del umbral,
  migraciones, reglas del dinero.
- **7 widget tests** de la consola + los de SaaS de la Fase 3.
- **6 jobs de CI** en verde en el PR #61, incluido `Arnés E2E (reglas del dinero)`.
- **SQL verificado contra la base real**: `tenants`, detalle de miembros, `dashboard` y
  `audit-logs` ejecutan sin error.

### Arnés E2E del ciclo completo
`backend/scripts/qaSaasE2E.js` recorre: registro → onboarding (salón) → bootstrap idempotente →
invitar equipo → checkout de plan → API key (devuelta una sola vez) → uso → consola SuperAdmin.
Se niega a correr contra producción sin `--force`, porque **crea cuentas reales**.

```bash
node backend/scripts/qaSaasE2E.js --base=https://<staging> --email=qa@glowapp.test \
  --password='...' --admin-email='...' --admin-password='...'
```

### Pendiente que no se puede cerrar desde aquí
| Ítem del plan | Estado | Por qué |
|---|---|---|
| E2E registro → onboarding → invitar → upgrade → API key | ⏳ | requiere un entorno de staging con cuentas; el arnés está listo |
| Emails transaccionales (trial ending, invoice, dunning, invitación) | ⏳ | requiere proveedor de correo configurado y una cuenta real |
| Pruebas de límites (usage alerts, hard limits) | ⏳ | `usage_metrics` vacía: no hay consumo que agotar |
| Deploy staging → validación con usuario real | ⏳ | no existe servicio de staging; solo producción |
| Consola SuperAdmin con datos | ⏳ | requiere `SUPER_ADMIN_EMAILS` o rol + un tenant provisionado |

## Qué falta, en orden

1. **Configurar la identidad SuperAdmin** (1 variable de entorno) y provisionar un tenant
   real de punta a punta: eso desbloquea Fase 4 y la mitad de Fase 5.
2. **Crear staging** (servicio Railway + base de datos separada). Sin staging, cualquier
   prueba E2E escribe en producción: por eso el arnés se niega a correr ahí.
3. **Conectar correo transaccional** y repetir el E2E para verificar las 4 plantillas.

Nada de esto es código pendiente: es infraestructura y una decisión de identidad.
