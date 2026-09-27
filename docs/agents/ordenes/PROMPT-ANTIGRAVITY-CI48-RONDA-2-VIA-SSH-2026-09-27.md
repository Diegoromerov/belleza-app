# Orden para Antigravity — CI-48, ronda 2: cerrar la puerta por la vía que SÍ existe

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Autorización:** el Dueño autorizó esta intervención sobre datos de producción (2026-09-27). Esta orden es el vehículo.
**Punto de partida:** en la ronda 1 declaraste correctamente «no pude acceder a la base de producción». La vía que probaste no es la única, y existe una que **sí funciona desde tu terminal**: `railway ssh`. La puerta sigue abierta: mediste 6 cuentas entregando token.

---

## 1. Corrección de método que esta orden exige (primero)

1. **Prohibido `NODE_TLS_REJECT_UNAUTHORIZED=0` y `-SkipCertificateCheck`.** Los usaste dos veces contra producción. No hacen falta y no están autorizados: desactivar la verificación TLS convierte una sonda en un riesgo de intermediario. Si un request falla por TLS, **se reporta el fallo**, no se desactiva la verificación.
2. **Prohibido `--force`** (push o checkout), y **prohibido `git checkout -f`** sobre un banco de trabajo compartido.
3. **No hagas push a `main` ni mergees nada.** El merge de `fix/ci46-segunda-causa` es del Dueño, en la interfaz de GitHub.
4. La ronda anterior dejó claro el patrón: **un cambio no se declara por su razonamiento, se declara por su medición.**

## 2. Vía de acceso que tenés que usar

El CLI de Railway **soporta SSH no interactivo** (verificado por el Arquitecto: `railway ssh [OPCIONES] [COMANDO]` — *«Command to execute instead of starting an interactive shell»*).

```powershell
cd C:\beauty-app
Remove-Item Env:RAILWAY_TOKEN -ErrorAction SilentlyContinue   # la sesión guardada es la que vale; el token exportado da Unauthorized
railway status                                                 # confirmá que ves el proyecto/servicio enlazado
railway ssh -- echo ok                                          # prueba de que el canal SSH funciona
```
Si `railway ssh` responde **«No SSH keys found in your SSH agent or ~/.ssh/»** (es lo que pasó al Arquitecto al validar esta orden), faltan dos pasos y son la causa de que la ronda 1 no tuviera canal:

```powershell
ssh-keygen -t ed25519                 # aceptá la ruta por defecto y Enter DOS veces (passphrase vacía)
railway ssh keys                       # registrá la clave pública en la cuenta de Railway
railway ssh -- echo ok                 # repetí hasta que devuelva ok
```
Notas: la passphrase vacía es deliberada (el CLI no puede contestar un prompt en modo no interactivo); la clave queda en tu equipo, no en el repo — **no la versiones**. Si `railway ssh keys` pide confirmación interactiva, aceptala y documentalo en el informe.

## 3. La intervención (una sola escritura, reversible)

Ejecutala **dentro del contenedor, desde el directorio de la app** (ahí está `node_modules` con `pg`). Bloque escrito para PowerShell: comillas simples por fuera para que `$1` llegue intacto.

```powershell
railway ssh -- node -e 'const { Client } = require("pg");
const c = new Client({ connectionString: process.env.DATABASE_URL });
const seis = ["admin@beautyapp.com","provider@beautyapp.com","ana@cliente.com","miusuario@correo.com","maria@correo.com","carlos@correo.com"];
(async () => {
  await c.connect();
  const antes = await c.query("SELECT email, rol, is_active FROM usuarios WHERE email = ANY($1) ORDER BY email", [seis.concat(["admin_plataforma@glowapp.com"])]);
  console.log("ANTES:", JSON.stringify(antes.rows));
  const upd = await c.query("UPDATE usuarios SET is_active = false WHERE email = ANY($1)", [seis]);
  console.log("FILAS ACTUALIZADAS:", upd.rowCount);
  const desp = await c.query("SELECT email, rol, is_active FROM usuarios WHERE email = ANY($1) ORDER BY email", [seis.concat(["admin_plataforma@glowapp.com"])]);
  console.log("DESPUES:", JSON.stringify(desp.rows));
  await c.end();
})().catch(e => { console.error("ERROR:", e.message); process.exit(1); });'
```

Si el CLI destroza el pasaje de comillas, hacelo en dos tiempos: `railway ssh` (shell interactiva) y pegá el mismo bloque.

**Reglas de la escritura:**
- Sólo esos **6** emails. `admin_plataforma@glowapp.com` entra **sólo en los `SELECT`** (para mostrar que sigue activa), **nunca** en el `UPDATE`.
- **No se borra ninguna fila.** Se pone `is_active = false`. Reversible.
- Se esperan **6 filas** afectadas. Si el conteo no es 6, reportalo como anomalía y no sigas.
- **Nunca imprimas** `DATABASE_URL`, tokens ni hashes: sólo estados (`is_active`), conteos y códigos HTTP.

## 4. Verificación de cierre (la única que cuenta)

```powershell
$API = "https://belleza-app-production.up.railway.app/api"
foreach ($u in @("admin@beautyapp.com","provider@beautyapp.com","ana@cliente.com","miusuario@correo.com","maria@correo.com","carlos@correo.com")) {
  $body = @{ email = $u; password = "password123" } | ConvertTo-Json
  try {
    $res = Invoke-WebRequest -Uri "$API/auth/login" -Method POST -ContentType "application/json" -Body $body -ErrorAction Stop
    Write-Host "$u -> HTTP $($res.StatusCode)"
  } catch {
    Write-Host "$u -> HTTP $([int]$_.Exception.Response.StatusCode)"
  }
}
```

**Criterio:** ninguna de las 6 devuelve **200 con token**. Se espera 401, 403 o el error de cuenta desactivada.

**Trampa medida por el Arquitecto — un `429` NO es una puerta cerrada.** Tras varias pasadas seguidas, `POST /api/auth/login` responde **429** por límite de tasa del propio endpoint. Si te sale 429: **esperá unos minutos y reintentá**; si seguís sin poder medir, escribí «no pude medirlo por límite de tasa». Un 429 **nunca** se reporta como éxito.

Y confirmá que el admin real sigue sano: el login de `admin_plataforma@glowapp.com` con `password123` debe seguir dando **401** (no forma parte del cambio; es control).

## 5. Plan B — si el canal SSH no existe

Escribí literalmente: **«no hay canal a la base de producción desde mi terminal»** y entregá el SQL listo para el Dueño (consola de datos del servicio PostgreSQL en Railway), que es lo único que él necesita pegar:

```sql
SELECT email, rol, is_active FROM usuarios
WHERE email IN ('admin@beautyapp.com','provider@beautyapp.com','ana@cliente.com',
                'miusuario@correo.com','maria@correo.com','carlos@correo.com',
                'admin_plataforma@glowapp.com') ORDER BY email;

UPDATE usuarios SET is_active = false
WHERE email IN ('admin@beautyapp.com','provider@beautyapp.com','ana@cliente.com',
                'miusuario@correo.com','maria@correo.com','carlos@correo.com');

SELECT email, rol, is_active FROM usuarios
WHERE email IN ('admin@beautyapp.com','provider@beautyapp.com','ana@cliente.com',
                'miusuario@correo.com','maria@correo.com','carlos@correo.com',
                'admin_plataforma@glowapp.com') ORDER BY email;
```

## 6. Fuera de alcance

- **No toques `paymentRoutes.js`** (quitar el fallback por email es C-02 y necesita excepción escrita del Dueño; **no está dada**).
- **No cambies `backend/seed.sql`** (CI-49 va aparte).
- No rotes ni desactives otras cuentas, no toques `admin_plataforma@glowapp.com`.
- No mergees ni empujes a `main`.

## 7. Criterio de cierre

1. `SELECT` **antes** con las 7 filas y **después** con las 6 en `is_active = false` y el admin real **activo**.
2. **Conteo exacto de filas** del `UPDATE` (se esperan 6).
3. Los **códigos HTTP** de las 6 cuentas tras la intervención: **ninguna 200 con token** (y los 429 reportados como «no pude medirlo», no como éxito).
4. Control: `admin_plataforma@glowapp.com` → **401** con `password123`.
5. Si algo no se pudo medir, la frase «no pude medirlo». Sin excepciones.
