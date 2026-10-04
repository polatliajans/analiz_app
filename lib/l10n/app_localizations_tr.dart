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
}
