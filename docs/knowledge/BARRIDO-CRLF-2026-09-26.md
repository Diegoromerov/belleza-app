# Barrido de la clase CI-31 — ¿qué otras compuertas leen líneas y pueden mentir?

**Fecha:** 2026-09-26 · **Autor:** Hermes (Arquitecto/Verificador) · **Commit medido:** `b545ef22` (base `fase-a/verdad-operativa`)
**Motivo:** CI-31 demostró que el escáner de secretos viejo da **falso limpio en Windows**. Un defecto así se arregla por **clase**, no por sitio: había que barrer el resto de las verificaciones que leen líneas.

## Método

Dos worktrees del **mismo commit**, uno convertido de verdad a CRLF (2964 de 2965 archivos de texto, con `ci.yml` en 129 CRLF y `AUDITORIA_PREPRODUCCION_MASTER.md` en 273) y otro en LF. En cada uno se corrieron las compuertas que leen archivos y se comparó **exit code + salida**.

## Resultado

| Verificación | checkout CRLF | checkout LF | Veredicto |
|---|---|---|---|
| `scripts/verifyNoVersionedSecrets.js` (**paso 7, bloqueante**) | exit 1 · **1 hallazgo** | exit 1 · **39 hallazgos** | ❌ **ciego al CRLF (CI-31, reconfirmado)** |
| `scripts/checkNoConflictMarkers.js` (**paso 6, bloqueante**) | exit 0 sin marcadores · **exit 1 con marcador sintético** | idéntico | ✅ robusto |
| `scripts/inspectCiSuites.js` (A-05, rama pendiente) | exit 0, lista idéntica | idéntico | ✅ robusto |

**Conclusión:** de las compuertas que leen líneas, **sólo el escáner** tenía la ceguera. El barrido no encontró una segunda. Es un resultado negativo, y por eso se registra: acota el riesgo a un solo script — el que A-06 r5 reemplaza.

## Hallazgo colateral (importante, y no es del escáner)

El repo tiene **finales de línea mezclados por worktree**, medidos hoy sobre el mismo commit con `backend/index.js`:

| Worktree | CRLF en `index.js` |
|---|---|
| banco `C:/beauty-app` | **1851** |
| ejecutor (`setup_glowguide_architecture`) | **0** (LF) |
| KB (`sistema-agentes`) | **1853** |

Consecuencia: **dos worktrees del mismo commit pueden dar veredictos distintos** en cualquier verificación que lea líneas — y una medición hecha en el banco o en la KB no predice lo que verá el CI. El `.git/config` del repo quedó con `core.autocrlf=false` (puesto por el Ejecutor durante A-07, **sin declararlo**), así que los worktrees **nuevos** nacen LF mientras los viejos siguen en CRLF.

**Regla:** toda verificación que lea líneas **declara primero los finales de línea de su worktree**, con el número, y si difieren del CI (LF) se mide en un checkout LF. Registrado como CI-36 (decisión del Dueño: dejar `core.autocrlf=false` + normalizar los existentes, o fijarlo con `.gitattributes`).
