# Etapa 1: Construccion de la aplicacion Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS builder

ARG GOOGLE_WEB_CLIENT_ID=374223351186-0fukntsog02r0p1tofd2aju3c7lsr86j.apps.googleusercontent.com

# Configuracion de Firebase: se inyecta en BUILD, nunca se versiona
# (ver lib/firebase_options.dart). Railway pasa las variables del servicio
# como build args en cuanto se declaran aqui.
ARG FIREBASE_API_KEY=""
ARG FIREBASE_PROJECT_ID=""
ARG FIREBASE_MESSAGING_SENDER_ID=""
ARG FIREBASE_STORAGE_BUCKET=""
ARG FIREBASE_WEB_APP_ID=""
ARG FCM_VAPID_KEY=""

WORKDIR /app
COPY . .

# El service worker de FCM es JavaScript plano y no puede leer --dart-define:
# se genera ANTES del build (ver tool/generate_firebase_sw.dart). Estos ENV
# viven solo en la etapa builder; la imagen final es nginx y no los hereda.
ENV FIREBASE_API_KEY=$FIREBASE_API_KEY \
    FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
    FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
    FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET \
    FIREBASE_WEB_APP_ID=$FIREBASE_WEB_APP_ID \
    FCM_VAPID_KEY=$FCM_VAPID_KEY

# Obtener dependencias y construir
RUN flutter pub get \
 && dart run tool/generate_firebase_sw.dart \
 && flutter build web --release \
      --dart-define=GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID} \
      --dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY} \
      --dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID} \
      --dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID} \
      --dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET} \
      --dart-define=FIREBASE_WEB_APP_ID=${FIREBASE_WEB_APP_ID} \
      --dart-define=FCM_VAPID_KEY=${FCM_VAPID_KEY}

# Etapa 2: Servidor web con Nginx (Non-Root)
FROM public.ecr.aws/nginx/nginx-unprivileged:alpine

# Copiar archivos construidos
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copiar configuracion personalizada de Nginx para soporte SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponer puertos compatibles con Railway (8080 por defecto, o dinamico segun $PORT)
EXPOSE 8080 3000 80

CMD ["/bin/sh", "-c", "sed -i 's/listen 8080;/listen '${PORT:-8080}';/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
