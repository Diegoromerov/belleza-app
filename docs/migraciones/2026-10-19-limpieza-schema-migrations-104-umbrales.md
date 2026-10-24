# Limpieza de `schema_migrations`: registro duplicado de umbrales de envío

**Fecha:** 2026-10-19 · **Entorno:** producción (Railway, servicio `belleza-app`) · **Autorización:** el director pidió «limpiar el registro viejo».

## Qué se borró y por qué

La migración de umbrales de envío (T-094) se aplicó dos veces con nombres distintos durante la colisión de numeración:

| id | filename | checksum | applied_at |
|---|---|---|---|
| 178 | `104_umbrales_envio_aprobados.sql` | `06671ae75d8809a3` | 2026-10-20 04:04:59 |
| 179 | `105_umbrales_envio_aprobados.sql` | `06671ae75d8809a3` | 2026-10-20 04:10:18 |

**Mismo checksum → mismo contenido.** El archivo `104_...` ya no existe en el repositorio: se renumeró a `105` para resolver el choque. Se borró la fila 178 (el nombre que ya no existe) y se conservó la 179, que es la que corresponde al archivo actual.

## Evidencia previa (antes de escribir)

- `zonas_envio`: `300000.00` → 1 fila (Bogotá), `480000.00` → 20 filas. El efecto de la migración está aplicado y no depende del registro.
- Sin claves foráneas que apunten a `schema_migrations`.
- Total de registros antes: **179**.
- Respaldo: `docs/migraciones/backups/backup-schema-migrations-104-umbrales.json` (491 bytes, incluye las dos filas con checksum y fecha).

## Ensayo en seco

`BEGIN` → `DELETE ... WHERE filename = $1 AND checksum = $2` → `rowCount 1` → `SELECT count(*)` = 178 → `ROLLBACK` → 179.
Sin escritura persistida.

## Ejecución

```sql
BEGIN;
DELETE FROM schema_migrations
 WHERE filename = '104_umbrales_envio_aprobados.sql'
   AND checksum = '06671ae75d8809a3';
-- rowCount: 1
COMMIT;
```

Guarda previa en el mismo script: se aborta si la fila destino o la 105 no están con el checksum esperado, y si `rowCount <> 1`.

## Verificación posterior (conexión nueva, sin transacción)

| Comprobación | Resultado |
|---|---|
| Total de registros | **178** (era 179) |
| Registros `%umbrales%` | sólo `105_umbrales_envio_aprobados.sql`, checksum intacto |
| `zonas_envio` | `300000.00` → 1 · `480000.00` → 20 (sin cambios) |
| `biometric_scan_sessions.image_hash` | presente (Y-F5 intacta) |
| `/api/health` | 200 · commit `6dd8c2c2` |

## Qué NO cubre esta limpieza

- No toca las migraciones duplicadas históricas por prefijo (`001`…`082`): son el baseline legacy que el guard de numeración conoce y no se renumeran.
- No modifica los archivos de migración ni el código; sólo el registro de aplicación.
- Si alguien vuelve a crear un `104_umbrales_envio_aprobados.sql`, el runner lo aplicaría otra vez (es idempotente), pero el guard de numeración lo bloquearía antes de mergear.
