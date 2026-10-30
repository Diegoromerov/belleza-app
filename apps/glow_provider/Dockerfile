# Dockerfile for glowapp-provider (Flutter web)
# Uses ghcr.io/cirruslabs/flutter:stable (or specific version from GitHub Container Registry)
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy entire monorepo for glow_core dependency
COPY . .

# Get dependencies for glow_provider (includes glow_core via path)
WORKDIR /app/apps/glow_provider
RUN flutter pub get

# Build web release
RUN flutter build web --release

# Production stage: nginx to serve static files
FROM nginx:alpine AS runner

# Copy nginx config
COPY apps/glow_provider/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web assets
COPY --from=builder /app/apps/glow_provider/build/web /usr/share/nginx/html

# Expose port (Railway sets $PORT)
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
