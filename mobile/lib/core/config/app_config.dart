/// Global MIGO app configuration.
/// Change these values in one place — used everywhere.
class AppConfig {
  AppConfig._();

  static const String appName = 'MIGO';
  static const String tagline = 'Discover. Save. Earn. Together.';

  /// Default country for launch market.
  static const String defaultCountryCode = 'QA';
  static const String defaultCurrency = 'QAR';
  static const String defaultLocale = 'en';

  /// Supported locales for localization.
  static const List<String> supportedLocales = ['en', 'ml'];

  /// API base URL — will be filled in backend step.
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
}