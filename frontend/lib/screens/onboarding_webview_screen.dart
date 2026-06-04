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
  Widget build(BuildContext context) {
    // Si estamos en entorno web de desarrollo, podemos usar HtmlElementView o fallback local directo
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E17),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tutorial Interactivo de Onboarding',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'El simulador interactivo de onboarding requiere ejecución nativa de WebView en móviles. Si estás en web, puedes omitir este paso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC89D93),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Omitir e Ir a la Aplicación', style: TextStyle(fontWeight: FontWeight.bold)),
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
