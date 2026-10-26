# Integración de Firebase en Beauty‑App

Esta guía describe cómo está configurado **Firebase** en el proyecto `beauty-app` y qué pasos seguir para mantenerlo.

## 1. Configuración de credenciales

- Las credenciales (apiKey, projectId, messagingSenderId, storageBucket y los appIds por plataforma) están **hard‑codeadas** en `lib/firebase_options.dart`.  
- Esto se hizo porque la compilación usa `--dart-define` y el proyecto requiere que los valores reales estén presentes en el bundle sin depender de variables de entorno.
- **No** se deben subir credenciales secretas a repositorios públicos; en este caso el usuario ha provisto los valores explícitamente, por lo que son seguros dentro del repositorio interno.

## 2. Inicialización de Firebase

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```
- La inicialización se realiza de forma **incondicional** dentro de `runZonedGuarded` en `lib/main.dart`.
- La guardia `DefaultFirebaseOptions.estaConfigurado` ahora devuelve `true` porque todas las variables están presentes.

## 3. Uso de `DefaultFirebaseOptions`

- `DefaultFirebaseOptions.currentPlatform` devuelve un objeto `FirebaseOptions` válido para la plataforma actual.
- Si en algún futuro se desea volver a usar variables de entorno, basta con volver a añadir las constantes `String.fromEnvironment` y ajustar los tests.

## 4. Pruebas

- `test/firebase_options_test.dart` verifica que `estaConfigurado` sea `true` y que `currentPlatform` devuelva opciones sin lanzar excepción.
- El resto de la suite de pruebas del proyecto pasa correctamente.

## 5. CI / GitHub Actions

- Se añadió el workflow `.github/workflows/flutter.yml` que se ejecuta en `push` y `pull_request`.
- El workflow ejecuta `flutter pub get`, `flutter test` y `flutter analyze` en un runner Windows.

## 6. Actualización de credenciales

Si necesitas cambiar alguna credencial:
1. Edita los valores en `lib/firebase_options.dart` (líneas 26‑36).
2. Ejecuta `flutter test` para confirmar que todo sigue compilando.
3. Commit & push los cambios.

---
**Nota:** Si decides volver a usar `--dart-define`, elimina los valores hard‑codeados y reinstaura las constantes basadas en `String.fromEnvironment`, ajustando los tests en consecuencia.
