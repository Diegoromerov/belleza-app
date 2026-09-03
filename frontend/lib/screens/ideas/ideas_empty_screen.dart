import 'package:flutter/material.dart';
import '../../services/biometric_service.dart';
import 'biometric_consent_screen.dart';
import 'welcome_screen.dart';

class IdeasEmptyScreen extends StatefulWidget {
  const IdeasEmptyScreen({super.key});

  @override
  State<IdeasEmptyScreen> createState() => _IdeasEmptyScreenState();
}

class _IdeasEmptyScreenState extends State<IdeasEmptyScreen> {
  @override
  void initState() {
    super.initState();
    _checkConsentAndNavigate();
  }

  Future<void> _checkConsentAndNavigate() async {
    final consentActive = await BiometricService.hasConsent();
    if (!mounted) return;

    if (consentActive) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BiometricWelcomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BiometricConsentScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFAF8F5),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC5A052),
        ),
      ),
    );
  }
}

