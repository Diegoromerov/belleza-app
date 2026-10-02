#!/usr/bin/env bash
# =============================================================================
# scripts/db_restore.sh — Restore automatizado de PostgreSQL (GlowApp)
#
# Cierra el hallazgo P0 «Sin backup/restore automation» (AUDITORIA_...:73):
#   * Restaura un dump CUSTOM con pg_restore en PARALELO (-j): minutos en vez de
#     los 15-30 min del volcado SQL plano.
#   * Valida el ARCHIVO (pg_restore --list) y su CHECKSUM SHA-256 ANTES de tocar
#     la base de destino: un respaldo corrupto no destruye nada.
#   * Guard contra producción: si el destino parece PROD exige ALLOW_PROD=yes.
#   * Credenciales SOLO por entorno (DB_PASSWORD / PGPASSWORD / DATABASE_URL).
#
# Uso:
#   ./scripts/db_restore.sh <archivo.dump> [--target-db DB] [--dry-run] [--force]
#
# Entorno:
#   DB_HOST (localhost) DB_PORT (5432) DB_USER (glowapp)
#   DB_PASSWORD | PGPASSWORD     — obligatoria en ejecución real
#   TARGET_DB                    — base destino (por defecto DB_NAME o glowapp_restore)
#   JOBS (4)  ALLOW_PROD (no)
# =============================================================================
set -euo pipefail

usage() {
  cat <<'EOF'
scripts/db_restore.sh — restore de PostgreSQL (GlowApp)

Uso: db_restore.sh <archivo.dump> [opciones]

Opciones:
  --target-db DB   Base de datos destino (default: DB_NAME o glowapp_restore)
  -n, --dry-run    Imprime el plan (validación, checksum, pg_restore) y sale 0
  -f, --force      Confirma restaurar sobre un destino que parece PRODUCCIÓN
  -h, --help       Muestra esta ayuda

Entorno: DB_HOST DB_PORT DB_USER DB_PASSWORD|PGPASSWORD TARGET_DB JOBS ALLOW_PROD
EOF
}

BACKUP_FILE=""
TARGET_DB="${TARGET_DB:-}"
DRY_RUN="false"
ALLOW_PROD="${ALLOW_PROD:-no}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n)   DRY_RUN="true"; shift ;;
    --force|-f)     ALLOW_PROD="yes"; shift ;;
    --target-db)    TARGET_DB="${2:-}"; shift 2 ;;
    --target-db=*)  TARGET_DB="${1#*=}"; shift ;;
    --help|-h)      usage; exit 0 ;;
    -*)             echo "Opción desconocida: $1" >&2; usage >&2; exit 2 ;;
    *)              BACKUP_FILE="$1"; shift ;;
  esac
done

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-glowapp}"
DB_PASSWORD="${DB_PASSWORD:-${PGPASSWORD:-}}"
JOBS="${JOBS:-4}"
TARGET_DB="${TARGET_DB:-${DB_NAME:-glowapp_restore}}"

# En dry-run sin archivo, mostrar el plan con una ruta representativa.
if [ -z "$BACKUP_FILE" ] && [ "$DRY_RUN" = "true" ]; then
  BACKUP_FILE="${BACKUP_DIR:-/var/backups/glowapp}/glowapp_latest.dump"
fi
if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Falta el archivo de respaldo: db_restore.sh <archivo.dump>" >&2
  exit 2
fi

# Guard contra producción: nunca pisar PROD por accidente.
case "$TARGET_DB" in
  *prod*|*PROD*|*production*|railway)
    if [ "$ALLOW_PROD" != "yes" ]; then
      echo "❌ El destino '$TARGET_DB' parece PRODUCCIÓN. Confirma con --force o ALLOW_PROD=yes." >&2
      exit 4
    fi ;;
esac

# Comando de restore: paralelo (-j), limpia objetos preexistentes de forma segura.
PG_RESTORE_CMD=(pg_restore -j "${JOBS}" --no-owner --clean --if-exists \
  -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}" "${BACKUP_FILE}")

# --- Plan (dry-run) ----------------------------------------------------------
if [ "$DRY_RUN" = "true" ]; then
  echo "[dry-run] Restore de PostgreSQL (no se toca la base de datos):"
  echo "[dry-run] pg_restore --list ${BACKUP_FILE}        # valida el archivo"
  echo "[dry-run] sha256sum -c ${BACKUP_FILE}.sha256     # verifica integridad"
  echo "[dry-run] ${PG_RESTORE_CMD[*]}"
  exit 0
fi

# --- Ejecución real ----------------------------------------------------------
if [ -z "$DB_PASSWORD" ]; then
  echo "❌ Falta la contraseña de PostgreSQL: exporta DB_PASSWORD (o PGPASSWORD)." >&2
  exit 2
fi
command -v pg_restore >/dev/null 2>&1 || { echo "❌ pg_restore no está en el PATH." >&2; exit 2; }
if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ No existe el archivo de respaldo: $BACKUP_FILE" >&2
  exit 2
fi

# 1) Integridad: si hay checksum, verificarlo (respaldo corrupto -> abortar).
if [ -f "${BACKUP_FILE}.sha256" ] || [ -f "${BACKUP_FILE}.sha256.sha256" ]; then
  CHECK="${BACKUP_FILE}.sha256"
  [ -f "$CHECK" ] || CHECK="${BACKUP_FILE}.sha256.sha256"
  ( cd "$(dirname "$BACKUP_FILE")" && sha256sum -c "$(basename "$CHECK")" ) \
    || { echo "❌ Checksum inválido: el respaldo está corrupto." >&2; exit 5; }
else
  echo "⚠️  No hay archivo .sha256 junto al respaldo; se omite la verificación de integridad." >&2
fi

# 2) Formato: pg_restore debe reconocer el archivo antes de tocar la BD destino.
if ! pg_restore --list "$BACKUP_FILE" >/dev/null 2>&1; then
  echo "❌ pg_restore no reconoce '$BACKUP_FILE' (¿no es un dump -Fc?)." >&2
  exit 5
fi

export PGPASSWORD="$DB_PASSWORD"
echo "⏪ Restaurando '$(basename "$BACKUP_FILE")' en la base '${TARGET_DB}'..."
"${PG_RESTORE_CMD[@]}"

echo "✅ Restore completado en '${TARGET_DB}'."
exit 0
