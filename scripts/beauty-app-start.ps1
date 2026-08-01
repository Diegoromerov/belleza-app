<#
.SYNOPSIS
    Beauty App - Script de Inicio y Verificación Manual
.DESCRIPTION
    Automatiza el Plan de Verificación Manual del Walkthrough 1:
    1. Iniciar Backend (Docker + Node.js)
    2. Iniciar Frontend Flutter (emulador o web)
    3. Verificar conectividad y estado de servicios
.NOTES
    - Ejecutar como Administrador en PowerShell
    - Requisitos: Docker Desktop, Node.js 18+, Flutter 3.44+, PostgreSQL con PostGIS
    - Credenciales de prueba:
        • Cliente: miusuario@correo.com / password123
        • Provider: provider@beautyapp.com / password123
#>

# ==========================================
# CONFIGURACIÓN INICIAL
# ==========================================
$ErrorActionPreference = 'Continue'
$projectRoot = "C:\beauty-app"
$backendPath = "$projectRoot\backend"
$frontendPath = "$projectRoot\frontend"
$postgresContainer = "beauty-postgres"
$redisContainer = "beauty-redis"
$backendPort = 3000
$frontendPort = 8081
$adminEmail = "admin"
$adminPassword = "admin123"
$dbName = "beauty_db"

# Credenciales de prueba
$testUsers = @{
    client = @{ email = "miusuario@correo.com"; password = "password123"; role = "client" }
    provider = @{ email = "provider@beautyapp.com"; password = "password123"; role = "provider" }
}

# ==========================================
# FUNCIONES DE OUTPUT CON COLORES
# ==========================================
function Write-Color {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan -BackgroundColor Black
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host "[$Step] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Gray
}

# ==========================================
# FUNCIONES AUXILIARES
# ==========================================

function Test-CommandAvailable {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
}

function Invoke-DockerCompose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    if (Test-CommandAvailable "docker-compose") {
        & docker-compose @Args
        return
    }

    if (Test-CommandAvailable "docker") {
        & docker compose @Args
        return
    }

    throw "Ni 'docker-compose' ni 'docker compose' están disponibles."
}

function Test-BackendRunning {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$backendPort/api/health" -TimeoutSec 5 -ErrorAction Stop
        return ($response.status -eq "OK")
    } catch {
        return $false
    }
}

function Test-PostgresRunning {
    try {
        docker exec $postgresContainer psql -U $adminEmail -d $dbName -c "SELECT 1;" | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-RedisRunning {
    try {
        docker exec $redisContainer redis-cli ping | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-FlutterAvailable {
    try {
        $null = flutter --version 2>&1
        return $true
    } catch {
        return $false
    }
}

function Test-DeviceAvailable {
    try {
        $devices = flutter devices 2>&1
        return ($devices -match "(chrome|android|ios|edge)")
    } catch {
        return $false
    }
}

function Run-Sql {
    param([string]$Query)
    try {
        return docker exec $postgresContainer psql -U $adminEmail -d $dbName -c $Query 2>$null
    } catch {
        return $null
    }
}

function Get-JwtToken {
    param([string]$Email, [string]$Password)
    try {
        $body = @{ email = $Email; password = $Password } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "http://localhost:$backendPort/api/auth/login" -Method Post -ContentType "application/json" -Body $body -TimeoutSec 10
        return $response.token
    } catch {
        Write-Warning "Error obteniendo token: $($_.Exception.Message)"
        return $null
    }
}

# ==========================================
# PASO 1: INICIAR BACKEND
# ==========================================
function Invoke-Start-Backend {
    Write-Section "PASO 1: INICIANDO BACKEND"
    
    # Verificar paths
    if (!(Test-Path $backendPath)) {
        Write-Error "Backend path no encontrado: $backendPath"
        return $false
    }
    Write-Success "Backend path verificado: $backendPath"
    
    # Verificar Docker
    if (!(Test-CommandAvailable "docker")) {
        Write-Error "Docker no está instalado o no está en PATH"
        Write-Info "Descarga Docker Desktop: https://www.docker.com/products/docker-desktop"
        return $false
    }
    Write-Success "Docker disponible"
    
    # Verificar docker-compose.yml
    if (!(Test-Path "$backendPath\docker-compose.yml")) {
        Write-Warning "docker-compose.yml no encontrado en $backendPath"
        Write-Info "Asegúrate de que el archivo existe con servicios postgres y redis"
    } else {
        Write-Success "docker-compose.yml encontrado"
    }
    
    # Levantar contenedores
    Write-Step "1.1" "Levantando PostgreSQL y Redis con Docker..."
    try {
        cd $backendPath
        Invoke-DockerCompose up -d 2>&1 | ForEach-Object { Write-Info $_ }
        Start-Sleep -Seconds 5
        
        # Verificar contenedores
        $containers = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String -Pattern "($postgresContainer|$redisContainer)"
        if ($containers) {
            Write-Success "Contenedores activos:"
            $containers | ForEach-Object { Write-Info "   • $_" }
        } else {
            Write-Warning "Contenedores no detectados como activos. Verifica con: docker ps"
        }
    } catch {
        Write-Error "Error al levantar contenedores: $($_.Exception.Message)"
        return $false
    }
    
    # Esperar a que PostgreSQL esté listo
    Write-Step "1.2" "Esperando a que PostgreSQL esté listo..."
    $maxAttempts = 30
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        if (Test-PostgresRunning) {
            Write-Success "PostgreSQL conectado y listo"
            break
        }
        $attempt++
        Write-Info "   Intento $attempt/$maxAttempts - Esperando PostgreSQL..."
        Start-Sleep -Seconds 2
    }
    if ($attempt -eq $maxAttempts) {
        Write-Error "PostgreSQL no respondió después de $maxAttempts intentos"
        return $false
    }
    
    # Verificar Redis (opcional)
    if (Test-RedisRunning) {
        Write-Success "Redis conectado y listo"
    } else {
        Write-Warning "Redis no disponible (puede ser opcional para tu configuración)"
    }
    
    # Ejecutar migraciones/seed si es necesario
    Write-Step "1.3" "Verificando migraciones y seed..."
    $seedFile = "$backendPath\seed.sql"
    if (Test-Path $seedFile) {
        Write-Info "Seed file encontrado: $seedFile"
        # Preguntar si desea ejecutar seed
        $runSeed = Read-Host "   ¿Ejecutar seed.sql para datos de prueba? (s/N)"
        if ($runSeed -eq "s" -or $runSeed -eq "S") {
            try {
                docker exec -i $postgresContainer psql -U $adminEmail -d $dbName -f /docker-entrypoint-initdb.d/seed.sql 2>$null
                Write-Success "Seed ejecutado exitosamente"
            } catch {
                Write-Warning "Error ejecutando seed: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Info "No se encontró seed.sql (puede que ya tengas datos)"
    }
    
    # Verificar Node.js y npm
    if (!(Test-CommandAvailable "node") -or !(Test-CommandAvailable "npm")) {
        Write-Error "Node.js o npm no están instalados"
        Write-Info "Descarga Node.js 18+: https://nodejs.org/"
        return $false
    }
    Write-Success "Node.js y npm disponibles"
    
    # Instalar dependencias del backend
    Write-Step "1.4" "Instalando dependencias del backend..."
    try {
        cd $backendPath
        npm install 2>&1 | ForEach-Object { if ($_ -match "(added|updated|removed|audited)") { Write-Info $_ } }
        Write-Success "Dependencias del backend instaladas"
    } catch {
        Write-Error "Error instalando dependencias: $($_.Exception.Message)"
        return $false
    }
    
    # Iniciar servidor de desarrollo
    Write-Step "1.5" "Iniciando servidor de desarrollo en puerto $backendPort..."
    Write-Info "💡 El servidor se ejecutará en segundo plano. Para detenerlo: Ctrl+C en esta terminal"
    
    # Iniciar npm run dev en background
    $backendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -WorkingDirectory $backendPath -PassThru -NoNewWindow
    
    # Esperar a que el backend responda
    Write-Step "1.6" "Esperando a que el backend responda..."
    $maxAttempts = 20
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        if (Test-BackendRunning) {
            Write-Success "Backend respondiendo en http://localhost:$backendPort"
            break
        }
        $attempt++
        Write-Info "   Intento $attempt/$maxAttempts - Esperando backend..."
        Start-Sleep -Seconds 3
    }
    if ($attempt -eq $maxAttempts) {
        Write-Error "Backend no respondió después de $maxAttempts intentos"
        Write-Info "Verifica los logs en la terminal del backend o ejecuta: curl http://localhost:$backendPort/api/health"
        return $false
    }
    
    # Health check detallado
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:$backendPort/api/health" -TimeoutSec 5
        Write-Success "Health check: $($health.status) - $($health.message)"
        if ($health.env) { Write-Info "   Entorno: $($health.env)" }
    } catch {
        Write-Warning "No se pudo obtener health check detallado"
    }
    
    Write-Success "✅ Backend iniciado exitosamente"
    return $true
}

# ==========================================
# PASO 2: INICIAR FLUTTER APP
# ==========================================
function Invoke-Start-Frontend {
    param([ValidateSet("web", "chrome", "android", "ios", "edge")][string]$Target = "web")
    
    Write-Section "PASO 2: INICIANDO FRONTEND FLUTTER"
    
    # Verificar paths
    if (!(Test-Path $frontendPath)) {
        Write-Error "Frontend path no encontrado: $frontendPath"
        return $false
    }
    Write-Success "Frontend path verificado: $frontendPath"
    
    # Verificar Flutter
    if (!(Test-FlutterAvailable)) {
        Write-Error "Flutter no está instalado o no está en PATH"
        Write-Info "Instala Flutter: https://docs.flutter.dev/get-started/install"
        return $false
    }
    Write-Success "Flutter disponible"
    
    # Doctor check rápido
    Write-Step "2.1" "Ejecutando flutter doctor (resumen)..."
    try {
        $doctor = flutter doctor -v 2>&1 | Select-String -Pattern "(\[✓\]|\[!\])" | Select-Object -First 10
        $doctor | ForEach-Object { Write-Info "   $_" }
    } catch {
        Write-Warning "No se pudo ejecutar flutter doctor"
    }
    
    # Obtener dependencias
    Write-Step "2.2" "Ejecutando flutter pub get..."
    try {
        cd $frontendPath
        flutter pub get 2>&1 | ForEach-Object { if ($_ -match "(Resolving|Downloading|Got)") { Write-Info $_ } }
        Write-Success "Dependencias de Flutter actualizadas"
    } catch {
        Write-Error "Error ejecutando flutter pub get: $($_.Exception.Message)"
        return $false
    }
    
    # Analizar código (opcional pero recomendado)
    Write-Step "2.3" "Ejecutando flutter analyze (verificación de código)..."
    try {
        $analyze = flutter analyze 2>&1
        if ($analyze -match "No issues found") {
            Write-Success "flutter analyze: No issues found! ✅"
        } elseif ($analyze -match "info|warning") {
            Write-Warning "flutter analyze: Hay warnings/info (no bloqueantes)"
            $analyze | Select-String -Pattern "(info|warning)" | Select-Object -First 5 | ForEach-Object { Write-Info "   $_" }
        } else {
            Write-Error "flutter analyze: Hay errores de compilación"
            $analyze | Select-String -Pattern "error" | Select-Object -First 5 | ForEach-Object { Write-Error "   $_" }
            return $false
        }
    } catch {
        Write-Warning "No se pudo ejecutar flutter analyze"
    }
    
    # Verificar dispositivo/emulador disponible
    Write-Step "2.4" "Verificando dispositivo disponible para '$Target'..."
    $deviceOk = $false
    
    switch ($Target) {
        "web" {
            # Web server no requiere dispositivo específico
            $deviceOk = $true
            Write-Success "Target web: No requiere dispositivo, se usará web-server"
        }
        "chrome" {
            if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") {
                $deviceOk = $true
                Write-Success "Chrome detectado en Windows"
            } else {
                Write-Warning "Chrome no detectado. ¿Está instalado en otra ruta?"
            }
        }
        "android" {
            if (flutter devices 2>&1 | Select-String -Pattern "android") {
                $deviceOk = $true
                Write-Success "Dispositivo Android detectado"
            } else {
                Write-Warning "No se detectó dispositivo Android. Conecta un dispositivo o inicia un emulador."
                Write-Info "   • Para emulador: Android Studio → Device Manager → Start"
                Write-Info "   • Para USB: Activa 'Depuración USB' en Opciones de desarrollador"
            }
        }
        "ios" {
            if ($IsMacOS -and (flutter devices 2>&1 | Select-String -Pattern "ios")) {
                $deviceOk = $true
                Write-Success "Dispositivo iOS detectado"
            } else {
                Write-Warning "iOS solo disponible en macOS. Usa web o Android en Windows."
            }
        }
        "edge" {
            if (Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe") {
                $deviceOk = $true
                Write-Success "Microsoft Edge detectado"
            } else {
                Write-Warning "Edge no detectado"
            }
        }
    }
    
    if (-not $deviceOk -and $Target -ne "web") {
        Write-Warning "No se detectó dispositivo para '$Target'. ¿Deseas cambiar a 'web'?"
        $change = Read-Host "   Cambiar a web (s/N)"
        if ($change -eq "s" -or $change -eq "S") {
            $Target = "web"
            Write-Info "Cambiando target a: web"
        } else {
            Write-Error "No se puede continuar sin dispositivo disponible"
            return $false
        }
    }
    
    # Iniciar la app
    Write-Step "2.5" "Iniciando Flutter app en target '$Target'..."
    
    # Preparar comando
    $flutterArgs = @("run")
    if ($Target -eq "web") {
        $flutterArgs += @("-d", "web-server", "--web-port", $frontendPort.ToString())
        Write-Info "💡 La app estará disponible en: http://localhost:$frontendPort"
    } elseif ($Target -eq "chrome") {
        $flutterArgs += @("-d", "chrome", "--web-port", $frontendPort.ToString())
        Write-Info "💡 Chrome se abrirá automáticamente en: http://localhost:$frontendPort"
    } else {
        $flutterArgs += @("-d", $Target)
    }
    
    # Agregar flag para web si aplica
    if ($Target -in @("web", "chrome", "edge")) {
        $flutterArgs += @("--web-browser-flag", "--disable-web-security") # Para CORS en desarrollo
    }
    
    Write-Info "🚀 Ejecutando: flutter $($flutterArgs -join ' ')"
    Write-Info "💡 Para detener la app: Presiona Ctrl+C en esta terminal"
    Write-Info "💡 Para hot reload: Presiona 'r' en la terminal de Flutter"
    Write-Info "💡 Para hot restart: Presiona 'R' en la terminal de Flutter"
    Write-Host ""
    
    # Ejecutar Flutter (bloqueante, el usuario debe Ctrl+C para salir)
    try {
        cd $frontendPath
        flutter @flutterArgs
    } catch {
        Write-Error "Error ejecutando Flutter: $($_.Exception.Message)"
        return $false
    }
    
    Write-Success "✅ Frontend iniciado exitosamente"
    return $true
}

# ==========================================
# PASO 3: VERIFICACIÓN FINAL Y PRUEBAS
# ==========================================
function Invoke-Final-Verification {
    Write-Section "PASO 3: VERIFICACIÓN FINAL Y PRUEBAS"
    
    # Verificar backend
    Write-Step "3.1" "Verificando backend..."
    if (Test-BackendRunning) {
        Write-Success "Backend: OK"
    } else {
        Write-Error "Backend: NO RESPONDE"
        return $false
    }
    
    # Verificar base de datos
    Write-Step "3.2" "Verificando base de datos..."
    if (Test-PostgresRunning) {
        Write-Success "PostgreSQL: OK"
        
        # Verificar usuarios de prueba
        $users = Run-Sql "SELECT email, role FROM users WHERE email IN ('miusuario@correo.com', 'provider@beautyapp.com');"
        if ($users -match "miusuario@correo.com.*client") {
            Write-Success "Usuario cliente de prueba: OK"
        } else {
            Write-Warning "Usuario cliente de prueba no encontrado o con rol incorrecto"
        }
        if ($users -match "provider@beautyapp.com.*provider") {
            Write-Success "Usuario provider de prueba: OK"
        } else {
            Write-Warning "Usuario provider de prueba no encontrado o con rol incorrecto"
        }
    } else {
        Write-Error "PostgreSQL: NO RESPONDE"
        return $false
    }
    
    # Probar login de cliente
    Write-Step "3.3" "Probando login de cliente..."
    $clientToken = Get-JwtToken $testUsers.client.email $testUsers.client.password
    if ($clientToken) {
        $payload = Decode-JwtPayload $clientToken
        if ($payload -and $payload.role -eq "client") {
            Write-Success "Login cliente: OK (rol: $($payload.role))"
        } else {
            Write-Warning "Login cliente: Token obtenido pero rol inesperado"
        }
    } else {
        Write-Error "Login cliente: FALLIDO"
    }
    
    # Probar login de provider
    Write-Step "3.4" "Probando login de provider..."
    $providerToken = Get-JwtToken $testUsers.provider.email $testUsers.provider.password
    if ($providerToken) {
        $payload = Decode-JwtPayload $providerToken
        if ($payload -and $payload.role -eq "provider") {
            Write-Success "Login provider: OK (rol: $($payload.role))"
        } else {
            Write-Warning "Login provider: Token obtenido pero rol inesperado"
        }
    } else {
        Write-Error "Login provider: FALLIDO"
    }
    
    # Probar endpoint de cliente (si token válido)
    if ($clientToken) {
        Write-Step "3.5" "Probando endpoint GET /api/bookings/client..."
        try {
            $headers = @{ Authorization = "Bearer $clientToken" }
            $bookings = Invoke-RestMethod -Uri "http://localhost:$backendPort/api/bookings/client" -Headers $headers -TimeoutSec 10
            Write-Success "Endpoint client bookings: OK ($($bookings.count) citas)"
        } catch {
            Write-Warning "Endpoint client bookings: No se pudo probar ($($_.Exception.Message))"
        }
    }
    
    # Probar endpoint de provider (si token válido)
    if ($providerToken) {
        Write-Step "3.6" "Probando endpoint GET /api/services/provider..."
        try {
            $headers = @{ Authorization = "Bearer $providerToken" }
            $services = Invoke-RestMethod -Uri "http://localhost:$backendPort/api/services/provider" -Headers $headers -TimeoutSec 10
            Write-Success "Endpoint provider services: OK ($($services.count) servicios)"
        } catch {
            Write-Warning "Endpoint provider services: No se pudo probar ($($_.Exception.Message))"
        }
    }
    
    Write-Success "✅ Verificación final completada"
    return $true
}

# ==========================================
# SCRIPT PRINCIPAL
# ==========================================
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("web", "chrome", "android", "ios", "edge")]
    [string]$Target = "web",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBackend,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFrontend,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipVerification
)

function Invoke-BeautyApp-Start {
    Write-Color "`n🚀 Beauty App - Script de Inicio y Verificación" -ForegroundColor Magenta
    Write-Color "   Ejecutando: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Color "   Target: $Target" -ForegroundColor Gray
    Write-Color "   SkipBackend: $SkipBackend | SkipFrontend: $SkipFrontend | SkipVerification: $SkipVerification`n" -ForegroundColor Gray
    
    # Mostrar credenciales de prueba
    Write-Section "CREDENCIALES DE PRUEBA"
    Write-Host "👤 CLIENTE:" -ForegroundColor Cyan
    Write-Host "   Email: $($testUsers.client.email)" -ForegroundColor White
    Write-Host "   Password: $($testUsers.client.password)" -ForegroundColor White
    Write-Host "   Rol: $($testUsers.client.role)" -ForegroundColor White
    Write-Host ""
    Write-Host "👨‍💼 PROVIDER:" -ForegroundColor Cyan
    Write-Host "   Email: $($testUsers.provider.email)" -ForegroundColor White
    Write-Host "   Password: $($testUsers.provider.password)" -ForegroundColor White
    Write-Host "   Rol: $($testUsers.provider.role)" -ForegroundColor White
    Write-Host "   Negocio: Salón Ana Beauty" -ForegroundColor White
    
    # Paso 1: Backend
    if (-not $SkipBackend) {
        $backendOk = Invoke-Start-Backend
        if (-not $backendOk) {
            Write-Error "❌ No se pudo iniciar el backend. Deteniendo script."
            return
        }
    } else {
        Write-Warning "⏭️  Saltando inicio de backend (usando --SkipBackend)"
        if (!(Test-BackendRunning)) {
            Write-Warning "⚠️  Backend no está respondiendo. Verifica que esté corriendo manualmente."
        }
    }
    
    # Paso 2: Frontend
    if (-not $SkipFrontend) {
        $frontendOk = Invoke-Start-Frontend -Target $Target
        if (-not $frontendOk) {
            Write-Error "❌ No se pudo iniciar el frontend. Deteniendo script."
            return
        }
    } else {
        Write-Warning "⏭️  Saltando inicio de frontend (usando --SkipFrontend)"
    }
    
    # Paso 3: Verificación
    if (-not $SkipVerification) {
        Invoke-Final-Verification
    } else {
        Write-Warning "⏭️  Saltando verificación final (usando --SkipVerification)"
    }
    
    # Resumen final
    Write-Section "RESUMEN FINAL"
    Write-Color "✅ Beauty App iniciado exitosamente." -ForegroundColor Green
    Write-Color "`n📋 Próximos pasos manuales:" -ForegroundColor Cyan
    Write-Color "   1. Abre la app en tu navegador o dispositivo" -ForegroundColor White
    Write-Color "   2. Inicia sesión con las credenciales de prueba mostradas arriba" -ForegroundColor White
    Write-Color "   3. Prueba los flujos de Walkthrough 1 y 2:" -ForegroundColor White
    Write-Color "      • Cliente: Ver prestadores → Reservar → Mis Citas → Cancelar/Calificar" -ForegroundColor White
    Write-Color "      • Provider: Panel → Gestionar citas → Mis Servicios → Crear/Editar/Desactivar" -ForegroundColor White
    Write-Color "`n🔧 Comandos útiles:" -ForegroundColor Cyan
    Write-Color "   • Detener app Flutter: Ctrl+C en la terminal de Flutter" -ForegroundColor White
    Write-Color "   • Detener backend: Ctrl+C en la terminal del backend" -ForegroundColor White
    Write-Color "   • Detener Docker: desde $backendPath ejecutar 'docker compose down' o 'docker-compose down'" -ForegroundColor White
    Write-Color "   • Ver logs backend: tail -f $backendPath\npm-debug.log (o revisar terminal)" -ForegroundColor White
    Write-Color "`n🎉 ¡Listo para probar Walkthroughs 1 y 2!`n" -ForegroundColor Magenta
}

# ==========================================
# EJECUCIÓN DEL SCRIPT
# ==========================================
try {
    Invoke-BeautyApp-Start
} catch {
    Write-Error "❌ Error crítico durante la ejecución: $($_.Exception.Message)"
    Write-Host "`n💡 Consejos de solución de problemas:" -ForegroundColor Yellow
    Write-Host "   • Ejecuta este script como Administrador" -ForegroundColor White
    Write-Host "   • Verifica que Docker Desktop esté corriendo" -ForegroundColor White
    Write-Host "   • Verifica que Node.js 18+ y Flutter 3.44+ estén en PATH" -ForegroundColor White
    Write-Host "   • Revisa que los puertos $backendPort y $frontendPort no estén ocupados" -ForegroundColor White
    Write-Host "   • Para debug: ejecuta cada paso manualmente siguiendo el Plan de Verificación Manual" -ForegroundColor White
}
