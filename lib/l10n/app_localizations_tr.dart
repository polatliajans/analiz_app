// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Kripto Analiz';

  @override
  String get chooseLanguage => 'Dilini seç';

  @override
  String get continueButton => 'Devam';

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameTr => 'Türkçe';

  @override
  String get languageNameEs => 'Español';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String errorOccurred(String details) {
    return 'Bir hata oluştu: $details';
  }

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get logIn => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get logOut => 'Çıkış Yap';

  @override
  String get cancel => 'İptal';

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get deleteAccountConfirmTitle => 'Hesabın silinsin mi?';

  @override
  String get deleteAccountConfirmBody =>
      'Hesabın ve tüm verilerin kalıcı olarak silinir: takip listesi, analiz geçmişi, krediler, bildirimler ve bağlı giriş yöntemleri. Bu işlem geri alınamaz.';

  @override
  String get deleteAccountProNote =>
      'Aktif bir Pro aboneliğin varsa, hesabı silmek aboneliği iptal etmez. Ücretlendirilmeye devam etmemek için aboneliği Google Play\'den ayrıca iptal etmelisin.';

  @override
  String get deleteAccountConfirmAction => 'Sil';

  @override
  String deleteAccountCreditsLost(int credits) {
    return '$credits krediniz silinecek ve iade edilmeyecek.';
  }

  @override
  String get deleteAccountManageSubscription =>
      'Google Play\'de aboneliği yönet';

  @override
  String get deleteAccountAckCheckbox =>
      'Kredilerimin silineceğini ve iade edilmeyeceğini anlıyorum';

  @override
  String get deleteAccountOpenFailed => 'Google Play açılamadı.';

  @override
  String get errorPurchaseAlreadyProcessed =>
      'Bu satın alma daha önce işlendi ve tekrar kullanılamaz.';

  @override
  String get myAccount => 'Hesabım';

  @override
  String get myWatchlist => 'Takip Listem';

  @override
  String get mustLogIn => 'Giriş yapmalısın';

  @override
  String get buy => 'Satın Al';

  @override
  String accountEmail(String email) {
    return 'E-posta: $email';
  }

  @override
  String accountRole(String role) {
    return 'Rol: $role';
  }

  @override
  String get roleFree => 'Ücretsiz';

  @override
  String get rolePro => 'Pro';

  @override
  String accountCreditBalance(int count) {
    return 'Kredi Bakiyesi: $count';
  }

  @override
  String get buyCredits => 'Kredi Satın Al';

  @override
  String get upgradeToPro => 'Pro\'ya Yükselt';

  @override
  String get logInOrSignUp => 'Giriş Yap / Kayıt Ol';

  @override
  String get coins => 'Coinler';

  @override
  String get radar => 'Radar';

  @override
  String get searchSymbol => 'Sembol ara...';

  @override
  String get noCoinsFound => 'Coin bulunamadı';

  @override
  String volumeLabel(String value) {
    return 'Hacim: $value';
  }

  @override
  String get noCandleData => 'Mum verisi yok';

  @override
  String get strongSignalsProNote => 'Güçlü (3) kademe sinyaller Pro\'da';

  @override
  String creditsSpent(int count) {
    return '$count kredi harcandı';
  }

  @override
  String analysisFailed(String details) {
    return 'Analiz alınamadı: $details';
  }

  @override
  String deepAnalysisFailed(String details) {
    return 'Derin analiz alınamadı: $details';
  }

  @override
  String get quickAnalysisButton => 'Analiz Yaptır';

  @override
  String get deepAnalysisButton => 'Derin Analiz';

  @override
  String creditsCount(int count) {
    return '$count kredi';
  }

  @override
  String get proSubscription => 'Pro Abonelik';

  @override
  String durationDays(int count) {
    return '$count gün';
  }

  @override
  String monthlyCredits(int count) {
    return 'her ay $count kredi';
  }

  @override
  String purchaseFailed(String details) {
    return 'Satın alma başarısız: $details';
  }

  @override
  String get purchaseNoPackage =>
      'Satın alma doğrulanamadı, paket bilgisi bulunamadı. Uygulamayı yeniden açtığınızda tekrar denenecek.';

  @override
  String get purchaseNoPlan =>
      'Satın alma doğrulanamadı, abonelik planı bilgisi bulunamadı. Uygulamayı yeniden açtığınızda tekrar denenecek.';

  @override
  String get creditsAdded => 'Kredi bakiyenize eklendi.';

  @override
  String get proActivated => 'Pro aboneliğiniz aktifleştirildi.';

  @override
  String purchaseWillRetry(String details) {
    return '$details Satın alma tekrar denenecek.';
  }

  @override
  String get purchaseServiceUnavailable => 'Satın alma servisi kullanılamıyor.';

  @override
  String get productNotFound => 'Ürün mağazada bulunamadı.';

  @override
  String purchaseStartFailed(String details) {
    return 'Satın alma başlatılamadı: $details';
  }

  @override
  String get termAll => 'Tümü';

  @override
  String get termShort => 'Kısa';

  @override
  String get termMedium => 'Orta';

  @override
  String get termLong => 'Uzun';

  @override
  String get termShortLabel => 'Kısa vade';

  @override
  String get termMediumLabel => 'Orta vade';

  @override
  String get termLongLabel => 'Uzun vade';

  @override
  String get agoNow => 'şimdi';

  @override
  String agoMinutes(int n) {
    return '$n dk önce';
  }

  @override
  String agoHours(int n) {
    return '$n sa önce';
  }

  @override
  String agoDays(int n) {
    return '$n gün önce';
  }

  @override
  String get radarEmpty => 'Şu an teknik şartları sağlayan fırsat yok.';

  @override
  String get radarFooter =>
      'Skor 0-100: ne kadar aşırı satımda olduğunu gösterir. Yapay zeka destekli derin analiz için bir fırsata dokunun.';

  @override
  String get watchlistEmpty => 'Henüz takip ettiğin bir coin yok';

  @override
  String errorServer(int status) {
    return 'Sunucu hatası: $status';
  }

  @override
  String get errorInsufficientCredit => 'Yetersiz kredi.';

  @override
  String get errorAnalysisUnavailable => 'Analiz şu anda kullanılamıyor.';

  @override
  String get errorDeepAnalysisUnavailable =>
      'Derin analiz şu anda kullanılamıyor.';

  @override
  String get deepAnalysisWaitingTitle => 'Derin analiz çalışıyor';

  @override
  String get deepAnalysisWaitingBody =>
      'Bu genellikle 30-90 saniye sürer, bazen 4 dakikaya kadar uzayabilir. Bu ekrandan ayrılabilirsiniz - hazır olunca size bildirim göndereceğiz.';

  @override
  String get deepAnalysisFailedRefunded =>
      'Derin analiz tamamlanamadı. Kredileriniz iade edildi.';

  @override
  String get deepAnalysisAlreadyRunning =>
      'Zaten devam eden bir derin analiziniz var. Lütfen bitmesini bekleyin.';

  @override
  String get deepAnalysisCheckLater =>
      'Sunucuya ulaşılamadı. Analiziniz hâlâ çalışıyor olabilir - daha sonra tekrar bakın veya analiz geçmişinize göz atın.';

  @override
  String get deepAnalysisStillRunning =>
      'Analiziniz hâlâ çalışıyor. Hazır olunca bildirim alacaksınız; analiz geçmişinizden de ulaşabilirsiniz.';

  @override
  String errorAnalysisRequestFailed(String details) {
    return 'Analiz isteği gönderilemedi: $details';
  }

  @override
  String errorDeepAnalysisRequestFailed(String details) {
    return 'Derin analiz isteği gönderilemedi: $details';
  }

  @override
  String get errorSessionInvalid => 'Oturum doğrulanamadı.';

  @override
  String errorRequestFailed(String details) {
    return 'İstek gönderilemedi: $details';
  }

  @override
  String get errorInvalidCredentialsOrEmailTaken =>
      'Bilgiler hatalı veya bu e-posta zaten kayıtlı.';

  @override
  String errorSignalsFailed(String details) {
    return 'Sinyal verisi alınamadı: $details';
  }

  @override
  String errorServerUnreachable(String details) {
    return 'Sunucuya bağlanılamadı: $details';
  }

  @override
  String errorCreditPackagesFailed(String details) {
    return 'Kredi paketleri alınamadı: $details';
  }

  @override
  String errorDeviceTokenFailed(String details) {
    return 'Cihaz token\'ı kaydedilemedi: $details';
  }

  @override
  String get errorProOnly => 'Bu özellik sadece Pro üyeler içindir.';

  @override
  String errorPurchaseVerifyFailed(String details) {
    return 'Satın alma doğrulanamadı: $details';
  }

  @override
  String get errorPurchaseInvalid => 'Satın alma geçerli değil.';

  @override
  String get errorPlayVerificationUnreachable =>
      'Google Play doğrulama servisine ulaşılamadı.';

  @override
  String errorRadarFailed(String details) {
    return 'Radar alınamadı: $details';
  }

  @override
  String errorPlansFailed(String details) {
    return 'Abonelik planları alınamadı: $details';
  }

  @override
  String errorSubscriptionVerifyFailed(String details) {
    return 'Abonelik doğrulanamadı: $details';
  }

  @override
  String get errorSubscriptionInvalid => 'Abonelik geçerli değil.';

  @override
  String get errorWatchlistFailed => 'Takip listesi alınamadı.';

  @override
  String get errorFollowFailed => 'Takip edilemedi.';

  @override
  String get errorUnfollowFailed => 'Takipten çıkarılamadı.';

  @override
  String errorCandlesFailed(String details) {
    return 'Mum verisi alınamadı: $details';
  }

  @override
  String errorBinance(int status) {
    return 'Binance hatası: $status';
  }

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingStart => 'Başla';

  @override
  String get replayIntro => 'Tanıtımı tekrar izle';

  @override
  String get onboardingDefault1Title => 'Radar: en iyi fırsatlar';

  @override
  String get onboardingDefault1Body =>
      'Radar piyasayı tarar ve en güçlü teknik fırsatları sunan coinleri öne çıkarır; aramakla uğraşmazsın.';

  @override
  String get onboardingDefault2Title => 'Sinyalli grafikler';

  @override
  String get onboardingDefault2Body =>
      'Fiyat hareketini tek bakışta oku. Grafikteki alış ve satış okları sinyalleri oluştukları anda gösterir.';

  @override
  String get onboardingDefault3Title => 'Yapay zeka analizi ve bildirimler';

  @override
  String get onboardingDefault3Body =>
      'Kredi kullanarak hızlı veya Derin Analiz yaptır, coinleri Takip Listem\'e ekle ve bir gelişme olduğunda bildirim al.';

  @override
  String get authErrorInvalidEmail => 'Geçersiz e-posta adresi.';

  @override
  String get authErrorWrongCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get authErrorEmailInUse => 'Bu e-postayla bir hesap zaten var.';

  @override
  String get authErrorWeakPassword =>
      'Şifre çok zayıf. En az 8 karakter kullan.';

  @override
  String get authErrorNetwork =>
      'Ağ hatası. Bağlantını kontrol edip tekrar dene.';

  @override
  String get authErrorTooManyRequests =>
      'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar dene.';

  @override
  String get authErrorCancelled => 'Giriş iptal edildi.';

  @override
  String get authErrorEmailUnverifiedConflict =>
      'Bu e-postayla bir hesap zaten var. Önce e-postanı doğrula.';

  @override
  String get authErrorUnknown => 'Bir şeyler ters gitti. Lütfen tekrar dene.';

  @override
  String get authWelcomeTitle => 'Hoş geldin';

  @override
  String get authWelcomeSubtitle =>
      'AI analizi yapmak, coin takip etmek ve bildirim almak için giriş yap. Misafir olarak da göz atabilirsin.';

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get continueWithEmail => 'E-posta ile devam et';

  @override
  String get continueAsGuest => 'Misafir olarak devam et';

  @override
  String get passwordTooShort => 'Şifre en az 8 karakter olmalı';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get resetEmailSent =>
      'Şifre sıfırlama e-postası gönderildi. Gelen kutunu kontrol et.';

  @override
  String get verificationEmailSent =>
      'Doğrulama e-postası gönderildi. Gelen kutunu kontrol et.';

  @override
  String get verifyEmailBannerText =>
      'Hoş geldin kredini almak için e-postanı doğrula.';

  @override
  String get iHaveVerified => 'Doğruladım';

  @override
  String get resendEmail => 'Tekrar gönder';

  @override
  String get emailNotVerifiedYet => 'E-postan henüz doğrulanmadı.';

  @override
  String get accountEmailVerified => 'E-posta doğrulandı';

  @override
  String get accountEmailNotVerified => 'E-posta doğrulanmadı';

  @override
  String get confirmPassword => 'Şifre tekrar';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get guestProfileHint =>
      'Takip listeni, kredilerini ve hesabını kullanmak için giriş yap veya kayıt ol.';

  @override
  String get tabChart => 'Grafik';

  @override
  String get tabWatchlist => 'Takip Listesi';

  @override
  String get tabProfile => 'Profil';

  @override
  String get analysisInProgress => 'Analiz yapılıyor';

  @override
  String get analysisMayTakeTime => '20-30 saniye sürebilir';

  @override
  String get analysisHistoryTitle => 'Analizlerim';

  @override
  String get analysisHistorySection => 'Geçmiş analizler';

  @override
  String get analysisHistoryEmpty => 'Henüz analiz yok';

  @override
  String get analysisHistoryLoginHint =>
      'Geçmiş analizlerini görmek için giriş yap';

  @override
  String get analysisTypeQuick => 'Hızlı';

  @override
  String get analysisTypeDeep => 'Derin';

  @override
  String get favoritesTab => 'Favoriler';

  @override
  String get favoritesLoginHint => 'Favori coinlerini görmek için giriş yap';

  @override
  String get favoritesEmpty => 'Henüz favori yok';

  @override
  String get alertTooltip => 'Fiyat alarmı';

  @override
  String get myAlerts => 'Alarmlarım';

  @override
  String get alertsTabActive => 'Aktif';

  @override
  String get alertsTabHistory => 'Geçmiş';

  @override
  String get alertSetTitle => 'Fiyat alarmı kur';

  @override
  String alertCurrentPrice(String price) {
    return 'Güncel fiyat: $price';
  }

  @override
  String get alertWaitingPrice => 'Güncel fiyat bekleniyor...';

  @override
  String get alertTargetPriceLabel => 'Hedef fiyat';

  @override
  String alertWillTriggerAbove(String price) {
    return 'Fiyat $price seviyesine çıkınca ya da üzerine geçince bildirim alacaksın.';
  }

  @override
  String alertWillTriggerBelow(String price) {
    return 'Fiyat $price seviyesine inince ya da altına düşünce bildirim alacaksın.';
  }

  @override
  String get alertEnterDifferentPrice =>
      'Güncel fiyattan farklı bir hedef fiyat gir.';

  @override
  String get alertSetButton => 'Alarm kur';

  @override
  String alertSetSuccess(String symbol) {
    return '$symbol için alarm kuruldu';
  }

  @override
  String get alertActiveForCoin => 'Bu coinin aktif alarmları';

  @override
  String alertLimitInfo(int count, int max) {
    return '$max aktif alarmdan $count tanesi kullanıldı';
  }

  @override
  String get alertCancelTooltip => 'Alarmı iptal et';

  @override
  String get alertCanceled => 'Alarm iptal edildi';

  @override
  String get alertRearm => 'Tekrar kur';

  @override
  String get alertRearmed => 'Alarm tekrar kuruldu';

  @override
  String alertDirectionAbove(String price) {
    return '$price üzeri';
  }

  @override
  String alertDirectionBelow(String price) {
    return '$price altı';
  }

  @override
  String get alertStatusTriggered => 'Tetiklendi';

  @override
  String get alertStatusCanceled => 'İptal edildi';

  @override
  String alertTriggeredAt(String date, String price) {
    return '$date, fiyat $price';
  }

  @override
  String get alertsEmptyActive =>
      'Aktif alarm yok. Bir coinin grafiğinde zil simgesine dokunarak alarm kurabilirsin.';

  @override
  String get alertsEmptyHistory =>
      'Henüz tetiklenen ya da iptal edilen alarm yok.';

  @override
  String get alertProTitle => 'Fiyat alarmı bir Pro özelliğidir';

  @override
  String get alertProBody =>
      'Pro üyeler, bir coin hedef fiyatına ulaştığı anda anlık bildirim alır.';

  @override
  String get alertErrorProRequired =>
      'Fiyat alarmı yalnızca Pro üyeler için kullanılabilir.';

  @override
  String alertErrorLimitReached(int limit) {
    return 'En fazla $limit aktif alarmın olabilir. Yenisini eklemek için birini iptal et.';
  }

  @override
  String get alertErrorDuplicate =>
      'Bu fiyat için zaten aktif bir alarmın var.';

  @override
  String get alertErrorGeneric =>
      'Alarm işleminde bir sorun oluştu. Lütfen tekrar dene.';

  @override
  String get legalAboutSection => 'Yasal ve Hakkında';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get termsOfUse => 'Kullanım Koşulları';

  @override
  String get deleteAccountPage => 'Hesap silme';

  @override
  String get support => 'Destek';

  @override
  String get financialDisclaimer => 'Finansal uyarı';

  @override
  String get financialDisclaimerText =>
      'CryptoAnaliz yatırım tavsiyesi vermez. Sinyaller ve analizler yalnızca bilgilendirme amaçlıdır, garanti içermez. Kripto varlık yatırımları yüksek risk taşır; kararlarınızdan ve olası kayıplardan siz sorumlusunuz.';

  @override
  String get appVersion => 'Uygulama sürümü';

  @override
  String get close => 'Kapat';

  @override
  String get couldNotOpenLink => 'Bağlantı açılamadı.';

  @override
  String get proUpsellBenefitsHeading => 'Pro ile şunlara sahip olursun';

  @override
  String get proBenefitNoAds => 'Reklamsız kullanım';

  @override
  String get proBenefitDeepAnalysis => 'Derin analiz';

  @override
  String get proBenefitCredits => 'Her ay 300 kredi';

  @override
  String get proBenefitAlerts => 'Push bildirimleri ve fiyat alarmı';

  @override
  String get proBenefitTimeframes =>
      '1m ve 5m periyotları ile güçlü (3) kademe sinyaller';

  @override
  String get proBenefitWatchlist => 'Limitsiz takip listesi';

  @override
  String get proUpsellNotNow => 'Şimdi değil';

  @override
  String get proUpsellDeepTitle => 'Derin analiz bir Pro özelliğidir';

  @override
  String get proUpsellDeepBody =>
      'Pro üyeler, her coin için daha ayrıntılı ve çok zaman dilimli derin analiz alır.';

  @override
  String get proUpsellTimeframeTitle => '1m ve 5m Pro periyotlarıdır';

  @override
  String get proUpsellTimeframeBody =>
      'Pro üyeler en hızlı periyotları izleyebilir ve bunlarda yapay zekâ analizi çalıştırabilir.';

  @override
  String get proUpsellStrongSignalsTitle =>
      'Güçlü (3) kademe sinyaller bir Pro özelliğidir';

  @override
  String get proUpsellStrongSignalsBody =>
      'Pro üyeler grafikte en güçlü (3) kademe dahil tüm sinyalleri görür.';

  @override
  String proUpsellWatchlistTitle(int count, int limit) {
    return 'Takip listen dolu ($count/$limit)';
  }

  @override
  String get proUpsellWatchlistBody =>
      'Limitsiz takip listesi için Pro\'ya geç.';

  @override
  String get proUpsellGenericTitle => 'Bu bir Pro özelliğidir';

  @override
  String get proUpsellGenericBody => 'Açmak için Pro\'ya geç.';

  @override
  String get proBadgeTooltip => 'Pro özelliği';

  @override
  String get adLabel => 'Reklam';

  @override
  String get insufficientCreditTitle => 'Kredi yetersiz';

  @override
  String get insufficientCreditBody =>
      'Bu analiz için yeterli kredin yok. Devam etmek için kredi alabilirsin.';

  @override
  String get insufficientCreditBodyWithAd =>
      'Bu analiz için yeterli kredin yok. Kısa bir reklam izleyerek bu hızlı analizi yapabilir, kredi alabilir ya da Pro olabilirsin.';

  @override
  String get insufficientCreditDeepBody =>
      'Derin analiz için yeterli kredin yok. Kredi alabilir ya da Pro olabilirsin.';

  @override
  String get adAnalysisDeepAlwaysCredits =>
      'Derin analiz her zaman kredi harcar.';

  @override
  String get adAnalysisWatchButton => 'Reklam izle ve analiz yap';

  @override
  String adAnalysisRemainingToday(int remaining) {
    return 'Bugün kalan: $remaining';
  }

  @override
  String get adAnalysisCapReached =>
      'Bugünkü reklamlı analiz hakkın doldu: kredi al veya Pro ol.';

  @override
  String get adAnalysisEmailUnverified =>
      'Reklam izleyerek analiz yapmak için önce e-posta adresini doğrulamalısın.';

  @override
  String get adAnalysisAdUnavailable =>
      'Reklam şu an yüklenemedi. Lütfen biraz sonra tekrar dene.';

  @override
  String get adAnalysisVerifyTimeout =>
      'Reklam henüz doğrulanamadı. Lütfen birkaç saniye sonra tekrar dene.';

  @override
  String get adAnalysisSessionExpired =>
      'Reklam oturumunun süresi doldu. Lütfen tekrar dene.';

  @override
  String get adAnalysisNotFree =>
      'Reklamlı analiz yalnızca ücretsiz üyeler içindir.';

  @override
  String get adAnalysisDisabled => 'Reklamlı analiz şu an kullanılamıyor.';

  @override
  String get notifChannelAnnouncementsName => 'Duyurular';

  @override
  String get notifChannelAnnouncementsDesc =>
      'Uygulamadan haberler ve duyurular';

  @override
  String get notifChannelCreditsName => 'Kredi';

  @override
  String get notifChannelCreditsDesc =>
      'Hesabına kredi eklendiğinde gelen bildirimler';

  @override
  String get notifChannelSignalsName => 'Takip listesi sinyalleri';

  @override
  String get notifChannelSignalsDesc =>
      'Takip ettiğin coinler için işlem sinyalleri';

  @override
  String get notifChannelAlertsName => 'Fiyat alarmları';

  @override
  String get notifChannelAlertsDesc =>
      'Bir coin hedef fiyatına ulaştığında gelen bildirimler';

  @override
  String get notifRationaleTitle => 'Bildirimler açılsın mı?';

  @override
  String get notifRationaleBody =>
      'Kredi ve duyuru bildirimleri al. Pro üyeler ayrıca takip listesi sinyali ve fiyat alarmı bildirimleri alır.';

  @override
  String get notifRationaleAllow => 'İzin ver';

  @override
  String get notifRationaleLater => 'Şimdi değil';

  @override
  String get notifSettingsSection => 'Bildirimler';

  @override
  String get notifAnnouncementsTitle => 'Duyurular';

  @override
  String get notifAnnouncementsSubtitle =>
      'Uygulamadan haberler ve güncellemeler';

  @override
  String get notifCreditsTitle => 'Kredi bildirimleri';

  @override
  String get notifCreditsSubtitle => 'Hesabına kredi eklendiğinde';

  @override
  String get notifSignalsTitle => 'Takip listesi sinyalleri';

  @override
  String get notifSignalsSubtitle =>
      'Takip ettiğin coinler için yeni sinyaller';

  @override
  String get notifAlertsTitle => 'Fiyat alarmları';

  @override
  String get notifAlertsSubtitle => 'Bir coin hedef fiyatına ulaştığında';

  @override
  String get notifPermissionOffTitle => 'Bildirim izni kapalı';

  @override
  String get notifPermissionOffBody =>
      'İzin verene kadar bildirim almayacaksın.';

  @override
  String get notifOpenSystemSettings => 'Sistem ayarlarını aç';

  @override
  String get notifPermissionManual =>
      'Bildirimleri telefonunun ayarlarından aç.';

  @override
  String get notifSettingsLoadFailed => 'Bildirim ayarları yüklenemedi.';

  @override
  String get notifSettingsSaveFailed =>
      'Değişiklik kaydedilemedi. Lütfen tekrar dene.';

  @override
  String get proUpsellPushSignalsTitle => 'Sinyal bildirimleri Pro özelliğidir';

  @override
  String get proUpsellPushSignalsBody =>
      'Pro üyeler, takip listesindeki bir coin için yeni sinyal geldiğinde anlık bildirim alır.';

  @override
  String get structuredBiasBullish => 'Yükseliş';

  @override
  String get structuredBiasBearish => 'Düşüş';

  @override
  String get structuredBiasNeutral => 'Nötr';

  @override
  String structuredConfidence(int value) {
    return 'Güven %$value';
  }

  @override
  String structuredHorizon(String label) {
    return 'Ufuk: $label';
  }

  @override
  String structuredHorizonCandles(int count) {
    return '$count mum';
  }

  @override
  String get structuredSectionSummary => 'Özet';

  @override
  String get structuredSectionDrivers => 'Ana etkenler';

  @override
  String get structuredSectionScenarios => 'Senaryolar';

  @override
  String get structuredSectionLevels => 'Önemli seviyeler';

  @override
  String get structuredSectionRisks => 'Riskler';

  @override
  String get structuredSectionWatch => 'İzlenecekler';

  @override
  String get structuredSectionSources => 'Kaynaklar';

  @override
  String get structuredScenarioBull => 'Boğa senaryosu';

  @override
  String get structuredScenarioBase => 'Baz senaryo';

  @override
  String get structuredScenarioBear => 'Ayı senaryosu';

  @override
  String structuredScenarioTrigger(String price) {
    return 'Tetikleyici: $price';
  }

  @override
  String structuredScenarioTarget(String price) {
    return 'Hedef: $price';
  }

  @override
  String get structuredLevelResistance => 'Direnç';

  @override
  String get structuredLevelSupport => 'Destek';

  @override
  String get structuredLevelInvalidation => 'İptal seviyesi';

  @override
  String get structuredLevelPrice => 'Analiz anındaki fiyat';

  @override
  String structuredDataMissing(String sources) {
    return 'Bazı veri kaynakları alınamadı: $sources';
  }

  @override
  String get structuredDisclaimer => 'Yatırım tavsiyesi değildir.';

  @override
  String get structuredSourceOpenFailed => 'Bağlantı açılamadı.';

  @override
  String get glossaryTitle => 'Teknik Terimler Sözlüğü';

  @override
  String get glossarySearchHint => 'Terim ara (ör. RSI, fonlama)';

  @override
  String get glossaryNoResults => 'Eşleşen terim yok.';

  @override
  String get glossaryLearnTerms => 'Terimleri öğren';

  @override
  String get glossaryIntro =>
      'Analizlerde geçen terimlerin kısa ve tarafsız açıklamaları. Yalnızca bilgi amaçlıdır, yatırım tavsiyesi değildir.';

  @override
  String get structuredConclusionTitle => 'Nihai düşünce';

  @override
  String get structuredSectionBalance => 'Etken dengesi';

  @override
  String get structuredSectionLadder => 'Fiyat merdiveni';

  @override
  String get structuredSectionDataNotes => 'Veri notları';

  @override
  String get structuredSectionOdds => 'Senaryo olasılıkları';

  @override
  String structuredBalanceItem(String label, int count) {
    return '$label $count';
  }

  @override
  String analysisPreparedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dk önce hazırlandı',
    );
    return '$_temp0';
  }

  @override
  String analysisPreparedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sa önce hazırlandı',
    );
    return '$_temp0';
  }

  @override
  String analysisPreparedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce hazırlandı',
    );
    return '$_temp0';
  }

  @override
  String get analysisPreparedJustNow => 'Az önce hazırlandı';

  @override
  String get tabHome => 'Ana Sayfa';

  @override
  String homeStaleNote(String ago) {
    return 'Güncel değil · son güncelleme $ago';
  }

  @override
  String get homeStaleNoTime => 'Güncel değil';

  @override
  String get homeGuestTitle => 'Özetini gör';

  @override
  String get homeGuestBody =>
      'Giriş yap; piyasa nabzı, takip listen, radar sinyalleri ve son analizin tek yerde olsun.';

  @override
  String get homeErrorTitle => 'Özet yüklenemedi';

  @override
  String get homeLoadingSemantics => 'Özet yükleniyor';

  @override
  String get homeResumeTitle => 'Kaldığın yer';

  @override
  String get homeResumeOpen => 'Grafiği aç';

  @override
  String get homeMarketTitle => 'Piyasa nabzı';

  @override
  String get homeFearGreedTitle => 'Korku ve Açgözlülük';

  @override
  String get homeFngExtremeFear => 'Aşırı korku';

  @override
  String get homeFngFear => 'Korku';

  @override
  String get homeFngNeutral => 'Nötr';

  @override
  String get homeFngGreed => 'Açgözlülük';

  @override
  String get homeFngExtremeGreed => 'Aşırı açgözlülük';

  @override
  String homeFngChange7d(String delta) {
    return '7 gün: $delta';
  }

  @override
  String homeFngSemantics(int value, String label) {
    return 'Korku ve Açgözlülük endeksi $value, $label';
  }

  @override
  String get homeBtcDominance => 'BTC dominansı';

  @override
  String get homeTotalCap => 'Toplam piyasa değeri';

  @override
  String homeRegimeLabel(String regime) {
    return 'Rejim: $regime';
  }

  @override
  String get homeRegimeBull => 'Boğa';

  @override
  String get homeRegimeBear => 'Ayı';

  @override
  String get homeRegimeSideways => 'Yatay';

  @override
  String get homeRegimeUnknown => 'Belirsiz';

  @override
  String get homeMarketUnavailable => 'Piyasa verisi şu an alınamıyor.';

  @override
  String get homeMoversTitle => 'Takip listem';

  @override
  String get homeMoversEmpty =>
      'Coin takip et; 24 saatteki en büyük hareketler burada görünsün.';

  @override
  String get homeMoversEmptyAction => 'Takip listeme git';

  @override
  String get homeRadarTitle => 'Radar\'dan son sinyaller';

  @override
  String get homeRadarEmpty => 'Şu an yeni radar sinyali yok.';

  @override
  String get homeSignalBuy => 'Al';

  @override
  String get homeSignalSell => 'Sat';

  @override
  String homeSignalStrength(int n) {
    return 'Güç $n/3';
  }

  @override
  String get homeAnalysisTitle => 'Son derin analizin';

  @override
  String get homeAnalysisEmpty =>
      'Henüz derin analiz yapmadın. Bir coin seç ve ilk analizini dene.';

  @override
  String get homeAnalysisNew => 'Yeni analiz';

  @override
  String get homeAnalysisCachedBadge => 'Ortak sonuç';

  @override
  String get homeAnalysisOpenFailed =>
      'Bu analiz açılamadı. Lütfen tekrar dene.';

  @override
  String get homeEventsTitle => 'Yaklaşan olaylar';

  @override
  String homeInMinutes(int n) {
    return '$n dk sonra';
  }

  @override
  String homeInHours(int n) {
    return '$n sa sonra';
  }

  @override
  String homeInDays(int n) {
    return '$n gün sonra';
  }

  @override
  String get homeEventHigh => 'Yüksek önem';

  @override
  String get homeEventMedium => 'Orta önem';

  @override
  String get homeLearnTitle => 'Öğren';

  @override
  String get homeTermOfDay => 'Günün terimi';

  @override
  String get homeOpenGlossary => 'Sözlüğü aç';

  @override
  String get homeProPromoTitle => 'Pro ile daha ileri git';

  @override
  String get homeProPromoBody =>
      'Derin analiz, fiyat alarmları ve aylık krediler; ihtiyacın olduğunda.';

  @override
  String get homeProPromoAction => 'Pro\'yu incele';

  @override
  String get homeFooterDisclaimer =>
      'Yalnızca bilgilendirme amaçlıdır; yatırım tavsiyesi değildir.';

  @override
  String get homeFooterSources =>
      'Veri kaynakları: Binance, CoinMarketCap, Alternative.me (Fear & Greed Index), FRED.';

  @override
  String get startupPageTitle => 'Açılış sayfası';

  @override
  String get homeMktTitle => 'Piyasa';

  @override
  String get homeMktGainers => 'Yükselenler';

  @override
  String get homeMktLosers => 'Düşenler';

  @override
  String get homeMktVolume => 'Hacim';

  @override
  String get homeMktMore => 'Daha fazla';

  @override
  String get homeMktLess => 'Daha az';

  @override
  String homeMktVolumeShort(String amount) {
    return 'Hacim $amount';
  }

  @override
  String get homeQuickDeep => 'Derin analiz';

  @override
  String get homeQuickAlerts => 'Alarmlar';

  @override
  String get homeQuickGlossary => 'Sözlük';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeSystem => 'Sistem';

  @override
  String quickAnalysisButtonCost(int cost) {
    return 'Hızlı analiz · $cost kredi';
  }

  @override
  String deepAnalysisButtonCost(int cost) {
    return 'Derin analiz · $cost kredi';
  }

  @override
  String get chartTabSummary => 'Özet';

  @override
  String get chartTabAnalyses => 'Analizlerim';

  @override
  String get chartTabMarket => 'Piyasa';

  @override
  String get chartTabSignals => 'Sinyaller';

  @override
  String get chartTabAlerts => 'Alarmlar';

  @override
  String get ovEmpty => 'Bu coin için henüz özet bilgi yok.';

  @override
  String get ovMarketCap => 'Piyasa değeri';

  @override
  String get ovFdv => 'Tam seyreltilmiş değer (FDV)';

  @override
  String get ovVolume24h => '24s hacim';

  @override
  String get ovVolMcap => 'Hacim / piyasa değeri';

  @override
  String get ovSupplyTitle => 'Arz';

  @override
  String get ovCirculating => 'Dolaşımdaki';

  @override
  String get ovTotalSupply => 'Toplam';

  @override
  String get ovMaxSupply => 'Maksimum';

  @override
  String get ovNoMaxSupply => 'Maksimum arz sınırı yok';

  @override
  String ovCirculatingOfMax(String pct) {
    return 'Maksimum arzın %$pct kadarı dolaşımda';
  }

  @override
  String get ovPriceChangeTitle => 'Fiyat değişimi';

  @override
  String get ovPeriod24h => '24s';

  @override
  String get ovPeriod7d => '7g';

  @override
  String get ovPeriod30d => '30g';

  @override
  String get ovPeriod90d => '90g';

  @override
  String get ovAth => 'Tüm zamanların zirvesi';

  @override
  String get ovAtl => 'Tüm zamanların dibi';

  @override
  String ovFromCurrent(String pct) {
    return 'Güncel fiyata göre $pct';
  }

  @override
  String get ovCategory => 'Kategori';

  @override
  String get ovTags => 'Etiketler';

  @override
  String get ovPlatform => 'Platform';

  @override
  String get ovCoinAge => 'Coin yaşı';

  @override
  String get ovListingAge => 'Listeleme yaşı';

  @override
  String get ovNewListing => 'Yeni listeleme';

  @override
  String ovAgeDays(int count) {
    return '$count gün';
  }

  @override
  String ovAgeMonths(int count) {
    return '$count ay';
  }

  @override
  String ovAgeYears(int count) {
    return '$count yıl';
  }

  @override
  String get ovSource => 'Veri: CoinMarketCap, Binance';

  @override
  String get tabLoadFailed => 'Bu bölüm yüklenemedi.';

  @override
  String get glossaryHelpTooltip => 'Bu ne demek?';

  @override
  String get coAnalysesEmptyTitle => 'Bu coin için henüz analizin yok';

  @override
  String get coAnalysesEmptyBody =>
      'Yukarıdaki butonlarla ilk hızlı veya derin analizini yaptır.';

  @override
  String get coAnalysesLoginHint =>
      'Bu coin için analizlerini görmek için giriş yap';

  @override
  String get coAnalysisCached => 'önbellek';

  @override
  String get relAgoNow => 'az önce';

  @override
  String relAgoMinutes(int count) {
    return '$count dk önce';
  }

  @override
  String relAgoHours(int count) {
    return '$count sa önce';
  }

  @override
  String relAgoDays(int count) {
    return '$count gün önce';
  }

  @override
  String get mkEmpty => 'Bu coin için henüz piyasa verisi yok.';

  @override
  String get mkFuturesTitle => 'Vadeli işlemler (türev)';

  @override
  String get mkFunding => 'Fonlama oranı';

  @override
  String mkFundingPercentile(String pct) {
    return 'Son ölçümlerin %$pct kadarından yüksek';
  }

  @override
  String get mkFundingHintHigh =>
      'Fonlama yakın geçmişe göre yüksek: long pozisyonlar shortlara ödeme yapıyor, long tarafın kalabalık olduğuna işaret eder.';

  @override
  String get mkFundingHintLow =>
      'Fonlama yakın geçmişe göre düşük: shortlar longlara ödeme yapıyor veya long taraf kalabalık değil.';

  @override
  String get mkFundingHintNormal => 'Fonlama olağan aralığında.';

  @override
  String get mkOpenInterest => 'Açık pozisyon değişimi';

  @override
  String get mkOiHint =>
      'Açık pozisyon artıyorsa yeni para pozisyonlara giriyor, azalıyorsa pozisyonlar kapanıyor demektir.';

  @override
  String get mkLongShort => 'Long / short dengesi';

  @override
  String mkLongShare(String pct) {
    return 'Long payı %$pct';
  }

  @override
  String get mkLsRatio => 'Long/short oranı';

  @override
  String get mkTopTrader => 'En iyi traderların oranı';

  @override
  String get mkLongShortHint =>
      '1 üzeri long pozisyonların short pozisyonlardan fazla olduğunu gösterir. Yönü değil, pozisyonlanmayı anlatır.';

  @override
  String get mkTaker => 'Taker alım / satım';

  @override
  String get mkTakerHintBuy => 'Son işlemlerde agresif alıcılar ağır basıyor.';

  @override
  String get mkTakerHintSell =>
      'Son işlemlerde agresif satıcılar ağır basıyor.';

  @override
  String get mkTakerHintBalanced => 'Agresif alım ve satım kabaca dengede.';

  @override
  String get mkBasis => 'Baz (vadeli - spot farkı)';

  @override
  String get mkBasisHintPos => 'Vadeli fiyat spotun üzerinde (prim).';

  @override
  String get mkBasisHintNeg => 'Vadeli fiyat spotun altında (iskonto).';

  @override
  String get mkLiquidityTitle => 'Likidite';

  @override
  String get mkSpread => 'Spread (alış-satış farkı)';

  @override
  String mkSpreadValue(String bps) {
    return '$bps baz puan';
  }

  @override
  String get mkDepthTitle => 'Emir defteri derinliği';

  @override
  String get mkDepthBid => 'Alış';

  @override
  String get mkDepthAsk => 'Satış';

  @override
  String mkDepthImbalance(String pct) {
    return 'Dengesizlik $pct';
  }

  @override
  String get mkDepthNote =>
      'Derinlik emir defterinin anlık görüntüsüdür, sinyal değildir.';

  @override
  String get mkActivityTitle => 'Hareketlilik';

  @override
  String get mkVolume24h => '24s hacim';

  @override
  String get mkTrades24h => 'İşlem sayısı (24s)';

  @override
  String get mkVolumeRank => 'Hacim sırası';

  @override
  String get mkSpotNote =>
      'Türev verileri (fonlama, açık pozisyon, long/short) yalnızca vadeli işlem coinleri için geçerlidir.';

  @override
  String get sgEmptyTitle => 'Henüz sinyal yok';

  @override
  String get sgEmptyBody =>
      'Yüklenen geçmişte bu coin ve zaman dilimi için ok yok.';

  @override
  String get sgUnsupported =>
      'Sinyaller 15d, 1s, 4s ve 1g zaman dilimlerinde bulunur.';

  @override
  String sgPriceAtSignal(String price) {
    return 'Sinyalde $price';
  }

  @override
  String sgSinceSignal(String pct) {
    return 'Sinyalden beri $pct';
  }

  @override
  String get sgTapHint => 'Grafiğe dönmek için bir satıra dokun.';

  @override
  String get alTabEmpty => 'Bu coin için henüz alarmın yok.';

  @override
  String get alTabAdd => 'Alarm ekle';

  @override
  String get alTabLoginHint => 'Fiyat alarmı kurmak için giriş yap';

  @override
  String get alTabHistory => 'Geçmiş alarmlar';

  @override
  String get ovPeriod1h => '1s';

  @override
  String get ovPeriod4h => '4s';
}
