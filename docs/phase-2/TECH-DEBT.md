# 🧹 Tech Debt & Technical Backlog

## Inventario de Deuda Técnica
1. **Rutas de Importación Relativas:** Migradas en GOAL 00 al alias `@/`. *(Resuelto)*
2. **Duplicación de Tipos TypeScript:** Existen interfaces repetidas entre frontend y backend para la entidad `Booking`. Se recomienda consolidar en `src/types/booking.ts`.
3. **Manejo de Errores Heterogéneo:** Algunos endpoints retornan `{ error: msg }` y otros `{ message: msg }`. Se debe estandarizar la respuesta HTTP a un formato unificado.
