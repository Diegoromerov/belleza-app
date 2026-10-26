// lib/services/firebase_auth_service.dart
// Servicio de autenticación usando Firebase Auth (Email/Password, Google, Apple).
// Mantiene la misma interfaz de AuthService pero delega a Firebase.

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Instancia estática de FirebaseAuth




class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;


  // Outlook / Microsoft Sign‑In (requires Firebase Auth native provider)
  static Future<UserCredential?> signInWithMicrosoft() async {
    try {
      // Create the Microsoft OAuth provider.
      final provider = OAuthProvider('microsoft.com');
      // Optionally add scopes.
      provider.addScope('email');
      provider.addScope('profile');
      if (kIsWeb) {
        // Web uses signInWithPopup.
        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile platforms use signInWithProvider.
        return await _auth.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Microsoft sign‑in error: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('Microsoft sign‑in generic error: $e');
      return null;
    }
  }





  /// Email / Password
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase email sign‑in error: ${e.code}');
      return null;
    }
  }

  static Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase registration error: ${e.code}');
      return null;
    }
  }

  /// Google Sign‑In (requires firebase_auth + google_sign_in)
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // cancelled
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign‑in error: ${e.code}');
      return null;
    }
  }

  /// Apple Sign‑In (requires sign_in_with_apple)
  static Future<UserCredential?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      return await _auth.signInWithCredential(oauthCredential);
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple sign‑in error: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('Apple sign‑in generic error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    // También cerrar sesión de Google si está conectado.
    await GoogleSignIn().signOut();
  }

  static User? get currentUser => _auth.currentUser;
}
