// E-06 (D-GL-027) — Deep links: el parseo es puro, así que se prueba sin app.
import 'package:beauty_app/core/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('seccionDeUri', () {
    test('reconoce el esquema beautyapp con segmentos', () {
      expect(seccionDeUri(Uri.parse('beautyapp://salon/caja')), 'caja');
      expect(seccionDeUri(Uri.parse('beautyapp://salon/agenda')), 'agenda');
      expect(seccionDeUri(Uri.parse('beautyapp://salon/equipo')), 'equipo');
    });

    test('reconoce el query y el fragmento', () {
      expect(seccionDeUri(Uri.parse('https://glowapp.co/salon?seccion=caja')), 'caja');
      expect(seccionDeUri(Uri.parse('/salon?tab=equipo')), 'equipo');
      expect(seccionDeUri(Uri.parse('/salon#servicios')), 'servicios');
    });

    test('tolera prefijos en el camino', () {
      expect(seccionDeUri(Uri.parse('https://glowapp.co/app/salon/caja')), 'caja');
    });

    test('traduce los alias que la gente escribe', () {
      expect(seccionDeUri(Uri.parse('beautyapp://salon/reservas')), 'agenda');
      expect(seccionDeUri(Uri.parse('beautyapp://salon/staff')), 'equipo');
      expect(seccionDeUri(Uri.parse('beautyapp://salon/pagos')), 'caja');
      expect(seccionDeUri(Uri.parse('beautyapp://salon/config')), 'mas');
    });

    test('no inventa sección cuando el enlace no la tiene', () {
      expect(seccionDeUri(Uri.parse('beautyapp://salon')), isNull);
      expect(seccionDeUri(Uri.parse('beautyapp://pedidos/123')), isNull);
      expect(seccionDeUri(Uri.parse('https://glowapp.co/')), isNull);
      expect(seccionDeUri(Uri.parse('beautyapp://salon/xyz')), isNull);
    });
  });

  group('indiceDeEnlace', () {
    test('mapea a la posición de la pestaña en el shell', () {
      expect(indiceDeEnlace('beautyapp://salon/agenda'), 0);
      expect(indiceDeEnlace('beautyapp://salon/caja'), 1);
      expect(indiceDeEnlace('beautyapp://salon/equipo'), 2);
      expect(indiceDeEnlace('beautyapp://salon/servicios'), 3);
      expect(indiceDeEnlace('beautyapp://salon/mas'), 4);
    });

    test('un enlace roto no rompe la navegación', () {
      expect(indiceDeEnlace('no es una uri'), isNull);
      expect(indiceDeEnlace(''), isNull);
      expect(indiceDeEnlace('beautyapp://salon/inexistente'), isNull);
    });

    test('el orden de secciones es el contrato del shell', () {
      expect(seccionesSalon, ['agenda', 'caja', 'equipo', 'servicios', 'mas']);
    });
  });
}
