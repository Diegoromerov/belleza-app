// frontend/lib/screens/onboarding_webview_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';

class OnboardingWebViewScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingWebViewScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingWebViewScreen> createState() => _OnboardingWebViewScreenState();
}

class _OnboardingWebViewScreenState extends State<OnboardingWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  // Web Onboarding Slide state
  int _webCurrentPage = 0;
  final PageController _webPageController = PageController();

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _isLoading = false;
      return;
    }

    final onboardingUrl = '${ApiService.baseUrl}/onboarding';
    debugPrint('🌐 Cargando Tutorial Interactivo en WebView: $onboardingUrl');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0E17))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ Error de recursos en WebView: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterInterface',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('📱 Mensaje recibido de la Web: ${message.message}');
          if (message.message == 'finish' || message.message == 'skip') {
            widget.onCompleted();
          }
        },
      )
      ..loadRequest(Uri.parse(onboardingUrl));
  }

  @override
  void dispose() {
    _webPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final List<Map<String, dynamic>> slides = [
        {
          'title': 'Bienvenido a Belleza App',
          'description': 'Reserva estilistas y profesionales de belleza a domicilio en Fontibón de manera fácil y rápida.',
          'icon': Icons.face_retouching_natural,
          'color': const Color(0xFFC89D93),
        },
        {
          'title': 'Garantía OTP Segura',
          'description': 'Tu pago se retiene de forma segura. El prestador solo recibe los fondos cuando ingresas el código OTP que confirma tu entera satisfacción.',
          'icon': Icons.verified_user_outlined,
          'color': const Color(0xFF8BAEA6),
        },
        {
          'title': 'Try-On Virtual con IA',
          'description': 'Visualiza cómo se verán tus diseños de uñas antes de agendar la cita, utilizando tecnología inteligente de vanguardia.',
          'icon': Icons.auto_awesome_outlined,
          'color': const Color(0xFFE5CECA),
        }
      ];

      return Scaffold(
        backgroundColor: const Color(0xFF0A0E17),
        body: SafeArea(
          child: Column(
            children: [
              // Botón Omitir arriba a la derecha
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: widget.onCompleted,
                    child: const Text(
                      'Omitir',
                      style: TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _webPageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _webCurrentPage = page;
                    });
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: slide['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              slide['icon'],
                              size: 100,
                              color: slide['color'],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            slide['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            slide['description'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Indicador de páginas y botón de acción inferior
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8.0,
                          width: _webCurrentPage == index ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            color: _webCurrentPage == index ? const Color(0xFFC89D93) : Colors.grey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (_webCurrentPage == slides.length - 1) {
                          widget.onCompleted();
                        } else {
                          _webPageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC89D93),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _webCurrentPage == slides.length - 1 ? 'Empezar ahora' : 'Siguiente',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text('Guía de Onboarding'),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: widget.onCompleted,
            child: const Text(
              'Omitir',
              style: TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC89D93),
              ),
            ),
        ],
      ),
    );
  }
}
