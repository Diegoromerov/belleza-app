# Auditoría — Fases 0 a 5 del plan de rediseño del salón

**Fecha:** 2026-10-25
**Proyecto:** C:\beauty-app\frontend
**Commit:** a269bb580
**Rama durante la auditoría:** firebase-setup
**Alcance:** Fases 0, 1, 2, 3, 4 y 5 del plan “Salon redesign”.
**Naturaleza:** auditoría de solo lectura; no se modificó código.

---

## Veredicto ejecutivo

**Ninguna de las fases 0–5 está cumplida por completo.** Hay tres fases parciales (1, 2 y 4) y tres no cumplidas (0, 3 y 5). El patrón dominante es **andamiaje sin integración**: existen archivos aislados (router, MainScaffold, theme) que no están conectados a la aplicación real, mientras la app sigue usando `MaterialApp` + `Navigator.pushNamed`.

| Fase | Estado | Resumen |
|---|---|---|
| 0 — Preparación | ❌ No cumplida | Tag existe, pero el árbol actual no compila ni pasa tests y el CI no ejecuta tests. |
| 1 — Rutas | ⚠️ Parcial | `app_router.dart` existe con rutas y guard, pero no está montado (`MaterialApp.router` = 0 usos). |
| 2 — Scaffold | ⚠️ Parcial | `MainScaffold` existe dentro del router, pero no se usa; falta archivo propio, fadeThrough y goldens. |
| 3 — Migración de pantallas | ❌ No cumplida | Servicios/Reservas/Inventario son placeholders de 13 líneas; siguen 36 `Navigator.pushNamed`. |
| 4 — UI & Theme | ⚠️ Parcial | `theme_salon.dart` existe, pero no se referencia en ninguna pantalla; faltan componentes reutilizables. |
| 5 — Estado global | ❌ No cumplida | No existen los 5 providers del plan; el dashboard del salón usa `setState` + `ApiService` directo. |

---

## Estado del repositorio durante la auditoría

Hechos comprobados:

- `HEAD` = `a269bb580`; la rama cambió a `firebase-setup` durante la sesión (antes `feature/salon-redesign`).
- `git status --porcelain` = 84 entradas.
- `flutter test --no-pub`: **126 pasan, 8 fallan al cargar**.
- `flutter analyze lib`: **34 errores**, 21 warnings, 69 infos.
- Los 34 errores provienen de código Firebase nuevo (`lib/services/firebase_auth_service.dart`, `lib/services/fcm_service.dart`, `lib/main.dart`), ajeno al plan de rediseño del salón.

Tests que fallan al cargar:

1. `test/app_smoke_test.dart`
2. `test/fcm_service_no_firebase_test.dart`
3. `test/firebase_options_test.dart`
4. `test/golden/phase5_goldens_test.dart`
5. `test/screens/booking_screen_overflow_test.dart`
6. `test/screens/booking_screen_test.dart`
7. `test/services/biometric_consent_state_test.dart`
8. `test/widget_test.dart`

Causa: `firebase_auth_service.dart` usa `FirebaseAuth`, `UserCredential`, `User`, `kIsWeb`, `debugPrint` y `FirebaseAuthException` sin los imports correspondientes. Es trabajo en curso de la rama `firebase-setup`, no del rediseño.

> Referencia histórica: en la rama `feature/salon-redesign`, en el mismo commit, la suite pasó **153/153** y `flutter analyze lib` dio **0 errores**. La auditoría de contenido de abajo se basa en los archivos actuales, que conservan el andamiaje del rediseño.

---

## Fase 0 — Preparación

| Compromiso | Evidencia | Estado |
|---|---|---|
| Snapshot de la rama develop con tag `v0-pre-redesign` | El tag existe y apunta a `ce708d999` (2026-10-24). **No existe rama `develop`.** | ⚠️ Parcial |
| Pipeline CI/CD actualizado con tests unitarios + lint | `.github/workflows/ci.yml` tiene job `frontend-ci`, pero solo ejecuta `flutter pub get` y `flutter analyze --no-fatal-infos --no-fatal-warnings`. **No ejecuta `flutter test`.** | ❌ No cumplido |
| Verificar que los tests existentes pasen | En el árbol actual: 8 suites no cargan y 34 errores de análisis. | ❌ No cumplido |
| Documentar versiones de dependencias | Existe `pubspec.lock`, pero no se encontró documento dedicado de versiones. | ⚠️ Parcial |

**Conclusión F0:** el snapshot existe, pero el criterio de “código base estable” no se cumple en el estado actual y el CI no protege con tests.

---

## Fase 1 — Infraestructura de rutas

| Compromiso | Evidencia | Estado |
|---|---|---|
| `app_router.dart` con rutas nombradas | Existe `lib/router/app_router.dart` (180 líneas) con 9 rutas: `/login`, `/home`, `/salon/dashboard`, `/salon/servicios`, `/salon/reservas`, `/salon/inventario`, `/salon/perfil`, `/provider`, `/superadmin`. | ✅ Archivo existe |
| Migrar `MaterialApp` → `MaterialApp.router` | `MaterialApp.router` aparece **0 veces**. `main.dart` sigue usando `MaterialApp` con un mapa `routes:` de más de 40 entradas. | ❌ No cumplido |
| `appRouter` como router único | `appRouter` solo se referencia dentro de `app_router.dart`; **no se importa en `main.dart` ni en ningún otro archivo**. Es código muerto. | ❌ No cumplido |
| `authRedirectGuard` con JWT y rol | El guard lee `SecureStorageService().read('jwt')` y redirige a `/login` si no hay token. No lee rol ni decide dashboard por rol; el propio comentario dice “Additional role-based logic could be added here”. | ⚠️ Parcial |
| Redirect `/provider` → `/salon/dashboard` | Definido en `app_router.dart`, pero no activo porque el router no se usa. | ⚠️ Definido, inactivo |
| Pruebas de integración de rutas | No hay tests que importen `appRouter`, `GoRouter` ni `MaterialApp.router`. | ❌ No cumplido |

**Conclusión F1:** se creó el archivo, pero no se centralizó la navegación. La app real sigue con `Navigator` y el mapa de rutas de `main.dart`.

---

## Fase 2 — Scaffold y navegación principal

| Compromiso | Evidencia | Estado |
|---|---|---|
| `main_scaffold.dart` reutilizable | No existe ese archivo. `MainScaffold` está definido dentro de `lib/router/app_router.dart`. | ⚠️ Parcial |
| BottomNav de 5 ítems | `_navItems` tiene Dashboard, Servicios, Reservas, Inventario y Perfil. | ✅ Implementado |
| Drawer con Analytics, Settings, Help | Drawer con “Analytics”, “Configuración” y “Ayuda”; los dos últimos solo muestran SnackBar “no implementada”. | ⚠️ Parcial |
| `WillPopScope` para cerrar drawer antes de salir | Presente en `MainScaffold` (con `key: Key('mainScaffold')`). | ✅ Implementado |
| Animaciones fadeThrough | Usa `AnimatedSwitcher` + `FadeTransition`, no `PageTransitionSwitcher`/fadeThrough. | ⚠️ Parcial |
| Conectar cada ítem a las rutas | Los ítems usan `context.go(...)`, pero `MainScaffold` no está montado en la app. | ⚠️ Código sí, integración no |
| Golden tests del scaffold | No hay goldens de `MainScaffold`, BottomNav ni Drawer. Los goldens existentes son de Booking y ProviderDetail. | ❌ No cumplido |

**Conclusión F2:** el componente existe y tiene la estructura pedida, pero es código no utilizado por la aplicación y carece de cobertura visual.

---

## Fase 3 — Migración de pantallas existentes

| Compromiso | Evidencia | Estado |
|---|---|---|
| Dashboard bajo `/salon/dashboard` | `SalonDashboardScreen` existe, pero `main.dart` lo monta en `/salon`, no en `/salon/dashboard`. | ⚠️ Parcial |
| Pantallas migradas con lógica | `servicios_screen.dart`, `reservas_screen.dart` e `inventario_screen.dart` son placeholders de **13 líneas** que solo muestran un texto. No tienen lógica de negocio ni endpoints. | ❌ No cumplido |
| Nombres `SalonServicesScreen`, `SalonBookingsScreen`, `SalonInventoryScreen`, `SalonProfileScreen` | Las clases son `ServiciosScreen`, `ReservasScreen`, `InventarioScreen`; perfil usa `UserProfileScreen`. | ❌ No cumplido |
| Cambiar `Navigator.pushNamed` a nuevas rutas | Quedan **36** `Navigator.pushNamed` (46 menciones incluyendo comentarios), 61 `Navigator.push`; solo 2 `context.go` y 0 `context.push`. | ❌ No cumplido |
| Eliminar imports obsoletos de `provider_dashboard_screen.dart` | `main.dart` sigue importando `provider_dashboard_screen.dart`. | ❌ No cumplido |
| `SalonAppBar` común | No existe ninguna clase `SalonAppBar`. | ❌ No cumplido |
| Mismos endpoints `/api/...` | Los placeholders no consumen endpoints; el dashboard sí usa `ApiService` directo. | ⚠️ No verificable / parcial |

**Conclusión F3:** no hubo migración real de pantallas. Se crearon destinos vacíos para que las rutas existan, pero la lógica y la navegación antigua siguen intactas.

---

## Fase 4 — UI & Theme consistente

| Compromiso | Evidencia | Estado |
|---|---|---|
| `theme_salon.dart` con tokens | Existe `lib/theme/theme_salon.dart` con `primary = #D81B60`, `secondary = #4A148C`, tipografías Inter/Playfair, radios y `CardThemeData`. | ✅ Archivo existe |
| Aplicar el tema a las pantallas | `SalonTheme` no se referencia en **ningún** archivo fuera de `theme_salon.dart` (0 referencias). `main.dart` usa `AppTheme`/`MensTheme`. | ❌ No cumplido |
| `CardElevated`, `ActionFAB`, `EmptyState`, `SkeletonLoader` | No existe ninguna de esas clases en `lib/`. | ❌ No cumplido |
| Micro-interacciones y `PageTransitionSwitcher` | No se usa `PageTransitionSwitcher`; hay un `AnimatedSwitcher` en el router muerto. | ⚠️ Parcial |
| Test de accesibilidad | Existe `test/wcag_contrast_test.dart` y pasa en la suite actual. | ✅ Implementado |

**Conclusión F4:** el tema está definido como archivo aislado, pero no gobierna la UI. Los componentes reutilizables del plan no existen.

---

## Fase 5 — Estado global y data layer

| Compromiso | Evidencia | Estado |
|---|---|---|
| `authProvider`, `salonInfoProvider`, `servicesProvider`, `bookingsProvider`, `inventoryProvider` | Ninguno existe. `authProvider` solo aparece como parámetro string en `auth_service.dart`. | ❌ No cumplido |
| Carpeta `state/` con `salon_state.dart`, `service_state.dart`, etc. | No existe `lib/state/`. Solo hay `lib/providers/` con providers de SaaS y SuperAdmin. | ❌ No cumplido |
| Wrapper `AsyncValue` para loading/error | Solo 1 referencia a `AsyncValue` en todo `lib/` (en `super_admin_state.dart`, de otra área). | ❌ No cumplido |
| Reescribir llamadas `ApiService` en providers | `SalonDashboardScreen` conserva 4 `setState` y llamada directa a `ApiService`. | ❌ No cumplido |
| UI consumiendo `ref.watch(...)` | 26 `ref.watch` y 9 widgets `Consumer*` en total, concentrados en SaaS/SuperAdmin; las pantallas del salón no usan Riverpod. | ⚠️ Parcial, fuera del salón |
| Pruebas unitarias de providers con API mockeada | No hay tests de providers del salón. | ❌ No cumplido |

**Conclusión F5:** el data layer del salón no se consolidó. La pantalla principal sigue con `setState` y llamadas directas, exactamente lo que la fase buscaba eliminar.

---

## Hallazgos transversales

1. **El rediseño es Andamiaje, no integración.** `app_router.dart`, `MainScaffold` y `theme_salon.dart` existen, pero ninguno participa del árbol real de widgets. La app sigue usando `MaterialApp` + `Navigator`.
2. **Las rutas nuevas no son alcanzables.** Los destinos `/salon/*` del router no se usan; la app navega con `/salon`, `/salon-hub`, `/provider`, etc. desde `main.dart`.
3. **Las pantallas del salón son cáscaras.** Servicios, Reservas e Inventario tienen 13 líneas y no conservan lógica ni endpoints.
4. **El tema no se aplica.** `SalonTheme` tiene 0 referencias externas; los colores reales vienen de `AppTheme`/`MensTheme`.
5. **El estado global del salón no existe.** No hay providers de salón ni carpeta `state/`; el dashboard usa `setState`.
6. **La fase 0 está contaminada por trabajo concurrente.** La rama `firebase-setup` introdujo código Firebase incompleto que rompe 8 suites y produce 34 errores de análisis. Eso impide certificar “código base estable” en el árbol actual.

---

## Qué faltaría para cerrar cada fase

- **F0:** arreglar el código Firebase de la rama actual (imports/dependencias) o volver a un árbol verde; añadir `flutter test` al job `frontend-ci`; documentar versiones.
- **F1:** montar `MaterialApp.router` con `appRouter`; eliminar el mapa `routes:` de `main.dart`; implementar redirect por rol; añadir tests de rutas.
- **F2:** mover `MainScaffold` a `lib/widgets/main_scaffold.dart`; montarlo como shell real; usar fadeThrough; añadir goldens del scaffold.
- **F3:** migrar la lógica real de Servicios/Reservas/Inventario/Perfil; renombrar a `Salon*Screen`; sustituir `Navigator.pushNamed` por `context.go`; crear `SalonAppBar`.
- **F4:** aplicar `SalonTheme` en `MaterialApp`/pantallas; crear `CardElevated`, `ActionFAB`, `EmptyState`, `SkeletonLoader`; sustituir transiciones; mantener WCAG.
- **F5:** crear `state/` y los 5 providers; mover `ApiService` a los providers; consumir con `ref.watch`; añadir tests con API mockeada.

---

## Limitaciones de la auditoría

- No se auditaron tiempos ni responsables: el repositorio no contiene evidencia de esfuerzo por fase.
- El árbol cambió de rama durante la sesión (`feature/salon-redesign` → `firebase-setup`) y tiene 84 entradas sin commitear; los resultados de tests/análisis corresponden a ese estado, no al commit limpio.
- “Cumplido” significa que el entregable existe **y** está integrado/verificado; un archivo aislado se marca como parcial.