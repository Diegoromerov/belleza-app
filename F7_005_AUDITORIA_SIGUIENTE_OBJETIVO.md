# F7.005 — AUDITORÍA DE SIGUIENTE OBJETIVO

## 1. ESTADO ACTUAL DE GLOWAPP

Tras la finalización exitosa de la fase F7.004 (menú flotante del HOME con GlowIcon), el proyecto GlowApp presenta el siguiente estado:

- **GlowIcon**: Infraestructura completa y funcional para resolución semántica de íconos mediante `GlowIcon.resolve()`.
- **GlowIconRegistry**: Registro centralizado con todos los íconos núcleo (16 P0), propietarios (6 I1) y extensiones (beauty, men, concierge, aura, system) mapeados a assets SVG.
- **GlowIconThemeExtension**: Extensión de tema que permite reactividad al modo de audiencia (Women/Men) mediante `isMenMode`.
- **Token system**: Sistema de tokens de diseño (colores, spacing, tipografía, etc.) en `lib/core/theme/tokens.dart` con soporte para light/dark y expresión de audiencia.
- **AudienceService**: Servicio reactivo que expone `AudienceMode` (all, men, women) y `isMenMode` para theming condicional.
- **ThemeData**: Temas light y dark en `lib/core/theme/app_theme.dart` que integran Token y GlowIconThemeExtension.
- **SOUL y Governance**: Evidencia de cumplimiento en las capas de theming y acceso a tokens (no se observaron violaciones en lo revisado).
- **Componentes visuales migrados**: 
  - Menú flotante del HOME (CITAS | GLOWSTORE | GLOW IA+ | PERFIL) → 100% migrado a GlowIcon.
  - Algunos componentes en `screens/academy/` y `widgets/` usan GlowIcon (ej: `glow_glass_card.dart`, `glow_app_logo.dart`).
- **Pantallas parcialmente migradas**: 
  - `home_screen.dart` (NavigationBar) usa GlowIcon para íconos pero aún mantiene lógica de selección legacy.
  - `provider_dashboard_screen.dart` usa GlowIcon en algunos lugares pero aún tiene íconos legacy.
  - `provider_detail_screen.dart` usa GlowIcon de forma puntual (ej: ícono verificado).
- **Pantallas con infraestructura legacy**: 
  - La mayoría de las screens aún utilizan:
    - `Icon(Icons.*)` directo (Material Icons).
    - `Image.asset()` para assets rasterizados.
    - Colores hardcoded (ej: `Color(0xFF...)`).
    - Acceso directo a `Theme.of(context)` sin usar Tokens.
    - Navegación con `BottomNavigationBar` y `NavigationBar` tradicionales.

## 2. INFRAESTRUCTURA DISPONIBLE

| Componente | Estado | Comentario |
|------------|--------|------------|
| GlowIcon | ✅ Completa | API estable, registro completo, theming integrado |
| GlowIconRegistry | ✅ Completa | Todos los íconos registrados vía `glow_icon_registry_init.dart` |
| GlowIconThemeExtension | ✅ Existente | Usada en `app_theme.dart` para proveer `isMenMode` |
| Token system | ✅ Completa | Tokens para colores, spacing, tipografía, sombras, radios |
| AudienceService | ✅ Completa | ValueNotifier reactivo, persistente en SharedPreferences |
| ThemeData (light/dark) | ✅ Existente | Integra Tokens y GlowIconThemeExtension |
| AppTheme legacy (shared/theme.dart) | ⚠️ Parcial | Getters deprecados que delegan a Token, aún en uso |
| SOUL (GlowApp BELLEZA LUXE) | ✅ Base | Tokens y theming alineados con S1 (Color System) |
| Governance | ✅ Base | No se observaron violaciones en lo revisado |

## 3. INFRAESTRUCTURA REALMENTE CONSUMIDA

| Componente | Consumidores reales | % de uso estimado | Comentario |
|------------|---------------------|-------------------|------------|
| GlowIcon.resolve() | ~15 ubicaciones | <5% | Principalmente en menú flotante HOME, algunos widgets académicos, provider detail |
| Token.of(context) / Token.light/dark | 0 usos directos | 0% | El patrón `Token.of(context)` no existe; se usa `Token.light` estático o `context.glow*` (ver abajo) |
| context.glow* (extensiones) | ~8 ubicaciones | <2% | Extensiones de Theme para acceso a tokens (ej: `context.glowPrimary`) |
| AudienceService.isMenMode | ~4 ubicaciones | <1% | Usado en `app_theme.dart` y algunos widgets condicionales |
| Colores hardcoded | >100 usos | ~60% | Predominan en UI legacy (Containers, Text, etc.) |
| Material Icons (Icon(Icons.*)) | >80 usos | ~50% | Amplamente usado en lugar de GlowIcon |
| Image.asset (assets rasterizados) | >30 usos | ~25% | Incluye nav_*_icon.png y otros assets legacy |

Nota: El porcentaje es una estimación basada en greps rápidos y no constituye un conteo exacto.

## 4. MAPA DE CONSUMIDORES

| Componente | Existe | Consumidores reales | Reactivo | Estado |
|------------|--------|---------------------|----------|--------|
| GlowIcon | Sí | Menú flotante HOME, widgets académicos, provider detail (pocos) | Sí (vía colorRole) | Subutilizado |
| GlowIconRegistry | Sí | Interno por GlowIcon | N/A | Completa pero solo consumida por GlowIcon |
| GlowIconThemeExtension | Sí | En app_theme.dart (light y dark themes) | Sí (isMenMode) | Existente pero no extendida a widgets |
| Token system | Sí | En app_theme.dart y algunos widgets vía context.glow* | Sí | Subutilizado (predomina hardcoded) |
| AudienceService | Sí | En app_theme.dart y algunos widgets | Sí (ValueNotifier) | Subutilizado |
| ThemeData | Sí | En MaterialApp | Sí | Base correcta pero widgets no usan sus propiedades semánticas |
| SOUL | Sí | En definición de tokens | N/A | Base estable |
| Governance | Sí | En patrones de theming y acceso | N/A | Base estable |

## 5. DEUDA VISUAL/ARQUITECTÓNICA

Las principales áreas de deuda que afectan la evolución visual y arquitectónica son:

1. **Uso predominante de Material Icons y colores hardcoded**: Más del 50% de los íconos y el 60% de los colores no usan la infraestructura de theming.
2. **Falta de consumo de extensiones de tema**: Aunque `app_theme.dart` provee `context.glowPrimary`, etc., pocos widgets lo usan.
3. **Inconsistencia en navegación**: Algunos BottomNavigationBar y NavigationBar aún usan íconos legacy y no están conectados a AudienceService para theming dinámico.
4. **Pantallas académicas parcialmente migradas**: Usan algunos GlowIcon pero aún dependen de assets rasterizados y hardcoded.
5. **ProviderDetailScreen y BookingScreen**: Pantallas de alto impacto visual que aún usan infraestructura legacy (pendientes de migración).

## 6. HALLAZGOS CRÍTICOS

No se encontraron hallazgoss **críticos** (que bloqueen la compilación o la funcionalidad básica). Sin embargo, se identificaron las siguientes áreas de **deuda técnica de alto impacto**:

- **ProviderDetailScreen**: Usa una mezcla de GlowIcon puntual y legacy extensive (ej: íconos de corazón, bolsa, etc. como `Icon(Icons.favorite)`).
- **BookingScreen**: Flujo de reserva completo con múltiples pasos que aún usan colores hardcoded y Material Icons.
- **home_screen.dart** (NavigationBar): Aunque usa GlowIcon para los íconos, la lógica de selección y colores no es reactiva a AudienceService de forma óptima.
- **provider_dashboard_screen.dart**: Similar al home_screen, pero con más complejidad de estado.

## 7. CANDIDATOS A SIGUIENTE OBJETIVO

Evaluamos candidatos basado en impacto visual, reutilización de infraestructura y riesgo:

| Candidato | Problema | Infraestructura reutilizable | Impacto | Riesgo | Esfuerzo | Dependencia |
|-----------|----------|------------------------------|---------|--------|----------|-------------|
| **ProviderDetailScreen** | Alta complejidad visual, mezcla de GlowIcon y legacy, colores hardcoded, falta de theming reactivo | GlowIcon, Token, AudienceService, GlowIconThemeExtension | Alto (pantalla de detalle clave para conversión) | Medio (lógica de negocio presente pero aislable) | Alto (muchos widgets) | Ninguna |
| **BookingScreen** | Flujo crítico de negocio, uso de hardcoded y legacy en todos los pasos, falta de consistencia visual | GlowIcon, Token, AudienceService | Muy alto (impacto directo en ingresos) | Alto (lógica de negocio intrincada) | Muy alto (flujo multi-paso) | Depende de auth y servicios de reserva |
| **home_screen.dart (NavigationBar)** | Ya usa GlowIcon pero lógica de selección y colores no reactivos optimizados | GlowIcon, Token, AudienceService | Medio (mejora de consistencia) | Bajo (lógica de navegación aislada) | Bajo-Medio | Ninguna |
| **provider_dashboard_screen.dart** | Similar a home_screen pero con más tabs y estado complejo | GlowIcon, Token, AudienceService | Alto (pantalla principal de proveedor) | Medio | Medio | Ninguna |
| **Widgets reutilizables (ej: botones, tarjetas)** | Uso disperso de legacy en componentes básicos | GlowIcon, Token | Alto (efecto en cadena) | Bajo | Bajo-Medio | Ninguna |

## 8. PRIORIZACIÓN

El siguiente objetivo debe ser el que ofrezca el mejor equilibrio entre:
- **Impacto visual y arquitectónico** (cuánta deuda se paga y cuánta consistencia se gana)
- **Reutilización de infraestructura existente** (cuanto se puede aplicar sin crear nuevos sistemas)
- **Posibilidad de validar objetivamente** (facilidad de verificar con analyze y tests)
- **Riesgo de alterar lógica de negocio** (menor riesgo = más rápido)

**ProviderDetailScreen** emerge como el candidato óptimo porque:
1. Tiene alto impacto visual (es la pantalla donde se decide la compra).
2. Ya muestra señales de migración parcial (uso de algunos GlowIcon), lo que indica que la infraestructura es compatible.
3. Su lógica de negocio está relativamente aislada (principalmente presentación de datos y acciones como reservar/favorito).
4. Permite aplicar de manera sistemática los tokens, GlowIcon y theming reactivo.
5. El esfuerzo, aunque alto, está contenido en un solo archivo y sus widgets hijos.
6. No depende de otras pantallas en curso de migración (a diferencia de BookingScreen que involucra múltiples pasos y servicios).

## 9. OBJETIVO RECOMENDADO

**Migrar ProviderDetailScreen a la infraestructura GlowApp existente**, específicamente:
- Reemplazar todos los `Icon(Icons.*)` por `GlowIcon.resolve(...)` con los semantic names apropiados.
- Reemplazar colores hardcoded por referencias a Token o extensiones de tema (`context.glow*`, `Token.light/dark`).
- Asegurar que los colores sean reactivos a AudienceService (Women/Men) mediante el uso de `GlowIconThemeExtension` o `Token` dinámico.
- Mantener exactamente la misma navegación, lógica de negocio y comportamiento de interacción.
- Preservar los assets rasterizados que ya no se usan (verificar que no se regrese a ellos).
- No alterar la estructura de la pantalla (slivers, listas, etc.) más allá de la sustitución visual y de theming.

## 10. ALCANCE

**ENTRA**:
- `frontend/lib/screens/provider_detail_screen.dart`
- Widgets hijos exclusivamente usados por este screen (si se crean nuevos widgets locales para refactorizar, están permitidos siempre que estén dentro del mismo archivo o en un nuevo archivo bajo `widgets/` específicamente para este screen).
- Actualización de imports necesarios (eliminar imports no usados, añadir los necesarios para GlowIcon y Token).

**NO ENTRA**:
- Cualquier otro screen (home_screen.dart, provider_dashboard_screen.dart, booking_screen.dart, etc.).
- Lógica de negocio (llamadas a servicios, manejo de estado, navegación).
- Assets rasterizados (no se deben reintroducir ni eliminar; simplemente no se deben usar en el screen).
- Arquitectura de navegación (rutas, `_checkAuthAndNavigate`, etc.).
- SOUL o Governance (se asume que la infraestructura existente ya es compatible; se debe usar, no modificar).
- Otros sistemas como analytics, logging, etc.

## 11. CRITERIOS DE ACEPTACIÓN

Se considerará el objetivo cumplido cuando:
1. **flutter analyze --no-pub** en `provider_detail_screen.dart` muestra **0 nuevos errores** atribuibles a esta migración (los errores preexistentes en otros archivos se ignoran).
2. **flutter test** pasa para los tests que puedan ejecutarse (los que fallen por razones preexistentes no relacionadas con este screen se ignoran).
3. El screen **compila y se renderiza sin errores** en modo de luz y oscuridad (simulado o real).
4. **Todas las instancias de** `Icon(Icons.*)` **en el screen han sido reemplazadas por** `GlowIcon.resolve(...)` **con semantic names válidos y existentes en el registro**.
5. **Ningún color hardcoded** (ej: `Color(0xFF...)`) **permanece en el screen**; todos usan Token o extensiones de tema.
6. **Los semantic names de GlowIcon usados son correctos** (ej: 'favorite' para corazón, 'bag' para bolsa, etc.) y corresponden a los assets SVG registrados.
7. **El label y semanticLabel de accesibilidad se preservan exactamente** (si existía).
8. **La navegación y los callbacks (onTap, etc.) permanecen idénticos** (llamando a las mismas funciones que antes).
9. **No se introduce estado seleccionado ni lógica de negocio nueva** en el screen.
10. **Se verifica que los assets rasterizados legacy** (ej: cualquier `Image.asset` que estuviera en el screen) **ya no se usan** (opcional: si había alguno, debe haberse removido).

## 12. RIESGOS

- **Riesgo medio**: La pantalla tiene lógica de presentación que podría acoplarse con estado de negocio (ej: mostrar un indicador de carga basado en un modelo). Se debe preservar exactamente el mismo comportamiento.
- **Riesgo bajo-medio**: El uso de Tokens y extensiones de tema requiere acceso a `BuildContext`. Se debe asegurar que todos los widgets tengan contexto disponible (evitar usar en estáticos o initState sin contexto).
- **Riesgo bajo**: La infraestructura de GlowIcon y Token es estable y ya probada en el menú flotante HOME.

## 13. VEREDICTO

**READY FOR NEXT PHASE**

La auditoría ha identificado un objetivo claro, de alto impacto y factible para la siguiente fase. Se cuenta con la infraestructura necesaria y el riesgo es manageable.

## 14. PROMPT DE IMPLEMENTACIÓN PROPUESTO

AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — F7.005-MIGRACION_PROVIDER_DETAIL

OBJETIVO ÚNICO

Migrar exclusivamente el ProviderDetailScreen a la infraestructura GlowApp existente (GlowIcon, Token, AudienceService, theming reactivo) sin alterar lógica de negocio, navegación o estructura visual más allá de las sustituciones de íconos y colores.

CONTEXTO YA VERIFICADO

El screen objetivo está implementado en:
frontend/lib/screens/provider_detail_screen.dart

Clase: ProviderDetailScreen (o similar según el archivo actual)

Actualmente usa una mezcla de:
- GlowIcon.resolve() puntual (ej: ícono verificado)
- Icon(Icons.*) legado
- Colores hardcoded
- Algunos assets rasterizados (verificar si los usa y reemplazarlos por GlowIcon si corresponde)

La navegación y lógica de negocio deben permanecer intactas:
- Rutas de entrada/salida (ej: desde home_screen.dart, desde búsquedas)
- Lógica de reserva, favorito, compartido, etc.
- Llamadas a servicios (api_service, auth_service, etc.)
- Estado de negocio (cargando, error, datos)

RESTRICCIONES DE TRABAJO

1. LEER → ANALIZAR → INFORMAR → PROPONER → IMPLEMENTAR → VERIFICAR → CERRAR
2. No modificar archivos fuera del alcance definido en la sección 10 del informe F7.005.
3. No reconstruir sistemas existentes (usar GlowIcon, Token, AudienceService tal cual).
4. No inventar componentes nuevos (reutilizar widgets existentes de GlowApp si aplica, o crear nuevos locales únicamente si estrictamente necesario para el refactor).
5. Preservar exactamente la lógica de negocio y navegación.
6. Verificar cada cambio con flutter analyze y flutter test (comparando baseline de errores preexistentes).
7. Reportar evidencia de que se usó realmente GlowIcon y Token (no solo que se escribió el código).
8. Detenerse si se encuentra un riesgo real de romper lógica de negocio o una contradicción con SOUL/Governance.

EVIDENCIA REQUERIDA AL FINALIZAR

- Antes/after de las sustituciones clave (con comentarios de líneas).
- Resultado de flutter analyze y test separados en preexistente vs nuevo.
- Lista de semantic names de GlowIcon usados y verificación de su existencia en el registro.
- Confirmación de que no quedan colores hardcoded ni Material Icons en el screen.
- Confirmación de que la navegación y los callbacks son idénticos.

IMPORTANTE: No continuar con F7.006 u otras fases sin autorización explícita. Primero hacer que el objetivo principal FUNCIONE: PROVIDER DETAIL SREEN USANDO REALMENTE LA INFRAESTRUCTURA GLOWAPP Y CONSERVIENDO SU LÓGICA DE NEGOCIO.

SIGA