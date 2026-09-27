# Orden para Antigravity — CI-48: cerrar la puerta de administración (producción)

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Autorización:** el Dueño (Diego) autorizó explícitamente esta intervención sobre **datos de producción** el 2026-09-27, en la conversación de trabajo. Esta orden es el vehículo de esa autorización.
**Naturaleza de la operación:** desactivación de cuentas de seed. **No se borra ninguna fila.** Reversible.

---

## 1. Qué está pasando (medido hoy por el Arquitecto, en vivo)

Contra `https://belleza-app-production.up.railway.app`, con la credencial que está **publicada en `backend/seed.sql` de este repositorio público** (`admin@beautyapp.com` / `password123`, líneas 1-2):

| Comprobación | Resultado medido |
|---|---|
| `POST /api/auth/login` | **HTTP 200 · devuelve token** · la respuesta declara `rol: admin` |
| `GET /api/admin/dashboard` con ese token | **HTTP 200** · claves `financiero, disputas, wallets` |
| `GET /api/admin/disputes` con ese token | **HTTP 200** · claves `disputas, page, limit` |

La puerta la abre **el email**, no el rol (`backend/src/routes/paymentRoutes.js:49-55`, `requireAdmin`). La cuenta tiene `rol='PRESTADOR'` y aun así pasa. El login no pide OTP (`authController.js:185`). Con ese token se puede además resolver disputas (`PUT /admin/disputes/:id/resolve`), que **mueve dinero**.

No lo causó ningún cambio de hoy: la cuenta existe en producción desde el **2026-09-02**.

## 2. Objetivo de esta orden, y sólo éste

**Dejar sin efecto, en producción, las 6 cuentas que usan el hash público** del seed, para que la credencial publicada deje de abrir la puerta. La verificación final **no es leer el SQL: es que el login deje de entregar token**.

## 3. Cuentas a intervenir (las 6 con el hash público)

```
admin@beautyapp.com
provider@beautyapp.com
ana@cliente.com
miusuario@correo.com
maria@correo.com
carlos@correo.com
```

**NO tocar** ninguna otra cuenta. En particular **`admin_plataforma@glowapp.com` debe quedar ACTIVA**: es el administrador real de producción y no proviene del seed.

## 4. Procedimiento (elegí la vía que tengas disponible)

### Vía A — consola de datos de Railway (preferida, no requiere SSH)
1. Entrá al servicio de **PostgreSQL** del proyecto en Railway → pestaña de datos/consulta SQL.
2. **Paso 0 — evidencia ANTES** (pegá la salida completa en el informe):
```sql
SELECT email, rol, is_active FROM usuarios
WHERE email IN ('admin@beautyapp.com','provider@beautyapp.com','ana@cliente.com',
                'miusuario@correo.com','maria@correo.com','carlos@correo.com')
ORDER BY email;
```
3. **Paso 1 — la intervención**:
```sql
UPDATE usuarios SET is_active = false
WHERE email IN ('admin@beautyapp.com','provider@beautyapp.com','ana@cliente.com',
                'miusuario@correo.com','maria@correo.com','carlos@correo.com');
```
   Anotá cuántas filas afectó. **Se esperan 6.**
4. **Paso 2 — evidencia DESPUÉS**: repetí el `SELECT` del Paso 0 y pegá la salida.

### Vía B — `railway ssh` al servicio (si la consola no está disponible)
1. `railway ssh` (el contenedor del backend tiene Node y el código).
2. Dentro, usá el propio cliente de la app con `DATABASE_URL` del entorno — **sin imprimir la cadena de conexión**. Ejecutalo **desde el directorio de la app** (donde está `node_modules`, para que resuelva `pg`). El bloque está escrito para que funcione igual en PowerShell (exterior) y en el shell del contenedor:

```powershell
node -e 'const { Client } = require("pg");
const c = new Client({ connectionString: process.env.DATABASE_URL });
const emails = ["admin@beautyapp.com","provider@beautyapp.com","ana@cliente.com","miusuario@correo.com","maria@correo.com","carlos@correo.com"];
(async () => {
  await c.connect();
  const antes = await c.query("SELECT email, rol, is_active FROM usuarios WHERE email = ANY($1) ORDER BY email", [emails]);
  console.log("ANTES:", JSON.stringify(antes.rows));
  const upd = await c.query("UPDATE usuarios SET is_active = false WHERE email = ANY($1)", [emails]);
  console.log("FILAS ACTUALIZADAS:", upd.rowCount);
  const desp = await c.query("SELECT email, rol, is_active FROM usuarios WHERE email = ANY($1) ORDER BY email", [emails]);
  console.log("DESPUES:", JSON.stringify(desp.rows));
  await c.end();
})().catch(e => { console.error("ERROR:", e.message); process.exit(1); });'
```

### Si no podés acceder a ninguna de las dos vías
Escribí **«no pude acceder a la base de producción»** y terminá ahí. **No inventes** resultados ni intentes rodeos (nada de exponer la base públicamente, nada de tocar `NODE_TLS_REJECT_UNAUTHORIZED`, nada de `--force`).

## 5. Verificación de cierre (obligatoria, y es la que cuenta)

Con la intervención hecha, la credencial publicada **ya no debe entregar token**. Corré esto y pegá **los códigos HTTP literales**:

```bash
API=https://belleza-app-production.up.railway.app/api
for u in admin@beautyapp.com provider@beautyapp.com; do
  code=$(curl -s -o /tmp/l.json -w '%{http_code}' -X POST "$API/auth/login" \
    -H 'Content-Type: application/json' -d "{\"email\":\"$u\",\"password\":\"password123\"}")
  echo "$u → HTTP $code · $(head -c 120 /tmp/l.json)"
done
```
**Éxito = un código distinto de 200 con token** (401/403, o el error de cuenta inactiva). Si sigue devolviendo 200 **con token**, la intervención no se aplicó: reportalo como fallo, no como éxito.
**Nunca imprimas el token.** No llames a ningún endpoint que modifique estado (ni `resolve`, ni reembolsos): esta orden es sólo de desactivación.

## 6. Fuera de alcance (no lo hagas en esta ronda)

- **No toques `paymentRoutes.js`.** Quitar el fallback por email es territorio **C-02** y requiere una excepción escrita del Dueño. Esa excepción **no** está dada en esta orden.
- **No cambies `backend/seed.sql`** (el cambio de hoy ya está en `main`; el uso de una contraseña conocida en dev es un tema aparte, registrado como CI-49).
- **No borres filas**, no cambies contraseñas de otras cuentas, no rotes `admin_plataforma@glowapp.com`.
- **No hagas push a `main`** ni mergees nada: el merge de `fix/ci46-segunda-causa` es del Dueño, en la interfaz de GitHub. Si necesitás registrar algo, va por rama + PR como siempre.
- No imprimas jamás tokens, hashes ni cadenas de conexión en el informe: sólo **estados** (`is_active`), **conteos** y **códigos HTTP**.

## 7. Criterio de cierre de esta ronda

1. `SELECT` antes y después de las 6 cuentas, con `is_active` visible en ambos.
2. Conteo de filas afectadas por el `UPDATE` (se esperan 6).
3. Los dos códigos HTTP del login posterior: **ninguno 200 con token**.
4. `admin_plataforma@glowapp.com` sigue **activa** (mostralo en el mismo `SELECT`).
5. Si algo no se pudo medir, la frase «no pude medirlo» en su lugar.
