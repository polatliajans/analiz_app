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
  String get cancel => 'Cancelar';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountConfirmTitle => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountConfirmBody =>
      'Se eliminarán de forma permanente tu cuenta y todos tus datos: lista de seguimiento, historial de análisis, créditos, notificaciones y métodos de inicio de sesión vinculados. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountProNote =>
      'Si tienes una suscripción Pro activa, eliminar tu cuenta no la cancela. Cancélala por separado en Google Play; de lo contrario podrían seguir cobrándote.';

  @override
  String get deleteAccountConfirmAction => 'Eliminar';

  @override
  String deleteAccountCreditsLost(int credits) {
    return 'Se eliminarán $credits créditos y no se reembolsarán.';
  }

  @override
  String get deleteAccountManageSubscription =>
      'Gestionar suscripción en Google Play';

  @override
  String get deleteAccountAckCheckbox =>
      'Entiendo que mis créditos se eliminarán y no se reembolsarán';

  @override
  String get deleteAccountOpenFailed => 'No se pudo abrir Google Play.';

  @override
  String get errorPurchaseAlreadyProcessed =>
      'Esta compra ya fue procesada y no se puede canjear de nuevo.';

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
  String get strongSignalsProNote => 'Las señales fuertes (3) son Pro';

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
  String get deepAnalysisWaitingTitle => 'El análisis profundo está en curso';

  @override
  String get deepAnalysisWaitingBody =>
      'Suele tardar entre 30 y 90 segundos, a veces hasta 4 minutos. Puedes salir de esta pantalla: te enviaremos una notificación cuando esté listo.';

  @override
  String get deepAnalysisFailedRefunded =>
      'No se pudo completar el análisis profundo. Tus créditos han sido reembolsados.';

  @override
  String get deepAnalysisAlreadyRunning =>
      'Ya tienes un análisis profundo en curso. Espera a que termine.';

  @override
  String get deepAnalysisCheckLater =>
      'No pudimos conectar con el servidor. Tu análisis puede seguir en curso: vuelve más tarde o consulta tu historial de análisis.';

  @override
  String get deepAnalysisStillRunning =>
      'Tu análisis sigue en curso. Recibirás una notificación cuando esté listo, o puedes encontrarlo en tu historial de análisis.';

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

  @override
  String get analysisInProgress => 'Análisis en curso';

  @override
  String get analysisMayTakeTime => 'Puede tardar de 20 a 30 segundos';

  @override
  String get analysisHistoryTitle => 'Mis análisis';

  @override
  String get analysisHistorySection => 'Análisis anteriores';

  @override
  String get analysisHistoryEmpty => 'Aún no hay análisis';

  @override
  String get analysisHistoryLoginHint =>
      'Inicia sesión para ver tus análisis anteriores';

  @override
  String get analysisTypeQuick => 'Rápido';

  @override
  String get analysisTypeDeep => 'Profundo';

  @override
  String get favoritesTab => 'Favoritos';

  @override
  String get favoritesLoginHint =>
      'Inicia sesión para ver tus monedas favoritas';

  @override
  String get favoritesEmpty => 'Aún no hay favoritos';

  @override
  String get alertTooltip => 'Alerta de precio';

  @override
  String get myAlerts => 'Mis alertas';

  @override
  String get alertsTabActive => 'Activas';

  @override
  String get alertsTabHistory => 'Historial';

  @override
  String get alertSetTitle => 'Crear alerta de precio';

  @override
  String alertCurrentPrice(String price) {
    return 'Precio actual: $price';
  }

  @override
  String get alertWaitingPrice => 'Esperando el precio actual...';

  @override
  String get alertTargetPriceLabel => 'Precio objetivo';

  @override
  String alertWillTriggerAbove(String price) {
    return 'Recibirás una notificación cuando el precio suba a $price o más.';
  }

  @override
  String alertWillTriggerBelow(String price) {
    return 'Recibirás una notificación cuando el precio baje a $price o menos.';
  }

  @override
  String get alertEnterDifferentPrice =>
      'Introduce un precio objetivo distinto del precio actual.';

  @override
  String get alertSetButton => 'Crear alerta';

  @override
  String alertSetSuccess(String symbol) {
    return 'Alerta creada para $symbol';
  }

  @override
  String get alertActiveForCoin => 'Alertas activas de esta moneda';

  @override
  String alertLimitInfo(int count, int max) {
    return '$count de $max alertas activas usadas';
  }

  @override
  String get alertCancelTooltip => 'Cancelar alerta';

  @override
  String get alertCanceled => 'Alerta cancelada';

  @override
  String get alertRearm => 'Crear de nuevo';

  @override
  String get alertRearmed => 'Alerta creada de nuevo';

  @override
  String alertDirectionAbove(String price) {
    return 'Por encima de $price';
  }

  @override
  String alertDirectionBelow(String price) {
    return 'Por debajo de $price';
  }

  @override
  String get alertStatusTriggered => 'Activada';

  @override
  String get alertStatusCanceled => 'Cancelada';

  @override
  String alertTriggeredAt(String date, String price) {
    return '$date, precio $price';
  }

  @override
  String get alertsEmptyActive =>
      'No hay alertas activas. Abre el gráfico de una moneda y toca la campana para crear una.';

  @override
  String get alertsEmptyHistory => 'Aún no hay alertas activadas o canceladas.';

  @override
  String get alertProTitle => 'Las alertas de precio son una función Pro';

  @override
  String get alertProBody =>
      'Los miembros Pro reciben una notificación push en cuanto una moneda alcanza su precio objetivo.';

  @override
  String get alertErrorProRequired =>
      'Las alertas de precio son solo para miembros Pro.';

  @override
  String alertErrorLimitReached(int limit) {
    return 'Puedes tener como máximo $limit alertas activas. Cancela una para añadir otra.';
  }

  @override
  String get alertErrorDuplicate =>
      'Ya tienes una alerta activa para este precio.';

  @override
  String get alertErrorGeneric =>
      'Algo salió mal con la alerta. Inténtalo de nuevo.';

  @override
  String get legalAboutSection => 'Legal y acerca de';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get deleteAccountPage => 'Eliminar cuenta';

  @override
  String get support => 'Soporte';

  @override
  String get financialDisclaimer => 'Aviso financiero';

  @override
  String get financialDisclaimerText =>
      'CryptoAnaliz no ofrece asesoramiento de inversión. Las señales y los análisis son solo informativos y no ofrecen garantías. Invertir en criptoactivos conlleva un riesgo elevado; usted es responsable de sus decisiones y de las posibles pérdidas.';

  @override
  String get appVersion => 'Versión de la app';

  @override
  String get close => 'Cerrar';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace.';

  @override
  String get proUpsellBenefitsHeading => 'Con Pro obtienes';

  @override
  String get proBenefitNoAds => 'Sin anuncios';

  @override
  String get proBenefitDeepAnalysis => 'Análisis profundo';

  @override
  String get proBenefitCredits => '300 créditos cada mes';

  @override
  String get proBenefitAlerts => 'Notificaciones push y alertas de precio';

  @override
  String get proBenefitTimeframes =>
      'Marcos de 1m y 5m y señales de nivel fuerte (3)';

  @override
  String get proBenefitWatchlist => 'Lista de seguimiento ilimitada';

  @override
  String get proUpsellNotNow => 'Ahora no';

  @override
  String get proUpsellDeepTitle => 'El análisis profundo es una función Pro';

  @override
  String get proUpsellDeepBody =>
      'Los miembros Pro reciben un análisis profundo más detallado y multi-marco de cualquier moneda.';

  @override
  String get proUpsellTimeframeTitle => '1m y 5m son marcos temporales Pro';

  @override
  String get proUpsellTimeframeBody =>
      'Los miembros Pro pueden ver los marcos más rápidos y ejecutar análisis de IA en ellos.';

  @override
  String get proUpsellStrongSignalsTitle =>
      'Las señales de nivel fuerte (3) son una función Pro';

  @override
  String get proUpsellStrongSignalsBody =>
      'Los miembros Pro ven todos los niveles de señal en el gráfico, incluido el más fuerte (3).';

  @override
  String proUpsellWatchlistTitle(int count, int limit) {
    return 'Tu lista de seguimiento está llena ($count/$limit)';
  }

  @override
  String get proUpsellWatchlistBody =>
      'Mejora a Pro para tener una lista de seguimiento ilimitada.';

  @override
  String get proUpsellGenericTitle => 'Esta es una función Pro';

  @override
  String get proUpsellGenericBody => 'Mejora a Pro para desbloquearla.';

  @override
  String get proBadgeTooltip => 'Función Pro';

  @override
  String get adLabel => 'Anuncio';

  @override
  String rewardedWatchButton(int amount, int remaining) {
    return 'Mira un anuncio, +$amount créditos (quedan hoy: $remaining)';
  }

  @override
  String get rewardedEarnedPending =>
      '¡Gracias! Tus créditos llegarán en unos segundos.';

  @override
  String get rewardedAdUnavailable =>
      'No hay ningún anuncio disponible ahora. Inténtalo de nuevo en un rato.';

  @override
  String get rewardedNotCompleted =>
      'El anuncio se cerró antes de terminar, así que no se añadieron créditos.';

  @override
  String get insufficientCreditTitle => 'Créditos insuficientes';

  @override
  String get insufficientCreditBody =>
      'No tienes créditos suficientes para este análisis. Puedes comprar créditos para continuar.';

  @override
  String get insufficientCreditBodyWithAd =>
      'No tienes créditos suficientes para este análisis. Compra créditos o mira un anuncio corto para ganar créditos gratis.';

  @override
  String get notifChannelAnnouncementsName => 'Anuncios';

  @override
  String get notifChannelAnnouncementsDesc => 'Novedades y anuncios de la app';

  @override
  String get notifChannelCreditsName => 'Créditos';

  @override
  String get notifChannelCreditsDesc =>
      'Notificaciones cuando se añaden créditos a tu cuenta';

  @override
  String get notifChannelSignalsName => 'Señales de la lista de seguimiento';

  @override
  String get notifChannelSignalsDesc =>
      'Señales de trading de las monedas que sigues';

  @override
  String get notifChannelAlertsName => 'Alertas de precio';

  @override
  String get notifChannelAlertsDesc =>
      'Notificaciones cuando una moneda alcanza tu precio objetivo';

  @override
  String get notifRationaleTitle => '¿Activar las notificaciones?';

  @override
  String get notifRationaleBody =>
      'Recibe notificaciones de créditos y anuncios. Los miembros Pro también reciben notificaciones de señales y alertas de precio.';

  @override
  String get notifRationaleAllow => 'Permitir';

  @override
  String get notifRationaleLater => 'Ahora no';

  @override
  String get notifSettingsSection => 'Notificaciones';

  @override
  String get notifAnnouncementsTitle => 'Anuncios';

  @override
  String get notifAnnouncementsSubtitle =>
      'Novedades y actualizaciones de la app';

  @override
  String get notifCreditsTitle => 'Notificaciones de créditos';

  @override
  String get notifCreditsSubtitle => 'Cuando se añaden créditos a tu cuenta';

  @override
  String get notifSignalsTitle => 'Señales de la lista de seguimiento';

  @override
  String get notifSignalsSubtitle => 'Nuevas señales de las monedas que sigues';

  @override
  String get notifAlertsTitle => 'Alertas de precio';

  @override
  String get notifAlertsSubtitle =>
      'Cuando una moneda alcanza tu precio objetivo';

  @override
  String get notifPermissionOffTitle =>
      'El permiso de notificaciones está desactivado';

  @override
  String get notifPermissionOffBody =>
      'No recibirás notificaciones hasta que las permitas.';

  @override
  String get notifOpenSystemSettings => 'Abrir ajustes del sistema';

  @override
  String get notifPermissionManual =>
      'Activa las notificaciones en los ajustes del teléfono.';

  @override
  String get notifSettingsLoadFailed =>
      'No se pudieron cargar los ajustes de notificaciones.';

  @override
  String get notifSettingsSaveFailed =>
      'No se pudo guardar el cambio. Inténtalo de nuevo.';

  @override
  String get proUpsellPushSignalsTitle =>
      'Las notificaciones de señales son una función Pro';

  @override
  String get proUpsellPushSignalsBody =>
      'Los miembros Pro reciben una notificación push cuando una moneda de su lista de seguimiento tiene una nueva señal.';

  @override
  String get structuredBiasBullish => 'Alcista';

  @override
  String get structuredBiasBearish => 'Bajista';

  @override
  String get structuredBiasNeutral => 'Neutral';

  @override
  String structuredConfidence(int value) {
    return 'Confianza $value%';
  }

  @override
  String structuredHorizon(String label) {
    return 'Horizonte: $label';
  }

  @override
  String structuredHorizonCandles(int count) {
    return '$count velas';
  }

  @override
  String get structuredSectionSummary => 'Resumen';

  @override
  String get structuredSectionDrivers => 'Factores clave';

  @override
  String get structuredSectionScenarios => 'Escenarios';

  @override
  String get structuredSectionLevels => 'Niveles clave';

  @override
  String get structuredSectionRisks => 'Riesgos';

  @override
  String get structuredSectionWatch => 'Qué vigilar';

  @override
  String get structuredSectionSources => 'Fuentes';

  @override
  String get structuredScenarioBull => 'Escenario alcista';

  @override
  String get structuredScenarioBase => 'Escenario base';

  @override
  String get structuredScenarioBear => 'Escenario bajista';

  @override
  String structuredScenarioTrigger(String price) {
    return 'Disparador: $price';
  }

  @override
  String structuredScenarioTarget(String price) {
    return 'Objetivo: $price';
  }

  @override
  String get structuredLevelResistance => 'Resistencia';

  @override
  String get structuredLevelSupport => 'Soporte';

  @override
  String get structuredLevelInvalidation => 'Invalidación';

  @override
  String get structuredLevelPrice => 'Precio en el análisis';

  @override
  String structuredDataMissing(String sources) {
    return 'Algunas fuentes de datos no estuvieron disponibles: $sources';
  }

  @override
  String get structuredDisclaimer => 'No es asesoramiento de inversión.';

  @override
  String get structuredSourceOpenFailed => 'No se pudo abrir el enlace.';

  @override
  String get glossaryTitle => 'Glosario de términos técnicos';

  @override
  String get glossarySearchHint => 'Buscar términos (p. ej. RSI, funding)';

  @override
  String get glossaryNoResults => 'No hay términos coincidentes.';

  @override
  String get glossaryLearnTerms => 'Aprende los términos';

  @override
  String get glossaryIntro =>
      'Explicaciones breves y neutrales de los términos usados en los análisis. Solo informativo, no es asesoramiento de inversión.';

  @override
  String get structuredConclusionTitle => 'Conclusión';

  @override
  String get structuredSectionBalance => 'Balance de factores';

  @override
  String get structuredSectionLadder => 'Escalera de precios';

  @override
  String get structuredSectionDataNotes => 'Notas de datos';

  @override
  String get structuredSectionOdds => 'Probabilidad de escenarios';

  @override
  String structuredBalanceItem(String label, int count) {
    return '$label $count';
  }

  @override
  String analysisPreparedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preparado hace $count min',
      one: 'Preparado hace 1 min',
    );
    return '$_temp0';
  }

  @override
  String analysisPreparedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preparado hace $count h',
      one: 'Preparado hace 1 h',
    );
    return '$_temp0';
  }

  @override
  String analysisPreparedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preparado hace $count días',
      one: 'Preparado hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get analysisPreparedJustNow => 'Recién preparado';
}
