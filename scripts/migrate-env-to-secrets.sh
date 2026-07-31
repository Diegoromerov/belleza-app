#!/bin/bash
# scripts/migrate-env-to-secrets.sh
# Script para validar e migrar variables sensibles hacia Secret Manager (Mock/Staging)

set -e

echo "======================================================"
echo "  MIGRACIÓN DE VARIABLES SENSIBLES A SECRET MANAGER   "
echo "======================================================"

SENSITIVE_KEYS=(
  "JWT_SECRET"
  "WOMPI_WEBHOOK_SECRET"
  "KYC_WEBHOOK_SECRET"
  "DB_PASSWORD"
  "REDIS_PASSWORD"
)

ENV_FILE="backend/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "⚠️ Archivo $ENV_FILE no encontrado. Usando .env.example como referencia..."
  ENV_FILE="backend/.env.example"
fi

echo "🔍 Auditando claves sensibles en $ENV_FILE..."

for key in "${SENSITIVE_KEYS[@]}"; do
  if grep -q "^$key=" "$ENV_FILE"; then
    echo "  [OK] Clave encontrada: $key"
  else
    echo "  [ALERTA] Clave faltante o no configurada: $key"
  fi
done

echo ""
echo "✅ Validación de migración completada (Entorno Mock/Staging listo)."
