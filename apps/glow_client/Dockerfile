# Dockerfile - para glowapp-client (Flutter Web) - versión ligera
FROM ghcr.io/cirruslabs/flutter:3.29.2 AS build

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# Stage 2: nginx para servir estáticos
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]