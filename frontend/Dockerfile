# Etapa 1: Construcción de la aplicación Flutter
FROM ubuntu:latest

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Instalar Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Verificar instalación
RUN flutter doctor -v

# Configurar directorio de trabajo
WORKDIR /app

# Copiar archivos del proyecto
COPY . .

# Obtener dependencias
RUN flutter pub get

# Construir la aplicación web
RUN flutter build web --release

# Etapa 2: Servidor web con Nginx
FROM nginx:alpine

# Copiar archivos construidos
COPY --from=0 /app/build/web /usr/share/nginx/html

# Copiar configuración personalizada de Nginx para soporte SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponer puerto 80
EXPOSE 80

# Iniciar Nginx
CMD ["nginx", "-g", "daemon off;"]
