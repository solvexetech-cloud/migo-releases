import 'package:flutter/foundation.dart';
import '../../services/localization_service.dart';

/// Simple ChangeNotifier for current locale.
/// Notifies MaterialApp to rebuild when locale changes.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();
  static final LocaleProvider instance = LocaleProvider._();

  String _locale = 'en';
  String get locale => _locale;

  /// Initialize — load languages + apply default locale.
  Future<void> init({String? userPreferredLocale}) async {
    await LocalizationService.instance.loadLanguages();
    final target = userPreferredLocale ?? 'en';
    await _apply(target, notify: false);
  }

  /// Change locale (from settings).
  Future<void> setLocale(String langCode) async {
    if (_locale == langCode) return;
    await _apply(langCode, notify: true);
  }

  Future<void> _apply(String langCode, {required bool notify}) async {
    await LocalizationService.instance.setLocale(langCode);
    _locale = langCode;
    if (notify) notifyListeners();
  }

  bool get isRtl => LocalizationService.instance.isRtl;
}