# GLOWAPP — GAP ANALYSIS

## 1. BRECHAS IDENTIFICADAS (GAPS TÉCNICOS Y FUNCIONALES)

### GAP-01: Homologación Visual SOUL en Pantallas Periféricas
* **Descripción:** Aunque los flujos principales (Auth, Home, Ideas/AURA, Store) utilizan el sistema de tokens canónico (`AppTheme`, `tokens.dart`, `GlowIcon`), ciertas pantallas complejas de proveedor (`provider_dashboard_screen.dart`, `provider_detail_screen.dart`) conservan scripts de parche y código legacy.
* **Impacto:** Medio (Consistencia visual y mantenibilidad).
* **Prioridad:** P1.

### GAP-02: Limpieza de Scripts de Migración en la Raíz
* **Descripción:** Existen más de 30 scripts temporales de Python/JS en la raíz del repositorio (`clean_duplicates.py`, `do_replace.py`, `migrate_menu.py`, `update_buttons.py`).
* **Impacto:** Bajo (Ruido de repositorio; no afecta runtime).
* **Prioridad:** P2.

### GAP-03: Automatización de Tests de Integración End-to-End con PostgreSQL Local
* **Descripción:** De 308 tests totales en Jest, 289 aprueban limpiamente (94%). 18 tests fallan debido a mocks de Redis/DB en entornos locales sin contenedor activo o rutas de bash en Windows (`ciRagEvaluation.sh`).
* **Impacto:** Medio (Calidad de CI/CD).
* **Prioridad:** P1.

### GAP-04: Módulos SaaS B2B en Estado Experimental
* **Descripción:** Las rutas `b2bCoPilotRoutes.js` y servicios de retención automática requieren mayor integración con el flujo de facturación y CRM real de salones.
* **Impacto:** Medio.
* **Prioridad:** P2.
