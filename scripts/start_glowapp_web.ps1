<#
.SYNOPSIS
Starts a local HTTP server to serve GlowApp web build.

.DESCRIPTION
This script serves the contents of <repo_root>/frontend/build/web on a specified port (default 3000).
It checks if the build directory exists and if the port is available.
#>

param(
    [int]$Port = 3000,
    [string]$Root = (Resolve-Path -Path "$PSScriptRoot\.." -ErrorAction Stop)
)

$BuildPath = Join-Path $Root "frontend\build\web"

if (-not (Test-Path $BuildPath)) {
    Write-Error "Build directory not found: $BuildPath"
    Write-Host "Run 'flutter build web' first or use BuildAndServe script."
    exit 1
}

# Check if port is already in use
$used = netstat -ano | findstr ":$Port"
if ($used) {
    Write-Error "Port $Port is already in use. Another process may be serving GlowApp."
    Write-Host "Use a different port or stop the existing server."
    exit 1
}

Write-Host "GlowApp Web Server"
Write-Host "=================="
Write-Host "Serving: $BuildPath"
Write-Host "URL: http://localhost:$Port"
Write-Host ""
Write-Host "Press Ctrl+C to stop the server."

# Start Python HTTP server
python -m http.server $Port --directory $BuildPath