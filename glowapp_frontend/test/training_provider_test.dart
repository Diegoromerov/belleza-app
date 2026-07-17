// test/training_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:glowapp_frontend/providers/training_provider.dart';
import 'package:glowapp_frontend/services/api_service.dart';
import 'package:glowapp_frontend/providers/auth_provider.dart';
import 'package:glowapp_frontend/models/user.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  test('submitResult calls API with correct parameters', () async {
    final mockApi = MockApiService();
    // Mock auth provider to return a user
    final mockUser = User(id: '99', name: 'Tester', email: 'tester@example.com');
    final authProviderOverride = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      return AuthNotifier()..state = AsyncData(mockUser);
    });

    final container = ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(mockApi),
      authProvider.overrideWithProvider(authProviderOverride),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(trainingProvider.notifier);
    // Simulate a finished training state
    notifier.state = notifier.state.copyWith(
      difficultyLevel: 2,
      totalAttempts: 10,
      correctAnswers: 7,
      isPlaying: false,
    );

    await notifier._finishTraining(); // internal method, but we can call via reflection if needed; here we invoke directly for test purposes
    verify(mockApi.submitTrainingResult(
      userId: '99',
      difficultyLevel: 2,
      totalAttempts: 10,
      correctAnswers: 7,
      accuracy: anyNamed('accuracy'),
    )).called(1);
  });
}
