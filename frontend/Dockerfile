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

# Exponer puertos compatibles con Railway (8080 por defecto, o dinamico segun $PORT)
EXPOSE 8080 3000 80

CMD ["/bin/sh", "-c", "sed -i 's/listen 8080;/listen '${PORT:-8080}';/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
