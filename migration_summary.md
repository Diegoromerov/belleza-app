# Migración del Menú Flotante del HOME

## Cambios realizados

1. **Actualización del método `_buildProminentCenterNavItem`**
   - Añadido el parámetro `iconWidget: Widget?` para aceptar widgets de íconos personalizados.
   - Mantenidos los parámetros existentes: `icon`, `assetPath`, `gradientColors`, `shadowColor`, `borderColor`, `label`, `onTap`.
   - El método ahora usa `iconWidget` si está disponible, de lo contrario cae atrás a `assetPath` o `Icon`.

2. **Reemplazo de assetPath por GlowIcon.resolve en los cuatro botones**
   - **Botón 1: Citas**
     - Antes: `assetPath: 'images/nav_citas_icon.png'`
     - Después: `iconWidget: GlowIcon.resolve('calendar', size: 26, colorRole: GlowIconColorRole.neutral, semanticLabel: 'Citas')`
   - **Botón 2: GlowShop**
     - Antes: `assetPath: 'images/nav_glowshop_icon.png'`
     - Después: `iconWidget: GlowIcon.resolve('bag', size: 26, colorRole: GlowIconColorRole.accent, semanticLabel: 'GlowShop')`
   - **Botón 3: Glow IA+**
     - Antes: `assetPath: 'images/glow_ia_mesh_avatar.jpg'`
     - Después: `iconWidget: GlowIcon.resolve('aura', size: 26, colorRole: GlowIconColorRole.aura, semanticLabel: 'Glow IA+')`
   - **Botón 4: Perfil**
     - Antes: `assetPath: 'images/nav_perfil_icon.png'`
     - Después: `iconWidget: GlowIcon.resolve('profile', size: 26, colorRole: GlowIconColorRole.secondary, semanticLabel: 'Perfil')`

3. **Mantenimiento de estilos existentes**
   - Se conservaron los mismos `gradientColors`, `shadowColor`, `label` y `onTap` para cada botón.
   - Se preservó el comportamiento de navegación y la autenticación mediante `_checkAuthAndNavigate`.

## Archivo modificado
- `frontend/lib/main.dart`

## Verificación
- El menú flotante ahora utiliza el sistema de íconos GlowApp ya construido (`GlowIcon.resolve`).
- Se eliminó la dependencia de assets de imagen para estos botones.
- Los íconos utilizados pertenecen al conjunto definido en `GlowIconRegistry`.

## Cumplimiento de requisitos
- ✅ Se usó la infraestructura GlowIcon ya construida.
- ✅ No se modificaron otras navegaciones (HomeScreen NavigationBar, Provider Dashboard, etc.).
- ✅ No se toccaron rutas ni lógica de negocio ajena al menú.
- ✅ Los cambios se limitan exclusivamente al menú flotante con los botones: CITAS | GLOWSTORE | GLOW IA+ | PERFIL.