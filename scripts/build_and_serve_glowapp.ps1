# ============================================================================
# GLOWAPP - BUILD + SERVE WEB
# ============================================================================
# Archivo:
#   C:\beauty-app\scripts\build_and_serve_glowapp.ps1
#
# Uso:
#   cd C:\beauty-app
#   powershell -ExecutionPolicy Bypass -File scripts\build_and_serve_glowapp.ps1
#
# Resultado:
#   http://localhost:3000
#
# Este script:
#   - valida la estructura del proyecto
#   - usa C:\flutter\bin\flutter.bat si existe
#   - ejecuta flutter pub get
#   - ejecuta flutter build web --release
#   - valida build\web
#   - libera SOLO un servidor Python anterior en 3000
#   - sirve build\web en 127.0.0.1:3000
# ============================================================================

$ErrorActionPreference = "Stop"

# ----------------------------------------------------------------------------
# CONFIGURACION
# ----------------------------------------------------------------------------

$ProjectRoot = "C:\beauty-app"
$FrontendDir = Join-Path $ProjectRoot "frontend"
$BuildDir = Join-Path $FrontendDir "build\web"
$Pubspec = Join-Path $FrontendDir "pubspec.yaml"

$FlutterBin = "C:\flutter\bin\flutter.bat"
$Port = 3000
$BindAddress = "127.0.0.1"

# ----------------------------------------------------------------------------
# ENCABEZADO
# ----------------------------------------------------------------------------

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " GLOWAPP WEB - BUILD + SERVE" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------------
# VALIDAR PROYECTO
# ----------------------------------------------------------------------------

Write-Host "[1/6] Validando proyecto..." -ForegroundColor Yellow

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    Write-Error "No existe el proyecto: $ProjectRoot"
    exit 1
}

if (-not (Test-Path -LiteralPath $FrontendDir -PathType Container)) {
    Write-Error "No existe el frontend: $FrontendDir"
    exit 1
}

if (-not (Test-Path -LiteralPath $Pubspec -PathType Leaf)) {
    Write-Error "No se encontró pubspec.yaml: $Pubspec"
    exit 1
}

Write-Host "  Proyecto : $ProjectRoot" -ForegroundColor Green
Write-Host "  Frontend : $FrontendDir" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------------------
# VALIDAR FLUTTER
# ----------------------------------------------------------------------------

Write-Host "[2/6] Validando Flutter..." -ForegroundColor Yellow

$FlutterExecutable = $null

if (Test-Path -LiteralPath $FlutterBin -PathType Leaf) {
    $FlutterExecutable = $FlutterBin
}
else {
    $FlutterCommand = Get-Command flutter -ErrorAction SilentlyContinue

    if ($null -ne $FlutterCommand) {
        $FlutterExecutable = $FlutterCommand.Source
    }
}

if ([string]::IsNullOrWhiteSpace($FlutterExecutable)) {
    Write-Error "Flutter no está disponible."
    Write-Error "No se encontró C:\flutter\bin\flutter.bat ni flutter en PATH."
    exit 1
}

Write-Host "  Flutter: $FlutterExecutable" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------------------
# VALIDAR PYTHON
# ----------------------------------------------------------------------------

Write-Host "[3/6] Validando Python..." -ForegroundColor Yellow

$PythonCommand = Get-Command python -ErrorAction SilentlyContinue

if ($null -eq $PythonCommand) {
    Write-Error "Python no está disponible en PATH."
    Write-Error "Se necesita para ejecutar python -m http.server."
    exit 1
}

$PythonExecutable = $PythonCommand.Source

Write-Host "  Python: $PythonExecutable" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------------------
# COMPROBAR PUERTO 3000
# ----------------------------------------------------------------------------

Write-Host "[4/6] Comprobando puerto $Port..." -ForegroundColor Yellow

$Connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue

if ($null -ne $Connections) {

    foreach ($Connection in @($Connections)) {

        $ExistingPid = $Connection.OwningProcess

        if ($ExistingPid -eq 0) {
            continue
        }

        $ExistingProcess = Get-Process -Id $ExistingPid -ErrorAction SilentlyContinue

        if ($null -eq $ExistingProcess) {
            continue
        }

        Write-Host ""
        Write-Host "Puerto $Port ocupado por:" -ForegroundColor Yellow
        Write-Host "  PID : $ExistingPid"
        Write-Host "  Name: $($ExistingProcess.ProcessName)"
        Write-Host ""

        if (
            $ExistingProcess.ProcessName -eq "python" -or
            $ExistingProcess.ProcessName -eq "python3"
        ) {

            Write-Host "Deteniendo servidor Python anterior..." -ForegroundColor Yellow

            Stop-Process -Id $ExistingPid -Force -ErrorAction SilentlyContinue

            Start-Sleep -Milliseconds 800
        }
        else {

            Write-Error "El puerto $Port está ocupado por '$($ExistingProcess.ProcessName)' (PID $ExistingPid). No se detendrá automáticamente."
            exit 1
        }
    }
}

# ----------------------------------------------------------------------------
# BUILD
# ----------------------------------------------------------------------------

Write-Host ""
Write-Host "[5/6] Construyendo GlowApp..." -ForegroundColor Yellow
Write-Host ""

Set-Location -LiteralPath $FrontendDir

Write-Host "----------------------------------------------" -ForegroundColor DarkGray
Write-Host " flutter pub get" -ForegroundColor Cyan
Write-Host "----------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

& $FlutterExecutable pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host " PUB GET FALLIDO" -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Código de salida: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "flutter pub get: OK" -ForegroundColor Green
Write-Host ""

Write-Host "----------------------------------------------" -ForegroundColor DarkGray
Write-Host " flutter build web --release" -ForegroundColor Cyan
Write-Host "----------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

& $FlutterExecutable build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host " BUILD FALLIDO" -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Código de salida: $LASTEXITCODE" -ForegroundColor Red
    Write-Host ""
    Write-Host "El servidor en puerto $Port NO será iniciado." -ForegroundColor Yellow
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "flutter build web: OK" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------------------
# VALIDAR BUILD
# ----------------------------------------------------------------------------

Write-Host "[6/6] Validando build generado..." -ForegroundColor Yellow

$IndexFile = Join-Path $BuildDir "index.html"
$MainJs = Join-Path $BuildDir "main.dart.js"

if (-not (Test-Path -LiteralPath $BuildDir -PathType Container)) {
    Write-Error "No existe el directorio generado: $BuildDir"
    exit 1
}

if (-not (Test-Path -LiteralPath $IndexFile -PathType Leaf)) {
    Write-Error "No se encontró index.html en: $BuildDir"
    exit 1
}

if (-not (Test-Path -LiteralPath $MainJs -PathType Leaf)) {
    Write-Error "No se encontró main.dart.js en: $BuildDir"
    exit 1
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " BUILD CORRECTO" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Build : $BuildDir" -ForegroundColor White
Write-Host "Index : OK" -ForegroundColor Green
Write-Host "JS    : OK" -ForegroundColor Green
Write-Host ""

# ----------------------------------------------------------------------------
# SERVIDOR ESTÁTICO
# ----------------------------------------------------------------------------

Write-Host "Iniciando servidor web estático..." -ForegroundColor Cyan
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " GLOWAPP DISPONIBLE" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host " URL: http://localhost:$Port" -ForegroundColor Cyan
Write-Host " Bind: $BindAddress" -ForegroundColor White
Write-Host " Dir : $BuildDir" -ForegroundColor White
Write-Host ""
Write-Host "Presiona Ctrl+C para detener el servidor." -ForegroundColor DarkGray
Write-Host ""
Write-Host "Este modo NO utiliza DDC." -ForegroundColor DarkGray
Write-Host "Este modo NO utiliza el puerto 8080." -ForegroundColor DarkGray
Write-Host ""

Set-Location -LiteralPath $BuildDir

# ----------------------------------------------------------------------------
# INICIAR PYTHON
# ----------------------------------------------------------------------------

& $PythonExecutable -m http.server $Port --bind $BindAddress

exit 0
