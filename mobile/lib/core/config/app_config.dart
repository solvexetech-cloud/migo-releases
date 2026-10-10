/// Global MIGO app configuration.
/// Change these values in one place — used everywhere.
class AppConfig {
  AppConfig._();

  static const String appName = 'MIGO';
  static const String tagline = 'Discover. Save. Earn. Together.';

  /// Default country for launch market.
  /// New countries can be added via admin panel — see `countries` collection.
  static const String defaultCountryCode = 'QA';

  /// Fallback currency (only used if country lookup fails).
  /// Actual currency should come from `CountryModel.currency`.
  static const String fallbackCurrency = 'QAR';

  /// Default locale (only used if country lookup fails).
  /// Actual locale should come from `CountryModel.locale`.
  static const String defaultLocale = 'en';

  /// Supported locales for localization.
  /// Add more here as new translations are added.
  static const List<String> supportedLocales = ['en', 'ar'];

  /// RTL locales (Arabic, Urdu, Hebrew, etc.)
  static const List<String> rtlLocales = ['ar', 'ur', 'he'];

  /// Check if a locale is RTL.
  static bool isRtl(String locale) => rtlLocales.contains(locale);

  /// API base URL — will be filled in backend step.
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
}