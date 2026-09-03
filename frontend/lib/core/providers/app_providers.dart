// lib/core/providers/app_providers.dart
// Riverpod Providers — Core App State
// Configuración base, providers globales, y providers para features del prestador

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../core/models/booking_model.dart';
import '../../core/models/provider_profile_model.dart';
import '../../core/models/wallet_model.dart';
import '../../core/models/service_model.dart';
import '../../core/models/portfolio_model.dart';

export 'app_providers.dart'
    show
        BookingsNotifier,
        bookingsProvider,
        ProviderProfileNotifier,
        providerProfileProvider,
        WalletNotifier,
        walletProvider,
        WalletTransactionsNotifier,
        walletTransactionsProvider,
        ProviderServicesNotifier,
        providerServicesProvider,
        ProviderPortfolioNotifier,
        providerPortfolioProvider,
        todayBookingsCountProvider,
        weeklyNetEarningsProvider,
        lastWeekNetEarningsProvider,
        weeklyEarningsWoWProvider,
        nextBookingProvider,
        activeBookingsCountProvider,
        isProviderOnlineProvider,
        providerRatingProvider,
        connectivityProvider,
        webSocketStatusProvider,
        bookingLoadingProvider,
        sosLoadingProvider,
        statusToggleLoadingProvider;

// ============================================================================
// INFRASTRUCTURE PROVIDERS
// ============================================================================

/// SharedPreferences async provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// ApiService singleton
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// AnalyticsService singleton
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// ============================================================================
// AUTH STATE PROVIDERS
// ============================================================================

/// Current auth token (null si no logueado)
final authTokenProvider = FutureProvider<String?>((ref) async {
  return await AuthService.getToken();
});

/// Current user role
final userRoleProvider = FutureProvider<String?>((ref) async {
  final token = await AuthService.getToken();
  if (token == null) return null;
  // Decode JWT or fetch from profile
  try {
    final profile = await ApiService.fetchUserProfile();
    return profile['role'] as String?;
  } catch (_) {
    return null;
  }
});

/// Is provider verified (estatus_verificacion == 'APROBADO')
final isProviderVerifiedProvider = FutureProvider<bool>((ref) async {
  try {
    final profile = await ApiService.fetchUserProfile();
    return profile['estatus_verificacion'] == 'APROBADO';
  } catch (_) {
    return false;
  }
});

// ============================================================================
// PROVIDER DASHBOARD STATE
// ============================================================================

/// Provider Profile State Notifier
class ProviderProfileNotifier extends AsyncNotifier<ProviderProfile> {
  @override
  Future<ProviderProfile> build() async {
    return _fetchProfile();
  }

  Future<ProviderProfile> _fetchProfile() async {
    final data = await ApiService.fetchUserProfile();
    return ProviderProfile.fromBackendJson(data);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProfile);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? description,
    int? activeStartHour,
    int? activeEndHour,
    Map<String, dynamic>? weeklySchedule,
  }) async {
    // Get current profile to use existing values for required fields
    final currentProfile = state.value;
    if (currentProfile == null) return;
    
    await ApiService.updateUserProfile(
      fullName: fullName ?? currentProfile.fullName,
      phone: phone ?? currentProfile.phone,
      description: description,
      activeStartHour: activeStartHour,
      activeEndHour: activeEndHour,
      weeklySchedule: weeklySchedule,
    );
    await refresh();
  }

  Future<void> toggleActiveStatus(bool isActive) async {
    double? lat, lon;
    if (isActive) {
      // TODO: Get real geolocation
    }
    await ApiService.updateProviderStatus(isActive, latitude: lat, longitude: lon);
    await refresh();
  }

  Future<void> updateAvatar(String dataUri) async {
    await ApiService.updateAvatar(dataUri);
    await refresh();
  }
}

final providerProfileProvider = AsyncNotifierProvider<ProviderProfileNotifier, ProviderProfile>(
  ProviderProfileNotifier.new,
);

/// Bookings State Notifier
class BookingsNotifier extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    return _fetchBookings();
  }

  Future<List<Booking>> _fetchBookings() async {
    final data = await ApiService.fetchProviderBookings();
    return data.map((json) => Booking.fromBackendJson(json)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchBookings);
  }

  Future<void> startBooking(String bookingId) async {
    await ApiService.startBooking(bookingId);
    await refresh();
  }

  Future<void> completeBooking(String bookingId) async {
    await ApiService.post('/api/bookings/$bookingId/complete', {});
    await refresh();
  }

  Future<void> verifyPin(String bookingId, String pin, {
    required double providerLat,
    required double providerLon,
    required double clientLat,
    required double clientLon,
  }) async {
    await ApiService.completeBooking(bookingId, pin,
      providerLat: providerLat,
      providerLon: providerLon,
      clientLat: clientLat,
      clientLon: clientLon,
    );
    await refresh();
  }

  Future<void> reportDispute(String bookingId) async {
    await ApiService.updateBookingStatus(bookingId, 'EN_DISPUTA');
    await refresh();
  }
}

final bookingsProvider = AsyncNotifierProvider<BookingsNotifier, List<Booking>>(
  BookingsNotifier.new,
);

/// Wallet State Notifier
class WalletNotifier extends AsyncNotifier<Wallet> {
  @override
  Future<Wallet> build() async {
    return _fetchWallet();
  }

  Future<Wallet> _fetchWallet() async {
    final data = await ApiService.get('/api/wallet');
    return Wallet.fromBackendJson(data);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchWallet);
  }

  Future<void> requestWithdrawal(double amount) async {
    await ApiService.post('/api/wallet/withdraw', {'monto': amount});
    await refresh();
  }

  Future<void> updateWithdrawalModel(String model) async {
    await ApiService.put('/api/wallet/model', {'modelo': model});
    await refresh();
  }
}

final walletProvider = AsyncNotifierProvider<WalletNotifier, Wallet>(
  WalletNotifier.new,
);

/// Wallet Transactions State Notifier
class WalletTransactionsNotifier extends AsyncNotifier<List<WalletTransaction>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<WalletTransaction>> build() async {
    _currentPage = 1;
    _hasMore = true;
    return _fetchTransactions(loadMore: false);
  }

  Future<List<WalletTransaction>> _fetchTransactions({required bool loadMore}) async {
    final page = loadMore ? _currentPage + 1 : 1;
    final res = await ApiService.get('/api/wallet/transactions?page=$page&limit=15');
    final transactions = (res['transacciones'] as List? ?? [])
        .map((json) => WalletTransaction.fromBackendJson(json as Map<String, dynamic>))
        .toList();
    final pagination = res['pagination'];
    final total = pagination != null ? (pagination['total'] as int? ?? 0) : 0;

    if (loadMore) {
      _isLoadingMore = false;
      _hasMore = transactions.length < total && transactions.isNotEmpty;
      if (_hasMore) _currentPage = page;
      return [...state.valueOrNull ?? [], ...transactions];
    } else {
      _currentPage = 1;
      _hasMore = transactions.length < total && transactions.isNotEmpty;
      if (_hasMore) _currentPage = 2;
      return transactions;
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchTransactions(loadMore: false));
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    final newTransactions = await _fetchTransactions(loadMore: true);
    state = AsyncData(newTransactions);
  }
}

final walletTransactionsProvider = AsyncNotifierProvider<WalletTransactionsNotifier, List<WalletTransaction>>(
  WalletTransactionsNotifier.new,
);

/// Provider Services State Notifier
class ProviderServicesNotifier extends AsyncNotifier<List<ServiceModel>> {
  @override
  Future<List<ServiceModel>> build() async {
    return _fetchServices();
  }

  Future<List<ServiceModel>> _fetchServices() async {
    final data = await ApiService.fetchProviderServices();
    return data.map((json) => ServiceModel.fromBackendJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchServices);
  }

  Future<void> createService({
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? category,
    required bool isActive,
  }) async {
    await ApiService.createService(
      name: name,
      price: price,
      durationMinutes: durationMinutes,
      description: description,
      category: category,
      isActive: isActive,
    );
    await refresh();
  }

  Future<void> updateService({
    required String id,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? category,
    required bool isActive,
  }) async {
    await ApiService.updateService(
      id: id,
      name: name,
      price: price,
      durationMinutes: durationMinutes,
      description: description,
      category: category,
      isActive: isActive,
    );
    await refresh();
  }

  Future<void> toggleServiceStatus(ServiceModel service) async {
    if (service.isActive) {
      await ApiService.deleteService(service.id);
    } else {
      await ApiService.updateService(
        id: service.id,
        name: service.name,
        price: service.price,
        durationMinutes: service.durationMinutes,
        description: service.description,
        category: service.category,
        isActive: true,
      );
    }
    await refresh();
  }
}

final providerServicesProvider = AsyncNotifierProvider<ProviderServicesNotifier, List<ServiceModel>>(
  ProviderServicesNotifier.new,
);

/// Provider Portfolio State Notifier
class ProviderPortfolioNotifier extends AsyncNotifier<List<PortfolioItem>> {
  @override
  Future<List<PortfolioItem>> build() async {
    return _fetchPortfolio();
  }

  Future<List<PortfolioItem>> _fetchPortfolio() async {
    final data = await ApiService.fetchProviderPortfolio();
    return data.map((json) => PortfolioItem.fromBackendJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchPortfolio);
  }

  Future<void> addItem({
    required String imageUrl,
    required String title,
    required String category,
  }) async {
    await ApiService.addPortfolioItem(imageUrl: imageUrl, title: title, category: category);
    await refresh();
  }

  Future<void> updateItem({
    required String id,
    required String title,
    required String category,
  }) async {
    await ApiService.updatePortfolioItem(id: id, title: title, category: category);
    await refresh();
  }

  Future<void> deleteItem(String id) async {
    await ApiService.deletePortfolioItem(id);
    await refresh();
  }
}

final providerPortfolioProvider = AsyncNotifierProvider<ProviderPortfolioNotifier, List<PortfolioItem>>(
  ProviderPortfolioNotifier.new,
);

// ============================================================================
// DERIVED / COMPUTED PROVIDERS
// ============================================================================

/// Today's bookings count
final todayBookingsCountProvider = Provider<int>((ref) {
  final bookingsAsync = ref.watch(bookingsProvider);
  return bookingsAsync.when(
    data: (bookings) {
      final now = DateTime.now();
      return bookings.where((b) {
        final date = b.scheduledAt;
        return date.year == now.year && date.month == now.month && date.day == now.day;
      }).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Weekly net earnings (current week)
final weeklyNetEarningsProvider = Provider<double>((ref) {
  final bookingsAsync = ref.watch(bookingsProvider);
  return bookingsAsync.when(
    data: (bookings) {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      return bookings.where((b) {
        final st = b.status.toUpperCase();
        final isStatusOk = st == 'CONFIRMADA' || st == 'COMPLETADA' || st == 'CONFIRMED' || st == 'COMPLETED' || st == 'EN_PROGRESO';
        if (!isStatusOk) return false;
        final date = b.scheduledAt;
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && date.isBefore(endOfWeek);
      }).fold(0.0, (sum, b) => sum + (b.providerNetAmount ?? 0));
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Last week net earnings (for WoW comparison)
final lastWeekNetEarningsProvider = Provider<double>((ref) {
  final bookingsAsync = ref.watch(bookingsProvider);
  return bookingsAsync.when(
    data: (bookings) {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfThisWeek = DateTime(monday.year, monday.month, monday.day);
      final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
      final endOfLastWeek = startOfThisWeek;

      return bookings.where((b) {
        final st = b.status.toUpperCase();
        final isStatusOk = st == 'CONFIRMADA' || st == 'COMPLETADA' || st == 'CONFIRMED' || st == 'COMPLETED' || st == 'EN_PROGRESO';
        if (!isStatusOk) return false;
        final date = b.scheduledAt;
        return date.isAfter(startOfLastWeek.subtract(const Duration(microseconds: 1))) && date.isBefore(endOfLastWeek);
      }).fold(0.0, (sum, b) => sum + (b.providerNetAmount ?? 0));
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Weekly earnings WoW text
final weeklyEarningsWoWProvider = Provider<String>((ref) {
  final current = ref.watch(weeklyNetEarningsProvider);
  final last = ref.watch(lastWeekNetEarningsProvider);
  if (last == 0) {
    return current > 0 ? '+100% vs sem. ant.' : 'Estable vs sem. ant.';
  }
  final diff = ((current - last) / last) * 100;
  final sign = diff >= 0 ? '+' : '';
  return '$sign${diff.toStringAsFixed(0)}% vs sem. ant.';
});

/// Next upcoming booking
final nextBookingProvider = Provider<Booking?>((ref) {
  final bookingsAsync = ref.watch(bookingsProvider);
  return bookingsAsync.when(
    data: (bookings) {
      final upcoming = bookings.where((b) {
        final st = b.status.toUpperCase();
        return st != 'COMPLETED' && st != 'COMPLETADA' && st != 'CANCELLED' && st != 'CANCELADA' && st != 'PENDIENTE_PAGO';
      }).toList();
      if (upcoming.isEmpty) return null;
      upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return upcoming.first;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Active bookings count (for badge)
final activeBookingsCountProvider = Provider<int>((ref) {
  final bookingsAsync = ref.watch(bookingsProvider);
  return bookingsAsync.when(
    data: (bookings) => bookings.where((b) {
      final st = b.status.toUpperCase();
      return st == 'CONFIRMED' || st == 'CONFIRMADA' || st == 'EN_PROGRESO' || st == 'ESPERANDO_OTP';
    }).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Is provider online
final isProviderOnlineProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(providerProfileProvider);
  return profileAsync.when(
    data: (profile) => profile.isActive,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider rating
final providerRatingProvider = Provider<(double?, int)>((ref) {
  final profileAsync = ref.watch(providerProfileProvider);
  return profileAsync.when(
    data: (profile) => (profile.ratingAvg > 0 ? profile.ratingAvg : null, profile.ratingCount),
    loading: () => (null, 0),
    error: (_, __) => (null, 0),
  );
});

// ============================================================================
// UTILITY PROVIDERS
// ============================================================================

/// Connectivity status (online/offline)
final connectivityProvider = StreamProvider<bool>((ref) async* {
  // TODO: Implement with connectivity_plus package
  yield true;
});

/// WebSocket connection status
final webSocketStatusProvider = StateProvider<WebSocketStatus>((ref) => WebSocketStatus.disconnected);

enum WebSocketStatus { disconnected, connecting, connected, error }

/// Loading states for individual bookings (prevent double-tap)
final bookingLoadingProvider = StateProvider<Set<String>>((ref) => <String>{});

/// SOS loading state
final sosLoadingProvider = StateProvider<bool>((ref) => false);

/// Status toggle loading
final statusToggleLoadingProvider = StateProvider<bool>((ref) => false);