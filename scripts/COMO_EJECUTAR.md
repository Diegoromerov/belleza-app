# Guía de Ejecución — Migración de Columnas de Dirección

> Aplica las columnas estructuradas de dirección Bogotá a la tabla `bookings`.

## Archivos involucrados

| Archivo | Propósito |
|---|---|
| `backend/sql/add_address_columns.sql` | Migración SQL idempotente |
| `scripts/apply_address_columns.ps1` | Orquestador principal (Windows/PowerShell) |
| `scripts/apply_address_columns_node.js` | Fallback Node.js si `psql` no está disponible |

---

## Paso a paso

### 1. Ubícate en la raíz del repositorio

```powershell
cd "C:\beauty-app"
```

### 2. Define las variables de entorno de conexión

> [!CAUTION]
> **NUNCA** guardes credenciales en archivos ni las commitees al repositorio.

```powershell
$env:PGHOST     = "127.0.0.1"   # o el host de Railway/Supabase para prod
$env:PGPORT     = "5432"
$env:PGDATABASE = "beauty_db"
$env:PGUSER     = "admin"

# Opción segura — te pide la contraseña interactivamente, sin exponerla:
$env:PGPASSWORD = Read-Host -AsSecureString "Password" | ConvertFrom-SecureString -AsPlainText

# Opción directa (solo en sesión local, nunca en scripts commiteados):
# $env:PGPASSWORD = "tu_password"
```

### 3. Instala la dependencia Node si falta

```powershell
cd backend
npm install pg
cd ..
```

### 4. Ejecuta el script completo

```powershell
# Aplica columnas + verifica + arranca el backend automáticamente
.\scripts\apply_address_columns.ps1

# Si NO quieres que arranque el backend al finalizar:
.\scripts\apply_address_columns.ps1 -SkipBackendStart
```

Los logs se guardan en:
- `scripts/apply_address_columns.log` — ejecución completa
- `scripts/verify_columns.log` — resultado de verificación
- `scripts/backend_start.log` — logs del backend (si arrancó)

---

## Alternativas manuales

### Aplicar con `psql` directamente

```powershell
psql -h $env:PGHOST -p $env:PGPORT -U $env:PGUSER -d $env:PGDATABASE `
     -f backend\sql\add_address_columns.sql
```

### Aplicar con Node.js directamente

```powershell
node scripts\apply_address_columns_node.js
```

### Verificar columnas manualmente

```powershell
psql -h $env:PGHOST -p $env:PGPORT -U $env:PGUSER -d $env:PGDATABASE -c "
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'bookings'
  AND column_name IN (
    'tipo_via', 'numero_via', 'numero_placa',
    'numero_complemento', 'complemento_interior',
    'barrio', 'localidad'
  )
ORDER BY column_name;
"
```

Resultado esperado (7 filas):

```
    column_name      | data_type
---------------------+-----------
 barrio              | text
 complemento_interior| text
 localidad           | text
 numero_complemento  | text
 numero_placa        | text
 numero_via          | text
 tipo_via            | text
(7 rows)
```

### Reiniciar el backend manualmente

```powershell
cd backend
node index.js
```

---

## Para entornos en la nube (Railway / Supabase / Neon)

Activa SSL y usa el host remoto:

```powershell
$env:PGHOST     = "tu-host.railway.app"  # o db.xxx.supabase.co
$env:PGPORT     = "5432"
$env:PGDATABASE = "railway"              # o postgres
$env:PGUSER     = "postgres"
$env:PGPASSWORD = "tu_password_prod"
$env:PGSSL      = "true"                 # habilita SSL en el fallback Node.js

.\scripts\apply_address_columns.ps1 -SkipBackendStart
```

> [!WARNING]
> Aplica siempre primero en **desarrollo/staging** y verifica antes de correr en producción.
