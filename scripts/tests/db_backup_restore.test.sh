#!/bin/bash
# =============================================================================
# Test estático + ejecución dry-run (sin node_modules, sin base de datos)
# t_fix_infra_05 — P0 INFRA #5: "Sin backup/restore automation (RPO/RTO indefinidos)"
#   Hallazgo: AUDITORIA_PREPRODUCCION_MASTER.md:73 · scripts/db_backup.ps1
#
# Reproduce las invariantes que el hallazgo exige (acción prescrita:
# `pg_dump -Fc -Z 3 -j 4` + cron + test-restore mensual):
#
#   [A] scripts/db_backup.sh        backup automático: custom/comprimido/paralelo,
#                                   lock anti-concurrencia, retención, checksum,
#                                   credenciales por entorno, fallo con exit!=0.
#   [B] scripts/db_restore.sh       restore automático: pg_restore -j, valida
#                                   archivo + checksum antes de restaurar, guard
#                                   contra producción, nunca password literal.
#   [C] scripts/db_restore_test.sh  drill de restauración sobre DB scratch
#                                   (= "test restore mensual" del hallazgo).
#   [D] scripts/backup.cron         crontab: backup diario + drill recurrente.
#   [E] scripts/install_backup_cron.sh  instalador idempotente del crontab.
#   [F] Ejecución real de cada script con --dry-run (no toca pg_dump ni la BD)
#       y comprobación del comando planificado.
#
# Uso:  bash scripts/tests/db_backup_restore.test.sh
# Salida: PASS/FAIL por aserción + resumen; exit 1 si algo falla.
# =============================================================================
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BACKUP="$ROOT/scripts/db_backup.sh"
RESTORE="$ROOT/scripts/db_restore.sh"
DRILL="$ROOT/scripts/db_restore_test.sh"
CRON="$ROOT/scripts/backup.cron"
INSTALL="$ROOT/scripts/install_backup_cron.sh"
RUNBOOK="$ROOT/scripts/BACKUP_RESTORE.md"

PASS=0
FAIL=0

ok()  { echo "  ✅ $1"; PASS=$((PASS + 1)); }
ko()  { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

check() { # descripción  patrón-ERE  archivo  -> el patrón DEBE existir
  local desc="$1" pat="$2" f="$3"
  if grep -Eq -- "$pat" "$f" 2>/dev/null; then ok "$desc"; else ko "$desc  [patrón ausente: $pat]"; fi
}
absent() { # descripción  patrón-ERE  archivo  -> el patrón NO debe existir
  local desc="$1" pat="$2" f="$3"
  if grep -Eq -- "$pat" "$f" 2>/dev/null; then ko "$desc  [patrón prohibido presente: $pat]"; else ok "$desc"; fi
}
exists() { if [ -f "$1" ]; then ok "$(basename "$1") existe"; else ko "$(basename "$1") NO existe"; fi; }
syntax() { if bash -n "$1" 2>/dev/null; then ok "$(basename "$1") sintaxis bash válida"; else ko "$(basename "$1") sintaxis bash inválida"; fi; }

echo "=== t_fix_infra_05: backup/restore automation (TEST ESTÁTICO + dry-run) ==="
echo

# ─────────────────────────────────────────────────────────────────────────────
echo "[A] scripts/db_backup.sh — backup automático"
exists "$BACKUP"
if [ -f "$BACKUP" ]; then
  syntax "$BACKUP"
  check "usa pg_dump" 'pg_dump' "$BACKUP"
  check "formato custom de pg_dump (-Fc)" '(-Fc|--format[[:space:]=]*c)' "$BACKUP"
  check "comprime el dump (-Z 3 / --compress)" '(-Z[[:space:]]|--compress)' "$BACKUP"
  check "dump PARALELO (-j / --jobs) — el hallazgo pide -j 4" '(-j[[:space:]]|--jobs)' "$BACKUP"
  check "lock anti-concurrencia (flock)" 'flock' "$BACKUP"
  check "retención configurable (RETENTION_DAYS)" 'RETENTION_DAYS' "$BACKUP"
  check "rota/borra respaldos antiguos por antigüedad (find -mtime/-mmin)" 'find[^\n]*-m(time|min)' "$BACKUP"
  check "genera checksum del artefacto (sha256)" '(sha256sum|shasum)' "$BACKUP"
  check "credenciales por ENTORNO (DB_PASSWORD/PGPASSWORD/DATABASE_URL)" '(DB_PASSWORD|PGPASSWORD|DATABASE_URL)' "$BACKUP"
  check "modo estricto (set -e / -euo pipefail)" '^[[:space:]]*set[[:space:]]+-[a-z]*e' "$BACKUP"
  check "modo --dry-run (plan sin tocar la BD)" '(dry-run|DRY_RUN)' "$BACKUP"
  absent "NO hardcodea contraseña literal" '(DB_PASSWORD|PGPASSWORD)[[:space:]]*=[[:space:]]*[A-Za-z0-9]' "$BACKUP"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo "[B] scripts/db_restore.sh — restore automático"
exists "$RESTORE"
if [ -f "$RESTORE" ]; then
  syntax "$RESTORE"
  check "usa pg_restore" 'pg_restore' "$RESTORE"
  check "restore PARALELO (-j / --jobs)" '(-j[[:space:]]|--jobs)' "$RESTORE"
  check "valida el archivo antes de restaurar (pg_restore --list)" '(--list|list[[:space:]])' "$RESTORE"
  check "verifica checksum antes de restaurar (sha256)" '(sha256sum|shasum|sha256)' "$RESTORE"
  check "guard de seguridad para producción" '(ALLOW_PROD|FORCE|I_UNDERSTAND|CONFIRM)' "$RESTORE"
  check "requiere el archivo de respaldo (argumento/\$1)" '(\$1|BACKUP_FILE|ARCHIVO)' "$RESTORE"
  check "modo --dry-run" '(dry-run|DRY_RUN)' "$RESTORE"
  absent "NO hardcodea contraseña literal" '(DB_PASSWORD|PGPASSWORD)[[:space:]]*=[[:space:]]*[A-Za-z0-9]' "$RESTORE"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo "[C] scripts/db_restore_test.sh — drill de restore (test mensual)"
exists "$DRILL"
if [ -f "$DRILL" ]; then
  syntax "$DRILL"
  check "crea una base de datos scratch (CREATE DATABASE/createdb)" '(CREATE DATABASE|createdb)' "$DRILL"
  check "restaura el respaldo en la scratch (pg_restore/db_restore.sh)" '(pg_restore|db_restore\.sh)' "$DRILL"
  check "valida contenido tras restaurar (count/information_schema/pg_tables)" '(COUNT\(|count\(|information_schema|pg_tables)' "$DRILL"
  check "limpia la base scratch (DROP DATABASE/dropdb)" '(DROP DATABASE|dropdb)' "$DRILL"
  check "falla con exit != 0 si el restore no es válido" '(exit[[:space:]]+1|return[[:space:]]+1)' "$DRILL"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo "[D] scripts/backup.cron — programación (cron)"
exists "$CRON"
if [ -f "$CRON" ]; then
  check "programa backup DIARIO (5 campos + db_backup.sh)" '^[0-9*/, -]+[[:space:]]+[0-9*/, -]+[[:space:]]+[0-9*/, -]+[[:space:]]+[0-9*/, -]+[[:space:]]+[0-9*/, -]+[[:space:]]+[^\n#]*db_backup\.sh' "$CRON"
  check "programa drill de restore recurrente (db_restore_test.sh)" '[^\n#]*db_restore_test\.sh' "$CRON"
  check "es un crontab documentado (MAILTO o comentario de cabecera)" '(MAILTO|^#)' "$CRON"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo "[E] scripts/install_backup_cron.sh — instalación idempotente del cron"
exists "$INSTALL"
if [ -f "$INSTALL" ]; then
  syntax "$INSTALL"
  check "instala el crontab con el comando crontab" 'crontab' "$INSTALL"
  check "idempotente (marca gestionada GLOWAPP/BEGIN/END)" '(GLOWAPP|BEGIN|END|marca)' "$INSTALL"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo "[F] Runbook de operación (RPO/RTO documentados)"
if [ -f "$RUNBOOK" ]; then
  ok "BACKUP_RESTORE.md existe"
  check "documenta RPO" 'RPO' "$RUNBOOK"
  check "documenta RTO" 'RTO' "$RUNBOOK"
else
  ko "scripts/BACKUP_RESTORE.md NO existe"
fi

# ─────────────────────────────────────────────────────────────────────────────
# [G] EJECUCIÓN REAL en modo --dry-run (sin pg_dump ni PostgreSQL)
# ─────────────────────────────────────────────────────────────────────────────
echo "[G] Ejecución real --dry-run (sin BD)"
DRY_OUT="$(mktemp 2>/dev/null || echo "$ROOT/.dry_run_out")"

run_dry() { # script
  local s="$1" name
  name="$(basename "$s")"
  if [ ! -f "$s" ]; then ko "$name --dry-run (script ausente)"; return 1; fi
  if bash "$s" --dry-run >"$DRY_OUT" 2>&1; then
    ok "$name --dry-run sale 0"
  else
    ko "$name --dry-run devolvió exit != 0"
  fi
}

if [ -f "$BACKUP" ]; then
  run_dry "$BACKUP"
  if grep -Eq -- 'pg_dump' "$DRY_OUT" && grep -Eq -- '(-Fc|--format[[:space:]=]*c)' "$DRY_OUT"; then
    ok "el plan de backup incluye pg_dump -Fc"
  else
    ko "el plan de backup no muestra pg_dump -Fc"
  fi
  if grep -Eq -- '(-j[[:space:]]*[0-9]|--jobs)' "$DRY_OUT"; then
    ok "el plan de backup es paralelo (-j)"
  else
    ko "el plan de backup no es paralelo (-j)"
  fi
fi

if [ -f "$RESTORE" ]; then
  run_dry "$RESTORE"
  if grep -Eq -- 'pg_restore' "$DRY_OUT"; then
    ok "el plan de restore incluye pg_restore"
  else
    ko "el plan de restore no muestra pg_restore"
  fi
fi

if [ -f "$DRILL" ]; then
  run_dry "$DRILL"
fi

rm -f "$DRY_OUT" 2>/dev/null

# ─────────────────────────────────────────────────────────────────────────────
echo
echo "--- RESULTADO ---"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: ❌ ROJO  (NO existe automatización de backup/restore)"
  exit 1
fi
echo "RESULT: ✅ VERDE (automatización de backup/restore presente y operativa)"
exit 0
