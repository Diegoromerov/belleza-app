# Variables de Entorno Railway - Admin Dashboard

Configura estas variables en el dashboard de Railway para el servicio **admin-dashboard**:

## Requeridas (Obligatorias)

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `BACKEND_INTERNAL_URL` | `http://backend.railway.internal:3000` | URL interna del backend (DNS privado Railway) |
| `JWT_SECRET` | `glowapp_jwt_secret_key_32_chars_minimum` | **Debe ser idéntica a la del backend** (mínimo 32 chars) |
| `NODE_ENV` | `production` | Entorno de producción |

## Opcionales (para features específicas)

| Variable | Valor por defecto | Descripción |
|----------|-------------------|-------------|
| `NEXT_PUBLIC_API_BASE_URL` | `https://tu-dominio.up.railway.app` | URL pública del backend para llamadas directas del cliente |
| `BACKEND_URL` | `https://tu-backend.up.railway.app` | URL pública del backend (fallback) |

## Cómo configurar en Railway Dashboard

1. Ve a **Railway Dashboard** → Proyecto `grateful-harmony`
2. Click en servicio **admin-dashboard**
3. Tab **Variables** → **New Variable**
4. Añade cada variable de la tabla superior
5. **Deploy automático** se disparará al guardar

## Verificación

Después del deploy, verifica en logs del servicio:
```
🚀 Servidor en http://localhost:3001
📦 Entorno: production
✅ Backend conectado en http://backend.railway.internal:3000
```

## Importante: JWT_SECRET

**El JWT_SECRET debe ser EXACTAMENTE IGUAL en ambos servicios:**

```bash
# En backend (ya configurado)
JWT_SECRET=glowapp_jwt_secret_key_32_chars_minimum

# En admin-dashboard (configurar igual)
JWT_SECRET=glowapp_jwt_secret_key_32_chars_minimum
```

Si difieren, el login fallará con "Token inválido o expirado".

## Preview Deployments

Al abrir PR, Railway crea automáticamente:
- URL: `https://admin-dashboard-preview-<PR_NUMBER>.up.railway.app`
- Variables de entorno: **heredadas del servicio principal**
- Cada push al PR actualiza el preview automáticamente