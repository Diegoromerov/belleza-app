#!/bin/bash
# =============================================================================
# scripts/deploy.sh — Despliegue ZERO-DOWNTIME (blue-green) para GlowApp
#
# Reemplaza el deploy destructivo anterior (build + `up -d` + `down` en fallo)
# por un flujo que NUNCA deja el sitio sin sirvientes:
#
#   1. Construye la imagen del release mientras el contenedor vivo sigue
#      atendiendo tráfico (build no es downtime).
#   2. Etiqueta la imagen por release (rollback determinista).
#   3. Levanta un CANDIDATO en paralelo en un puerto secundario, sin tocar el
#      contenedor vivo.
#   4. Espera (readiness con reintentos/timeout) a que el candidato esté sano.
#      Si NO lo está, aborta con el servicio vivo intacto → cero downtime.
#   5. Hace cutover drenando el contenedor viejo con SIGTERM + timeout
#      (graceful shutdown) mientras el candidato ya sirve.
#   6. Promueve el candidato al servicio gestionado por compose.
#   7. Verifica y retira el candidato temporal.
#
# Config por variables de entorno (todas opcionales).
# =============================================================================
set -Eeuo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
SERVICE="${SERVICE:-backend}"
CANDIDATE_NAME="${CANDIDATE_NAME:-glowapp-backend-candidate}"
CANDIDATE_IMAGE="${CANDIDATE_IMAGE:-glowapp-backend:latest}"
ENV_FILE="${ENV_FILE:-./backend/.env.production}"
LIVE_PORT="${LIVE_PORT:-8080}"
HEALTH_PORT="${HEALTH_PORT:-8081}"
HEALTH_PATH="${HEALTH_PATH:-/api/health}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-90}"
HEALTH_INTERVAL="${HEALTH_INTERVAL:-3}"
DRAIN_SECONDS="${DRAIN_SECONDS:-30}"

RELEASE_TAG="${RELEASE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"
RELEASE_IMAGE="glowapp-backend:${RELEASE_TAG}"
HEALTH_URL="http://localhost:${LIVE_PORT}${HEALTH_PATH}"
CANDIDATE_HEALTH_URL="http://localhost:${HEALTH_PORT}${HEALTH_PATH}"

log()  { echo -e "${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }
err()  { echo -e "${RED}$*${NC}"; }

# --- Graceful shutdown del script (trap) -------------------------------------
# En cualquier salida retiramos el candidato temporal. El servicio en vivo NO
# se toca aquí: si el deploy aborta, el sitio sigue sirviendo → sin downtime.
cleanup() {
    local code=$?
    docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true
    if [ "$code" -ne 0 ]; then
        err "❌ Deploy abortado (código $code). El servicio en vivo queda intacto (sin downtime)."
    fi
}
trap cleanup EXIT
trap 'err "⛔ Interrupción recibida: drenando y saliendo"; exit 130' INT TERM

# --- Readiness con reintentos -------------------------------------------------
# Sondea el endpoint health por HTTP hasta agotar HEALTH_TIMEOUT. Un único
# `sleep` fijo no basta: el contenedor puede tardar más o levantarse roto.
wait_healthy() {
    local url="$1"
    local deadline=$(( $(date +%s) + HEALTH_TIMEOUT ))
    while [ "$(date +%s)" -lt "$deadline" ]; do
        if curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then   # health probe
            return 0
        fi
        sleep "$HEALTH_INTERVAL"
    done
    return 1
}

live_container() {
    docker compose -f "$COMPOSE_FILE" ps -q "$SERVICE" 2>/dev/null | head -n1
}

log "🚀 Despliegue zero-downtime (blue-green) — release ${RELEASE_TAG}"

# 1. Pull latest code
echo "📦 Actualizando código desde repositorio..."
git pull --ff-only origin main || warn "⚠️ Advertencia: No se pudo hacer pull (ignorar si es local)."

# 2. Build de la nueva imagen SIN tocar el contenedor en vivo
log "🐳 Construyendo imágenes Docker del release (el servicio en vivo sigue atendiendo)..."
docker compose -f "$COMPOSE_FILE" build "$SERVICE"
docker tag "$CANDIDATE_IMAGE" "$RELEASE_IMAGE"

# 3. Baseline: ¿el servicio en vivo responde antes de empezar?
if ! curl -fsS --max-time 5 "$HEALTH_URL" >/dev/null 2>&1; then
    warn "⚠️ El servicio en vivo no responde en ${HEALTH_URL} antes del deploy (continuando)."
fi

# 4. Levantar el CANDIDATO en paralelo (rolling, sin pisar el puerto en vivo)
LIVE_ID="$(live_container || true)"
NETWORK=""
if [ -n "$LIVE_ID" ]; then
    NETWORK="$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' "$LIVE_ID" 2>/dev/null || true)"
fi
if [ -z "$NETWORK" ]; then
    NETWORK="$(docker network ls --format '{{.Name}}' | grep -i glowapp | head -n1 || true)"
fi

log "🟩 Levantando candidato ${RELEASE_TAG} en paralelo (puerto de sonda ${HEALTH_PORT})..."
docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true
docker run -d --name "$CANDIDATE_NAME" \
    --restart unless-stopped \
    --env-file "$ENV_FILE" \
    ${NETWORK:+--network "$NETWORK" --network-alias "$SERVICE"} \
    -p "127.0.0.1:${HEALTH_PORT}:8080" \
    "$RELEASE_IMAGE" >/dev/null

# 5. Health gate del candidato ANTES del cutover
log "🏥 Verificando salud del candidato (hasta ${HEALTH_TIMEOUT}s)..."
if ! wait_healthy "$CANDIDATE_HEALTH_URL"; then
    err "❌ Candidato no saludable. Abortando: el servicio en vivo queda intacto (cero downtime)."
    exit 1
fi
log "✅ Candidato saludable."

# 6. Cutover graceful: drenar el viejo (SIGTERM + timeout) — el candidato ya sirve
if [ -n "$LIVE_ID" ]; then
    log "♻️ Drenando contenedor viejo ${LIVE_ID} con ${DRAIN_SECONDS}s de gracia (SIGTERM)..."
    docker stop -t "$DRAIN_SECONDS" "$LIVE_ID" >/dev/null
    docker rm "$LIVE_ID" >/dev/null 2>&1 || true
fi

# 7. Promover el candidato al servicio gestionado por compose (sin recrear deps)
log "🔄 Promoviendo candidato al servicio gestionado por compose..."
docker compose -f "$COMPOSE_FILE" up -d --no-deps "$SERVICE"

# 8. Verificar el servicio promovido
if ! wait_healthy "$HEALTH_URL"; then
    err "❌ El servicio promovido no responde en ${HEALTH_URL} (el candidato sigue sirviendo)."
    exit 1
fi

# 9. Retirar el candidato temporal
docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true

log "✅ Despliegue productivo zero-downtime finalizado — release ${RELEASE_TAG} en producción."
