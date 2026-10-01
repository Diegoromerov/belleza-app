import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  // Seguridad de build (P1 · t_fix_flutter_05): no emitir source maps del
  // bundle de navegador en producción. Un .map publicado expone el código
  // fuente, rutas internas y estructura del panel admin. Next.js ya no los
  // emite por defecto; se declara EXPLÍCITAMENTE para que la garantía quede
  // auditada y no dependa de un default implícito (ni de una futura config
  // webpack que lo reactive).
  productionBrowserSourceMaps: false,
};

export default nextConfig;
