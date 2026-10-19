# GLOW APP ADMIN WEB - Start Script
# Ejecuta en PowerShell como administrador

Write-Host "=== GLOW APP ADMIN WEB - Iniciando servicios ===" -ForegroundColor Cyan

# 1. Verificar Docker (PostgreSQL + Redis)
Write-Host "`n[1/4] Verificando contenedores Docker..." -ForegroundColor Yellow
docker start beauty-postgres beauty-redis 2>$null
Start-Sleep 3
docker ps --filter "name=beauty" --format "table {{.Names}}\t{{.Status}}"

# 2. Backend (puerto 3000)
Write-Host "`n[2/4] Iniciando Backend en puerto 3000..." -ForegroundColor Yellow
$backendDir = "C:\glowadmin-work\backend"
if (-not (Test-Path "$backendDir\.env")) {
    Copy-Item "$backendDir\.env.example" "$backendDir\.env"
    (Get-Content "$backendDir\.env") -replace 'usa_una_clave_local_segura', 'postgres' | Set-Content "$backendDir\.env"
    (Get-Content "$backendDir\.env") -replace 'usa_una_clave_de_al_menos_32_caracteres', 'glowapp_jwt_secret_key_32_chars_minimum' | Set-Content "$backendDir\.env"
    (Get-Content "$backendDir\.env") -replace 'DB_PORT=5432', 'DB_PORT=5435' | Set-Content "$backendDir\.env"
    (Get-Content "$backendDir\.env") -replace 'DB_USER=beauty_app_user', 'DB_USER=postgres' | Set-Content "$backendDir\.env"
    (Get-Content "$backendDir\.env") -replace 'DB_NAME=beauty_db', 'DB_NAME=railway' | Set-Content "$backendDir\.env"
}

# Matar proceso previo en 3000
$pid3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
if ($pid3000) { Stop-Process -Id $pid3000 -Force }

# Iniciar backend en background
$env:TEST_RATE_LIMIT = "true"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendDir'; node index.js" -WindowStyle Hidden

Write-Host "    Esperando a que el backend esté listo..." -ForegroundColor Gray
Start-Sleep 5

# Verificar backend
try {
    $resp = Invoke-RestMethod -Uri "http://localhost:3000/api/admin/auth/login" -Method POST -ContentType "application/json" -Body '{"email":"admin@demo.com","password": "***"}' -ErrorAction Stop
    Write-Host "    ✅ Backend respondiendo: $($resp.success)" -ForegroundColor Green
} catch {
    Write-Host "    ❌ Backend no responde: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Dashboard (puerto 3001)
Write-Host "`n[3/4] Iniciando Dashboard en puerto 3001..." -ForegroundColor Yellow
$dashboardDir = "C:\glowadmin-work\admin-dashboard"
if (-not (Test-Path "$dashboardDir\.env")) {
    Copy-Item "$dashboardDir\.env.example" "$dashboardDir\.env"
    (Get-Content "$dashboardDir\.env") -replace 'replace-with-the-same-local-backend-jwt-secret', 'glowapp_jwt_secret_key_32_chars_minimum' | Set-Content "$dashboardDir\.env"
}

# Matar proceso previo en 3001
$pid3001 = Get-NetTCPConnection -LocalPort 3001 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
if ($pid3001) { Stop-Process -Id $pid3001 -Force }

# Iniciar dashboard en background
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$dashboardDir'; npm run dev" -WindowStyle Hidden

Write-Host "    Esperando a que Next.js compile..." -ForegroundColor Gray
Start-Sleep 15

# Verificar dashboard
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:3001" -Method GET -ErrorAction Stop
    if ($resp.Content -match "login") {
        Write-Host "    ✅ Dashboard respondiendo: /login" -ForegroundColor Green
    }
} catch {
    Write-Host "    ❌ Dashboard no responde: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Resumen final
Write-Host "`n=== ACCESO WEB ===" -ForegroundColor Cyan
Write-Host "URL: http://localhost:3001/login" -ForegroundColor Green
Write-Host "Email: admin@demo.com" -ForegroundColor Gray
Write-Host "Password: <configurar_en_.env_local>" -ForegroundColor Gray
Write-Host "`n=== RUTAS ADMIN DISPONIBLES ===" -ForegroundColor Cyan
Write-Host "  http://localhost:3001/admin/business   - Cumplimiento Business" -ForegroundColor Gray
Write-Host "  http://localhost:3001/admin/precios    - Gestión de Precios" -ForegroundColor Gray
Write-Host "  http://localhost:3001/admin/academia   - Academia Glow" -ForegroundColor Gray
Write-Host "  http://localhost:3001/admin/vto        - VTO" -ForegroundColor Gray
Write-Host "`n=== LOGS ===" -ForegroundColor Cyan
Write-Host "Backend:  Ventana PowerShell oculta (node index.js)" -ForegroundColor Gray
Write-Host "Dashboard: Ventana PowerShell oculta (npm run dev)" -ForegroundColor Gray
Write-Host "`nPara ver logs: Abre las ventanas PowerShell minimizadas en la barra de tareas." -ForegroundColor Yellow
Write-Host "Para detener: Cierra las ventanas PowerShell o ejecuta 'taskkill /F /IM node.exe'" -ForegroundColor Yellow