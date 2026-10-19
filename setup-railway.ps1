<# 
.SYNOPSIS
    GLOW APP ADMIN DASHBOARD - SETUP RAILWAY (PowerShell)
.DESCRIPTION
    Configura el admin-dashboard para deploy en Railway grateful-harmony
.EXAMPLE
    .\setup-railway.ps1
#>

param()

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  GLOW APP ADMIN DASHBOARD - SETUP RAILWAY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar git status
Write-Host "[1/6] Verificando estado git..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Cambios pendientes:" -ForegroundColor Gray
    git status --short
} else {
    Write-Host "Working tree limpio ✅" -ForegroundColor Green
}

# 2. Crear rama feature
Write-Host "[2/6] Creando rama feature/admin-dashboard-v1..." -ForegroundColor Yellow
$branch = "feature/admin-dashboard-v1"
if (git show-ref --verify --quiet "refs/heads/$branch") {
    Write-Host "Rama $branch ya existe, cambiando a ella..." -ForegroundColor Gray
    git checkout $branch
} else {
    git checkout -b $branch
    Write-Host "Rama creada ✅" -ForegroundColor Green
}

# 3. Commit cambios
Write-Host "[3/6] Commitando cambios..." -ForegroundColor Yellow
git add admin-dashboard/, railway.json, .github/workflows/deploy-admin-*.yml
if (-not (git diff --cached --quiet)) {
    git commit -m "feat(admin): add admin dashboard with business/precios/academia/vto routes

- Admin dashboard (Next.js 15) with protected routes
- Business compliance, Precios, Academia, VTO pages
- Sidebar navigation with mobile responsive
- BFF proxy with JWT HttpOnly cookies + auto-refresh
- Railway multi-service config (railway.json)
- GitHub Actions for preview/production deploy"
    Write-Host "Commit creado ✅" -ForegroundColor Green
} else {
    Write-Host "Nada nuevo para commit" -ForegroundColor Gray
}

# 4. Push a origin
Write-Host "[4/6] Pusheando a origin..." -ForegroundColor Yellow
git push -u origin $branch
Write-Host "Push completado ✅" -ForegroundColor Green

# 5. Verificar railway.json
Write-Host "[5/6] Verificando railway.json..." -ForegroundColor Yellow
if (Test-Path "railway.json") {
    Write-Host "railway.json existe ✅" -ForegroundColor Green
    Get-Content railway.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
} else {
    Write-Host "ERROR: railway.json no encontrado" -ForegroundColor Red
    exit 1
}

# 6. Instrucciones finales
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  ✅ SETUP COMPLETADO" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

Write-Host "PRÓXIMOS PASOS MANUALES EN RAILWAY DASHBOARD:" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. 🌐 Abre: https://railway.app/dashboard" -ForegroundColor White
Write-Host "   Proyecto: grateful-harmony" -ForegroundColor Gray
Write-Host ""

Write-Host "2. ➕ Añade servicio admin-dashboard:" -ForegroundColor White
Write-Host "   - New Service → GitHub Repo → Select repo" -ForegroundColor Gray
Write-Host "   - Root Directory: /admin-dashboard" -ForegroundColor Gray
Write-Host "   - O usa railway.json (auto-detecta)" -ForegroundColor Gray
Write-Host ""

Write-Host "3. ⚙️ Configura Variables de Entorno (servicio admin-dashboard):" -ForegroundColor White
Write-Host "   BACKEND_INTERNAL_URL=http://backend.railway.internal:3000" -ForegroundColor Gray
Write-Host "   JWT_SECRET=<tu_jwt_secret_de_al_menos_32_caracteres>" -ForegroundColor Gray
Write-Host "   NODE_ENV=production" -ForegroundColor Gray
Write-Host ""

Write-Host "4. 🔄 Habilita Preview Deployments:" -ForegroundColor White
Write-Host "   Project Settings → Preview Deployments → Enabled" -ForegroundColor Gray
Write-Host ""

Write-Host "5. 🔐 Añade secret en GitHub:" -ForegroundColor White
Write-Host "   Settings → Secrets → Actions → RAILWAY_TOKEN" -ForegroundColor Gray
Write-Host "   (Token desde Railway Account → Tokens)" -ForegroundColor Gray
Write-Host ""

Write-Host "6. 📝 Abre PR en GitHub:" -ForegroundColor White
Write-Host "   - Base: main ← Compare: feature/admin-dashboard-v1" -ForegroundColor Gray
Write-Host "   - Railway auto-crea preview deployment" -ForegroundColor Gray
Write-Host "   - URL preview aparece en comentarios del PR" -ForegroundColor Gray
Write-Host ""

Write-Host "7. ✅ Diego revisa preview → Merge → Auto-deploy a prod" -ForegroundColor White
Write-Host ""

Write-Host "ARCHIVOS CREADOS:" -ForegroundColor Yellow
Write-Host "  - railway.json (multi-service config)" -ForegroundColor Gray
Write-Host "  - .github/workflows/deploy-admin-preview.yml" -ForegroundColor Gray
Write-Host "  - .github/workflows/deploy-admin-prod.yml" -ForegroundColor Gray
Write-Host "  - admin-dashboard/RAILWAY_ENV.md" -ForegroundColor Gray
Write-Host "  - setup-railway.sh (bash version)" -ForegroundColor Gray
Write-Host "  - setup-railway.ps1 (this file)" -ForegroundColor Gray
Write-Host ""

Write-Host "¡Listo para deploy! 🎉" -ForegroundColor Green