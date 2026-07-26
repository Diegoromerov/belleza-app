# scripts/db_backup.ps1
# Script de Respaldos Automáticos para PostgreSQL (GlowApp)

param (
    [string]$DbHost = $env:DB_HOST,
    [string]$DbPort = $env:DB_PORT,
    [string]$DbName = $env:DB_NAME,
    [string]$DbUser = $env:DB_USER,
    [string]$BackupDir = "C:\beauty-app\backups",
    [int]$RetentionDays = 30
)

if (-not $DbHost) { $DbHost = "localhost" }
if (-not $DbPort) { $DbPort = "5432" }
if (-not $DbName) { $DbName = "beauty_db" }
if (-not $DbUser) { $DbUser = "postgres" }

# Asegurar carpeta de respaldos
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BackupDir "glowapp_${DbName}_${Timestamp}.sql"
$GzipFile = "${BackupFile}.gz"

Write-Host "📦 Iniciando respaldo de PostgreSQL [$DbName] en $DbHost:$DbPort..." -ForegroundColor Cyan

try {
    # Ejecutar pg_dump
    $env:PGPASSWORD = $env:DB_PASSWORD
    & pg_dump -h $DbHost -p $DbPort -U $DbUser -d $DbName -F p -f $BackupFile

    if (Test-Path $BackupFile) {
        Write-Host "✅ Dump generado: $BackupFile ($( [math]::round((Get-Item $BackupFile).Length / 1MB, 2) ) MB)" -ForegroundColor Green
        
        # Limpieza de respaldos antiguos (> RetentionDays)
        $LimitDate = (Get-Date).AddDays(-$RetentionDays)
        Get-ChildItem -Path $BackupDir -Filter "glowapp_*.sql*" | Where-Object { $_.LastWriteTime -lt $LimitDate } | Remove-Item -Force
        Write-Host "🧹 Limpieza completada (rotación a $RetentionDays días)." -ForegroundColor Yellow
    } else {
        Write-Host "⚠️ Warning: El archivo de respaldo no fue creado. Verifica que pg_dump esté en el PATH." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error ejecutando respaldo: $_" -ForegroundColor Red
}
