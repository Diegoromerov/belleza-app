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

---

## 8. DESIGN SYSTEM & UI/UX GOVERNANCE RULES

1. **Design Token Enforcement:** All visual styling must use tokenized classes (Tailwind CSS or `AppColors` in Flutter). Hardcoded hex codes or ad-hoc inline styles are prohibited.
2. **Component Reuse:** Agents must consume existing primitives from `src/components/ui/` before creating custom components.
3. **Booking Sequence Compliance:** Any modification to booking interactions must follow the 3-step logical progression: 1. Cuándo y Dónde -> 2. Productos -> 3. Pago.
4. **Accessibility Standards:** All interactive UI elements must adhere to WCAG 2.1 AA (minimum $4.5:1$ contrast ratio, $\ge 44\times 44\text{px}$ tap targets, keyboard focus support).
