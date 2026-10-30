# Dockerfile for glowapp-client (Flutter web)
# Uses pinned Flutter 3.29.3 from GitHub Container Registry
FROM ghcr.io/cirruslabs/flutter:3.29.3 AS builder

WORKDIR /app

# Copy entire monorepo for glow_core dependency
COPY . .

# Get dependencies for glow_client (includes glow_core via path)
WORKDIR /app/apps/glow_client
RUN flutter pub get

# Build web release
RUN flutter build web --release

# Production stage: nginx to serve static files
FROM nginx:alpine AS runner

# Copy nginx config
COPY apps/glow_client/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web assets
COPY --from=builder /app/apps/glow_client/build/web /usr/share/nginx/html

# Expose port (Railway sets $PORT)
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]