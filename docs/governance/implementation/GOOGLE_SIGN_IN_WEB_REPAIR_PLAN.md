# GOOGLE SIGN-IN WEB — REPAIR PLAN

## Causa
La pantalla blanca en Flutter Web localhost:8080 se debe a una excepción no capturada en el plugin `google_sign_in_web` versión 0.12.4+4. La excepción ocurre porque falta la configuración del `clientId` (App Client ID) para OAuth de Google en entorno web.

Specíficamente:
- Assertion failed: `appClientId != null` 
- Mensaje: "ClientID not set. Either set it on a <meta name=\"google-signin-client_id\" content=\"CLIENT_ID\" /> tag, or pass clientId when initializing GoogleSignIn"
- Ubicación: `google_sign_in_web.dart:144:9`
- Impacto: Detiene la ejecución de la aplicación Dart antes de que se renderice el primer frame → pantalla blanca

## Configuración actual
Archivo: `frontend/lib/screens/auth/login_screen.dart`
Líneas: 25-28

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  serverClientId: '466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com',
);
```

Observaciones:
- Se está configurando `serverClientId` (que es el Web Client ID utilizado en el backend para validar tokens)
- FALTA el parámetro `clientId` (que es el OAuth Client ID específico para el cliente web)
- El flujo de autenticación ya distingue entre web y móviles mediante `kIsWeb` (línea 80)
- En móviles (no web) se ejecuta el flujo interactivo de Google Sign-In
- En web actualmente se usa un token hardcodeado: `'test_google_token_usuario_pruebas'` (línea 77)

## Client ID encontrado
Sí existe un Client ID configurado:
- Valor: `'466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com'`
- Ubicación: Mismo lugar que `serverClientId` en la inicialización de GoogleSignIn
- Tipo: Este es un Web OAuth Client ID (termina en `.apps.googleusercontent.com`)
- Uso actual: Se está usando incorrectamente como `serverClientId` cuando debería ser el `clientId` para web

Nota: No se revelan credenciales sensibles en este plan, pero el valor ya está presente en el código fuente.

## Archivo responsable
`frontend/lib/screens/auth/login_screen.dart`
- Línea 25-28: Inicialización de GoogleSignIn
- Línea 71-117: Método `_handleGoogleSignIn()`
- Línea 80: Condicional `if (!kIsWeb)` que separa lógica web vs móvil

## Inicialización actual
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  serverClientId: '466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com',
);
```

Esta configuración:
- Funciona en Android/iOS porque usa el flujo nativo de Google Sign-In
- Falla en web porque el plugin `google_sign_in_web` requiere el `clientId` explícito
- Actualmente en web evita el flujo real usando un token hardcodeado (línea 77)

## Reparación recomendada
Modificar la inicialización de GoogleSignIn para incluir el `clientId` cuando se está en web, manteniendo la configuración existente para móviles.

Opción 1 (Recomendada - Configuración explícita por plataforma):
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  serverClientId: '466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com',
  // Para web: clientId es requerido por google_sign_in_web
  clientId: kIsWeb 
      ? '466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com'
      : null,
);
```

Opción 2 (Alternativa - Meta tag en index.html):
Agregar en `frontend/web/index.html` dentro de `<head>`:
```html
<meta name="google-signin-client_id" content="466897054371-qaec2ipcc0pea91obs0ejcb9tene7kma.apps.googleusercontent.com">
```

**Se recomienda la Opción 1** porque:
- Mantiene la configuración centralizada en el código
- No requiere modificar archivos externos
- Respeta la arquitectura existente que ya distingue plataformas con `kIsWeb`
- Es más transparente y fácil de mantener
- No introduce dependencias de orden de carga de scripts

## Archivos a modificar
Únicamente:
- `frontend/lib/screens/auth/login_screen.dart` (líneas 25-28)

## Archivos que NO deben modificarse
- `frontend/web/index.html` (a menos que se elija la Opción 2)
- Cualquier archivo de backend o servicios
- Archivos de tema, diseño o componentes UI
- Archivos de documentación o governance
- Arquivos de prueba
- Configuraciones de Firebase u otros providers
- `pubspec.yaml` o `pubspec.lock`

## Riesgos
1. **Riesgo bajo**: Solo se agrega un parámetro existente a una inicialización ya presente
2. **No afecta Android/iOS**: El `clientId` se establece en `null` para móviles, manteniendo el comportamiento actual
3. **No afecta otros providers**: Solo modifica la configuración de Google Sign-In
4. **No hay riesgo de exponer credenciales**: El Client ID ya está en el código y es público por naturaleza (se expone en las aplicaciones web de todos modos)
5. **Compatible con SOUL y Governance**: No afecta reglas visuales, theming o arquitectura de componentes
6. **No afecta navegación o flujo de login**: Solo habilita la autenticación real de Google en web

## Validación posterior
Después de aplicar la reparación (cuando se autorice):
1. ✅ `flutter test` - Deben seguir pasando todas las pruebas (8 passed, 0 failed)
2. ✅ `flutter analyze` - No se deben introducir nuevos errores
3. ✅ `flutter build web --release` - Debe construir exitosamente
4. ✅ Verificar en navegador: 
   - La pantalla blanca debe desaparecer
   - Debería mostrarse la pantalla de login de GlowApp
   - Al hacer click en "Google" debería iniciar el flujo real de OAuth de Google
   - No debería haber errores en la consola relacionados con `appClientId`
5. ✅ Verificar que el flujo de login con credenciales tradicionales siga funcionando
6. ✅ Verificar que los proveedores Outlook y Apple sigan funcionando (usando el flujo mock actual)

## Plan de rollback
Dado que el cambio es mínimo y específico:
1. Revertir únicamente las líneas 25-28 en `frontend/lib/screens/auth/login_screen.dart` a su estado anterior
2. O bien, eliminar el parámetro `clientId` agregado
3. El rollback es inmediato y no afecta otras funcionalidades
4. No requiere cambios en dependencias ni configuraciones externas
5. Las pruebas existentes servirán para validar que el rollback restauró el estado anterior (con pantalla blanca en web pero sin romper otras plataformas)

---
**NOTA**: Este plan es exclusivamente para análisis y propuesta. **NO SE HA MODIFICADO NINGÚN ARCHIVO** siguiendo las instrucciones de la tarea.

REPARACIÓN PROPUESTA — SIN MODIFICACIONES