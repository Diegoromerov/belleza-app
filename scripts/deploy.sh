#!/bin/bash
set -e

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Iniciando despliegue del Hub Biométrico en Producción${NC}"

# 1. Pull latest code
echo "📦 Actualizando código desde repositorio..."
git pull origin main || echo "⚠️ Advertencia: No se pudo hacer pull (ignorar si es local)."

# 2. Docker build y push
echo "🐳 Construyendo imágenes de contenedores Docker..."
docker compose -f docker-compose.prod.yml build

# 3. Deploy
echo "🚀 Levantando contenedores..."
docker compose -f docker-compose.prod.yml up -d

# 4. Health check
echo "🏥 Verificando salud del backend..."
sleep 8
curl -f http://localhost:8080/api/health || {
    echo -e "${RED}❌ Health check falló. Realizando rollback automático...${NC}"
    docker compose -f docker-compose.prod.yml down
    exit 1
}

echo -e "${GREEN}✅ Despliegue productivo finalizado exitosamente!${NC}"
