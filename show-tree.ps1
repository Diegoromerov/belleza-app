<#
.SYNOPSIS
    Muestra, con estilo tipo árbol, la estructura de carpetas y archivos del proyecto
    GlowApp (c:\beauty-app).

.DESCRIPTION
    Recursivamente recorre la carpeta raíz y dibuja una representación visual usando
    solo caracteres ASCII (`+`, `|`, `---` y espacios).  Se excluyen directorios pesados
    como .git y node_modules para que la salida sea rápida y legible.

.NOTES
    • Necesitas permisos de lectura sobre c:\beauty-app.
    • Si deseas incluir algún directorio que ahora está excluido, elimínalo del
      array $exclude.
#>

# -------------------------------------------------------------------------
# Ruta del proyecto
# -------------------------------------------------------------------------
$rootPath = 'C:\beauty-app'

# Patrones a excluir (puedes editarlos según necesites)
$exclude = @(
    '.git',
    'node_modules',
    'dist',
    'build',
    '.idea',
    '.vscode'
)

# -------------------------------------------------------------------------
# Función recursiva que genera la representación del árbol
# -------------------------------------------------------------------------
function Show-Tree {
    param(
        [string]$Path,      # Ruta que vamos a listar
        [string]$Prefix = '' # Prefijo visual acumulado (espacios y líneas)
    )

    # Obtener los ítems del directorio, ordenar: carpetas primero, luego archivos,
    # y excluir los que están en $exclude.
    $items = Get-ChildItem -LiteralPath $Path -Force |
        Where-Object { $exclude -notcontains $_.Name } |
        Sort-Object @{Expression = {$_.PSIsContainer}; Descending = $true}, Name

    $total   = $items.Count
    $counter = 0

    foreach ($item in $items) {
        $counter++
        $isLast = $counter -eq $total

        # Símbolos del árbol en ASCII
        $branch = if ($isLast) { '`--- ' } else { '+--- ' }

        Write-Host ("{0}{1}{2}" -f $Prefix, $branch, $item.Name)

        # Si es una carpeta, llamar recursivamente
        if ($item.PSIsContainer) {
            # Prefijo para la siguiente profundidad:
            #   • si es el último elemento, usamos espacios,
            #   • si no, mantenemos la barra vertical para continuar la rama.
            if ($isLast) {
                $newPrefix = $Prefix + '    '
            } else {
                $newPrefix = $Prefix + '|   '
            }
            Show-Tree -Path $item.FullName -Prefix $newPrefix
        }
    }
}

# -------------------------------------------------------------------------
# Ejecutar la visualización
# -------------------------------------------------------------------------
Write-Host "`nÁrbol de $rootPath`n"
Show-Tree -Path $rootPath