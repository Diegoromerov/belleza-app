# D-002 LEGAL-TECHNICAL BOUNDARY

## LEGAL BOUNDARY

Based on the Director's decision and Colombian labor law (Ley 1581, Código Sustantivo del Trabajo, etc.), the following legal boundaries apply:

1. GlowApp is not an employer, contractor, or intermediary for labor services.
2. GlowApp does not assume labor obligations (salaries, benefits, social security, etc.) for workers of the salons.
3. GlowApp does not intervene in the determination of the legal nature of the relationship between the salon and its workers.
4. GlowApp does not pay salaries or honorarios as an obligor; it only facilitates payments if configured by the salon.
5. GlowApp does not affiliate workers to the social security system.
6. GlowApp does not administer labor contracts, terminations, or disciplinary actions.
7. GlowApp does not verify professional licenses or certifications beyond storing URLs provided by the salon.
8. GlowApp does not act as an employment agency or labor contractor.

## TECHNICAL BOUNDARY

To respect the legal boundary, the technical implementation must ensure:

- No functionality in GlowApp creates a legal employer-employee relationship between GlowApp and the salon's workers.
- All data related to workers (if stored) is clearly marked as belonging to the salon (tenant) and is under the salon's control.
- Any payment processing is strictly facilitative: GlowApp only executes payments as instructed by the salon (e.g., via payment gateways) and does not decide payment amounts, recipients, or timing as an obligor.
- The system must not store or process data that could be interpreted as GlowApp assuming labor obligations (e.g., payroll tables, tax withholding as an employer, etc.).
- Role-based access control (RBAC) in GlowApp must be strictly for platform functionality (e.g., accessing the admin panel, managing services, etc.) and must not be conflated with labor roles.
- The term "employee" in the system, if used, must refer to a worker designated by the salon, not an employee of GlowApp.
- All workforce-related data (if any) must be isolated by tenant_id and subject to RLS if appropriate, reinforcing that the data belongs to the salon.

## RECOMMENDATIONS

- Avoid creating tables named `employees`, `contracts`, `payroll`, etc., that could imply GlowApp is managing labor relationships.
- If worker data is to be stored, use generic terms like `workforce_members` or `talent` and make it clear that the salon defines the nature of the relationship.
- Ensure that any commission or payment functionality is clearly presented as a service to the salon, not as GlowApp paying workers.
- In the UI and copy, avoid language that suggests GlowApp hires, pays, or manages workers (e.g., "GlowApp employees", "payroll", "hire staff").
- Legal review should be sought for any new feature that involves storing worker data or facilitating payments to ensure compliance with labor and data protection laws.

---
*Análisis completado el: $(date)*