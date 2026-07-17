import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowapp_frontend/models/user.dart';
import 'package:glowapp_frontend/services/api_service.dart';

/// Simple authentication state notifier.
/// In a real app this would call the backend and store a JWT.
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AsyncData(null));

  /// Real login using ApiService.
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(apiServiceProvider).login(email: email, password: password);
      // Expect token and user data from backend
      final userData = result['user'];
      final user = User.fromJson(userData as Map<String, dynamic>);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void logout() {
    state = const AsyncData(null);
  }
}

/// Provider exposing the AuthNotifier.
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});
