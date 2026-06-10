# RESUMEN DE COMPROMISOS Y LABORES POR ÁREA: INTEGRACIÓN DE KPIS EN DASHBOARD
**Fecha:** 2026-06-09  
**Sesión:** Reunión Directiva #001 (Seguimiento de Tarea)  
**Estado:** Documento de Coordinación Interna  

---

Para llevar a cabo el desarrollo y despliegue exitoso del nuevo módulo de **Reunión Directiva** en el panel de administración, cada jefatura tiene un rol específico e interdependiente:

### 1. Dirección de Operaciones (COO) — *Definición de Procesos e Impacto en Campo*
* **Definición de Requerimientos:** Detalla las reglas del SLA operativo para alertas SOS (cómo se mide el tiempo de respuesta desde que se pulsa el botón hasta la llamada a la policía) y los pasos clave del funnel KYC para que el checklist sea realista.
* **Consumo de Información:** Utilizará el panel para monitorear el balance oferta/demanda y coordinar acciones de campo basadas en la retención real de profesionales.

### 2. Dirección de Tecnología (CTO) — *Implementación Técnica y Telemetría*
* **Desarrollo de Software:** Responsable de codificar el componente interactivo en Next.js (React) con Tailwind CSS y Recharts, asegurando una estética premium y fluidez técnica.
* **Integración de Sockets y APIs:** Implementa las llamadas a bases de datos y websockets necesarios para que el indicador de latencia PostGIS y el temporizador SOS muestren valores en tiempo real, conectando el frontend con el backend Express.

### 3. Dirección Financiera y Legal (CFO & Legal Lead) — *Control de Fórmulas y Auditoría Legal*
* **Validación de Fórmulas:** Asegura que los cálculos del LTV/CAC y del split fiscal (retención del 8% e ingreso neto del 12% comisión) reflejados en el panel sean exactos y sigan las directrices contables de Wompi.
* **Registro de Decisiones (Compliance):** Garantiza que la bitácora de decisiones directivas guarde logs persistentes y auditables, y que el almacenamiento de datos sensibles de KYC y geolocalización cumpla con Habeas Data.

### 4. Dirección de Crecimiento y Marketing (CMO) — *Embudo de Conversión y Atribución*
* **Suministro de Eventos de Growth:** Aporta la estructura de eventos de Mixpanel/Firebase (registro finalizado, primer booking) y las bases de datos de costos publicitarios (Meta, Google, TikTok Ads) para calcular el CAC dinámico por canal.
* **Alineación de Demanda:** Utiliza los indicadores operativos del COO para redirigir el gasto de marketing hacia zonas geográficas específicas donde falten clientes o sobren proveedores.
