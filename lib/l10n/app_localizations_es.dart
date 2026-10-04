// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Análisis Cripto';

  @override
  String get chooseLanguage => 'Elige tu idioma';

  @override
  String get continueButton => 'Continuar';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameTr => 'Türkçe';

  @override
  String get languageNameEs => 'Español';

  @override
  String get retry => 'Reintentar';

  @override
  String errorOccurred(String details) {
    return 'Ocurrió un error: $details';
  }

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get myAccount => 'Mi cuenta';

  @override
  String get myWatchlist => 'Mi lista de seguimiento';

  @override
  String get mustLogIn => 'Debes iniciar sesión';

  @override
  String get buy => 'Comprar';

  @override
  String accountEmail(String email) {
    return 'Correo electrónico: $email';
  }

  @override
  String accountRole(String role) {
    return 'Rol: $role';
  }

  @override
  String get roleFree => 'Gratis';

  @override
  String get rolePro => 'Pro';

  @override
  String accountCreditBalance(int count) {
    return 'Saldo de créditos: $count';
  }

  @override
  String get buyCredits => 'Comprar créditos';

  @override
  String get upgradeToPro => 'Mejorar a Pro';

  @override
  String get logInOrSignUp => 'Iniciar sesión / Registrarse';

  @override
  String get coins => 'Monedas';

  @override
  String get radar => 'Radar';

  @override
  String get searchSymbol => 'Buscar símbolo...';

  @override
  String get noCoinsFound => 'No se encontraron monedas';

  @override
  String volumeLabel(String value) {
    return 'Volumen: $value';
  }

  @override
  String get noCandleData => 'Sin datos de velas';

  @override
  String creditsSpent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count créditos gastados',
      one: '1 crédito gastado',
    );
    return '$_temp0';
  }

  @override
  String analysisFailed(String details) {
    return 'No se pudo obtener el análisis: $details';
  }

  @override
  String deepAnalysisFailed(String details) {
    return 'No se pudo obtener el análisis profundo: $details';
  }

  @override
  String get quickAnalysisButton => 'Análisis rápido';

  @override
  String get deepAnalysisButton => 'Análisis profundo';

  @override
  String creditsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count créditos',
      one: '1 crédito',
    );
    return '$_temp0';
  }

  @override
  String get proSubscription => 'Suscripción Pro';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String monthlyCredits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count créditos cada mes',
      one: '1 crédito cada mes',
    );
    return '$_temp0';
  }

  @override
  String purchaseFailed(String details) {
    return 'La compra falló: $details';
  }

  @override
  String get purchaseNoPackage =>
      'No se pudo verificar la compra porque no se encontró la información del paquete. Se reintentará la próxima vez que abras la app.';

  @override
  String get purchaseNoPlan =>
      'No se pudo verificar la compra porque no se encontró la información del plan de suscripción. Se reintentará la próxima vez que abras la app.';

  @override
  String get creditsAdded => 'Los créditos se han añadido a tu saldo.';

  @override
  String get proActivated => 'Tu suscripción Pro se ha activado.';

  @override
  String purchaseWillRetry(String details) {
    return '$details Se reintentará la compra.';
  }

  @override
  String get purchaseServiceUnavailable =>
      'El servicio de compras no está disponible.';

  @override
  String get productNotFound => 'No se encontró el producto en la tienda.';

  @override
  String purchaseStartFailed(String details) {
    return 'No se pudo iniciar la compra: $details';
  }

  @override
  String get termAll => 'Todos';

  @override
  String get termShort => 'Corto';

  @override
  String get termMedium => 'Medio';

  @override
  String get termLong => 'Largo';

  @override
  String get termShortLabel => 'Corto plazo';

  @override
  String get termMediumLabel => 'Medio plazo';

  @override
  String get termLongLabel => 'Largo plazo';

  @override
  String get agoNow => 'ahora';

  @override
  String agoMinutes(int n) {
    return 'hace $n min';
  }

  @override
  String agoHours(int n) {
    return 'hace $n h';
  }

  @override
  String agoDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'hace $n días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get radarEmpty =>
      'Ahora mismo no hay oportunidades que cumplan los criterios técnicos.';

  @override
  String get radarFooter =>
      'Puntuación 0-100: indica qué tan sobrevendido está. Toca una oportunidad para un análisis profundo con IA.';

  @override
  String get watchlistEmpty => 'Aún no sigues ninguna moneda';

  @override
  String errorServer(int status) {
    return 'Error del servidor: $status';
  }

  @override
  String get errorInsufficientCredit => 'Crédito insuficiente.';

  @override
  String get errorAnalysisUnavailable =>
      'El análisis no está disponible en este momento.';

  @override
  String get errorDeepAnalysisUnavailable =>
      'El análisis profundo no está disponible en este momento.';

  @override
  String errorAnalysisRequestFailed(String details) {
    return 'No se pudo enviar la solicitud de análisis: $details';
  }

  @override
  String errorDeepAnalysisRequestFailed(String details) {
    return 'No se pudo enviar la solicitud de análisis profundo: $details';
  }

  @override
  String get errorSessionInvalid => 'No se pudo verificar la sesión.';

  @override
  String errorRequestFailed(String details) {
    return 'No se pudo enviar la solicitud: $details';
  }

  @override
  String get errorInvalidCredentialsOrEmailTaken =>
      'Datos incorrectos o este correo ya está registrado.';

  @override
  String errorSignalsFailed(String details) {
    return 'No se pudieron obtener los datos de señales: $details';
  }

  @override
  String errorServerUnreachable(String details) {
    return 'No se pudo conectar con el servidor: $details';
  }

  @override
  String errorCreditPackagesFailed(String details) {
    return 'No se pudieron obtener los paquetes de créditos: $details';
  }

  @override
  String errorDeviceTokenFailed(String details) {
    return 'No se pudo registrar el token del dispositivo: $details';
  }

  @override
  String get errorProOnly => 'Esta función es solo para miembros Pro.';

  @override
  String errorPurchaseVerifyFailed(String details) {
    return 'No se pudo verificar la compra: $details';
  }

  @override
  String get errorPurchaseInvalid => 'La compra no es válida.';

  @override
  String get errorPlayVerificationUnreachable =>
      'No se pudo acceder al servicio de verificación de Google Play.';

  @override
  String errorRadarFailed(String details) {
    return 'No se pudo cargar Radar: $details';
  }

  @override
  String errorPlansFailed(String details) {
    return 'No se pudieron obtener los planes de suscripción: $details';
  }

  @override
  String errorSubscriptionVerifyFailed(String details) {
    return 'No se pudo verificar la suscripción: $details';
  }

  @override
  String get errorSubscriptionInvalid => 'La suscripción no es válida.';

  @override
  String get errorWatchlistFailed =>
      'No se pudo obtener tu lista de seguimiento.';

  @override
  String get errorFollowFailed => 'No se pudo seguir esta moneda.';

  @override
  String get errorUnfollowFailed =>
      'No se pudo quitar de tu lista de seguimiento.';

  @override
  String errorCandlesFailed(String details) {
    return 'No se pudieron obtener los datos de velas: $details';
  }

  @override
  String errorBinance(int status) {
    return 'Error de Binance: $status';
  }

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get replayIntro => 'Ver la introducción otra vez';

  @override
  String get onboardingDefault1Title => 'Radar: las mejores oportunidades';

  @override
  String get onboardingDefault1Body =>
      'Radar analiza el mercado y destaca las monedas con las oportunidades técnicas más fuertes, para que no tengas que buscarlas.';

  @override
  String get onboardingDefault2Title => 'Gráficos con señales';

  @override
  String get onboardingDefault2Body =>
      'Lee el movimiento del precio de un vistazo. Las flechas de compra y venta en el gráfico marcan las señales a medida que aparecen.';

  @override
  String get onboardingDefault3Title => 'Análisis con IA y alertas';

  @override
  String get onboardingDefault3Body =>
      'Haz un análisis rápido o un Análisis profundo con créditos y añade monedas a Mi lista de seguimiento para recibir avisos cuando algo suceda.';

  @override
  String get authErrorInvalidEmail =>
      'La dirección de correo electrónico no es válida.';

  @override
  String get authErrorWrongCredentials =>
      'Correo electrónico o contraseña incorrectos.';

  @override
  String get authErrorEmailInUse =>
      'Ya existe una cuenta con este correo electrónico.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña es demasiado débil. Usa al menos 8 caracteres.';

  @override
  String get authErrorNetwork =>
      'Error de red. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get authErrorTooManyRequests =>
      'Demasiados intentos. Inténtalo de nuevo más tarde.';

  @override
  String get authErrorCancelled => 'Se canceló el inicio de sesión.';

  @override
  String get authErrorEmailUnverifiedConflict =>
      'Ya existe una cuenta con este correo. Verifica tu correo electrónico primero.';

  @override
  String get authErrorUnknown => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get authWelcomeTitle => 'Bienvenido';

  @override
  String get authWelcomeSubtitle =>
      'Inicia sesión para ejecutar análisis con IA, seguir monedas y recibir notificaciones. También puedes explorar como invitado.';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithEmail => 'Continuar con correo electrónico';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get resetEmailSent =>
      'Correo para restablecer la contraseña enviado. Revisa tu bandeja de entrada.';

  @override
  String get verificationEmailSent =>
      'Correo de verificación enviado. Revisa tu bandeja de entrada.';

  @override
  String get verifyEmailBannerText =>
      'Verifica tu correo electrónico para recibir tu crédito de bienvenida.';

  @override
  String get iHaveVerified => 'Ya verifiqué';

  @override
  String get resendEmail => 'Reenviar';

  @override
  String get emailNotVerifiedYet =>
      'Tu correo electrónico aún no está verificado.';

  @override
  String get accountEmailVerified => 'Correo electrónico verificado';

  @override
  String get accountEmailNotVerified => 'Correo electrónico sin verificar';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get guestProfileHint =>
      'Inicia sesión o regístrate para usar tu lista de seguimiento, comprar créditos y sincronizar tu cuenta.';

  @override
  String get tabChart => 'Gráfico';

  @override
  String get tabWatchlist => 'Seguimiento';

  @override
  String get tabProfile => 'Perfil';
}
