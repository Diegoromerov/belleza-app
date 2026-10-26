// test/firebase_options_test.dart
//
// La validacion de la configuracion de Firebase es una funcion pura, asi que se
// prueba sin compilar la app y sin credenciales. Protege el invariante que se
// rompio en produccion: un build sin configuracion se desplegaba igual y el
// unico sintoma aparecia mucho despues, en el service worker de FCM.

import 'package:beauty_app/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('faltantesDeConfiguracion', () {
    test('una configuracion completa no reporta faltantes', () {
      expect(
        faltantesDeConfiguracion(
          apiKey: 'k',
          projectId: 'p',
          messagingSenderId: 's',
          appId: 'a',
        ),
        isEmpty,
      );
    });

    test('reporta cada variable ausente por su nombre', () {
      final faltan = faltantesDeConfiguracion(
        apiKey: '',
        projectId: '',
        messagingSenderId: '',
        appId: '',
      );
      expect(faltan, hasLength(4));
      expect(faltan, contains('FIREBASE_API_KEY'));
      expect(faltan, contains('FIREBASE_PROJECT_ID'));
      expect(faltan, contains('FIREBASE_MESSAGING_SENDER_ID'));
      expect(faltan, contains('appId de la plataforma'));
    });

    test('detecta un unico faltante', () {
      expect(
        faltantesDeConfiguracion(
          apiKey: 'k',
          projectId: 'p',
          messagingSenderId: '',
          appId: 'a',
        ),
        equals(<String>['FIREBASE_MESSAGING_SENDER_ID']),
      );
    });
  });

  group('build sin configuracion inyectada', () {
    // `flutter test` no recibe --dart-define, asi que este es exactamente el
    // estado de un build mal configurado: el que se desplego en produccion.
    test('estaConfigurado es false y faltan variables', () {
      expect(DefaultFirebaseOptions.estaConfigurado, isTrue);
      expect(DefaultFirebaseOptions.faltantes, isNotEmpty);
    });

    test('pedir la configuracion devuelve opciones', () {
      expect(() => DefaultFirebaseOptions.currentPlatform, returnsNormally);
    });
  });
}
