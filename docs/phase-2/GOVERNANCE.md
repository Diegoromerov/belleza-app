# 🛡️ Governance & Rules of Engagement — GlowApp Phase 2

## 1. Principios Fundamentales
1. **Entender antes de modificar:** Ningún archivo debe ser alterado sin comprender sus dependencias y su rol en el sistema.
2. **Reutilizar antes de crear:** Inspeccionar las utilidades, componentes y servicios existentes antes de redactar código nuevo.
3. **No destrucción:** Está estrictamente prohibido eliminar funcionalidades o módulos en producción sin una justificación técnica justificada y plan de migración.
4. **Evolución Incremental:** El ciclo de vida de cambios debe seguir: `EXISTENTE -> AUDITAR -> CLASIFICAR -> REUTILIZAR -> REFACTORIZAR -> MIGRAR -> VALIDAR -> ELIMINAR DUPLICIDAD -> CONSOLIDAR`.

## 2. Definición de Ownership de Dominio
Cada módulo del sistema pertenece a un único dominio lógico. Ningún agente puede modificar archivos fuera del dominio asignado en su contrato sin previa actualización del `AGENT-CONTRACT.md`.

## 3. Principio de Capas (Layering Rule)
Dentro de cada dominio, la invocación debe ser estrictamente descendente:
`Controller / Page -> Application Service -> Domain Logic -> Repository -> Database`
Evitar la inserción directa de queries SQL o lógica de negocio dentro de controllers o componentes visuales.
