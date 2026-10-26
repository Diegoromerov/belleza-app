// lib/models/superadmin/super_admin_state.dart
/// Generic wrapper for Riverpod v2 async state.
/// Mirrors `AsyncValue<T>` but provides convenient constructors
/// (`loading`, `success`, `failure`) used by the existing notifiers.
library super_admin_state;

import '../../services/superadmin_api_service.dart';

class SuperAdminState<T> {
  final T? _data;
  final Object? _error;
  final bool _isLoading;

  const SuperAdminState._({T? data, Object? error, bool isLoading = false})
      : _data = data,
        _error = error,
        _isLoading = isLoading;

  /// Empty initial state (no data, not loading).
  SuperAdminState.empty() : this._();

  /// Loading state.
  SuperAdminState.loading() : this._(isLoading: true);

  /// Successful state with data.
  SuperAdminState.success(T data) : this._(data: data);

  /// Failure state.
  SuperAdminState.failure(Object e, [StackTrace? st]) : this._(error: e);

  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  bool get hasData => _data != null;
  T? get data => _data;
  Object? get error => _error;

  /// El backend respondió 403/401: no es un fallo de red.
  bool get isForbidden => error is SuperAdminForbidden;
}
