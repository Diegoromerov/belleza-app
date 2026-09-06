# Glow UI Design Director V2 — Hermes Agent

AI Design Director para una aplicación Flutter existente.

## Objetivo

Convertir el auditor V1 en un ciclo controlado:

**ANALIZAR → RENDERIZAR → DIAGNOSTICAR → PROPONER → IMPLEMENTAR EN WORKTREE → RENDERIZAR → COMPARAR → GENERAR PATCH**

El sistema está diseñado para GlowApp y prioriza:
- `ProviderDetailScreen`
- `BookingScreen`
- flujo de agendamiento/venta cruzada
- design system
- accesibilidad
- responsive
- consistencia visual
- cambios pequeños y revisables

No modifica la rama principal durante AUDIT+PATCH.

## Qué entrega V2

```text
.ui-audit/
├── evidence/
│   ├── before/
│   ├── proposal/
│   └── after/
├── reports/
│   ├── audit-report.md
│   ├── design-director.md
│   ├── visual-diff.md
│   └── change-plan.md
├── patches/
├── proposals/
├── snapshots/
└── metrics/
```

## Flujo

1. Descubre arquitectura Flutter.
2. Ejecuta análisis estático.
3. Ejecuta la app.
4. Captura pantallas reales.
5. Analiza UI/UX con evidencia.
6. Construye propuesta visual.
7. Implementa una propuesta en un worktree temporal.
8. Captura la versión modificada.
9. Compara BEFORE/PROPOSAL/AFTER.
10. Evalúa regresiones.
11. Exporta patch.
12. No aplica el patch a la rama principal.

## Instalación

Copia el contenido en la raíz del repositorio GlowApp.

Después verifica:

```powershell
git status
flutter doctor
flutter devices
```

Para Hermes, usa la skill:

```text
/glow-ui-design-director ejecuta el ciclo completo V2
```

O pega `PROMPT_HERMES_V2.md` en Hermes.

## Modos

- `AUDIT`: solo análisis.
- `AUDIT+PROPOSAL`: análisis + propuesta.
- `AUDIT+PATCH`: análisis + propuesta + patch.
- `FULL-LOOP`: antes → propuesta → después → comparación → patch.

V2 está preparado para `FULL-LOOP`, pero requiere revisión humana antes de aplicar patches.
