// tool/generate_firebase_sw.dart
//
// Genera web/firebase-messaging-sw.js a partir de variables de ENTORNO.
//
// Por que se genera y no se versiona: el service worker es JavaScript plano y no
// puede leer --dart-define, pero los valores tampoco pueden vivir en el repo
// (la compuerta bloqueante verifyNoVersionedSecrets.js prohibe claves AIza...).
// Generarlo en el build resuelve las dos cosas.
//
// Uso:
//   FIREBASE_API_KEY=... FIREBASE_PROJECT_ID=... FIREBASE_MESSAGING_SENDER_ID=...
//   FIREBASE_WEB_APP_ID=... dart run tool/generate_firebase_sw.dart
//
// Si la configuracion esta incompleta NO rompe el build: avisa y no escribe nada,
// para no bloquear despliegues. La app avisa ruidosamente en tiempo de ejecucion
// (ver lib/firebase_options.dart).

import 'dart:convert';
import 'dart:io';

const _salida = 'web/firebase-messaging-sw.js';

// Debe ir alineada con la version del SDK web que trae firebase_core.
const _versionSdkJs = '10.12.2';

void main() {
  final env = Platform.environment;
  final apiKey = env['FIREBASE_API_KEY'] ?? '';
  final projectId = env['FIREBASE_PROJECT_ID'] ?? '';
  final senderId = env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  final appId = env['FIREBASE_WEB_APP_ID'] ?? '';
  final bucketEnv = env['FIREBASE_STORAGE_BUCKET'] ?? '';

  final faltan = <String>[
    if (apiKey.isEmpty) 'FIREBASE_API_KEY',
    if (projectId.isEmpty) 'FIREBASE_PROJECT_ID',
    if (senderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
    if (appId.isEmpty) 'FIREBASE_WEB_APP_ID',
  ];

  if (faltan.isNotEmpty) {
    stdout.writeln('WARN no se genera $_salida: faltan ${faltan.join(', ')}.');
    stdout.writeln('     El push web quedara deshabilitado; la app lo avisa en consola.');
    return;
  }

  final bucket = bucketEnv.isNotEmpty ? bucketEnv : '$projectId.appspot.com';

  final contenido = '''
// GENERADO por tool/generate_firebase_sw.dart -- NO EDITAR A MANO.
// Se regenera en cada build y no se versiona (ver .gitignore).
importScripts('https://www.gstatic.com/firebasejs/$_versionSdkJs/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/$_versionSdkJs/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: ${jsonEncode(apiKey)},
  appId: ${jsonEncode(appId)},
  messagingSenderId: ${jsonEncode(senderId)},
  projectId: ${jsonEncode(projectId)},
  authDomain: ${jsonEncode('$projectId.firebaseapp.com')},
  storageBucket: ${jsonEncode(bucket)}
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notif = payload.notification || {};
  const data = payload.data || {};
  self.registration.showNotification(notif.title || 'Glow App', {
    body: notif.body || '',
    icon: '/android-chrome-192x192.png',
    badge: '/android-chrome-192x192.png',
    data: data
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const destino = data.url || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((ventanas) => {
      for (const v of ventanas) {
        if (v.url.indexOf(self.location.origin) === 0 && 'focus' in v) return v.focus();
      }
      if (clients.openWindow) return clients.openWindow(destino);
      return null;
    })
  );
});
''';

  File(_salida).writeAsStringSync(contenido);
  stdout.writeln('OK $_salida generado (${contenido.length} bytes)');
}
