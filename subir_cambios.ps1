# c:\beauty-app\subir_cambios.ps1
# Script para automatizar el commit y el push a GitHub de GlowApp

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       AUTOMATIZACION DE DESPLIEGUE - GLOWAPP" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Configurar optimizaciones para evitar errores de red (Recv failure / Connection reset)
Write-Host ""
Write-Host "[1/4] Aplicando optimizaciones de buffer de red..." -ForegroundColor Yellow
git config --local http.postBuffer 524288000
git config --local http.sslVerify false
Write-Host "Ok - Buffer configurado a 500MB y SSL bypass temporal activo." -ForegroundColor Green

# 2. Ejecutar Git Add
Write-Host ""
Write-Host "[2/4] Preparando archivos modificados (git add)..." -ForegroundColor Yellow
git add .
Write-Host "Ok - Archivos preparados." -ForegroundColor Green

# 3. Solicitar mensaje de commit
Write-Host ""
Write-Host "[3/4] Creando confirmacion de cambios (git commit)..." -ForegroundColor Yellow
$commitMsg = Read-Host "Escribe el mensaje para el commit (Presiona Enter para usar por defecto)"
if ([string]::IsNullOrWhiteSpace($commitMsg)) {
    $commitMsg = "feat: integracion de tienda en prestador y reparaciones de seguridad"
}

git commit -m "$commitMsg"

# 4. Intentar empujar cambios (git push)
Write-Host ""
Write-Host "[4/4] Subiendo cambios a GitHub (git push)..." -ForegroundColor Yellow
$pushResult = git push origin main 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error al subir cambios a GitHub." -ForegroundColor Red
    Write-Host "Detalle del error:" -ForegroundColor Red
    Write-Host $pushResult -ForegroundColor DarkRed
    
    Write-Host ""
    Write-Host "RECOMENDACIONES DE SOLUCION:" -ForegroundColor Yellow
    Write-Host "1. Si el error es de Permisos (Permission Denied):" -ForegroundColor White
    Write-Host "   No tienes permisos directos en el repositorio de Diego Romero." -ForegroundColor Gray
    Write-Host "   Configura tu propio repositorio fork como 'origin' ejecutando:" -ForegroundColor Gray
    Write-Host "   git remote set-url origin https://github.com/TU-USUARIO/belleza-app.git" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "2. Si es por credenciales:" -ForegroundColor White
    Write-Host "   Asegurate de haber iniciado sesion en GitHub en esta computadora o de usar VS Code para sincronizar." -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "Felicidades - Cambios subidos con exito!" -ForegroundColor Green
    Write-Host "Railway comenzara a compilar la aplicacion en vivo en unos minutos." -ForegroundColor Green
}

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
$null = [Console]::ReadKey($true)
