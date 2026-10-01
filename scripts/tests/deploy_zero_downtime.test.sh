#!/bin/bash
# =============================================================================
# Test estático (sin node_modules) — t_fix_infra_03
# Hallazgo P0: "Deploy sin zero-downtime" (scripts/deploy.sh)
#
# Verifica que scripts/deploy.sh implemente un despliegue ZERO-DOWNTIME:
#   1. Sintaxis bash válida.
#   2. Construye la imagen ANTES de tocar el contenedor en vivo.
#   3. Levanta un candidato blue-green en paralelo (rolling / sin parar el viejo).
#   4. Health check con reintentos (readiness) en vez de un `sleep` fijo.
#   5. Gate: aborta si el candidato no está sano SIN derribar el servicio vivo.
#   6. Graceful shutdown / drenado (SIGTERM con timeout) + traps de limpieza.
#   7. Nunca usa `docker compose down` (teardown destructivo = downtime).
#   8. Promoción gestionada por compose con --no-deps (no recrea dependencias).
#   9. Etiqueta la imagen por release para permitir rollback.
#
# Uso:  bash scripts/tests/deploy_zero_downtime.test.sh
# =============================================================================
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEPLOY="$ROOT/scripts/deploy.sh"

PASS=0
FAIL=0

ok()  { echo "  ✅ $1"; PASS=$((PASS + 1)); }
ko()  { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

# check <descripción> <patrón ERE>  -> el patrón DEBE existir
check() {
  local desc="$1" pat="$2"
  if grep -Eq -- "$pat" "$DEPLOY"; then
    ok "$desc"
  else
    ko "$desc  [patrón ausente: $pat]"
  fi
}

# absent <descripción> <patrón ERE>  -> el patrón NO debe existir
absent() {
  local desc="$1" pat="$2"
  if grep -Eq -- "$pat" "$DEPLOY"; then
    ko "$desc  [patrón prohibido presente: $pat]"
  else
    ok "$desc"
  fi
}

echo "=== t_fix_infra_03: deploy.sh SIN zero-downtime (TEST ESTÁTICO) ==="
echo "Archivo bajo test: scripts/deploy.sh"
echo

if [ ! -f "$DEPLOY" ]; then
  echo "  ❌ No existe $DEPLOY"
  exit 1
fi

# 1. Sintaxis
echo "[1] Sintaxis"
if bash -n "$DEPLOY" 2>/dev/null; then
  ok "deploy.sh tiene sintaxis bash válida"
else
  ko "deploy.sh tiene errores de sintaxis"
fi

# 2. Build antes de cutover (no derriba antes de construir)
echo "[2] Build antes de tocar el servicio en vivo"
check "construye imágenes con docker compose build" 'docker[[:space:]]+compose[^\n]*build'
absent "NO hace teardown destructivo (docker compose ... down)" 'compose[^\n]*[[:space:]]down([[:space:]]|$|\r)'

# 3. Candidato blue-green en paralelo
echo "[3] Candidato blue-green en paralelo (rolling)"
check "levanta contenedor candidato con docker run -d --name" 'docker[[:space:]]+run[[:space:]]+-d[^\n]*--name'
check "el candidato usa una imagen etiquetada por release" 'docker[[:space:]]+tag'
check "usa puerto secundario para el candidato (sin pisar el vivo)" '8081|HEALTH_PORT|CANDIDATE_PORT'

# 4. Readiness con reintentos (no sleep fijo)
echo "[4] Health check con reintentos"
check "define un sondeo iterativo de readiness (while/until)" '(while|until)[^\n]*(date|deadline|intento|attempt|retry)'
check "sondea el endpoint de salud por HTTP con curl" 'curl[^\n]*(health|HEALTH)'
check "respeta un timeout/intervalo de sondeo" 'HEALTH_TIMEOUT|HEALTH_INTERVAL|deadline'
absent "NO confía en un único 'sleep' fijo sin verificación" '^[[:space:]]*sleep[[:space:]]+[0-9]+[[:space:]]*$'

# 5. Gate de salud que aborta sin derribar el vivo
echo "[5] Gate de salud antes del cutover"
check "aborta si el candidato no está sano (wait_healthy + exit no-cero)" 'wait_healthy[^\n]*;'
check "declara que el servicio vivo queda intacto si el deploy falla" 'intacto|sin downtime|no fue derribado|zero.?downtime'

# 6. Graceful shutdown + traps
echo "[6] Graceful shutdown / drenado"
check "drena el contenedor viejo con SIGTERM y timeout (docker stop -t)" 'docker[[:space:]]+stop[^\n]*-t|docker[[:space:]]+stop[^\n]*--time'
check "define una ventana de drenado configurable" 'DRAIN_SECONDS|stop_grace_period|GRACE'
check "registra traps para limpieza/shutdown (INT/TERM/EXIT)" 'trap[[:space:]]+'

# 7. Promoción gestionada por compose
echo "[7] Promoción y rollback"
check "promueve con compose up -d --no-deps (no recrea dependencias)" 'up[[:space:]]+-d[^\n]*--no-deps'
check "etiqueta/registra el release para rollback" 'RELEASE_TAG'

echo
echo "--- RESULTADO ---"
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: ❌ ROJO  (scripts/deploy.sh NO implementa zero-downtime)"
  exit 1
fi
echo "RESULT: ✅ VERDE (scripts/deploy.sh implementa zero-downtime)"
exit 0
