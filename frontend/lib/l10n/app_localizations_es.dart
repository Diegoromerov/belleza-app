// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get registerConciergeTitle => 'REGISTRO CONCIERGE';

  @override
  String get registerConciergeSubtitle =>
      'Únete a la comunidad de alta belleza y salud';

  @override
  String get registerUserType => 'TIPO DE USUARIO';

  @override
  String get registerClientInfo =>
      '✨ Acceso a diagnósticos de IA Aura, GlowStore y reserva de servicios concierge.';

  @override
  String get registerProviderInfo =>
      '💼 Ofrece tus servicios, gestiona tu agenda y recibe pagos con comisión preferencial.';

  @override
  String get registerFullNameLabel => 'Nombre completo';

  @override
  String get registerFullNameHint => 'Nombre completo';

  @override
  String get registerFullNameError => 'Ingresa tu nombre completo';

  @override
  String get registerEmailLabel => 'Correo electrónico';

  @override
  String get registerEmailHint => 'Correo electrónico';

  @override
  String get registerEmailError => 'Ingresa tu correo';

  @override
  String get registerPasswordLabel => 'Contraseña';

  @override
  String get registerPasswordHint => 'Contraseña';

  @override
  String get registerPasswordError => 'Mínimo 6 caracteres';

  @override
  String get registerPhoneLabel => 'Teléfono (opcional)';

  @override
  String get registerPhoneHint => 'Teléfono (opcional)';

  @override
  String get registerCreateAccount => 'CREAR MI CUENTA';
}
