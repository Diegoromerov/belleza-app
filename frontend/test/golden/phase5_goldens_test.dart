import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/provider_detail_screen.dart';
import 'package:beauty_app/screens/booking_screen.dart';
import 'package:beauty_app/shared/theme.dart';
import '../test_helpers.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => MockHttpClientRequest(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClientRequest implements HttpClientRequest {
  final Uri url;
  MockHttpClientRequest(this.url);

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
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri url;
  MockHttpClientResponse(this.url);

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
  HttpHeaders get headers => MockHttpHeaders();

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
            'id': 'prod-1',
            'nombre': 'Aceite Argan Reparador 100ml',
            'precio': 68000,
            'stock': 5,
            'imagen_url': 'https://example.com/prod1.jpg',
            'tag_especialidad': 'Cabello'
          },
          {
            'id': 'prod-2',
            'nombre': 'Mascarilla Hidratante Intensiva',
            'precio': 85000,
            'stock': 0,
            'imagen_url': 'https://example.com/prod2.jpg',
            'tag_especialidad': 'Cabello'
          }
        ]
      }));
    } else if (path.contains('/providers/')) {
      return utf8.encode(jsonEncode({
        'success': true,
        'data': {
          'provider': {
            'id': 'prov-123',
            'full_name': 'Valeria Gómez',
            'business_name': 'Studio Valeria Gómez',
            'specialty': 'Cabello',
            'ciudad': 'Fontibón',
            'horario': 'Lunes a Sábado: 8:00 AM – 7:00 PM',
            'guarantee_title': 'Garantía y Protocolo GlowApp',
            'guarantee_subtitle': 'Bioseguridad certificada · Pago seguro en custodia',
            'rating': 4.9,
            'reviews_count': 48,
            'bio': 'Especialista en balayage y tratamiento capilar con 8 años de experiencia en Bogotá.',
            'cover_url': '',
            'avatar_url': ''
          },
          'services': [
            {
              'id': 'srv-1',
              'name': 'Balayage Premium',
              'price': 250000,
              'duration': 180,
              'category': 'Cabello',
              'description': 'Aclarado gradual con técnica mano alzada.'
            },
            {
              'id': 'srv-2',
              'name': 'Corte y Cepillado',
              'price': 45000,
              'duration': 45,
              'category': 'Cabello',
              'description': 'Corte y perfilado de puntas maltratadas.'
            }
          ],
          'portfolio': [
            {'id': 'p-1', 'image_url': ''}
          ],
          'reviews': [
            {
              'id': 'r-1',
              'user_name': 'Camila R.',
              'rating': 5,
              'comment': '¡Excelente servicio! Me encantó el balayage.'
            }
          ]
        }
      }));
    }
    // Transparent 1x1 PNG for images
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

  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    setupFlutterSecureStorageMock();

    try {
      final manropeLoader = FontLoader('Manrope');
      manropeLoader.addFont(rootBundle.load('assets/fonts/Manrope-Regular.ttf'));
      manropeLoader.addFont(rootBundle.load('assets/fonts/Manrope-Medium.ttf'));
      manropeLoader.addFont(rootBundle.load('assets/fonts/Manrope-SemiBold.ttf'));
      manropeLoader.addFont(rootBundle.load('assets/fonts/Manrope-Bold.ttf'));
      await manropeLoader.load();

      final cormorantLoader = FontLoader('CormorantGaramond');
      cormorantLoader.addFont(rootBundle.load('assets/fonts/CormorantGaramond-Regular.ttf'));
      cormorantLoader.addFont(rootBundle.load('assets/fonts/CormorantGaramond-Medium.ttf'));
      cormorantLoader.addFont(rootBundle.load('assets/fonts/CormorantGaramond-Bold.ttf'));
      await cormorantLoader.load();

      final jetbrainsLoader = FontLoader('JetBrainsMono');
      jetbrainsLoader.addFont(rootBundle.load('assets/fonts/JetBrainsMono-Medium.ttf'));
      jetbrainsLoader.addFont(rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'));
      await jetbrainsLoader.load();

      final didotLoader = FontLoader('Didot');
      didotLoader.addFont(rootBundle.load('assets/fonts/CormorantGaramond-Bold.ttf'));
      didotLoader.addFont(rootBundle.load('assets/fonts/CormorantGaramond-Regular.ttf'));
      await didotLoader.load();

      final interLoader = FontLoader('Inter');
      interLoader.addFont(rootBundle.load('assets/fonts/Manrope-Regular.ttf'));
      interLoader.addFont(rootBundle.load('assets/fonts/Manrope-Bold.ttf'));
      await interLoader.load();
    } catch (_) {}
  });

  tearDownAll(() {
    resetFlutterSecureStorageMock();
  });

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Manrope',
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primary),
        scaffoldBackgroundColor: AppTheme.background,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Manrope'),
          bodyMedium: TextStyle(fontFamily: 'Manrope'),
          bodySmall: TextStyle(fontFamily: 'Manrope'),
          titleLarge: TextStyle(fontFamily: 'CormorantGaramond'),
          titleMedium: TextStyle(fontFamily: 'CormorantGaramond'),
          titleSmall: TextStyle(fontFamily: 'Manrope'),
          labelLarge: TextStyle(fontFamily: 'Manrope'),
          labelMedium: TextStyle(fontFamily: 'Manrope'),
          labelSmall: TextStyle(fontFamily: 'Manrope'),
        ),
      ),
      home: Scaffold(body: child),
    );
  }

  // Set target folder: 'after' by default, or 'before' if GOLDEN_DIR=before environment variable
  final String goldenFolder = Platform.environment['GOLDEN_DIR'] == 'before' ? 'before' : 'after';

  group('Phase 5 Golden Tests (390x844)', () {
    testWidgets('ProviderDetailScreen - Collapsed State', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(
        const ProviderDetailScreen(providerId: 'prov-123'),
      ));
      await tester.pumpAndSettle();

      tester.takeException();
      await expectLater(
        find.byType(ProviderDetailScreen),
        matchesGoldenFile('$goldenFolder/provider_detail_collapsed.png'),
      );
    });

    testWidgets('ProviderDetailScreen - Expanded State', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(
        const ProviderDetailScreen(providerId: 'prov-123'),
      ));
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(200, 400), const Offset(0, -300));
      await tester.pumpAndSettle();

      tester.takeException();
      await expectLater(
        find.byType(ProviderDetailScreen),
        matchesGoldenFile('$goldenFolder/provider_detail_expanded.png'),
      );
    });

    Future<void> completeStep1(WidgetTester tester) async {
      final slotChip = find.text('09:00');
      if (slotChip.evaluate().isNotEmpty) {
        await tester.ensureVisible(slotChip);
        await tester.tap(slotChip);
        await tester.pump(const Duration(milliseconds: 500));
      }

      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await tester.ensureVisible(fields.first);
        await tester.enterText(fields.first, 'Calle 100 # 15-20, Bogotá');
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    testWidgets('BookingScreen - Step 1 (Cuándo y Dónde)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(
        BookingScreen(
          providerId: 'prov-123',
          providerName: 'Studio Valeria Gómez',
          services: const [
            {
              'id': 'srv-1',
              'name': 'Balayage Premium',
              'price': 250000,
              'duration': 180,
              'category': 'Cabello'
            }
          ],
        ),
      ));
      await tester.pumpAndSettle();

      tester.takeException();
      await expectLater(
        find.byType(BookingScreen),
        matchesGoldenFile('$goldenFolder/booking_step1_when_where.png'),
      );
    });

    testWidgets('BookingScreen - Step 2 (Productos)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(
        BookingScreen(
          providerId: 'prov-123',
          providerName: 'Studio Valeria Gómez',
          services: const [
            {
              'id': 'srv-1',
              'name': 'Balayage Premium',
              'price': 250000,
              'duration': 180,
              'category': 'Cabello'
            }
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await completeStep1(tester);

      // Tap Continuar button to go to Step 2
      final nextBtn = find.byType(ElevatedButton);
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.tap(nextBtn.last);
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Select a product in Step 2 to show active product state
      final addBtn = find.text('Añadir');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn.first);
        await tester.pump(const Duration(milliseconds: 500));
      }

      tester.takeException();
      await expectLater(
        find.byType(BookingScreen),
        matchesGoldenFile('$goldenFolder/booking_step2_products.png'),
      );
    });

    testWidgets('BookingScreen - Step 3 (Confirmación / Pago)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestableWidget(
        BookingScreen(
          providerId: 'prov-123',
          providerName: 'Studio Valeria Gómez',
          services: const [
            {
              'id': 'srv-1',
              'name': 'Balayage Premium',
              'price': 250000,
              'duration': 180,
              'category': 'Cabello'
            }
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await completeStep1(tester);

      // Step 1 -> Step 2
      final nextBtn1 = find.byType(ElevatedButton);
      if (nextBtn1.evaluate().isNotEmpty) {
        await tester.tap(nextBtn1.last);
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Step 2 -> Step 3
      final nextBtn2 = find.byType(ElevatedButton);
      if (nextBtn2.evaluate().isNotEmpty) {
        await tester.tap(nextBtn2.last);
        await tester.pump(const Duration(milliseconds: 500));
      }

      tester.takeException();
      await expectLater(
        find.byType(BookingScreen),
        matchesGoldenFile('$goldenFolder/booking_step3_checkout.png'),
      );
    });
  });
}
