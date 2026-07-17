// test/auth_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:glowapp_frontend/models/user.dart';
import 'package:glowapp_frontend/providers/auth_provider.dart';
import 'package:glowapp_frontend/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  test('login updates state with user from API', () async {
    final mockApi = MockApiService();
    const email = 'test@example.com';
    const password = 'secret';
    final apiResult = {
      'user': {'id': '42', 'name': 'Test User', 'email': email, 'avatarUrl': null},
      'token': 'dummy-jwt',
    };
    when(mockApi.login(email: email, password: password)).thenAnswer((_) async => apiResult);

    final container = ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(mockApi),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.login(email, password);
    final state = container.read(authProvider);
    expect(state.value, isA<User>());
    expect(state.value?.id, '42');
    expect(state.value?.email, email);
    verify(mockApi.login(email: email, password: password)).called(1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:glowapp_frontend/models/user.dart';
import 'package:glowapp_frontend/providers/auth_provider.dart';
import 'package:glowapp_frontend/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  test('login updates state with user from API', () async {
    final mockApi = MockApiService();
    const email = 'test@example.com';
    const password = 'secret';
    final apiResult = {
      'user': {'id': '42', 'name': 'Test User', 'email': email, 'avatarUrl': null},
      'token': 'dummy-jwt',
    };
    when(mockApi.login(email: email, password: password)).thenAnswer((_) async => apiResult);

    final container = ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(mockApi),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.login(email, password);
    final state = container.read(authProvider);
    expect(state.value, isA<User>());
    expect(state.value?.id, '42');
    expect(state.value?.email, email);
    verify(mockApi.login(email: email, password: password)).called(1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:glowapp_frontend/models/user.dart';
import 'package:glowapp_frontend/providers/auth_provider.dart';
import 'package:glowapp_frontend/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  test('login updates state with user from API', () async {
    final mockApi = MockApiService();
    const email = 'test@example.com';
    const password = 'secret';
    final apiResult = {
      'user': {'id': '42', 'name': 'Test User', 'email': email, 'avatarUrl': null},
      'token': 'dummy-jwt',
    };
    when(mockApi.login(email: email, password: password)).thenAnswer((_) async => apiResult);

    final container = ProviderContainer(overrides: [
      apiServiceProvider.overrideWithValue(mockApi),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.login(email, password);
    final state = container.read(authProvider);
    expect(state.value, isA<User>());
    expect(state.value?.id, '42');
    expect(state.value?.email, email);
    verify(mockApi.login(email: email, password: password)).called(1);
  });
}
