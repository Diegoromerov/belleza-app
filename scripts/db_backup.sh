#!/usr/bin/env bash
# =============================================================================
# scripts/db_backup.sh — Backup automático de PostgreSQL (GlowApp)
#
# Cierra el hallazgo P0 «Sin backup/restore automation (RPO/RTO indefinidos)»
# (AUDITORIA_PREPRODUCCION_MASTER.md:73):
#   * pg_dump en formato CUSTOM, COMPRIMIDO y PARALELO (-Fc -Z 3 -j 4), en vez del
#     volcado SQL plano de 252 MB que tardaba 15-30 min en restaurar.
#   * Bloqueo anti-concurrencia con flock: dos backups no se pisan.
#   * Integridad por checksum SHA-256 y rotación por RETENTION_DAYS.
#   * Credenciales SOLO por entorno (DB_PASSWORD / PGPASSWORD / DATABASE_URL).
#   * Diseñado para cron: ver scripts/backup.cron y scripts/install_backup_cron.sh.
#
# Uso:
#   DB_PASSWORD=*** ./scripts/db_backup.sh
#   ./scripts/db_backup.sh --dry-run     # imprime el plan, NO toca la base de datos
#   ./scripts/db_backup.sh --help
#
# Entorno (defaults seguros salvo la contraseña, que es obligatoria):
#   DB_HOST DB_PORT DB_NAME DB_USER   DB_PASSWORD (o PGPASSWORD / DATABASE_URL)
#   BACKUP_DIR=/var/backups/glowapp   RETENTION_DAYS=30
#   COMPRESS_LEVEL=3                  JOBS=4
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
scripts/db_backup.sh — backup automático de PostgreSQL (GlowApp)

Opciones:
  -n, --dry-run   Imprime el plan (comando pg_dump, checksum, rotación) y sale 0
                  sin conectarse a la base de datos.
  -h, --help      Muestra esta ayuda.

Entorno:
  DB_HOST (localhost) DB_PORT (5432) DB_NAME (glowapp) DB_USER (glowapp)
  DB_PASSWORD | PGPASSWORD   — obligatoria en ejecución real
  BACKUP_DIR (/var/backups/glowapp)  RETENTION_DAYS (30)
  COMPRESS_LEVEL (3)  JOBS (4)  LOCK_FILE  LOG_FILE
EOF
}

DRY_RUN="false"
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN="true" ;;
    --help|-h)     usage; exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

# --- Configuración (por entorno; la contraseña NUNCA se hardcodea) -----------
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-glowapp}"
DB_USER="${DB_USER:-glowapp}"
DB_PASSWORD="${DB_PASSWORD:-${PGPASSWORD:-}}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/glowapp}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
COMPRESS_LEVEL="${COMPRESS_LEVEL:-3}"
JOBS="${JOBS:-4}"
LOCK_FILE="${LOCK_FILE:-${BACKUP_DIR}/.db_backup.lock}"
LOG_FILE="${LOG_FILE:-${BACKUP_DIR}/backup.log}"

TS="$(date -u +%Y%m%d_%H%M%S)"
DUMP_FILE="${BACKUP_DIR}/glowapp_${DB_NAME}_${TS}.dump"
CHECK_FILE="${DUMP_FILE}.sha256"

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG_FILE"; }

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

# Comando de dump: custom (-Fc) + compresión (-Z) + paralelo (-j).
PG_DUMP_CMD=(pg_dump -Fc -Z "${COMPRESS_LEVEL}" -j "${JOBS}" \
  -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${DUMP_FILE}")

# --- Plan (dry-run) ----------------------------------------------------------
if [ "$DRY_RUN" = "true" ]; then
  echo "[dry-run] Backup de PostgreSQL (no se toca la base de datos):"
  echo "[dry-run] ${PG_DUMP_CMD[*]}"
  echo "[dry-run] checksum SHA-256 -> ${CHECK_FILE}"
  echo "[dry-run] rotación: borrar en ${BACKUP_DIR} los glowapp_*.dump* con más de ${RETENTION_DAYS} días (find -mtime)"
  exit 0
fi

# --- Ejecución real ----------------------------------------------------------
if [ -z "$DB_PASSWORD" ]; then
  echo "❌ Falta la contraseña de PostgreSQL: exporta DB_PASSWORD (o PGPASSWORD)." >&2
  exit 2
fi
command -v pg_dump >/dev/null 2>&1 || { echo "❌ pg_dump no está en el PATH." >&2; exit 2; }
command -v flock   >/dev/null 2>&1 || { echo "❌ flock no está instalado (lo exige el lock anti-concurrencia)." >&2; exit 2; }

mkdir -p "$BACKUP_DIR"

# Lock anti-concurrencia: si ya hay un backup en curso, abortar sin dañar nada.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "❌ Otro backup ya está en ejecución (lock: $LOCK_FILE). Abortando." >&2
  exit 3
fi

# Si el dump queda a medias, no dejarlo como si fuera un respaldo válido.
cleanup() {
  local rc=$?
  if [ "$rc" -ne 0 ] && [ -f "$DUMP_FILE" ]; then
    rm -f "$DUMP_FILE" "$CHECK_FILE"
    echo "🧹 Se eliminó el dump parcial tras el fallo (rc=$rc)." >&2
  fi
  exit "$rc"
}
trap cleanup EXIT INT TERM

# La contraseña se entrega al cliente por entorno, nunca por línea de comandos.
export PGPASSWORD="$DB_PASSWORD"

log "Iniciando backup de '${DB_NAME}' en ${DB_HOST}:${DB_PORT} -> ${DUMP_FILE}"
"${PG_DUMP_CMD[@]}"

if [ ! -s "$DUMP_FILE" ]; then
  echo "❌ El dump no se generó o quedó vacío: $DUMP_FILE" >&2
  exit 1
fi

# Checksum de integridad: el restore lo verifica antes de restaurar.
( cd "$BACKUP_DIR" && sha256 "$(basename "$DUMP_FILE")" > "$(basename "$CHECK_FILE")" )
log "Checksum generado -> ${CHECK_FILE}"

# Rotación por retención (evita llenar el disco; mantiene RETENTION_DAYS días).
DELETED="$(find "$BACKUP_DIR" -maxdepth 1 -type f \
  \( -name 'glowapp_*.dump' -o -name 'glowapp_*.dump.sha256' \) \
  -mtime +"$RETENTION_DAYS" -print -delete | wc -l | tr -d ' ')"
log "Rotación completada (retención ${RETENTION_DAYS} días; ${DELETED} archivos eliminados)."

trap - EXIT INT TERM
log "✅ Backup completado: $(basename "$DUMP_FILE")"
exit 0
