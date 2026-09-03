# start_glowapp.ps1
# Script to start GlowApp backend and frontend with process cleanup and health checks.
# Supports -Release flag to use flutter build + static server.

param(
    [switch]$Release
)

function Write-Log {
    param([string]$msg)
    Write-Host "[$(Get-Date -Format HH:mm:ss)] $msg"
}

function Kill-GlowAppProcesses {
    Write-Log "Buscando y terminando procesos huérfanos de GlowApp..."
    $projectPath = "C:\beauty-app"
    # Flutter/Dart processes
    Get-Process | Where-Object {
        $_.Path -and $_.Path.Contains($projectPath) -and
        ($_.ProcessName -in @("flutter","dart","dart_dev"))
    } | ForEach-Object {
        Write-Log "Terminando $($_.ProcessName) PID $($_.Id)"
        Stop-Process -Id $_.Id -Force
    }
    # Chrome instances used for Flutter debugging (look for remote-debugging-port)
    Get-Process | Where-Object {
        $_.ProcessName -eq "chrome" -and
        $_.CommandLine -match "--remote-debugging-port="
    } | ForEach-Object {
        Write-Log "Terminando Chrome de depuración PID $($_.Id)"
        Stop-Process -Id $_.Id -Force
    }
    # Node processes that are exactly the backend (index.js in backend folder)
    Get-Process | Where-Object {
        $_.ProcessName -eq "node" -and
        $_.Path -and $_.Path.Contains("beauty-app\backend") -and
        $_.CommandLine -like "*index.js*"
    } | ForEach-Object {
        # We'll let the health check decide whether to restart it; do NOT kill it here.
        # But if we want to ensure a clean start, we can kill and let script restart.
        Write-Log "Terminando instancia de backend Node PID $($_.Id) para reinicio limpio"
        Stop-Process -Id $_.Id -Force
    }
}

function Wait-ForPort {
    param(
        [int]$Port,
        [int]$TimeoutSeconds = 15,
        [string]$Description = "puerto"
    )
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        if (netstat -ano | findstr ":$Port" | findstr "LISTENING") {
            Write-Log "$Description ($Port) está listo."
            return $true
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Log "Timeout esperando $Description ($Port) después de $TimeoutSeconds segundos."
    return $false
}

function Start-Backend {
    Write-Log "Iniciando backend (npm run dev) en C:\beauty-app\backend..."
    $backendDir = "C:\beauty-app\backend"
    # Start npm run dev in a hidden window, capture the process
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c ""cd /d `"$backendDir`" && npm run dev"" "
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    # Wait a bit for it to start
    Start-Sleep -Seconds 2
    # Return the process object so we can keep it alive (script will keep reference)
    return $proc
}

function Start-FrontendDev {
    Write-Log "Iniciando Flutter Web en modo desarrollo..."
    $frontendDir = "C:\beauty-app\frontend"
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "flutter"
    $psi.Arguments = "run -d chrome --web-port 0 --web-browser-auto-launch false"
    $psi.WorkingDirectory = $frontendDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $false # we want to see Flutter output
    $proc = [System.Diagnostics.Process]::Start($psi)
    # Read output asynchronously to capture the URL
    $output = ""
    $url = $null
    $reader = $proc.StandardOutput
    while (-not $reader.EndOfStream) {
        $line = $reader.ReadLine()
        $output += $line + "`n"
        Write-Host $line
        if ($line -match 'Running on "http://127\.0\.0\.1:(\d+)"') {
            $url = "http://127.0.0.1:$($matches[1])"
            Write-Log "Flutter reportó URL: $url"
        }
    }
    $proc.WaitForExit()
    return @{ Process = $proc; Output = $output; Url = $url }
}

function Start-FrontendRelease {
    Write-Log "Generando build web de liberación..."
    $frontendDir = "C:\beauty-app\frontend"
    & flutter clean
    & flutter pub get
    & flutter build web --release
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Error al generar el build web."
        exit 1
    }
    Write-Log "Build web generado en build/web"
    # Serve with python http.server
    Write-Log "Iniciando servidor HTTP estático..."
    $port = 8080
    while (netstat -ano | findstr ":$port" | findstr "LISTENING") {
        $port++
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "python"
    $psi.Arguments = "-m http.server $port --directory build/web"
    $psi.WorkingDirectory = $frontendDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    # Wait for server to be ready
    if (-not (Wait-ForPort -Port $port -TimeoutSeconds 15 -Description "Servidor estático")) {
        Write-Log "El servidor estático no respondió a tiempo."
        exit 1
    }
    Write-Log "Servidor estático escuchando en puerto $port"
    return @{ Port = $port; Proc = $proc }
}

# Main
try {
    Write-Log "=== Inicio de secuencia de arranque de GlowApp ==="
    Kill-GlowAppProcesses

    # Backend
    $backendProc = Start-Backend
    if (-not (Wait-ForPort -Port 3000 -TimeoutSeconds 15 -Description "Backend")) {
        Write-Log "Fallo al iniciar el backend."
        exit 1
    }

    if ($Release) {
        $result = Start-FrontendRelease
        $url = "http://localhost:$($result.Port)"
        Write-Log "Aplicación disponible en $url"
        Start-Process "chrome.exe" $url
    } else {
        $result = Start-FrontendDev
        $url = $result.Url
        if (-not $url) {
            Write-Log "No se pudo obtener la URL de Flutter."
            exit 1
        }
        Write-Log "Aplicación disponible en $url"
        Start-Process "chrome.exe" $url
        # Keep the script alive while Flutter process runs
        Write-Log "El modo desarrollo está activo. Presiona Ctrl+C para detener."
        $result.Process.WaitForExit()
    }

    Write-Log "=== Arranque completado ==="
}
catch {
    Write-Log "Error inesperado: $($_.Exception.Message)"
    exit 1
}