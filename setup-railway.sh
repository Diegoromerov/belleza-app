#!/bin/bash
# ============================================
# GLOW APP ADMIN DASHBOARD - SETUP RAILWAY
# Ejecuta: bash setup-railway.sh
# ============================================

set -e

echo "🚀 Configurando Admin Dashboard para Railway grateful-harmony"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Verificar git status
echo -e "${YELLOW}[1/6] Verificando estado git...${NC}"
if [ -n "$(git status --porcelain)" ]; then
    echo "Cambios pendientes:"
    git status --short
else
    echo "Working tree limpio ✅"
fi

# 2. Crear rama feature
echo -e "${YELLOW}[2/6] Creando rama feature/admin-dashboard-v1...${NC}"
BRANCH="feature/admin-dashboard-v1"
if git show-ref --verify --quiet refs/heads/$BRANCH; then
    echo "Rama $BRANCH ya existe, cambiando a ella..."
    git checkout $BRANCH
else
    git checkout -b $BRANCH
    echo "Rama creada ✅"
fi

# 3. Commit cambios del admin-dashboard
echo -e "${YELLOW}[3/6] Commitando cambios...${NC}"
git add admin-dashboard/ railway.json .github/workflows/deploy-admin-*.yml
if git diff --cached --quiet; then
    echo "Nada nuevo para commit"
else
    git commit -m "feat(admin): add admin dashboard with business/precios/academia/vto routes

- Admin dashboard (Next.js 15) with protected routes
- Business compliance, Precios, Academia, VTO pages
- Sidebar navigation with mobile responsive
- BFF proxy with JWT HttpOnly cookies + auto-refresh
- Railway multi-service config (railway.json)
- GitHub Actions for preview/production deploy"
    echo "Commit creado ✅"
fi

# 4. Push a origin
echo -e "${YELLOW}[4/6] Pusheando a origin...${NC}"
git push -u origin $BRANCH
echo "Push completado ✅"

# 5. Verificar railway.json
echo -e "${YELLOW}[5/6] Verificando railway.json...${NC}"
if [ -f railway.json ]; then
    echo "railway.json existe ✅"
    cat railway.json | jq .
else
    echo -e "${RED}ERROR: railway.json no encontrado${NC}"
    exit 1
fi

# 6. Instrucciones finales
echo ""
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ SETUP COMPLETADO${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo "PRÓXIMOS PASOS MANUALES EN RAILWAY DASHBOARD:"
echo ""
echo "1. 🌐 Abre: https://railway.app/dashboard"
echo "   Proyecto: grateful-harmony"
echo ""
echo "2. ➕ Añade servicio admin-dashboard:"
echo "   - New Service → GitHub Repo → Select repo"
echo "   - Root Directory: /admin-dashboard"
echo "   - O usa railway.json (auto-detecta)"
echo ""
echo "3. ⚙️ Configura Variables de Entorno (servicio admin-dashboard):"
echo "   BACKEND_INTERNAL_URL=http://backend.railway.internal:3000"
echo "   JWT_SECRET=<tu_jwt_secret_de_al_menos_32_caracteres>"
echo "   NODE_ENV=production"
echo ""
echo "4. 🔄 Habilita Preview Deployments:"
echo "   Project Settings → Preview Deployments → Enabled"
echo ""
echo "5. 🔐 Añade secret en GitHub:"
echo "   Settings → Secrets → Actions → RAILWAY_TOKEN"
echo "   (Token desde Railway Account → Tokens)"
echo ""
echo "6. 📝 Abre PR en GitHub:"
echo "   - Base: main ← Compare: feature/admin-dashboard-v1"
echo "   - Railway auto-crea preview deployment"
echo "   - URL preview aparece en comentarios del PR"
echo ""
echo "7. ✅ Diego revisa preview → Merge → Auto-deploy a prod"
echo ""
echo -e "${YELLOW}ARCHIVOS CREADOS:${NC}"
echo "  - railway.json (multi-service config)"
echo "  - .github/workflows/deploy-admin-preview.yml"
echo "  - .github/workflows/deploy-admin-prod.yml"
echo "  - admin-dashboard/RAILWAY_ENV.md"
echo ""
echo -e "${GREEN}¡Listo para deploy! 🎉${NC}"