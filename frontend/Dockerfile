# Etapa 1: Construccion de la aplicacion Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY . .

# Obtener dependencias y construir
RUN flutter pub get && flutter build web --release

# Etapa 2: Servidor web con Nginx (Non-Root)
FROM nginxinc/nginx-unprivileged:alpine

# Copiar archivos construidos
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copiar configuracion personalizada de Nginx para soporte SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Ajustar puerto a 8080 (non-root no puede enlazar puertos < 1024)
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
