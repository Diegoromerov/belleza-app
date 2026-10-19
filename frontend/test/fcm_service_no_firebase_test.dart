// test/fcm_service_no_firebase_test.dart
//
// Regresion del defecto que dejo la web en PANTALLA EN BLANCO.
//
// En un build sin configuracion de Firebase, main() pedia `FcmService.instance`
// antes de `runApp`. Ese acceso construia el singleton, y su campo `_messaging`
// se inicializaba con `FirebaseMessaging.instance`, que busca la app '[DEFAULT]'
// y lanza [core/no-app] si no existe. La excepcion escapaba del runZonedGuarded
// ANTES de `runApp`, asi que la app nunca se dibujaba.
//
// El contrato que fija este test: construir el servicio y pedirle initialize() no
// puede tocar Firebase cuando el build no trae configuracion.

import 'package:beauty_app/firebase_options.dart';
import 'package:beauty_app/services/fcm_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el entorno de test no trae configuracion de Firebase', () {
    // Si esto fallara, los dos casos de abajo dejarian de probar lo que creen.
    expect(DefaultFirebaseOptions.estaConfigurado, isFalse);
  });

  test('pedir FcmService.instance NO toca Firebase y no lanza', () {
    expect(() => FcmService.instance, returnsNormally);
  });

  test('initialize() completa sin app de Firebase en vez de propagar [core/no-app]',
      () async {
    await expectLater(
      FcmService.instance.initialize(onPayloadTap: (_) async {}),
      completes,
    );
  });
}
