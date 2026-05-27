# 🌸 Beauty App - Plataforma de Belleza

## 📦 Stack Tecnológico
- **Backend:** Node.js + Express + PostgreSQL (PostGIS) + Redis
- **Frontend:** Flutter (iOS/Android)
- **Base de Datos:** PostgreSQL con extensión PostGIS para geolocalización

## 🚀 Inicio Rápido
1. Ir a `/backend` y ejecutar: `docker compose up -d` (o `docker-compose up -d` si usas el binario legacy)
2. Copiar `.env.example` a `.env` y configurar credenciales
3. Instalar dependencias: `npm install`
4. Iniciar servidor: `npm run dev`
5. Ir a `/frontend` y ejecutar: `flutter pub get && flutter run`

## 📁 Estructura
- `backend/`: API REST y lógica de negocio
- `frontend/`: App móvil multiplataforma
- `docs/`: Documentación técnica y de negocio
