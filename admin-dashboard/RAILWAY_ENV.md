# Variables de Entorno Railway - Admin Dashboard

Configura estas variables en el dashboard de Railway para el servicio **admin-dashboard**:

## Requeridas (Obligatorias)

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `BACKEND_INTERNAL_URL` | `http://belleza-app.railway.internal:3000` | URL interna del servicio backend `belleza-app` en Railway |
| `JWT_SECRET` | Configura el mismo secreto de al menos 32 caracteres usado por el backend; consúltalo desde Railway Variables sin copiarlo al repositorio. | **No uses una clave de ejemplo** |
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
✅ Backend conectado en http://belleza-app.railway.internal:3000
```

## Importante: JWT_SECRET

**El JWT_SECRET debe ser EXACTAMENTE IGUAL en ambos servicios:**

Consulta el valor configurado en el servicio `belleza-app` de Railway y asígnalo al servicio `admin-dashboard` sin copiarlo al repositorio ni a logs. No uses una clave de ejemplo en producción.

Si difieren, el login fallará con "Token inválido o expirado".

## Preview Deployments

Los PR environments nativos de Railway están habilitados en `grateful-harmony`. Railway crea un entorno temporal al abrir un PR contra la rama conectada y lo elimina al fusionar o cerrar el PR. El servicio `admin-dashboard` tiene como root directory `/admin-dashboard` y el proyecto usa PR environments enfocados, para evitar desplegar servicios sin cambios. Railway publica la URL del preview en el PR cuando el entorno queda listo.
