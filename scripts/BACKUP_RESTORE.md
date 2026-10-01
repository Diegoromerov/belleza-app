# Backup & Restore — GlowApp (runbook operativo)

Cierra el hallazgo **P0 INFRA #5 — «Sin backup/restore automation (RPO/RTO indefinidos)»**
(`AUDITORIA_PREPRODUCCION_MASTER.md:73`).

## Objetivos de continuidad (RPO / RTO)

| Métrica | Objetivo | Cómo se garantiza |
|---|---|---|
| **RPO** (pérdida máxima de datos) | ≤ 24 h | `db_backup.sh` en cron diario 02:00 UTC → `scripts/backup.cron` |
| **RTO** (tiempo máximo de restauración) | ≤ 30 min | `pg_dump -Fc -Z 3 -j 4` + `pg_restore -j 4` (paralelo, no el SQL plano de 15-30 min) |
| **Verificación** | mensual | `db_restore_test.sh` en cron (día 1, 04:00 UTC): restaura en scratch y valida |

Antes de este fix solo existía `db_backup.ps1` (volcado SQL **plano**, sin compresión,
sin paralelismo, sin cron y sin restore probado). Un backup nunca restaurado no es un backup.

## Componentes

| Archivo | Función |
|---|---|
| `scripts/db_backup.sh` | Backup: `pg_dump -Fc -Z 3 -j 4`, `flock` anti-concurrencia, checksum SHA-256, rotación `RETENTION_DAYS`. |
| `scripts/db_restore.sh` | Restore: `pg_restore -j`, valida `--list` + checksum antes de tocar la BD, guard contra PROD (`ALLOW_PROD`). |
| `scripts/db_restore_test.sh` | Drill: crea scratch, restaura, valida nº de tablas, elimina scratch. Falla ≠ 0 si el respaldo no restaura. |
| `scripts/backup.cron` | Programación: backup diario + drill mensual (formato `/etc/cron.d`). |
| `scripts/install_backup_cron.sh` | Instala/actualiza el crontab de forma **idempotente** (bloque gestionado GLOWAPP). |
| `scripts/tests/db_backup_restore.test.sh` | Test estático + ejecución `--dry-run` (rojo→verde), sin base de datos. |

## Operación

### Instalar la programación (una vez por host)

```bash
sudo ./scripts/install_backup_cron.sh     # instala/actualiza el bloque gestionado
./scripts/install_backup_cron.sh --print   # ver el bloque sin instalar
./scripts/install_backup_cron.sh --remove  # retirarlo
```

### Backup manual

```bash
export DB_HOST=... DB_PORT=5432 DB_NAME=glowapp DB_USER=glowapp DB_PASSWORD=***
./scripts/db_backup.sh
./scripts/db_backup.sh --dry-run    # imprime el plan sin conectarse
```

Salida: `BACKUP_DIR` (por defecto `/var/backups/glowapp`) contiene
`glowapp_<db>_<UTC>.dump` (custom comprimido, paralelo) y su `.dump.sha256`.

### Restore

```bash
./scripts/db_restore.sh /var/backups/glowapp/glowapp_glowapp_<ts>.dump --target-db glowapp_restore
# Sobre un destino que parece PRODUCCIÓN se exige --force / ALLOW_PROD=yes.
```

### Verificar que el respaldo RESTAURA (drill)

```bash
export DB_PASSWORD=***
./scripts/db_restore_test.sh                 # usa el .dump más reciente
./scripts/db_restore_test.sh --dry-run       # plan sin tocar la BD
```

## Credenciales

Ninguna contraseña se versiona: los scripts leen `DB_PASSWORD` / `PGPASSWORD`
(o `DATABASE_URL`) **solo del entorno**, coherente con el resto de P0 de seguridad.

## Test del fix

```bash
bash scripts/tests/db_backup_restore.test.sh
```

Nivel de evidencia **E1** (tests automatizados estáticos en worktree, sin
`node_modules` ni PostgreSQL). E2/E3 (staging/producción) pendientes del Dueño.
