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
  String get strongSignalsProNote =>
      'Pro añade las señales más fuertes (nivel 3), 1m/5m y alertas';

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
  String get radarTopPick => 'Mejor opción';

  @override
  String get radarTierStrong => 'Fuerte';

  @override
  String get radarTierGood => 'Buena';

  @override
  String get radarTierWatch => 'Vigilar';

  @override
  String get radarTierWeak => 'Baja';

  @override
  String get radarEmptyTitle => 'Ahora no hay monedas sobrevendidas';

  @override
  String get radarInfoTooltip => 'Cómo funciona el radar';

  @override
  String get radarHowTitle => 'Cómo funciona el radar';

  @override
  String get radarHowOversold =>
      'El radar lista monedas que parecen sobrevendidas: el RSI está bajo el umbral de sobreventa y el precio cayó bajo la banda de Bollinger inferior. Puede indicar que la caída está muy estirada.';

  @override
  String radarHowScore(
    int strong,
    int good,
    int goodMax,
    int watch,
    int watchMax,
  ) {
    return 'La puntuación (0-100) mide la fuerza de la configuración de sobreventa: $strong+ Fuerte, $good-$goodMax Buena, $watch-$watchMax Vigilar, menos de $watch Baja.';
  }

  @override
  String get radarHowFactors =>
      'La puntuación combina profundidad de sobreventa, extensión de Bollinger, tendencia de marco mayor, volumen, señales de reversión y cercanía al soporte, con una protección de liquidez que limita los mercados poco profundos.';

  @override
  String radarTermLocked(String term) {
    return '$term está bloqueado';
  }

  @override
  String get radarUpsellGuest => 'Inicia sesión para ver más';

  @override
  String get radarUpsellFree =>
      'Pro desbloquea todos los plazos, hasta 20 oportunidades, notas de IA y alertas del radar';

  @override
  String get radarAiNote => 'Nota de IA';

  @override
  String get radarAiNoteHint =>
      'Comentario automático, no es asesoría financiera.';

  @override
  String get radarFactorsTitle => 'Factores de la puntuación';

  @override
  String get radarFactorOversold => 'Sobreventa';

  @override
  String get radarFactorBollinger => 'Bollinger';

  @override
  String get radarFactorTrend => 'Tendencia';

  @override
  String get radarFactorVolume => 'Volumen';

  @override
  String get radarFactorReversal => 'Reversión';

  @override
  String get radarFactorSupport => 'Soporte';

  @override
  String get radarTrendUp => 'Tendencia alcista';

  @override
  String get radarTrendDown => 'Tendencia bajista';

  @override
  String radarVolumeRatio(String v) {
    return 'Vol x$v';
  }

  @override
  String get radarDetailsTooltip => 'Ver detalles';

  @override
  String get radarHideDetailsTooltip => 'Ocultar detalles';

  @override
  String get radarHowTerms =>
      'El corto, medio y largo plazo usan distintos marcos temporales. Elige el que encaje con tu horizonte.';

  @override
  String get radarHowDisclaimer =>
      'El radar es una herramienta de filtrado técnico, no asesoría financiera. Una moneda sobrevendida puede seguir cayendo; investiga por tu cuenta.';

  @override
  String radarRsi(String v) {
    return 'RSI $v';
  }

  @override
  String radarScoreSemantics(int score, String tier) {
    return 'Puntuación $score de 100, $tier';
  }

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
  String get authWelcomeSubtitleNoGuest =>
      'Inicia sesión para ejecutar análisis con IA, seguir monedas y recibir notificaciones.';

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
  String get crashReportingTitle => 'Informes de fallos';

  @override
  String get crashReportingNote =>
      'Los informes anónimos de fallos (versión de la app, idioma, pantalla, sesión iniciada sí/no) nos ayudan a corregir errores. No incluyen datos personales ni financieros.';

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
  String get insufficientCreditTitle => 'Créditos insuficientes';

  @override
  String get insufficientCreditBody =>
      'No tienes créditos suficientes para este análisis. Puedes comprar créditos para continuar.';

  @override
  String get insufficientCreditBodyWithAd =>
      'No tienes créditos suficientes para este análisis. Mira un anuncio corto para hacer este análisis rápido, compra créditos o hazte Pro.';

  @override
  String get insufficientCreditDeepBody =>
      'No tienes créditos suficientes para un análisis profundo. Puedes comprar créditos o hacerte Pro.';

  @override
  String get adAnalysisDeepAlwaysCredits =>
      'El análisis profundo siempre consume créditos.';

  @override
  String get adAnalysisWatchButton => 'Ver un anuncio y analizar';

  @override
  String adAnalysisRemainingToday(int remaining) {
    return 'Quedan hoy: $remaining';
  }

  @override
  String get adAnalysisCapReached =>
      'Has agotado los análisis con anuncios de hoy: compra créditos o hazte Pro.';

  @override
  String get adAnalysisEmailUnverified =>
      'Verifica tu correo electrónico para hacer un análisis viendo un anuncio.';

  @override
  String get adAnalysisAdUnavailable =>
      'No se pudo cargar el anuncio ahora. Inténtalo de nuevo en un momento.';

  @override
  String get adAnalysisVerifyTimeout =>
      'Aún no pudimos confirmar el anuncio. Inténtalo de nuevo en unos segundos.';

  @override
  String get adAnalysisSessionExpired =>
      'La sesión del anuncio ha caducado. Inténtalo de nuevo.';

  @override
  String get adAnalysisNotFree =>
      'El análisis con anuncios solo está disponible para miembros gratuitos.';

  @override
  String get adAnalysisDisabled =>
      'El análisis con anuncios no está disponible ahora.';

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

  @override
  String get tabHome => 'Inicio';

  @override
  String homeStaleNote(String ago) {
    return 'No actualizado · actualizado $ago';
  }

  @override
  String get homeStaleNoTime => 'No actualizado';

  @override
  String get homeGuestUnlock =>
      'Inicia sesión para desbloquear análisis, lista de seguimiento y alertas';

  @override
  String get homeErrorTitle => 'No se pudo cargar el resumen';

  @override
  String get homeLoadingSemantics => 'Cargando resumen';

  @override
  String get homeMarketTitle => 'Pulso del mercado';

  @override
  String get homeFearGreedTitle => 'Miedo y codicia';

  @override
  String get homeFngExtremeFear => 'Miedo extremo';

  @override
  String get homeFngFear => 'Miedo';

  @override
  String get homeFngNeutral => 'Neutral';

  @override
  String get homeFngGreed => 'Codicia';

  @override
  String get homeFngExtremeGreed => 'Codicia extrema';

  @override
  String homeFngChange7d(String delta) {
    return '7 d: $delta';
  }

  @override
  String homeFngSemantics(int value, String label) {
    return 'Índice de miedo y codicia $value, $label';
  }

  @override
  String get homeBtcDominance => 'Dominancia BTC';

  @override
  String get homeTotalCap => 'Capitalización total';

  @override
  String homeRegimeLabel(String regime) {
    return 'Régimen: $regime';
  }

  @override
  String get homeRegimeBull => 'Alcista';

  @override
  String get homeRegimeBear => 'Bajista';

  @override
  String get homeRegimeSideways => 'Lateral';

  @override
  String get homeRegimeUnknown => 'Incierto';

  @override
  String get homeMarketUnavailable =>
      'Los datos del mercado no están disponibles ahora.';

  @override
  String get homeMoversTitle => 'Mi lista';

  @override
  String get homeMoversEmpty =>
      'Sigue monedas para ver aquí sus mayores movimientos de 24 h.';

  @override
  String get homeMoversEmptyAction => 'Ir a mi lista';

  @override
  String get homeRadarTitle => 'Últimas señales del Radar';

  @override
  String get homeRadarEmpty => 'No hay señales nuevas en el radar ahora.';

  @override
  String get homeSignalBuy => 'Comprar';

  @override
  String get homeSignalSell => 'Vender';

  @override
  String homeSignalStrength(int n) {
    return 'Fuerza $n/3';
  }

  @override
  String get homeAnalysisTitle => 'Tu último análisis profundo';

  @override
  String get homeAnalysisEmpty =>
      'Aún no has hecho un análisis profundo. Elige una moneda y prueba el primero.';

  @override
  String get homeAnalysisNew => 'Nuevo análisis';

  @override
  String get homeAnalysisCachedBadge => 'Resultado compartido';

  @override
  String get homeAnalysisOpenFailed =>
      'No se pudo abrir este análisis. Inténtalo de nuevo.';

  @override
  String get homeEventsTitle => 'Próximos eventos';

  @override
  String homeInMinutes(int n) {
    return 'en $n min';
  }

  @override
  String homeInHours(int n) {
    return 'en $n h';
  }

  @override
  String homeInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'en $n días',
      one: 'en 1 día',
    );
    return '$_temp0';
  }

  @override
  String get homeEventHigh => 'Importancia alta';

  @override
  String get homeEventMedium => 'Importancia media';

  @override
  String get homeLearnTitle => 'Aprende';

  @override
  String get homeTermOfDay => 'Término del día';

  @override
  String get homeOpenGlossary => 'Abrir glosario';

  @override
  String get homeProPromoTitle => 'Mejora a Pro';

  @override
  String get homeProPromoBody =>
      'Análisis profundo, alertas de precio y créditos mensuales, cuando lo necesites.';

  @override
  String get homeProPromoAction => 'Ver ventajas de Pro';

  @override
  String get homeFooterDisclaimer =>
      'Solo con fines informativos; no es asesoramiento de inversión.';

  @override
  String get homeFooterSources =>
      'Fuentes de datos: Binance, CoinMarketCap, Alternative.me (Fear & Greed Index), FRED.';

  @override
  String get startupPageTitle => 'Página de inicio';

  @override
  String get homeMktTitle => 'Mercado';

  @override
  String get homeMktGainers => 'Ganadores';

  @override
  String get homeMktLosers => 'Perdedores';

  @override
  String get homeMktVolume => 'Volumen';

  @override
  String get homeMktMore => 'Ver más';

  @override
  String get homeMktLess => 'Ver menos';

  @override
  String homeMktVolumeShort(String amount) {
    return 'Vol. $amount';
  }

  @override
  String get homeQuickDeep => 'Análisis profundo';

  @override
  String get homeQuickAlerts => 'Alertas';

  @override
  String get homeQuickGlossary => 'Glosario';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String quickAnalysisButtonCost(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost créditos',
      one: '1 crédito',
    );
    return 'Análisis rápido · $_temp0';
  }

  @override
  String deepAnalysisButtonCost(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost créditos',
      one: '1 crédito',
    );
    return 'Análisis profundo · $_temp0';
  }

  @override
  String get chartTabSummary => 'Resumen';

  @override
  String get chartTabAnalyses => 'Mis análisis';

  @override
  String get chartTabMarket => 'Mercado';

  @override
  String get chartTabSignals => 'Señales';

  @override
  String get chartTabAlerts => 'Alertas';

  @override
  String get ovEmpty => 'Aún no hay resumen para esta moneda.';

  @override
  String get ovMarketCap => 'Capitalización';

  @override
  String get ovFdv => 'FDV';

  @override
  String get ovVolume24h => 'Volumen 24h';

  @override
  String get ovVolMcap => 'Volumen / capitalización';

  @override
  String get ovSupplyTitle => 'Suministro';

  @override
  String get ovCirculating => 'En circulación';

  @override
  String get ovTotalSupply => 'Total';

  @override
  String get ovMaxSupply => 'Máximo';

  @override
  String get ovNoMaxSupply => 'Sin suministro máximo';

  @override
  String ovCirculatingOfMax(String pct) {
    return 'El $pct% del suministro máximo está en circulación';
  }

  @override
  String get ovPriceChangeTitle => 'Cambio de precio';

  @override
  String get ovPeriod24h => '24h';

  @override
  String get ovPeriod7d => '7d';

  @override
  String get ovPeriod30d => '30d';

  @override
  String get ovPeriod90d => '90d';

  @override
  String get ovAth => 'Máximo histórico';

  @override
  String get ovAtl => 'Mínimo histórico';

  @override
  String ovFromCurrent(String pct) {
    return '$pct respecto al precio actual';
  }

  @override
  String get ovCategory => 'Categoría';

  @override
  String get ovTags => 'Etiquetas';

  @override
  String get ovPlatform => 'Plataforma';

  @override
  String get ovCoinAge => 'Antigüedad';

  @override
  String get ovListingAge => 'Tiempo listada';

  @override
  String get ovNewListing => 'Nueva en el listado';

  @override
  String ovAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String ovAgeMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mes',
    );
    return '$_temp0';
  }

  @override
  String ovAgeYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count años',
      one: '1 año',
    );
    return '$_temp0';
  }

  @override
  String get ovSource => 'Datos: CoinMarketCap, Binance';

  @override
  String get tabLoadFailed => 'No se pudo cargar esta sección.';

  @override
  String get glossaryHelpTooltip => '¿Qué significa?';

  @override
  String get coAnalysesEmptyTitle => 'Aún no tienes análisis de esta moneda';

  @override
  String get coAnalysesEmptyBody =>
      'Haz tu primer análisis rápido o profundo con los botones de arriba.';

  @override
  String get coAnalysesLoginHint =>
      'Inicia sesión para ver tus análisis de esta moneda';

  @override
  String get coAnalysisCached => 'en caché';

  @override
  String get relAgoNow => 'justo ahora';

  @override
  String relAgoMinutes(int count) {
    return 'hace $count min';
  }

  @override
  String relAgoHours(int count) {
    return 'hace $count h';
  }

  @override
  String relAgoDays(int count) {
    return 'hace $count d';
  }

  @override
  String get mkEmpty => 'Aún no hay datos de mercado para esta moneda.';

  @override
  String get mkFuturesTitle => 'Futuros (derivados)';

  @override
  String get mkFunding => 'Tasa de financiación';

  @override
  String mkFundingPercentile(String pct) {
    return 'Mayor que el $pct% de las lecturas recientes';
  }

  @override
  String get mkFundingHintHigh =>
      'La financiación es alta frente a su historial reciente: los largos pagan a los cortos, señal de posiciones largas saturadas.';

  @override
  String get mkFundingHintLow =>
      'La financiación es baja frente a su historial reciente: los cortos pagan a los largos o los largos no están saturados.';

  @override
  String get mkFundingHintNormal =>
      'La financiación está en su rango habitual.';

  @override
  String get mkOpenInterest => 'Cambio del interés abierto';

  @override
  String get mkOiHint =>
      'Si el interés abierto sube, entra dinero nuevo en posiciones; si baja, se cierran posiciones.';

  @override
  String get mkLongShort => 'Equilibrio largo / corto';

  @override
  String mkLongShare(String pct) {
    return 'Cuota larga $pct%';
  }

  @override
  String get mkLsRatio => 'Ratio largo/corto';

  @override
  String get mkTopTrader => 'Ratio de los mejores traders';

  @override
  String get mkLongShortHint =>
      'Por encima de 1 hay más largos que cortos. Describe el posicionamiento, no la dirección.';

  @override
  String get mkTaker => 'Compras / ventas taker';

  @override
  String get mkTakerHintBuy =>
      'Los compradores agresivos dominan las operaciones recientes.';

  @override
  String get mkTakerHintSell =>
      'Los vendedores agresivos dominan las operaciones recientes.';

  @override
  String get mkTakerHintBalanced =>
      'Las compras y ventas agresivas están equilibradas.';

  @override
  String get mkBasis => 'Base (futuros vs spot)';

  @override
  String get mkBasisHintPos =>
      'Los futuros cotizan por encima del spot (prima).';

  @override
  String get mkBasisHintNeg =>
      'Los futuros cotizan por debajo del spot (descuento).';

  @override
  String get mkLiquidityTitle => 'Liquidez';

  @override
  String get mkSpread => 'Diferencial (spread)';

  @override
  String mkSpreadValue(String bps) {
    return '$bps pb';
  }

  @override
  String get mkDepthTitle => 'Profundidad del libro de órdenes';

  @override
  String get mkDepthBid => 'Compra';

  @override
  String get mkDepthAsk => 'Venta';

  @override
  String mkDepthImbalance(String pct) {
    return 'Ratio de profundidad compra/venta $pct';
  }

  @override
  String get mkDepthNote =>
      'La profundidad es una instantánea del libro de órdenes, no una señal.';

  @override
  String get mkActivityTitle => 'Actividad';

  @override
  String get mkVolume24h => 'Volumen 24h';

  @override
  String get mkTrades24h => 'Operaciones (24h)';

  @override
  String get mkVolumeRank => 'Ranking de volumen';

  @override
  String get mkSpotNote =>
      'Las métricas de derivados (financiación, interés abierto, largo/corto) solo aplican a monedas de futuros.';

  @override
  String get sgEmptyTitle => 'Aún no hay señales';

  @override
  String get sgEmptyBody =>
      'No hay flechas para esta moneda y temporalidad en el historial cargado.';

  @override
  String get sgUnsupported =>
      'Las señales están disponibles en 15m, 1h, 4h y 1d.';

  @override
  String sgPriceAtSignal(String price) {
    return 'En la señal $price';
  }

  @override
  String sgSinceSignal(String pct) {
    return '$pct desde entonces';
  }

  @override
  String get sgTapHint => 'Toca una fila para volver al gráfico.';

  @override
  String get alTabEmpty => 'Aún no tienes alertas para esta moneda.';

  @override
  String get alTabAdd => 'Añadir alerta';

  @override
  String get alTabLoginHint => 'Inicia sesión para crear alertas de precio';

  @override
  String get alTabHistory => 'Alertas anteriores';

  @override
  String get ovPeriod1h => '1h';

  @override
  String get ovPeriod4h => '4h';

  @override
  String mkDepthIncomplete(String pct) {
    return 'Libro poco profundo: ventana cubierta ±$pct%';
  }

  @override
  String ovSourceFrom(String sources) {
    return 'Datos: $sources';
  }

  @override
  String get creditSummaryTitle => 'Tus créditos';

  @override
  String creditSummaryTotal(int count) {
    return 'Total: $count';
  }

  @override
  String creditSummaryMonthly(int left, int total) {
    return 'Créditos mensuales $left / $total';
  }

  @override
  String creditSummaryMonthlyLeft(int left) {
    return 'Créditos mensuales $left';
  }

  @override
  String creditSummaryRenewal(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'en $days días',
      one: 'en 1 día',
      zero: 'hoy',
    );
    return 'Renovación: $date ($_temp0)';
  }

  @override
  String creditSummaryPurchased(int count) {
    return 'Créditos comprados $count — no caducan';
  }

  @override
  String get creditPolicyGeneric =>
      'Los créditos mensuales no se acumulan al mes siguiente. El día de renovación, los créditos mensuales restantes se completan hasta la cantidad de tu paquete (Gratis: 10, Pro: 300). Los créditos comprados no caducan; primero se gastan los mensuales.';

  @override
  String creditPolicyWithTotal(int total) {
    return 'Los créditos mensuales no se acumulan al mes siguiente. El día de renovación, los créditos mensuales restantes se completan hasta la cantidad de tu paquete ($total). Los créditos comprados no caducan; primero se gastan los mensuales.';
  }

  @override
  String get creditPolicyShort =>
      'Los créditos mensuales no se acumulan; se completan hasta la cantidad de tu paquete el día de renovación. Los créditos comprados no caducan.';

  @override
  String planMonthlyNoCarry(int count) {
    return '$count créditos cada mes · no se acumulan, se completan hasta $count créditos el día de renovación';
  }

  @override
  String insufficientRenewsOn(String date) {
    return 'Tus créditos mensuales se renuevan el $date.';
  }

  @override
  String insufficientKeepsPurchased(int count) {
    return 'Tus $count créditos comprados no caducan.';
  }

  @override
  String get creditTxMonthlyReset => 'Renovación de créditos mensuales';

  @override
  String get watchlistEmptyHint =>
      'Toca la estrella en el gráfico de una moneda para añadirla aquí.';

  @override
  String get marketTypeSpot => 'Spot';

  @override
  String get marketTypeFutures => 'Futuros';

  @override
  String get quickAnalysisShort => 'Análisis rápido';

  @override
  String get deepAnalysisShort => 'Análisis profundo';

  @override
  String get subTagline =>
      'Señales más rápidas, análisis más profundo, cero anuncios.';

  @override
  String subBenefitCreditsTitle(int count) {
    return '$count créditos cada mes';
  }

  @override
  String get subBenefitCreditsDesc =>
      'Se completan en cada renovación. Los créditos mensuales sin usar no se acumulan; los créditos que compras nunca caducan.';

  @override
  String get subBenefitDeepDesc =>
      'Análisis profundo detallado y multimarco para cualquier moneda.';

  @override
  String get subBenefitAlertsDesc =>
      'Crea alertas de precio y recibe notificaciones push de nuevas señales de tu lista de seguimiento.';

  @override
  String get subBenefitTimeframesDesc =>
      'Desbloquea los gráficos rápidos de 1m y 5m y las señales más fuertes de nivel 3.';

  @override
  String get subBenefitNoAdsDesc => 'Usa toda la aplicación sin anuncios.';

  @override
  String get subscribe => 'Suscribirse';

  @override
  String get subCancelNote => 'Cancela cuando quieras en Google Play.';

  @override
  String get subAlreadyProTitle => 'Eres miembro Pro';

  @override
  String get subAlreadyProBody =>
      '¡Gracias por tu apoyo! Puedes gestionar o cancelar tu suscripción en cualquier momento en Google Play.';

  @override
  String get subPlansHeading => 'Elige tu plan';

  @override
  String get gbTitle => 'Qué puedes hacer al iniciar sesión';

  @override
  String get gbHeroTagline =>
      'Crear una cuenta es gratis. Esto es lo que desbloquea.';

  @override
  String get gbHeading => 'Con tu cuenta gratuita';

  @override
  String gbCreditsTitle(int count) {
    return '$count créditos gratis cada mes';
  }

  @override
  String get gbCreditsTitleGeneric => 'Créditos gratis cada mes';

  @override
  String get gbCreditsDesc =>
      'Úsalos en análisis con IA. Los créditos mensuales sin usar no se acumulan; los que compras nunca caducan.';

  @override
  String get gbQuickTitle => 'Análisis con IA de cualquier moneda';

  @override
  String gbQuickDesc(int cost) {
    return 'Un análisis rápido cuesta $cost créditos.';
  }

  @override
  String get gbDeepTitle => 'Análisis profundo';

  @override
  String get gbDeepDesc =>
      'Análisis profundo detallado en varios plazos, pagado con créditos.';

  @override
  String gbSignalsTitle(int level) {
    return 'Señales del gráfico hasta el nivel $level';
  }

  @override
  String get gbSignalsDesc =>
      'Ve las señales de compra y venta en el gráfico y en la pestaña Señales.';

  @override
  String get gbWatchlistTitle => 'Tu lista de seguimiento';

  @override
  String gbWatchlistDescLimit(int count) {
    return 'Sigue hasta $count monedas y vigílalas desde la página de inicio.';
  }

  @override
  String get gbWatchlistDescUnlimited =>
      'Sigue tus monedas y vigílalas desde la página de inicio.';

  @override
  String get gbHistoryTitle => 'Historial de análisis';

  @override
  String get gbHistoryDesc =>
      'Cada análisis que haces se guarda para que puedas reabrirlo cuando quieras.';

  @override
  String get gbAlertsTitle => 'Alertas de precio y notificaciones';

  @override
  String get gbAlertsDesc =>
      'Recibe un aviso cuando se alcance un nivel de precio.';

  @override
  String get gbProTease =>
      '¿Quieres más? Pro añade análisis profundo, alertas de precio, las señales más fuertes y los plazos más rápidos.';

  @override
  String get homeLockedAction => 'Ver qué obtienes';

  @override
  String get homeLockedWatchlist =>
      'Inicia sesión para seguir monedas y ver aquí sus movimientos.';

  @override
  String get homeLockedAnalysis =>
      'Inicia sesión para hacer análisis con IA y ver aquí el último.';

  @override
  String get ovGuestHint =>
      'Inicia sesión para ver el resumen y los datos de mercado de esta moneda';

  @override
  String get sgGuestHint => 'Inicia sesión para ver las señales de esta moneda';

  @override
  String get signalsGuestNote => 'Inicia sesión para ver las señales';
}
