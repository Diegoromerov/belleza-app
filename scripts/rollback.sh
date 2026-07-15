#!/bin/bash
VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Especifica la versión de tag a la que hacer rollback (ej. v1.2.3)"
  exit 1
fi

echo "⏪ Iniciando rollback hacia tag: $VERSION"

# Checkout en Git para el tag específico
git checkout tags/$VERSION

# Reconstruir y arrancar
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build

# Health check
sleep 5
curl -f http://localhost:8080/api/health || {
  echo "❌ Rollback falló. Revisa logs de contenedores."
  exit 1
}

echo "✅ Rollback ejecutado exitosamente a la versión $VERSION"
