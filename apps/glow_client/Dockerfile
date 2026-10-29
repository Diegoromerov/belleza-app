# Dockerfile - para glowapp-client (Flutter Web) - versión con shared package
FROM ghcr.io/cirruslabs/flutter:3.29.2 AS build

WORKDIR /app
# Copy pubspec files first (for cache)
COPY apps/glow_client/pubspec.* ./apps/glow_client/
COPY packages/glow_core/pubspec.* ./packages/glow_core/
# Copy glow_core source BEFORE pub get (needed for path dependency)
COPY packages/glow_core ./packages/glow_core/
RUN cd apps/glow_client && flutter pub get

COPY apps/glow_client ./apps/glow_client
RUN cd apps/glow_client && flutter build web --release

# Stage 2: nginx para servir estáticos
FROM nginx:alpine
COPY --from=build /app/apps/glow_client/build/web /usr/share/nginx/html
COPY apps/glow_client/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]