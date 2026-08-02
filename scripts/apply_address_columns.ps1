<#
.SYNOPSIS
  Aplica columnas de dirección estructurada (Bogotá) a la tabla bookings.
.DESCRIPTION
  Usa psql si está disponible; si no, hace fallback a Node.js (pg).
  Hace backup opcional con pg_dump. No requiere credenciales hardcodeadas:
  usa variables de entorno PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD.
.PARAMETER SkipBackendStart
  Si se especifica, no arranca el backend al finalizar.
.EXAMPLE
  $env:PGHOST='127.0.0.1'; $env:PGPORT='5432'; $env:PGDATABASE='beauty_db'
  $env:PGUSER='admin'; $env:PGPASSWORD='xxxx'
  .\scripts\apply_address_columns.ps1
#>

param(
    [switch]$SkipBackendStart
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$SqlFile   = Join-Path $RepoRoot "backend\sql\add_address_columns.sql"
$LogFile   = Join-Path $ScriptDir "apply_address_columns.log"
$VerifyLog = Join-Path $ScriptDir "verify_columns.log"
$BackupDir = Join-Path $ScriptDir "backups"
$BackendLog = Join-Path $ScriptDir "backend_start.log"

function Write-Log {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# --- Validaciones iniciales ---
if (-not (Test-Path $ScriptDir)) { New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null }
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
New-Item -ItemType File -Path $LogFile -Force | Out-Null

Write-Log "=== Inicio de ejecución ==="

if (-not (Test-Path $SqlFile)) {
    Write-Log "❌ ERROR: No se encontró el archivo SQL en $SqlFile"
    exit 1
}

$requiredEnv = @('PGHOST','PGPORT','PGDATABASE','PGUSER','PGPASSWORD')
$missing = $requiredEnv | Where-Object { -not (Test-Path "env:$_") }
if ($missing.Count -gt 0) {
    Write-Log "❌ ERROR: Faltan variables de entorno: $($missing -join ', ')"
    Write-Log "Ejemplo: `$env:PGPASSWORD='tu_password'"
    exit 1
}

$psqlExists = Get-Command psql -ErrorAction SilentlyContinue
$nodeExists = Get-Command node -ErrorAction SilentlyContinue

if (-not $nodeExists) {
    Write-Log "❌ ERROR: node no está en el PATH. Instálalo antes de continuar."
    exit 1
}

# --- Backup opcional con pg_dump ---
$pgDumpExists = Get-Command pg_dump -ErrorAction SilentlyContinue
if ($pgDumpExists) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $BackupDir "bookings_backup_$timestamp.sql"
    Write-Log "Creando backup de la tabla bookings en $backupFile ..."
    try {
        $env:PGPASSWORD = $env:PGPASSWORD
        & pg_dump -h $env:PGHOST -p $env:PGPORT -U $env:PGUSER -d $env:PGDATABASE `
            -t bookings -f $backupFile 2>> $LogFile
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Backup completado: $backupFile"
        } else {
            Write-Log "⚠️ pg_dump devolvió código $LASTEXITCODE. Revisa $LogFile. Continuando sin bloquear."
        }
    } catch {
        Write-Log "⚠️ Error al ejecutar pg_dump: $($_.Exception.Message). Continuando sin backup."
    }
} else {
    Write-Log "⚠️ pg_dump no encontrado en PATH. Se omite backup (no bloqueante)."
}

# --- Ejecución del ALTER TABLE ---
$applied = $false

if ($psqlExists) {
    Write-Log "psql encontrado. Ejecutando SQL vía psql..."
    try {
        $env:PGPASSWORD = $env:PGPASSWORD
        & psql -h $env:PGHOST -p $env:PGPORT -U $env:PGUSER -d $env:PGDATABASE `
            -v ON_ERROR_STOP=1 -f $SqlFile *>> $LogFile
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ SQL ejecutado correctamente vía psql."
            $applied = $true
        } else {
            Write-Log "❌ psql devolvió código de error $LASTEXITCODE. Ver $LogFile."
        }
    } catch {
        Write-Log "❌ Error ejecutando psql: $($_.Exception.Message)"
    }
} else {
    Write-Log "psql no encontrado en PATH. Usando fallback Node.js..."
}

if (-not $applied) {
    Write-Log "Ejecutando fallback: node scripts\apply_address_columns_node.js"
    $nodeScript = Join-Path $ScriptDir "apply_address_columns_node.js"
    try {
        & node $nodeScript *>> $LogFile
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Fallback Node.js ejecutado correctamente."
            $applied = $true
        } else {
            Write-Log "❌ Fallback Node.js devolvió código $LASTEXITCODE. Ver $LogFile."
            exit 1
        }
    } catch {
        Write-Log "❌ Error ejecutando fallback Node.js: $($_.Exception.Message)"
        exit 1
    }
}

# --- Verificación de columnas en information_schema ---
Write-Log "Verificando columnas en information_schema..."
$verifyScript = @"
const { Pool } = require('pg');
const pool = new Pool({
  host: process.env.PGHOST, port: parseInt(process.env.PGPORT,10),
  database: process.env.PGDATABASE, user: process.env.PGUSER, password: process.env.PGPASSWORD,
});
(async () => {
  const cols = ['tipo_via','numero_via','numero_placa','numero_complemento','complemento_interior','barrio','localidad'];
  const res = await pool.query(
    "SELECT column_name, data_type FROM information_schema.columns WHERE table_name='bookings' AND column_name = ANY(\$1) ORDER BY column_name;",
    [cols]
  );
  res.rows.forEach(r => console.log(r.column_name + ' (' + r.data_type + ')'));
  const found = res.rows.map(r => r.column_name);
  const missing = cols.filter(c => !found.includes(c));
  if (missing.length > 0) { console.error('MISSING: ' + missing.join(',')); process.exit(1); }
  console.log('ALL_PRESENT');
  await pool.end();
})().catch(e => { console.error(e.message); process.exit(1); });
"@
$tmpVerify = Join-Path $ScriptDir "_tmp_verify.js"
Set-Content -Path $tmpVerify -Value $verifyScript -Encoding UTF8

try {
    $verifyOutput = & node $tmpVerify 2>&1
    $verifyOutput | Out-File -FilePath $VerifyLog -Encoding UTF8
    Write-Log "Resultado de verificación guardado en $VerifyLog"
    if ($verifyOutput -match "ALL_PRESENT") {
        Write-Log "✅ Verificación exitosa: todas las columnas presentes."
    } else {
        Write-Log "❌ Verificación falló. Ver $VerifyLog para detalles."
        Remove-Item $tmpVerify -Force -ErrorAction SilentlyContinue
        exit 1
    }
} catch {
    Write-Log "❌ Error en verificación: $($_.Exception.Message)"
    Remove-Item $tmpVerify -Force -ErrorAction SilentlyContinue
    exit 1
} finally {
    Remove-Item $tmpVerify -Force -ErrorAction SilentlyContinue
}

# --- Arranque opcional del backend ---
if (-not $SkipBackendStart) {
    Write-Log "Arrancando backend (node backend\index.js)..."
    Write-Log "Logs del backend se escriben en $BackendLog"
    Push-Location (Join-Path $RepoRoot "backend")
    try {
        & node index.js *>> $BackendLog
    } finally {
        Pop-Location
    }
} else {
    Write-Log "Flag -SkipBackendStart activo: no se arranca el backend."
}

Write-Log "=== Fin de ejecución ==="
