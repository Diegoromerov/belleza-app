// E-06 (D-GL-027) — Inventario: el saldo que se ve es el que devuelve la API.
import 'package:beauty_app/screens/salon/inventario_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: child);

const _itemUno = {
  'id': 'i1',
  'nombre': 'Shampoo',
  'categoria': 'INSUMO',
  'unidad': 'LITRO',
  'stock_actual': 1,
  'stock_minimo': 5,
  'stock_bajo': true,
};

const _itemDos = {
  'id': 'i2',
  'nombre': 'Toallas',
  'categoria': 'HERRAMIENTA',
  'unidad': 'UNIDAD',
  'stock_actual': 20,
  'stock_minimo': 5,
  'stock_bajo': false,
};

void main() {
  testWidgets('avisa cuantos insumos estan en o bajo el minimo', (tester) async {
    await tester.pumpWidget(_app(const InventarioScreen(
      salonId: 1,
      cargarDatos: false,
      itemsIniciales: [_itemUno, _itemDos],
    )));

    expect(find.textContaining('en o bajo el m'), findsOneWidget);
    expect(find.text('Shampoo'), findsOneWidget);
    expect(find.text('Toallas'), findsOneWidget);
  });

  testWidgets('sin permiso de edicion no hay alta ni boton de movimiento',
      (tester) async {
    await tester.pumpWidget(_app(const InventarioScreen(
      salonId: 1,
      cargarDatos: false,
      itemsIniciales: [_itemUno],
      puedeEditarInicial: false,
    )));

    expect(find.text('Insumo'), findsNothing);
    expect(find.byIcon(Icons.swap_vert_rounded), findsNothing);
    expect(find.text('Shampoo'), findsOneWidget);
  });

  testWidgets('con permiso aparecen el alta y el movimiento', (tester) async {
    await tester.pumpWidget(_app(const InventarioScreen(
      salonId: 1,
      cargarDatos: false,
      itemsIniciales: [_itemUno],
      puedeEditarInicial: true,
    )));

    expect(find.text('Insumo'), findsOneWidget);
    expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
  });

  testWidgets('inventario vacio lo dice, no pinta una tabla vacia',
      (tester) async {
    await tester.pumpWidget(_app(const InventarioScreen(
      salonId: 1,
      cargarDatos: false,
      itemsIniciales: [],
      puedeEditarInicial: true,
    )));

    expect(find.textContaining('Registra el primer insumo'), findsOneWidget);
  });
}
