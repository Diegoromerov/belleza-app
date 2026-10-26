# Dockerfile for Railway static hosting of Flutter web build
FROM nginx:alpine
# Copy only the web build (thanks to .dockerignore it will be the only thing included)
COPY frontend/build/web /usr/share/nginx/html
# Expose port 80 (default for nginx)
EXPOSE 80
