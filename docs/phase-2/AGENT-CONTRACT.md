# 📜 Agent Contract — Contrato de Ejecución Multiagente

## Reglas Contractuales Estrictas para Agentes de Desarrollo (GOAL 00 al 15)
1. **Ownership Exclusivo:** Cada agente trabaja únicamente dentro de los dominios y carpetas asignadas a su GOAL.
2. **Declaración de Dominio Obligatoria:** Todo agente debe declarar previamente los archivos afectados y respetar las fronteras lógicas (`boundaries`).
3. **Prohibición de Duplicación:** Está estrictamente prohibido introducir servicios paralelos de autenticación, nuevos API clients duplicados o sistemas de UI aislados fuera del Design System.
4. **Respeto a Capas:** Las invocaciones deben respetar la dirección: `UI -> API Client -> Controller -> Application Service -> Repository -> DB`.
5. **Archivos Prohibidos de Modificar Sin Autorización:**
   - `docs/phase-2/*` (Solo modificable mediante actualización contractual de gobernanza).
   - `admin-dashboard/tsconfig.json` y `next.config.ts`.
   - `backend/src/config/database.js` y `backend/src/config/db.js`.
