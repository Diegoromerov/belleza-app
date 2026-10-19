import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/booking_screen.dart';
import 'package:beauty_app/shared/theme.dart';
import 'package:beauty_app/shared/app_tokens.dart';
import '../test_helpers.dart';

class TestMockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return TestMockHttpClient();
  }
}

class TestMockHttpClient implements HttpClient {
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => TestMockHttpClientRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => TestMockHttpClientRequest(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestMockHttpClientRequest implements HttpClientRequest {
  final Uri url;
  TestMockHttpClientRequest(this.url);

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = false;

  @override
  bool bufferOutput = true;

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    await stream.drain();
  }

  @override
  HttpHeaders get headers => TestMockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return TestMockHttpClientResponse(url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestMockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestMockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri url;
  TestMockHttpClientResponse(this.url);

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _getResponseBody().length;

  @override
  bool get persistentConnection => false;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpHeaders get headers => TestMockHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final bytes = _getResponseBody();
    return Stream<List<int>>.value(bytes).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  List<int> _getResponseBody() {
    final path = url.path;
    if (path.contains('/slots')) {
      return utf8.encode(jsonEncode({
        'success': true,
        'slots': [
          {'time': '09:00', 'is_available': true},
          {'time': '10:30', 'is_available': true},
          {'time': '14:00', 'is_available': true},
          {'time': '16:30', 'is_available': false}
        ]
      }));
    } else if (path.contains('/products')) {
      return utf8.encode(jsonEncode({
        'success': true,
        'data': [
          {
            'id': 101,
            'nombre': 'Tratamiento Reparador Intenso',
            'precio': 35000.0,
            'stock': 10,
            'imagen_url': '',
            'tag_especialidad': 'Cabello'
          },
          {
            'id': 102,
            'nombre': 'Óleo Nutritivo Glow',
            'precio': 22000.0,
            'stock': 15,
            'imagen_url': '',
            'tag_especialidad': 'Cabello'
          }
        ]
      }));
    }
    return const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = TestMockHttpOverrides();
    setupFlutterSecureStorageMock();
  });

  tearDownAll(() {
    resetFlutterSecureStorageMock();
  });

  testWidgets('Flujo de pasos con sticky summary y verificación de selección de producto', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Manrope',
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primary),
        ),
        home: const BookingScreen(
          providerId: 'test-provider',
          services: [
            {
              'id': 'srv-1',
              'name': 'Corte y Cepillado Profesional',
              'price': 45000,
              'duration': 45,
              'category': 'Cabello'
            }
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verificar Paso 1: Cuándo y Dónde (Servicios y calendario)
    expect(find.text('1. Selecciona un Servicio'), findsOneWidget);
    expect(find.text('2. Elige una Fecha (Calendario)'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long), findsOneWidget);

    // El sticky summary inicial debe mostrar total $0.00
    expect(find.text('\$0.00'), findsOneWidget);

    // Avanzar al Paso 2: Dirección y Notas
    final continueBtn = find.widgetWithText(ElevatedButton, 'Continuar');
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    expect(find.text('4. Dirección del servicio'), findsOneWidget);

    // Rellenar dirección habitual
    await tester.tap(find.text('📍 Usar dirección habitual (Casa)'));
    await tester.pumpAndSettle();

    // Avanzar al Paso 3: Productos (Cross-Selling)
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    expect(find.text('Completa tu experiencia'), findsOneWidget);

    // Buscar el botón 'Añadir' en los productos recomendados
    final addProductBtn = find.widgetWithText(ElevatedButton, 'Añadir').first;
    expect(addProductBtn, findsOneWidget);

    // Tap en añadir producto
    await tester.tap(addProductBtn);
    await tester.pumpAndSettle();

    // El sticky summary debe reflejar el precio del producto añadido ($35000.00)
    expect(find.text('\$35000.00'), findsOneWidget);

    // Avanzar al Paso 4: Confirmación y Pago
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    expect(find.text('\$35000.00'), findsOneWidget);
  });

  testWidgets('Sticky summary color token matches AppTokens.stickySummaryBg', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const BookingScreen(
          providerId: 'test-provider',
          services: [
            {
              'id': 'srv-1',
              'name': 'Corte y Cepillado',
              'price': 45000,
              'duration': 45,
              'category': 'Cabello'
            }
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final containerFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == AppTokens.stickySummaryBg;
      }
      return false;
    });

    expect(containerFinder, findsOneWidget);
  });
}
