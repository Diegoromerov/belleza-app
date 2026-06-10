# Auditoría Técnica — belleza-app (GlowApp)
**Fecha:** Junio 2026  
**Repositorio:** https://github.com/Diegoromerov/belleza-app  
**Stack:** Flutter + Node.js (Express) + PostgreSQL + Redis + Gemini API

---

## Resumen Ejecutivo

El proyecto está en un estado sólido para un ~90% de completitud. La arquitectura es coherente, el código está bien organizado y comentado, y los módulos críticos (auth, bookings, pagos, AI chat, admin) están funcionales. Sin embargo, hay **5 hallazgos de seguridad** que deben resolverse antes de cualquier despliegue en producción, más un conjunto de deudas técnicas y oportunidades de mejora.

---

## 1. HALLAZGOS DE SEGURIDAD 🔴

### SEC-01 — JWT Secrets Hardcodeados (CRÍTICO)
**Archivos afectados:**
- `backend/src/middleware/auth.js` línea 3
- `backend/src/modules/admin-glow/authAdmin.middleware.js` línea 4
- `backend/index.js` línea 615

**Problema:** Hay dos JWT secrets distintos hardcodeados como fallback:
```js
// auth.js
const JWT_SECRET = process.env.JWT_SECRET || 'beauty_app_super_secret_key_2026_change_in_production';

// authAdmin.middleware.js  
const JWT_SECRET = process.env.JWT_SECRET || 'glowapp_super_secret_admin_key_2026';
```
Además son **diferentes entre sí**, lo que significa que un token generado con el login normal NO puede validarse contra el middleware admin correctamente en fallback. Cualquier atacante que vea el repo puede forjar tokens de administrador válidos.

**Fix:**
```js
// En todos los archivos — sin fallback
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) throw new Error('JWT_SECRET no configurado. Revisar .env');
```

---

### SEC-02 — Archivos de Imágenes en el Repositorio (MODERADO)
**Problema:** La carpeta `backend/uploads/` contiene 9 archivos de imagen commiteados en el repo público. Son imágenes de usuarios (tryons de uñas), posiblemente datos personales.

**Fix inmediato en PowerShell:**
```powershell
Add-Content .gitignore "`nbackend/uploads/*"
Add-Content .gitignore "!backend/uploads/.gitkeep"
New-Item -ItemType File -Force backend/uploads/.gitkeep
git rm -r --cached backend/uploads/
git add .
git commit -m "fix: remove user images from repo, add uploads to gitignore"
git push origin main
```

---

### SEC-03 — CORS Solo Localhost (BLOQUEANTE para producción)
**Archivo:** `backend/index.js` línea 86-89

**Problema:**
```js
app.use(cors({
  origin: ['http://localhost:8080', 'http://localhost:8081', 'http://localhost:7357', 'http://127.0.0.1:8080'],
  credentials: true
}));
```
En producción el frontend no estará en localhost. Esto bloqueará todas las peticiones.

**Fix:**
```js
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:8080'];

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    callback(new Error('CORS no permitido'));
  },
  credentials: true
}));
```
Y en `.env` de producción: `ALLOWED_ORIGINS=https://tudominio.com,https://app.tudominio.com`

---

### SEC-04 — Sin Rate Limiting en Endpoints Críticos (MODERADO)
**Problema:** No hay `express-rate-limit` ni ningún mecanismo de throttling. Los endpoints `/api/auth/login`, `/api/auth/register` y `/api/auth/send-otp` están expuestos a fuerza bruta y spam de SMS/OTP ilimitados.

**Fix:**
```bash
npm install express-rate-limit
```
```js
const rateLimit = require('express-rate-limit');

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 10,
  message: { error: 'Demasiados intentos. Intente en 15 minutos.' }
});

app.use('/api/auth/login', authLimiter);
app.use('/api/auth/send-otp', authLimiter);
```

---

### SEC-05 — KYC Auto-Verify Sin Autenticación Fija (BAJA)
**Archivo:** `backend/src/modules/admin-glow/admin.controller.js` — función `verifyProviderAuto`

**Problema:** La función permite verificar un prestador automáticamente sin que `req.admin` sea obligatorio (`const adminId = req.admin ? req.admin.id : null`). Si se llama desde un webhook externo sin autenticación, puede verificar prestadores sin auditoría.

**Fix:** Requerir que el webhook tenga un token de firma HMAC o agregar verificación de IP origen para esta ruta específica.

---

## 2. DEUDA TÉCNICA 🟡

### DT-01 — index.js Monolítico (1787 líneas)
`backend/index.js` tiene 1787 líneas mezclando: configuración de Express, middleware, rutas inline, lógica de negocio, WebSocket, cron jobs, inicialización de base de datos, y creación de tablas al arranque.

**Impacto:** Mantenimiento difícil, imposible de testear unitariamente, onboarding lento para nuevos devs.

**Refactor sugerido:**
```
backend/
  app.js          ← solo Express setup y middleware
  server.js       ← solo listen() y arranque
  src/
    routes/       ← ya existe, mover rutas inline de index.js aquí
    sockets/      ← lógica WebSocket
    startup/      ← inicialización DB y tablas
```

---

### DT-02 — Dos ORM Coexistiendo (Sequelize + pg pool)
**Archivos:** `bookingController.js` usa Sequelize para `Booking.create()` y `Booking.findAll()`, pero también usa `pool.query()` directamente para otras queries del mismo controller.

**Problema:** Doble superficie de bugs, dos sistemas de gestión de conexiones, mayor peso en `node_modules`. Si hay una transacción que mezcle los dos, puede haber inconsistencias.

**Recomendación:** Migrar todo a `pg` nativo (ya que el resto del proyecto lo usa mayoritariamente) y eliminar Sequelize. Ganancia: simplificación, menos dependencias, más control sobre las queries.

---

### DT-03 — CREATE TABLE en Runtime (admin.model.js)
```js
await pool.query(`
  CREATE TABLE IF NOT EXISTS admin_actions (...)
`);
```
Esta sentencia se ejecuta en cada llamada a `logAdminAction()`. Es un antipatrón: la estructura de la BD debe manejarse exclusivamente por migraciones.

**Fix:** Mover al archivo de migraciones existente en `backend/migrations/`.

---

### DT-04 — Wompi Payout Simulado (Mock)
`backend/src/services/wompiService.js` — el payout completo es una simulación (`setTimeout`, referencia aleatoria). Está bien para desarrollo, pero debe estar claramente marcado y bloqueado en producción.

**Fix sugerido:** Agregar una variable de entorno `PAYMENT_MODE=sandbox|production` y lanzar error explícito si se intenta dispersar en producción sin la integración real.

---

### DT-05 — Módulo Nail Tryon Activo en Backend sin Frontend
Según `docs/ai-nail-tryon-paused.md`, el módulo está pausado visualmente pero todos los endpoints y la cola Redis siguen activos. Esto consume recursos de Redis innecesariamente y expone superficie de API sin uso.

**Recomendación:** Agregar middleware de feature flag:
```js
// En tryonRoutes.js
if (process.env.NAIL_TRYON_ENABLED !== 'true') {
  router.all('*', (req, res) => res.status(503).json({ error: 'Módulo en mantenimiento.' }));
}
```

---

## 3. OBSERVACIONES POSITIVAS ✅

**Auth bien implementada:** El middleware de auth.js consulta el rol actual en BD en cada request, evitando tokens JWT desactualizados. Excelente práctica.

**Admin module bien separado:** El módulo `admin-glow` tiene su propio middleware, controller, model y routes completamente aislados. Arquitectura limpia.

**Gemini Service robusto:** El servicio tiene modo simulación para desarrollo sin API key, manejo de errores graceful, soporte multimodal, y el system prompt de "Aura" está bien construido con instrucciones estructuradas para el catálogo.

**Queue Service correcto:** El patrón Redis RPUSH para nail_tryon_jobs es correcto. El cache de jobs por hash de imagen es una optimización inteligente.

**Collision check en bookings:** La validación de solapamiento de horarios del prestador está bien implementada.

**Habeas Data (Ley 1581):** El onboarding registra `habeas_data_accepted_at` y `habeas_data_ip`. Cumplimiento legal activo.

**Flutter Secure Storage:** El token JWT se maneja con `flutter_secure_storage`, no en SharedPreferences planos. Correcto.

**.gitignore adecuado:** `.env` está ignorado, `node_modules` está ignorado.

---

## 4. PRIORIZACIÓN DE ACCIÓN

| # | Hallazgo | Prioridad | Esfuerzo |
|---|----------|-----------|----------|
| SEC-01 | JWT secrets hardcodeados | 🔴 INMEDIATO | 15 min |
| SEC-02 | Imágenes de usuarios en repo | 🔴 INMEDIATO | 10 min |
| SEC-03 | CORS solo localhost | 🔴 Antes de deploy | 20 min |
| SEC-04 | Sin rate limiting | 🟡 Sprint actual | 30 min |
| DT-01 | index.js monolítico | 🟡 Sprint siguiente | 2-3 días |
| DT-02 | Doble ORM | 🟡 Sprint siguiente | 1 día |
| DT-03 | CREATE TABLE en runtime | 🟡 Sprint siguiente | 1 hora |
| DT-04 | Wompi mock en producción | 🟠 Antes de go-live | Depende Wompi |
| DT-05 | Nail tryon sin feature flag | 🟢 Cuando se reactive | 30 min |
| SEC-05 | KYC auto sin auditoría | 🟢 Baja urgencia | 1 hora |

---

## 5. SIGUIENTE PASO RECOMENDADO

Antes de cualquier otra cosa, ejecutar en PowerShell:

```powershell
# 1. Remover imágenes del repo (SEC-02)
Add-Content backend/.gitignore "`nuploads/*`n!uploads/.gitkeep"
New-Item -ItemType File -Force backend/uploads/.gitkeep
git rm -r --cached backend/uploads/
git add .
git commit -m "fix(security): remove user images from repo"
git push origin main
```

Luego, en el backend, asegurarse de que el `.env` de producción tenga:
```env
JWT_SECRET=<mínimo 64 caracteres aleatorios>
GEMINI_API_KEY=<clave real>
DATABASE_URL=<conexión producción>
ALLOWED_ORIGINS=https://tudominio.com
PAYMENT_MODE=sandbox
```

---

*Auditoría generada sobre commit c2bf281 — rama main*
