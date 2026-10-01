#!/usr/bin/env bash
# =============================================================================
# scripts/install_backup_cron.sh — instala (idempotente) la programación de
# respaldos GlowApp en el crontab del usuario actual.
#
# Cierra el «Sin cron» del hallazgo P0 (AUDITORIA_PREPRODUCCION_MASTER.md:73).
# El bloque gestionado se delimita con marcadores GLOWAPP; reinstalar ACTUALIZA
# el bloque en lugar de duplicarlo.
#
# Uso:
#   ./scripts/install_backup_cron.sh            # instala el bloque gestionado
#   ./scripts/install_backup_cron.sh --print    # imprime el bloque sin instalar
#   ./scripts/install_backup_cron.sh --remove   # retira el bloque gestionado
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_SRC="${SCRIPT_DIR}/backup.cron"
BEGIN="# BEGIN GLOWAPP BACKUP (managed — no editar a mano)"
END="# END GLOWAPP BACKUP"

MODE="install"
for arg in "$@"; do
  case "$arg" in
    --print)  MODE="print" ;;
    --remove) MODE="remove" ;;
    --help|-h)
      sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 2 ;;
  esac
done

[ -f "$CRON_SRC" ] || { echo "❌ No se encontró $CRON_SRC" >&2; exit 2; }

# El bloque gestionado replica las líneas de TAREA de backup.cron (se omiten las
# directivas de entorno de /etc/cron.d, que no aplican al crontab de usuario).
build_block() {
  echo "$BEGIN"
  echo "# Generado desde scripts/backup.cron — reinstala con scripts/install_backup_cron.sh"
  grep -Ev '^[[:space:]]*(#|SHELL=|MAILTO=|PATH=|$)' "$CRON_SRC"
  echo "$END"
}

current_crontab() { crontab -l 2>/dev/null || true; }
strip_block() { current_crontab | sed "\|^${BEGIN}$|,\|^${END}$|d"; }

case "$MODE" in
  print)
    build_block
    ;;
  remove)
    strip_block | crontab -
    echo "✅ Bloque GLOWAPP retirado del crontab."
    ;;
  install)
    TMP="$(mktemp)"
    strip_block > "$TMP"
    # Añade el bloque gestionado (idempotente: el bloque previo ya fue retirado).
    { cat "$TMP"; build_block; } | crontab -
    rm -f "$TMP"
    echo "✅ Programación de respaldos instalada en el crontab."
    echo "   Backup diario 02:00 UTC + drill de restauración mensual (día 1, 04:00 UTC)."
    crontab -l | grep -A2 -B1 GLOWAPP || true
    ;;
esac
