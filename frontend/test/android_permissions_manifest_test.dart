// frontend/test/android_permissions_manifest_test.dart
//
// FIX-FLUTTER-02 — P1: Android Permisos Sin Description.
// Test de contrato (estático): cada permiso peligroso declarado en el
// AndroidManifest principal DEBE llevar un atributo `android:description`
// apuntando a un string resource, y dicho recurso DEBE existir en
// `android/app/src/main/res/values/strings.xml`.
//
// Reproduce el hallazgo: android/app/src/main/AndroidManifest.xml:3-6 declara
// ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION / RECORD_AUDIO sin
// `android:description` y sin recursos de justificación.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  const stringsPath = 'android/app/src/main/res/values/strings.xml';

  const dangerousPermissions = <String>[
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.RECORD_AUDIO',
  ];

  // CRLF-safe (core.autocrlf=true en Windows).
  String readNormalized(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  test('el manifiesto principal declara los permisos peligrosos', () {
    final manifest = readNormalized(manifestPath);
    for (final p in dangerousPermissions) {
      expect(manifest.contains('android:name="$p"'), isTrue,
          reason: 'Falta declarar $p en el manifiesto');
    }
  });

  test('FIX-FLUTTER-02: cada permiso peligroso tiene android:description', () {
    final manifest = readNormalized(manifestPath);
    for (final p in dangerousPermissions) {
      final re = RegExp(
        r'<uses-permission\s+android:name="' +
            RegExp.escape(p) +
            r'"[^>]*android:description="[^"]+"',
      );
      expect(re.hasMatch(manifest), isTrue,
          reason: '$p no declara android:description (rationale de tienda/OS)');
    }
  });

  test('FIX-FLUTTER-02: strings.xml define cada android:description referenciado',
      () {
    final stringsFile = File(stringsPath);
    expect(stringsFile.existsSync(), isTrue,
        reason: 'Falta el archivo de recursos $stringsPath');

    final manifest = readNormalized(manifestPath);
    final strings = readNormalized(stringsPath);

    final refs = RegExp(r'android:description="@string/([^"]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1)!)
        .toList();

    expect(refs, isNotEmpty,
        reason: 'Ningún permiso declara android:description');

    for (final key in refs) {
      expect(strings.contains('<string name="$key"'), isTrue,
          reason: 'Falta la cadena @string/$key en strings.xml');
    }
  });
}
