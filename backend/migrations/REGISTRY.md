# Reglas y registro de numeración de migraciones

**Un prefijo numérico = una migración.** El prefijo es el único contrato de orden
entre migraciones independientes, y por eso está custodiado por el guard
`backend/tests/migrationsNoDuplicateNumbers.test.js` (bloqueante dentro del gate
de jest).

Cómo funciona el runner, para entender por qué el número importa
(`backend/src/config/migrationRunner.js`):

1. Lee `backend/migrations/` **solo el nivel superior**, toma los `.sql` que **no**
   terminan en `.down.sql`, y los ordena **alfabéticamente**.
2. Registra cada migración por **nombre de archivo completo** en
   `schema_migrations (filename UNIQUE)` — con checksum para detectar drift.
3. Una migración ya registrada **no se re-ejecuta nunca**.

Consecuencia directa: si dos archivos comparten el número, el orden de aplicación
lo decide el alfabeto del sufijo, nadie puede razonarlo, y el `filename` sí es
distinto ⇒ **las dos se aplican**, en un orden que nadie eligió.

---

## 1. Colisión resuelta: 4 ramas eligieron `073` (bloqueador de merge de Fase D)

**Qué pasó.** Cuatro ramas de fix partieron **en aislamiento** desde el mismo
commit `9cb3fb077` (verificado: `git merge-base <rama> 9cb3fb077` = `9cb3fb077` en
las cuatro). Cada una miró el directorio, vio que el máximo era `072`, y eligió el
mismo número libre: `073`. Ninguna pudo ver a las otras, porque el número se asigna
mirando el estado local, no el estado del repositorio.

**Estado del que se partió:** `072_catalogo_autorizado_y_historial_protegido.sql`
(máximo real, medido con el guard: 15 números ya duplicados de forma *histórica*,
ninguno por encima de `072`).

**Asignación determinista** (`ASIGNACION_FASE_D` en el guard):

| N.º | Migración | Rama de origen | Hallazgo |
|-----|-----------|----------------|----------|
| `073` | `073_create_kyc_audit_logs.sql` | `agent/t_fix_legal_02-fix-cumplimiento-legal` | KYC: auditoría legal inmutable de verificaciones |
| `074` | `074_wallet_transactions_append_only.sql` | `agent/t_fix_pagos_05-fix-seguridad-pagos` | P0-02 · `wallet_transactions` append-only + `wallet_ledger_events` |
| `075` | `075_create_admin_audit_logs.sql` | `agent/t_fix_flutter_10-flutter-audit-fix` | FIX-FLUTTER-10 P2 · trazabilidad de acciones admin |
| `076` | `076_rag_embedding_dimension_2048.sql` | `agent/t_fix_ragaura_03-fix-rag-aura` | N-4 · pgvector `1024 → 2048` + HNSW |

**Criterio de asignación.** Es una asignación **fija y determinista**, fijada una
sola vez por la resolución de integración: `073` KYC → `074` wallet → `075` admin →
`076` RAG. No se deriva del orden de merge ni del alfabeto de los archivos de
origen, y eso es deliberado: lo que importa no es *qué* orden se eligió, sino que
sea **estable y reproducible**. Queda congelado por el guard — cualquier
reasignación posterior rompe el caso `la asignación de Fase D está materializada con
números distintos` y obliga a actualizar este documento a propósito, no por
accidente.

**Rollbacks.** Los `.down.sql` viven en `backend/migrations/rollback/` (convención
que ya existía, p. ej. `rollback/035_fix_embedding_dimension_and_hnsw_index.down.sql`).
El runner ignora `.down.sql` y no lee subdirectorios, así que un rollback **jamás**
se ejecuta en un arranque. Se renumeraron con su `up`:

- `rollback/074_wallet_transactions_append_only.down.sql`
- `rollback/076_rag_embedding_dimension_2048.down.sql`

Las migraciones `073` (KYC) y `075` (admin) no traían rollback: son `CREATE TABLE`
+ triggers `IF NOT EXISTS` / `CREATE OR REPLACE`, y su reversión es
`DROP TABLE` manual (documentado en el propio archivo).

**Contenido idéntico al de origen.** La renumeración cambió **solo el número** en
nombre de archivo y en los comentarios internos que lo citaban. Verificado con
`git show <rama>:<ruta-original> | diff - <ruta-nueva>` para los 6 archivos: ninguna
sentencia SQL fue tocada.

---

## 2. Deuda histórica: 15 números duplicados desde antes de la Fase D

`main` ya llegaba con estos duplicados, **todos aplicados en producción**:

```
002  003  004  008  011  012  026  029  030  032  033  034  065  066  067
```

**Por qué NO se renumeran aquí.** `schema_migrations` rastrea por **nombre de
archivo**: renombrar un legacy cambiaría su `filename` y el runner lo trataría como
nueva ⇒ se re-ejecutaría. Varias de esas migraciones **no son idempotentes**, así
que eso no es una renumeración cosmética, es un incidente. Además hay rutas citadas
por nombre en el código, y hay que actualizarlas en el mismo cambio:

- `backend/scripts/prepareRlsDatabase.js:50` → `migrations/065_multi_tenant_hardening.sql`
- `backend/scripts/verifyCatalogoAutorizado.js:73` → `../migrations/072_catalogo_autorizado_y_historial_protegido.sql`

El reordenamiento **completo** del directorio (0→N secuencial, sin huecos) tiene
tarjeta propia y ya está en marcha:
**`agent/t_fix_8aeb7051-p2-3-consolidate-migrations`**. Duplicarlo aquí crearía dos
esquemas de renumeración en competencia y un conflicto mucho peor.

**Decisión:** el guard **congela** ese backlog en `BASELINE_DUPLICADOS_LEGACY`
(lista exacta de archivos por número, no solo el número). Queda visible y
verificable, y **cualquier duplicado nuevo falla**, sea cual sea su número:

- duplicado con número nuevo (≥ `073`) → falla por detección directa;
- duplicado colado bajo un número legacy → falla porque el baseline deja de
  coincidir con la realidad.

Un baseline obsoleto no protege: si alguien renumera o borra un legacy, el guard
falla y obliga a actualizar el baseline **y** este documento.

---

## 3. Colisión pendiente detectada (fuera del alcance de esta rama)

El mismo guard detecta una **segunda colisión en curso**, no reportada en el
hallazgo original, entre ramas que aún no han mergeado:

| N.º | Archivos | Ramas |
|-----|----------|-------|
| `049` | `049_fix_biometric_consents_user_id_type.sql` | `t_fix_bec_001`, `t_fix_qa_001`, `t_fix_veto_001` |
| `049` | `049_alter_embedding_dimension_to_2048.sql` | `t_fix_rag_001` |

`049` está libre en `main` (el directorio salta de `048` a `053`), y **cuatro ramas
lo reclamaron a la vez, con dos nombres distintos**: es exactamente el mismo patrón
de fallo que el `073`, un número más abajo. Al mergear, el guard **fallará**
(está diseñado para eso). Quien integre esas ramas debe asignar números distintos
antes de mergear, no ampliar el baseline.

---

## 4. Reglas para añadir una migración

1. **Toma el número libre más alto + 1**, comprobando el directorio **y las ramas
   en vuelo**, no solo tu worktree. Hoy: el máximo es `076` ⇒ el siguiente libre es
   **`077`**.
2. Formato `NNN_descripcion_en_snake_case.sql` (3 dígitos, con ceros a la izquierda).
3. Un `.down.sql` va en `rollback/`, con **el mismo prefijo y el mismo tallo** que su
   `up` (`074_x.sql` ⟺ `rollback/074_x.down.sql`). El guard lo verifica.
4. Antes de commitear:
   ```bash
   node backend/tests/migrationsNoDuplicateNumbers.test.js   # 0 fallos, exit 0
   ```
   El guard corre por **dos** vías, ambas bloqueantes: como paso propio en
   `.github/workflows/ci.yml` (antes de levantar PostgreSQL, porque el paso de jest
   queda `skipped` detrás de CI-46) y como test dentro del gate de jest
   (`testMatch` `**/tests/**/*.test.js`).
5. Si tu número choca con otra rama: **renumera tu migración** (la que aún no está
   aplicada). Nunca renumeres una ya aplicada, y nunca amplíes el baseline.

---

## 5. Evidencia

| Qué | Comando | Resultado |
|-----|---------|-----------|
| Colisión real | `node backend/tests/migrationsNoDuplicateNumbers.test.js` (4 migraciones con su `073` original) | **ROJO** · exit 1 · `073 (4): 073_create_admin_audit_logs.sql, 073_create_kyc_audit_logs.sql, 073_rag_embedding_dimension_2048.sql, 073_wallet_transactions_append_only.sql` |
| Fix aplicado | `node backend/tests/migrationsNoDuplicateNumbers.test.js` | **VERDE** · exit 0 · `7/7 casos en verde · 0 fallo(s)` |
| El guard no es vacuo | sembrar `077_control_a.sql` + `077_control_b.sql` y correr el guard | **ROJO** · exit 1 · 5/7 casos, falla «0 duplicados fuera del baseline» y el baseline |
| Origen común | `git merge-base <rama> 9cb3fb077` × 4 | `9cb3fb077` en las 4 |
| Contenido intacto | `git show <rama>:<ruta-original> \| diff - <ruta-nueva>` × 6 | solo el número |

---

## 6. Migración 077 — Fix biometric_consents schema (Post-Fase D)

**Problema:** Migración 026 renombró columnas que el código usa (`consent_type`→`version`, `ip_address`→`ip`, etc.). Migración 037 añadió columnas con `IF NOT EXISTS` sobre el esquema renombrado, creando duplicados/conflictos. El código INSERTa en columnas que no existen o tienen nombres distintos → error 500 en consent grant.

**Solución (077):**
1. Renombra columnas de vuelta a lo que el código espera (`version`→`consent_type`, `ip`→`ip_address`, `user_agent`→`device_info`, `accepted_at`→`created_at`)
2. Asegura columnas faltantes (`granted`, `granted_at`, `revoked_at`, `purpose`, `version_terms`, `updated_at`)
3. Crea constraint UNIQUE `(user_id, consent_type, version_terms)` para ON CONFLICT
4. Elimina índice legacy `unique_active_consent` (usa columna `active` no usada por código)
5. Asegura tabla `biometric_access_log` y trigger `updated_at`

**Archivo:** `077_fix_biometric_consents_schema.sql`
**Rollback:** `rollback/077_fix_biometric_consents_schema.down.sql`

**Validación:** Script verifica columnas esperadas, constraint UNIQUE, tabla access_log.

---

## 7. Migración 081 — PQRSF: tiempos de respuesta y autor del mensaje (F1)

**Problema.** `007_soporte_y_pqrsf.sql` dejó el hilo en `ticket_mensajes` con un único dato
de tiempo (`fecha_envio`) y sin autor. Consecuencias medidas: el "tiempo de primera
respuesta" solo existía como `MIN(fecha_envio)` cruzado contra `usuarios.rol` (consulta
frágil, reescrita en cada métrica), no se registraba **cuándo** un ticket pasó a
`RESUELTO`/`CERRADO` (solo cuándo se tocó por última vez), y no había forma de distinguir
a un operador humano de un agente — justo la costura que hace falta para automatizar
respuestas.

**Solución (081).** Añade `tickets.primera_respuesta_en | resuelto_en | cerrado_en` y
`ticket_mensajes.autor_tipo (USUARIO|OPERADOR|AGENTE) | es_borrador`, con backfill del
histórico (el autor se deduce del rol del remitente; un `PRESTADOR` **no** es operador, y
los mensajes sin remitente resoluble se asumen `USUARIO` para no inflar las métricas).

**Archivo:** `081_pqrsf_sla_y_autor.sql`
**Rollback:** `rollback/081_pqrsf_sla_y_autor.down.sql` (dropea columnas; **no** toca los
mensajes: la conversación es intocable)

**Por qué 081 y no 077 — corrige la regla 1 de este documento.** La regla decía «hoy el
máximo es 076 ⇒ el siguiente libre es 077», y **ya era falsa**: `077` está ocupado y en el
directorio convive `080_business_documents_signed_by_text.sql`. El guard compara contra el
**directorio real** (`fs.readdirSync`), no contra este documento, así que el número se elige
mirando el disco y **las ramas en vuelo**, nunca la cifra escrita aquí. Un documento que
dice cuál es el "siguiente libre" caduca cada vez que alguien añade una migración; por eso
no se deja una cifra como fuente de verdad.

**Verificación — no lectura del SQL, sino ejecución contra Postgres 16 real** (contenedor
`glow-ci-pg`, base desechable `pqrsf_f1`), aplicando el esquema REAL (`007` + `045`) y datos
sintéticos con fechas fijas: columnas creadas; `autor_tipo` con 2 `OPERADOR` (los del rol
`ADMIN`) y 4 `USUARIO`; `primera_respuesta_en` exacta y `NULL` donde nunca respondió un
operador; `resuelto_en`/`cerrado_en` solo donde corresponde; el `CHECK` **acepta `AGENTE` y
rechaza** cualquier otro valor; **re-aplicar la migración no cambia ningún dato** (hash
idéntico: el runner re-aplica lo que no esté registrado en `schema_migrations`); y el
rollback deja las columnas fuera con los 7 mensajes intactos.
