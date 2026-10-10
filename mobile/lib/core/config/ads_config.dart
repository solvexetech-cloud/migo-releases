// ═══════════════════════════════════════════════════════
// MIGO — Ads Configuration (D4)
// ═══════════════════════════════════════════════════════

class AdsConfig {
  AdsConfig._();

  // Test mode — Phase G-ൽ false ആക്കുക
  static const bool useTestAds = true;

  // Google Official TEST IDs
  static const String _testBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testNativeId =
      'ca-app-pub-3940256099942544/2247696110';

  // Production IDs (Phase G-ൽ പൂരിപ്പിക്കുക)
  static const String _prodBannerId = 'ca-app-pub-XXX/YYY';
  static const String _prodInterstitialId = 'ca-app-pub-XXX/YYY';
  static const String _prodNativeId = 'ca-app-pub-XXX/YYY';

  static String get bannerAdUnitId =>
      useTestAds ? _testBannerId : _prodBannerId;
  static String get interstitialAdUnitId =>
      useTestAds ? _testInterstitialId : _prodInterstitialId;
  static String get nativeAdUnitId =>
      useTestAds ? _testNativeId : _prodNativeId;

  // നിയമങ്ങൾ
  static const int nativeAdEveryNCards = 5;
  static const int interstitialEveryNClaims = 3;
  static const Duration interstitialMinGap = Duration(seconds: 60);

  // പരസ്യം കാണിക്കരുതാത്ത റോളുകൾ
  static const List<String> noAdsRoles = [
    'super_admin',
    'admin',
    'agency',
    'moderator',
    'business',
  ];

  static bool shouldShowAdsForRole(String? role) {
    if (role == null) return true;
    return !noAdsRoles.contains(role);
  }
}