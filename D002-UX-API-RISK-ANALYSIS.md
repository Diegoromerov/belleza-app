# D-002 UX/API RISK ANALYSIS

## UX Risks
- Terminology such as "empleado", "contratista", or "personal" in the interface could be misinterpreted as GlowApp employing or managing workers.
- Labels like "GlowApp team", "our employees", or "staff" in the UI must be avoided.
- Any flow that suggests GlowApp is assigning workers to shifts or managing labor schedules could create confusion.
- Copy should consistently refer to "usuarios del salón", "profesionales registrados por el salón", etc., to emphasize that the salon is the actor.

## API Risks
- Endpoints that imply GlowApp is the actor in labor relationships (e.g., POST /employees, GET /payroll) must be avoided.
- API responses should not include fields that suggest GlowApp assumes obligations (e.g., salary, tax_withheld, benefits).
- Authorization scopes should be clearly tied to tenant operations, not to GlowApp's internal labor management.
- Webhooks or notifications should not be framed as GlowApp initiating labor-related actions.

## Mitigation
- Use generic terms like "colaborador", "miembro del equipo", or "usuario del salón" in UX and API.
- Ensure all workforce-related endpoints require explicit tenant context and are presented as tools for the salon.
- Legal and UX review should be conducted for any new feature involving workforce management to confirm compliance with the D-002 boundary.

---
*Análisis completado el: $(date)*