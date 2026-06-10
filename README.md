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

## ⚖️ Privacidad y Protección de Datos (Ley 1581 / GDPR)
La geolocalización basada en PostGIS y los flujos de registro cumplen con la **Ley de Protección de Datos Personales (Ley 1581 de 2012 de Colombia)** y directrices de protección generales (GDPR). 
- El consentimiento explícito se registra mediante metadatos de aceptación de Habeas Data (`habeas_data_accepted_at`, `habeas_data_ip`) en el onboarding de cada usuario.
- Los logs de telemetría y geolocalización se manejan bajo estrictas políticas de anonimización en producción.

