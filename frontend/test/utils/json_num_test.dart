import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_app/utils/json_num.dart';

/// El caso real que motivo esto: el checkout de la tienda recibia
/// `{"total": "27350.00"}` (Postgres devuelve `numeric` como String), hacia
/// `as num?`, lanzaba TypeError y el dialogo "Procesando tu pago..." se quedaba
/// colgado para siempre sin abrir la pasarela.

void main() {
  group('toDoubleOrNull', () {
    test('acepta num', () {
      expect(toDoubleOrNull(27350), 27350.0);
      expect(toDoubleOrNull(36998.5), 36998.5);
    });

    test('acepta String numerico (lo que manda Postgres)', () {
      expect(toDoubleOrNull('27350.00'), 27350.0);
      expect(toDoubleOrNull(' 18150 '), 18150.0);
      expect(toDoubleOrNull('36998.50'), 36998.5);
    });

    test('no lanza con valores inservibles: devuelve null', () {
      expect(toDoubleOrNull(null), isNull);
      expect(toDoubleOrNull(''), isNull);
      expect(toDoubleOrNull('abc'), isNull);
      expect(toDoubleOrNull({'a': 1}), isNull);
    });
  });

  group('toDoubleOr', () {
    test('usa el respaldo cuando no se puede convertir', () {
      expect(toDoubleOr(null, 7.5), 7.5);
      expect(toDoubleOr('abc', 0.0), 0.0);
    });

    test('convierte cuando puede, incluido String', () {
      expect(toDoubleOr('43080.00', 0.0), 43080.0);
      expect(toDoubleOr(12, 0.0), 12.0);
    });
  });
}
