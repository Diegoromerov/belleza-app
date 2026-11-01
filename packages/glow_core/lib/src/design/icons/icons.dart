/// GlowIcon System — Barrel Export
///
/// Migrado desde el monolito (`lib/design/icons.dart`), que exportaba los
/// mismos cinco archivos. En el split viven en `src/design/icons/`, así que el
/// barrel solo ajusta las rutas relativas.
///
/// Importa este archivo para acceder a todo el sistema GlowIcon:
///
///   import 'package:glow_core/src/design/icons/icons.dart';
///
/// O selectivamente:
///
///   import 'package:glow_core/src/design/icons/glow_icon.dart';
///   import 'package:glow_core/src/design/icons/glow_icon_registry.dart';
///   import 'package:glow_core/src/design/icons/glow_icon_registry_init.dart';
///   import 'package:glow_core/src/design/icons/glow_icon_adapter.dart';
///   import 'package:glow_core/src/design/icons/glow_icon_demo.dart';
library glow_icons;

export 'glow_icon.dart';
export 'glow_icon_registry.dart';
export 'glow_icon_registry_init.dart';
export 'glow_icon_adapter.dart';
export 'glow_icon_demo.dart';
