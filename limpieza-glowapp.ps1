<#
.SYNOPSIS
    Limpieza integral de sistema y entorno de desarrollo (GlowApp / NURSIA / Oikos stack).
.DESCRIPTION
    Cubre: cachés de desarrollo (Gradle, Maven, npm, NuGet, Pub, pip, Docker, VSCode),
    navegadores (Chrome, Edge, Firefox), sistema (Temp, Prefetch, Logs, Error Reporting,
    Windows Update, Delivery Optimization, Recycle Bin, DNS cache), y descargas antiguas.
    Diseñado para limpieza REAL, no simulada: cierra procesos bloqueadores, verifica
    resultados post-borrado y usa robocopy /MIR como respaldo para carpetas con
    archivos bloqueados o rutas largas.
.PARAMETER Force
    Sin este switch, el script solo reporta (modo simulación). Con -Force, borra de verdad.
.PARAMETER DaysOld
    Antigüedad mínima (días) para considerar un archivo de Descargas como "viejo".
.PARAMETER SkipBrowsers
    Omite limpieza de navegadores (útil si no quieres que se cierren Chrome/Edge/Firefox).
.PARAMETER IncludeDocker
    Incluye poda de Docker (imágenes/contenedores/volúmenes no usados). Requiere Docker Desktop activo.
#>
param(
    [switch]$Force = $false,
    [int]$DaysOld = 30,
    [switch]$SkipBrowsers = $false,
    [switch]$IncludeDocker = $false
)

$ErrorActionPreference = "Stop"
$TotalSaved = 0.0
$FailCount = 0
$Report = @()
$UP = $env:USERPROFILE

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($Force -and !$IsAdmin) {
    Write-Host "ADVERTENCIA: No estás ejecutando como Administrador." -ForegroundColor Red
    Write-Host "Windows Update, Delivery Optimization, Error Reporting y Prefetch no se limpiarán del todo.`n" -ForegroundColor Yellow
}

function Get-MB {
    param($p)
    if (Test-Path $p) {
        $s = (Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
        if ($s) { return [math]::Round($s / 1MB, 2) }
    }
    return 0
}

function Force-EmptyDir {
    param($Path)
    if (!(Test-Path $Path)) { return }
    $empty = Join-Path $env:TEMP "empty_$(Get-Random)"
    New-Item -ItemType Directory -Path $empty -Force | Out-Null
    robocopy $empty $Path /MIR /NFL /NDL /NJH /NJS /NC /NS /NP /R:0 /W:0 | Out-Null
    Remove-Item $empty -Force -EA SilentlyContinue
}

function Wipe {
    param(
        [string]$Label,
        [string]$Path,
        [string[]]$KillProcesses = @(),
        [switch]$KeepRoot = $true
    )

    if (!(Test-Path $Path)) { return }

    $sz = Get-MB $Path
    if ($sz -le 0) { return }
    Write-Host "[$Label] $sz MB encontrados" -ForegroundColor Cyan

    if (!$Force) {
        $script:TotalSaved += $sz
        $script:Report += [pscustomobject]@{ Item = $Label; MB = $sz; Estado = "Simulado" }
        return
    }

    foreach ($proc in $KillProcesses) {
        Get-Process -Name $proc -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    }
    if ($KillProcesses.Count -gt 0) { Start-Sleep -Milliseconds 1000 }

    $itemsFailed = 0
    try {
        if ($KeepRoot) {
            $items = Get-ChildItem $Path -Force -EA SilentlyContinue
            foreach ($item in $items) {
                try { Remove-Item $item.FullName -Recurse -Force -EA Stop }
                catch { $itemsFailed++ }
            }
            $remaining = Get-MB $Path
            if ($remaining -gt 0) { Force-EmptyDir $Path }
        } else {
            try { Remove-Item $Path -Recurse -Force -EA Stop }
            catch {
                $itemsFailed++
                Force-EmptyDir $Path
                Remove-Item $Path -Force -EA SilentlyContinue
            }
        }
    } catch {
        $script:FailCount++
        Write-Host "   -> Error en ${Label}: $($_.Exception.Message)" -ForegroundColor Red
        $script:Report += [pscustomobject]@{ Item = $Label; MB = 0; Estado = "Error" }
        return
    }

    $final = Get-MB $Path
    $fr = [math]::Round($sz - $final, 2)
    $script:TotalSaved += $fr

    if ($final -gt 0) {
        $script:FailCount++
        Write-Host "   -> Liberado: $fr MB (quedaron $final MB bloqueados, $itemsFailed items con error)" -ForegroundColor Yellow
        $script:Report += [pscustomobject]@{ Item = $Label; MB = $fr; Estado = "Parcial ($final MB restantes)" }
    } else {
        Write-Host "   -> Liberado: $fr MB (100% limpio)" -ForegroundColor Green
        $script:Report += [pscustomobject]@{ Item = $Label; MB = $fr; Estado = "Completo" }
    }
}

function Wipe-OldFiles {
    param([string]$Label, [string]$Path, [int]$Days, [string[]]$ExcludeExt = @())

    if (!(Test-Path $Path)) { return }
    $cutoff = (Get-Date).AddDays(-$Days)
    $Files = Get-ChildItem $Path -File -Force -Recurse -EA SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff -and $ExcludeExt -notcontains $_.Extension }

    if (!$Files -or $Files.Count -eq 0) { return }

    $sz = [math]::Round((($Files | Measure-Object Length -Sum).Sum) / 1MB, 2)
    Write-Host "[$Label] $sz MB en $($Files.Count) archivos (>$Days días)" -ForegroundColor Cyan

    if (!$Force) {
        $script:TotalSaved += $sz
        $script:Report += [pscustomobject]@{ Item = $Label; MB = $sz; Estado = "Simulado" }
        return
    }

    $failed = 0
    foreach ($f in $Files) {
        try { Remove-Item $f.FullName -Force -EA Stop }
        catch { $failed++ }
    }
    $script:TotalSaved += $sz
    if ($failed -gt 0) {
        $script:FailCount++
        Write-Host "   -> Liberado: $sz MB ($failed archivos no se pudieron borrar)" -ForegroundColor Yellow
        $script:Report += [pscustomobject]@{ Item = $Label; MB = $sz; Estado = "Parcial ($failed fallidos)" }
    } else {
        Write-Host "   -> Liberado: $sz MB" -ForegroundColor Green
        $script:Report += [pscustomobject]@{ Item = $Label; MB = $sz; Estado = "Completo" }
    }
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "`n=====================================================" -ForegroundColor Magenta
Write-Host "   LIMPIEZA INTEGRAL DE SISTEMA Y DESARROLLO" -ForegroundColor Magenta
Write-Host "=====================================================" -ForegroundColor Magenta
if ($Force) { Write-Host "MODO: REAL (se borrará contenido)" -ForegroundColor Red }
else { Write-Host "MODO: SIMULACIÓN (usa -Force para borrar de verdad)" -ForegroundColor Yellow }
Write-Host "Administrador: $IsAdmin`n" -ForegroundColor DarkGray

Write-Host "--- Cachés de desarrollo ---" -ForegroundColor DarkCyan
Wipe "Gradle Cache"        "$UP\.gradle\caches"
Wipe "Gradle Wrapper"      "$UP\.gradle\wrapper\dists"
Wipe "Gradle Daemon Logs"  "$UP\.gradle\daemon"
Wipe "Maven Repo"          "$UP\.m2\repository"
Wipe "npm Cache"           "$UP\AppData\Local\npm-cache"
Wipe "Yarn Cache"          "$UP\AppData\Local\Yarn\Cache"
Wipe "NuGet Pkgs"          "$UP\.nuget\packages"
Wipe "Flutter Pub Cache"   "$UP\.pub-cache"
Wipe "Flutter/Dart Tool"   "$UP\AppData\Local\Pub\Cache"
Wipe "pip Cache"           "$UP\AppData\Local\pip\Cache"
Wipe "VSCode CachedData"   "$UP\AppData\Roaming\Code\CachedData"
Wipe "VSCode GPUCache"     "$UP\AppData\Roaming\Code\GPUCache"
Wipe "Android Build Cache" "$UP\.android\cache"
Wipe "Cocoapods Cache"     "$UP\.cocoapods\repos"

if ($IncludeDocker) {
    $dockerOk = Get-Command docker -EA SilentlyContinue
    if ($dockerOk) {
        Write-Host "[Docker Prune] Ejecutando poda de sistema..." -ForegroundColor Cyan
        if ($Force) {
            docker system prune -af --volumes 2>$null | Out-Null
            Write-Host "   -> Docker podado (imágenes, contenedores y volúmenes no usados)." -ForegroundColor Green
            $Report += [pscustomobject]@{ Item = "Docker Prune"; MB = "N/A"; Estado = "Completo" }
        } else {
            Write-Host "   -> (simulación) Usa -Force para ejecutar 'docker system prune -af --volumes'" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[Docker] No se encontró Docker CLI, se omite." -ForegroundColor DarkGray
    }
}

if (!$SkipBrowsers) {
    Write-Host "`n--- Navegadores ---" -ForegroundColor DarkCyan
    Wipe "Chrome Cache"        "$UP\AppData\Local\Google\Chrome\User Data\Default\Cache"            -KillProcesses @("chrome")
    Wipe "Chrome Code Cache"   "$UP\AppData\Local\Google\Chrome\User Data\Default\Code Cache"        -KillProcesses @("chrome")
    Wipe "Chrome GPUCache"     "$UP\AppData\Local\Google\Chrome\User Data\Default\GPUCache"          -KillProcesses @("chrome")
    Wipe "Edge Cache"          "$UP\AppData\Local\Microsoft\Edge\User Data\Default\Cache"            -KillProcesses @("msedge")
    Wipe "Edge Code Cache"     "$UP\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache"       -KillProcesses @("msedge")

    $ffProfiles = Get-ChildItem "$UP\AppData\Local\Mozilla\Firefox\Profiles" -Directory -EA SilentlyContinue
    if ($ffProfiles) { Get-Process -Name "firefox" -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue }
    foreach ($prof in $ffProfiles) {
        Wipe "Firefox Cache2 ($($prof.Name))" (Join-Path $prof.FullName "cache2")
    }
} else {
    Write-Host "`n--- Navegadores omitidos (-SkipBrowsers) ---" -ForegroundColor DarkGray
}

Write-Host "`n--- Sistema Windows ---" -ForegroundColor DarkCyan
Wipe "Windows Temp (usuario)" $env:TEMP
Wipe "Windows Temp (sistema)" "C:\Windows\Temp"
Wipe "Windows Error Reports"  "$UP\AppData\Local\Microsoft\Windows\WER"
Wipe "Recent Items"           "$UP\AppData\Roaming\Microsoft\Windows\Recent"
Wipe "IE/Edge Legacy Cache"   "$UP\AppData\Local\Microsoft\Windows\INetCache"
Wipe "CrashDumps"             "$UP\AppData\Local\CrashDumps"
Wipe "Diagnostic Logs (CBS)"  "C:\Windows\Logs\CBS"

if ($IsAdmin) {
    Wipe "Prefetch" "C:\Windows\Prefetch"
    Wipe "Delivery Optimization" "C:\Windows\SoftwareDistribution\DeliveryOptimization"

    $wuPath = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuPath) {
        $wsz = Get-MB $wuPath
        if ($wsz -gt 0) {
            Write-Host "[Windows Update Cache] $wsz MB encontrados" -ForegroundColor Cyan
            if ($Force) {
                Stop-Service -Name wuauserv -Force -EA SilentlyContinue
                Stop-Service -Name bits -Force -EA SilentlyContinue
                Force-EmptyDir $wuPath
                Start-Service -Name wuauserv -EA SilentlyContinue
                Start-Service -Name bits -EA SilentlyContinue
                $wns = Get-MB $wuPath
                $wfr = [math]::Round($wsz - $wns, 2)
                $TotalSaved += $wfr
                Write-Host "   -> Liberado: $wfr MB" -ForegroundColor Green
                $Report += [pscustomobject]@{ Item = "Windows Update Cache"; MB = $wfr; Estado = "Completo" }
            } else {
                $TotalSaved += $wsz
                $Report += [pscustomobject]@{ Item = "Windows Update Cache"; MB = $wsz; Estado = "Simulado" }
            }
        }
    }

    if ($Force) {
        try {
            Clear-RecycleBin -Force -EA SilentlyContinue
            Write-Host "[Papelera de Reciclaje] Vaciada (todas las unidades)." -ForegroundColor Green
            $Report += [pscustomobject]@{ Item = "Recycle Bin"; MB = "N/A"; Estado = "Completo" }
        } catch { }
    }
} else {
    Write-Host "[Prefetch / Windows Update / Delivery Optimization] Omitidos (requieren admin)" -ForegroundColor DarkGray

    if ($Force) {
        try {
            $shell = New-Object -ComObject Shell.Application
            $recycleBin = $shell.Namespace(0xA)
            $rbItems = $recycleBin.Items()
            $rbSize = [math]::Round((($rbItems | ForEach-Object { $_.Size }) | Measure-Object -Sum).Sum / 1MB, 2)
            if ($rbSize -gt 0) {
                Clear-RecycleBin -Force -EA SilentlyContinue
                Write-Host "[Papelera de Reciclaje] Vaciada: $rbSize MB" -ForegroundColor Green
                $TotalSaved += $rbSize
                $Report += [pscustomobject]@{ Item = "Recycle Bin"; MB = $rbSize; Estado = "Completo" }
            }
        } catch {
            Write-Host "   -> No se pudo vaciar la papelera automáticamente." -ForegroundColor Yellow
        }
    }
}

Write-Host "`n--- Descargas antiguas (>$DaysOld días) ---" -ForegroundColor DarkCyan
Wipe-OldFiles "Descargas Viejas" "$UP\Downloads" $DaysOld

if ($Force) {
    Write-Host "`n--- Caché DNS ---" -ForegroundColor DarkCyan
    try {
        ipconfig /flushdns | Out-Null
        Write-Host "[DNS Cache] Vaciada." -ForegroundColor Green
        $Report += [pscustomobject]@{ Item = "DNS Cache"; MB = "N/A"; Estado = "Completo" }
    } catch { }
}

$sw.Stop()
Write-Host "`n=====================================================" -ForegroundColor Magenta
Write-Host "   RESUMEN" -ForegroundColor Magenta
Write-Host "=====================================================" -ForegroundColor Magenta
$Report | Format-Table -AutoSize

Write-Host "TOTAL PROCESADO: $([math]::Round($TotalSaved,2)) MB ($([math]::Round($TotalSaved/1024,2)) GB)" -ForegroundColor White
Write-Host "Tiempo: $([math]::Round($sw.Elapsed.TotalSeconds,1))s" -ForegroundColor DarkGray

if ($FailCount -gt 0) {
    Write-Host "AVISO: $FailCount ubicaciones no se limpiaron al 100% (archivos bloqueados o sin permisos)." -ForegroundColor Yellow
}
if (!$Force) {
    Write-Host "`nEsto fue una SIMULACIÓN. Ejecuta con -Force (idealmente como Administrador) para limpiar de verdad:" -ForegroundColor Yellow
    Write-Host "   .\limpieza-glowapp.ps1 -Force" -ForegroundColor Yellow
    Write-Host "   .\limpieza-glowapp.ps1 -Force -IncludeDocker   (si usas Docker Desktop)" -ForegroundColor Yellow
}
