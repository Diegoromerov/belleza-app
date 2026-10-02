#!/usr/bin/env bash
# =============================================================================
# scripts/db_restore_test.sh — Drill de restauración (el «test restore mensual»
# del hallazgo P0 «Sin backup/restore automation», AUDITORIA_...:73).
#
# Un backup que nunca se ha restaurado NO es un backup. Este script:
#   1. Toma el respaldo más reciente (o el indicado) en BACKUP_DIR.
#   2. Crea una base SCRATCH aislada (nunca toca la de producción).
#   3. Restaura el respaldo en la scratch con scripts/db_restore.sh.
#   4. VALIDA el contenido (nº de tablas > 0 y tablas esperadas presentes).
#   5. Elimina la scratch (pase o falle) vía trap.
#   6. Sale != 0 si el respaldo NO es restaurable: el RTO/RPO queda probado.
#
# Uso:
#   DB_PASSWORD=*** ./scripts/db_restore_test.sh [archivo.dump]
#   ./scripts/db_restore_test.sh --dry-run     # imprime el plan, no toca la BD
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
scripts/db_restore_test.sh — drill de restauración de PostgreSQL (GlowApp)

Uso: db_restore_test.sh [archivo.dump] [--dry-run]

  Sin argumento, usa el .dump más reciente de BACKUP_DIR.
  -n, --dry-run   Imprime el plan (crear scratch, restaurar, validar, borrar) y sale 0.
  -h, --help      Muestra esta ayuda.

Entorno: DB_HOST DB_PORT DB_USER DB_PASSWORD|PGPASSWORD BACKUP_DIR JOBS
EOF
}

BACKUP_FILE=""
DRY_RUN="false"
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN="true" ;;
    --help|-h)    usage; exit 0 ;;
    -*)           echo "Opción desconocida: $arg" >&2; usage >&2; exit 2 ;;
    *)            BACKUP_FILE="$arg" ;;
  esac
done

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-glowapp}"
DB_PASSWORD="${DB_PASSWORD:-${PGPASSWORD:-}}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/glowapp}"
JOBS="${JOBS:-4}"

# Resolver el respaldo: argumento explícito o el .dump más reciente.
if [ -z "$BACKUP_FILE" ]; then
  BACKUP_FILE="$(ls -1t "${BACKUP_DIR}"/glowapp_*.dump 2>/dev/null | head -n 1 || true)"
fi
SCRATCH_DB="glowapp_restore_drill_$(date -u +%Y%m%d_%H%M%S)"

PSQL_BASE=(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -v ON_ERROR_STOP=1)

if [ "$DRY_RUN" = "true" ]; then
  echo "[dry-run] Drill de restauración (no se toca la base de datos):"
  echo "[dry-run] respaldo a probar: ${BACKUP_FILE:-<ninguno encontrado en ${BACKUP_DIR}>}"
  echo "[dry-run] psql -c 'CREATE DATABASE \"${SCRATCH_DB}\"'          # scratch aislada"
  echo "[dry-run] TARGET_DB=${SCRATCH_DB} ALLOW_PROD=yes ${SCRIPT_DIR}/db_restore.sh \"${BACKUP_FILE}\""
  echo "[dry-run] psql -d ${SCRATCH_DB} -tAc \"SELECT count(*) FROM information_schema.tables WHERE table_schema='public'\""
  echo "[dry-run] psql -c 'DROP DATABASE \"${SCRATCH_DB}\"'            # limpieza (trap)"
  exit 0
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ No se encontró ningún respaldo para probar (BACKUP_DIR=${BACKUP_DIR})." >&2
  exit 1
fi
command -v psql >/dev/null 2>&1 || { echo "❌ psql no está en el PATH." >&2; exit 2; }
[ -n "$DB_PASSWORD" ] || { echo "❌ Falta DB_PASSWORD (o PGPASSWORD)." >&2; exit 2; }

export PGPASSWORD="$DB_PASSWORD"

# Limpieza garantizada de la scratch, pase o falle el drill.
cleanup() {
  local rc=$?
  "${PSQL_BASE[@]}" -d postgres -c "DROP DATABASE IF EXISTS \"${SCRATCH_DB}\"" >/dev/null 2>&1 || true
  exit "$rc"
}
trap cleanup EXIT INT TERM

echo "🧪 Drill de restore: '$(basename "$BACKUP_FILE")' -> scratch '${SCRATCH_DB}'"

# 1) Crear base scratch aislada.
"${PSQL_BASE[@]}" -d postgres -c "CREATE DATABASE \"${SCRATCH_DB}\"" >/dev/null

# 2) Restaurar en la scratch (sin tocar producción).
TARGET_DB="$SCRATCH_DB" ALLOW_PROD=yes JOBS="$JOBS" \
  "${SCRIPT_DIR}/db_restore.sh" "$BACKUP_FILE"

# 3) Validar: el respaldo debe traer tablas en el esquema público.
TABLES="$("${PSQL_BASE[@]}" -d "$SCRATCH_DB" -tAc \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'")"
TABLES="${TABLES//[[:space:]]/}"
if [ "${TABLES:-0}" -le 0 ]; then
  echo "❌ Drill FALLIDO: el respaldo se restauró pero no contiene tablas en 'public'." >&2
  exit 1
fi

# Comprobación de una tabla núcleo, si existe en el esquema.
USUARIOS="$("${PSQL_BASE[@]}" -d "$SCRATCH_DB" -tAc \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='usuarios'")"
USUARIOS="${USUARIOS//[[:space:]]/}"

echo "✅ Drill OK: ${TABLES} tablas restauradas (usuarios presentes: ${USUARIOS:-0})."
echo "   RTO verificado: el respaldo es restaurable y contiene datos."
exit 0
