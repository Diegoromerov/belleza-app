# 🌸 Beauty App - Plataforma de Belleza

## 📦 Stack Tecnológico
- **Backend:** Node.js + Express + PostgreSQL (PostGIS) + Redis
- **Frontend:** Flutter (iOS/Android)
- **Base de Datos:** PostgreSQL con extensión PostGIS para geolocalización

## 🚀 Inicio Rápido
1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd beauty-app
   ```
2. **Backend**
   ```bash
   cd backend
   # Copiar variables de entorno de ejemplo
   cp .env.example .env
   # Editar .env con tus credenciales (API keys, DB, etc.)
   # Por ejemplo, abre con tu editor favorito
   nano .env
   npm install   # Instala dependencias (incluye node-cache)
   npm run dev   # Inicia el servidor en el puerto configurado (default 3000)
   ```
3. **Frontend**
   ```bash
   cd ../frontend
   flutter pub get && flutter run   # Compila y ejecuta la app en tu dispositivo/emulador
   ```
4. **Base de datos**
   - Si usas Docker, ejecuta `docker compose up -d` dentro de `backend/` (el `docker-compose.yml` crea la base PostgreSQL y Redis).
   - Si utilizas Railway, simplemente asegura que las variables de entorno estén definidas en el proyecto Railway (ver sección *Variables*).

## 📄 Variables de entorno (`.env.example`)
```
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=beauty_db
DB_USER=beauty_app_user
DB_PASSWORD=usa_una_clave_local_segura
JWT_SECRET=usa_una_clave_de_al_menos_32_caracteres
GOOGLE_CLIENT_ID=tu_google_client_id.apps.googleusercontent.com
WOMPI_WEBHOOK_SECRET=tu_secreto_de_webhook_wompi
ALLOWED_ORIGINS=http://localhost:3000
ALLOW_MOCK_AUTH=false
ALLOW_DEBUG_ROUTES=false
AUTO_APPROVE_PROVIDERS=false
GEMINI_API_KEY=tu_clave_gemini_api
GOOGLE_SEARCH_API_KEY=tu_google_search_api_key
GOOGLE_SEARCH_CX=tu_google_search_cx
OPENWEATHER_API_KEY=tu_openweather_api_key
```

## ⚖️ Privacidad y Protección de Datos (Ley 1581 / GDPR)
La geolocalización basada en PostGIS y los flujos de registro cumplen con la **Ley de Protección de Datos Personales (Ley 1581 de 2012 de Colombia)** y directrices de protección generales (GDPR).
- El consentimiento explícito se registra mediante metadatos de aceptación de Habeas Data (`habeas_data_accepted_at`, `habeas_data_ip`) en el onboarding de cada usuario.
- Los logs de telemetría y geolocalización se manejan bajo estrictas políticas de anonimización en producción.

