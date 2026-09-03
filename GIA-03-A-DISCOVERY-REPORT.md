# GIA-03-A — Frontend Discovery Report

## 1. OBJETIVO
Inventariar la arquitectura de pantallas, componentes visuales, servicios API, estado local y tokens de diseño SOUL en Flutter (`frontend/lib/`).

## 2. INVENTARIO DE COMPONENTES Y ACTIVOS (E0)
* **Entrada de Biometría Existente:**
  - `screens/ideas/welcome_screen.dart`, `biometric_consent_screen.dart`.
  - `screens/profile/biometric_history_screen.dart`: Visualización previa de registros aislados.
* **Tokens de Diseño SOUL (`core/theme/tokens.dart`, `belleza_luxe_theme.dart`):**
  - Colores fundacionales: `gold871` (`0xFFC5A052`), `creamSilk` (`0xFFFCF8F6`), `auraTeal` (`0xFF164C46`), escala `neutralLight` (`nude50` a `nude900`).
  - Tipografías canónicas: `Didot`, `CormorantGaramond`, `JetBrainsMono`.
* **Capa de Servicios (`services/api_service.dart`):**
  - Manejo de token JWT vía `FlutterSecureStorage` y `SharedPreferences`.
  - Conexión a `https://belleza-app-production.up.railway.app` o servidor local.
* **Componentes Visuales SOUL:**
  - `widgets/s3_hero_image.dart`, `design/components/s4_loading.dart`, `design/components/s4_text_field.dart`, `design/icons/glow_icon.dart`.

## 3. ESTADO DEL GATE
🟢 **PASS**
