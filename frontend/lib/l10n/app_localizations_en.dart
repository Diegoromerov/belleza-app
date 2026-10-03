// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get registerConciergeTitle => 'REGISTER CONCIERGE';

  @override
  String get registerConciergeSubtitle =>
      'Join the high beauty and wellness community';

  @override
  String get registerUserType => 'USER TYPE';

  @override
  String get registerClientInfo =>
      '✨ Access to AI Aura diagnostics, GlowStore, and concierge service booking.';

  @override
  String get registerProviderInfo =>
      '💼 Offer your services, manage your schedule, and receive payments with preferential commission.';

  @override
  String get registerFullNameLabel => 'Full Name';

  @override
  String get registerFullNameHint => 'Full Name';

  @override
  String get registerFullNameError => 'Please enter your full name';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerEmailHint => 'Email';

  @override
  String get registerEmailError => 'Please enter your email';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerPasswordHint => 'Password';

  @override
  String get registerPasswordError => 'Minimum 6 characters';

  @override
  String get registerPhoneLabel => 'Phone (optional)';

  @override
  String get registerPhoneHint => 'Phone (optional)';

  @override
  String get registerCreateAccount => 'CREATE MY ACCOUNT';
}
