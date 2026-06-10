# PROMPT DE DESARROLLO: INTEGRACIÓN DE KPIS DE JUNTA DIRECTIVA EN EL DASHBOARD DE GLOWADMIN

**Propósito:** Este prompt instruye al equipo de desarrollo (o a un subagente especializado de desarrollo frontend) sobre cómo implementar la pestaña "Reunión Directiva" en el panel de administración Next.js, integrando de forma interactiva las métricas y la toma de decisiones coordinadas de las cuatro áreas directivas.

---

## 📄 Prompt de Instrucción para el Desarrollador (o Subagente)

```markdown
Eres un desarrollador Frontend experto en React, Tailwind CSS y componentes interactivos de alto rendimiento visual. Tu tarea es integrar la pestaña "Reunión Directiva" (Board Meeting) en el panel GlowAdmin (ubicado en `admin-dashboard/src/app/page.tsx`).

### Requisitos de la Interfaz "Reunión Directiva"

1. **Estructura y Navegación:**
   - Añade una nueva pestaña llamada "Reunión Directiva" en el menú de navegación lateral, utilizando un icono apropiado (ej. `Users` de `lucide-react`).
   - Al hacer clic en esta pestaña, se debe renderizar una vista de sala de juntas corporativa digital.

2. **KPIs Integrados Interdependientes (Visualización de Datos):**
   - Diseña un panel resumen con los 4 indicadores transversales que demuestran la salud cruzada del marketplace:
     * **Relación LTV/CAC (Crecimiento/Finanzas):** Indicador de rentabilidad (Meta: >3.5x).
     * **SLA de Alerta SOS (Operaciones/Tecnología):** Tiempo promedio de reacción (Meta: <2 min).
     * **Latencia de Búsqueda PostGIS (Tecnología):** Rendimiento del motor espacial (Meta: <80ms).
     * **Precisión del Split Impositivo/Comisión (Finanzas/Legal):** Tasa de errores en dispersión (Meta: 100% libre de errores).

3. **Selector de Jefaturas (Foco por Rol):**
   - Implementa un selector visual (con pestañas internas o botones premium) para alternar la vista entre los 4 directores (COO, CTO, CFO, CMO).
   - Al seleccionar un rol, muestra dinámicamente:
     * **Perfil del Director:** Nombre, área y descripción breve de su rol.
     * **Listado de Tareas Clave (Checklist):** Tareas específicas del rol (extraídas de sus onboarding files correspondientes) que el usuario pueda marcar/desmarcar de manera interactiva.
     * **Métricas Específicas del Departamento:** Gráficos sencillos o medidores de progreso utilizando colores acordes al área.

4. **Matriz de Sinergia e Interdependencia:**
   - Diseña una sección visual interactiva (diagrama conceptual o rejilla de tarjetas) que explique cómo el fallo en un KPI técnico (ej. latencia) afecta al operativo (ej. tiempo de viaje) y al financiero (ej. cargos adicionales).

5. **Bitácora de Decisiones Activas (Minutas de Junta):**
   - Agrega un componente interactivo para gestionar la "Bitácora de Decisiones".
   - Debe permitir:
     * Visualizar las decisiones actuales registradas en la junta directiva (ej. "Aprobar presupuesto de pauta", "Iniciar migración PostGIS", "Congelar wallets con risk_score > 8").
     * Cambiar el estatus de cada decisión mediante un control interactivo (Estados: "Aprobado", "En Discusión", "Rechazado") con colores semánticos dinámicos.
     * Añadir nuevas minutas/decisiones a la lista mediante un formulario sencillo (Input de descripción, Selector de área involucrada y Selector de prioridad).

### Pautas de Diseño y Estética Premium
- Mantén la consistencia con el diseño del dashboard: fondo oscuro (`bg-[#0b0f19]`), bordes estilizados (`border-slate-800` o degradados sutiles).
- Utiliza efectos de glassmorphism (`backdrop-blur-md bg-slate-900/40`).
- Aplica micro-animaciones en hover para las tarjetas y botones para que la interfaz se sienta "viva".
- Usa fuentes de tamaño adecuado, iconos de `lucide-react` para cada indicador, y gráficos responsivos.

### Puntos de Entrada de Datos
Implementa la lógica del componente usando estados de React (`useState` y `useEffect`) de tal forma que los datos financieros, las tareas de directores y la lista de decisiones persistan localmente en el componente para esta demo interactiva.
```
