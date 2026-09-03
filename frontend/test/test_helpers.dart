// Test helpers for mocking flutter_secure_storage in tests
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory storage for the mock
final Map<String, String> _storage = <String, String>{};

/// Sets up a mock for the flutter_secure_storage plugin.
/// This mock uses the in-memory [_storage] map to simulate storage operations.
void setupFlutterSecureStorageMock() {
  const MethodChannel channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getAll':
        return Map<String, String>.from(_storage);
      case 'get':
        final String key = methodCall.arguments['key'] as String;
        return _storage[key];
      case 'set':
        final String key = methodCall.arguments['key'] as String;
        final String value = methodCall.arguments['value'] as String;
        _storage[key] = value;
        return null;
      case 'delete':
        final String key = methodCall.arguments['key'] as String;
        _storage.remove(key);
        return null;
      case 'deleteAll':
        _storage.clear();
        return null;
      case 'containsKey':
        final String key = methodCall.arguments['key'] as String;
        return _storage.containsKey(key);
      default:
        throw MissingPluginException();
    }
  });
}

/// Resets the mock for the flutter_secure_storage plugin.
/// Clears the in-memory storage and removes the mock method call handler.
void resetFlutterSecureStorageMock() {
  _storage.clear();
  const MethodChannel channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
}