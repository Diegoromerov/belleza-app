# ============================================
# GLOWAPP - EXTRACTOR DE ENDPOINTS v3
# Prompt estricto JSON
# ============================================

$backendPath = "C:\beauty-app\backend\src"
$outputFile  = "C:\beauty-app\glowapp_endpoints.json"
$reportFile  = "C:\beauty-app\glowapp_reporte.txt"

Write-Host "Leyendo rutas del backend..." -ForegroundColor Cyan

$rutasPath = @(
    "$backendPath\routes",
    "$backendPath\modules\admin-glow"
)

$archivos = @()
foreach ($ruta in $rutasPath) {
    $archivos += Get-ChildItem -Path $ruta -Include "*.js" -Recurse -ErrorAction SilentlyContinue
}

Write-Host "Archivos encontrados: $($archivos.Count)" -ForegroundColor Yellow
$archivos | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }

$codigoCompleto = ""
foreach ($archivo in $archivos) {
    $contenido = Get-Content $archivo.FullName -Raw -ErrorAction SilentlyContinue
    if ($contenido) {
        $codigoCompleto += "`n`n### ARCHIVO: $($archivo.Name) ###`n$contenido"
    }
}

Write-Host ""
Write-Host "Enviando a llama3.2:3b..." -ForegroundColor Cyan
Write-Host "(puede tomar 2-4 minutos)" -ForegroundColor Gray

$prompt = @"
Responde UNICAMENTE con JSON puro.
Cero texto antes. Cero texto despues. Cero markdown. Cero explicaciones.
La respuesta debe empezar con { y terminar con }

Ejemplo de formato exacto esperado:
{"endpoints":[{"metodo":"POST","ruta":"/api/auth/login","parametros":{"body":["email","password"]},"descripcion":"Login usuario","flujo":"auth"},{"metodo":"GET","ruta":"/api/bookings","parametros":{},"descripcion":"Lista reservas","flujo":"reservas"}]}

Ahora extrae todos los endpoints de este codigo Node.js Express y devuelve el mismo formato JSON:

$codigoCompleto
"@

$respuesta = $prompt | ollama run llama3.2:3b
$respuesta | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "Reporte raw guardado: $reportFile" -ForegroundColor Yellow

# Intentar extraer JSON limpio
try {
    # Buscar primer { y ultimo }
    $jsonStart = $respuesta.IndexOf('{')
    $jsonEnd   = $respuesta.LastIndexOf('}')

    if ($jsonStart -eq -1 -or $jsonEnd -eq -1) {
        throw "No se encontro JSON en la respuesta"
    }

    $jsonLimpio = $respuesta.Substring($jsonStart, $jsonEnd - $jsonStart + 1)

    # Limpiar caracteres problematicos
    $jsonLimpio = $jsonLimpio -replace '[\x00-\x1F\x7F]', ' '
    $jsonLimpio = $jsonLimpio.Trim()

    $endpoints = ($jsonLimpio | ConvertFrom-Json).endpoints

    if (-not $endpoints -or $endpoints.Count -eq 0) {
        throw "No se encontraron endpoints en el JSON"
    }

    Write-Host "Endpoints extraidos: $($endpoints.Count)" -ForegroundColor Green

    # Construir coleccion Postman
    $postmanCollection = @{
        info = @{
            name        = "GlowApp API"
            description = "Generada automaticamente con llama3.2:3b"
            schema      = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
        }
        variable = @(
            @{ key = "base_url"; value = "http://localhost:3000"; type = "string" }
            @{ key = "token";    value = "";                      type = "string" }
        )
        item = @()
    }

    $flujos = $endpoints | Group-Object -Property flujo

    foreach ($flujo in $flujos) {
        $carpeta = @{
            name = $flujo.Name.ToUpper()
            item = @()
        }

        foreach ($ep in $flujo.Group) {
            $request = @{
                name    = $ep.descripcion
                request = @{
                    method = $ep.metodo
                    url    = @{
                        raw  = "{{base_url}}$($ep.ruta)"
                        host = @("{{base_url}}")
                        path = ($ep.ruta.Split('/') | Where-Object { $_ -ne "" })
                    }
                    header = @(
                        @{ key = "Content-Type";  value = "application/json" }
                        @{ key = "Authorization"; value = "Bearer {{token}}" }
                    )
                }
            }

            if ($ep.metodo -in @("POST","PUT","PATCH") -and $ep.parametros.body) {
                $bodyObj = @{}
                foreach ($param in $ep.parametros.body) { $bodyObj[$param] = "" }
                $request.request.body = @{
                    mode    = "raw"
                    raw     = ($bodyObj | ConvertTo-Json -Compress)
                    options = @{ raw = @{ language = "json" } }
                }
            }

            $carpeta.item += $request
        }

        $postmanCollection.item += $carpeta
    }

    $postmanCollection | ConvertTo-Json -Depth 15 |
        Out-File -FilePath $outputFile -Encoding UTF8

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host " COLECCION POSTMAN GENERADA" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host " Archivo : $outputFile" -ForegroundColor White
    Write-Host " Endpoints: $($endpoints.Count)" -ForegroundColor White
    Write-Host ""
    Write-Host " RESUMEN POR FLUJO:" -ForegroundColor Cyan
    foreach ($flujo in $flujos) {
        Write-Host "   $($flujo.Name.PadRight(15)) -> $($flujo.Count) endpoints" -ForegroundColor White
    }
    Write-Host ""
    Write-Host " Importa en Postman:" -ForegroundColor Yellow
    Write-Host " File -> Import -> $outputFile" -ForegroundColor Gray

} catch {
    Write-Host ""
    Write-Host "El modelo no genero JSON limpio." -ForegroundColor Red
    Write-Host "Pegame el contenido de: $reportFile" -ForegroundColor Yellow
    Write-Host "y lo construyo manualmente." -ForegroundColor Gray
}