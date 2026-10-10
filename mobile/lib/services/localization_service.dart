import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/language_model.dart';

/// MIGO Localization Service
///
/// Loads languages + app strings from Firestore.
/// Provides `t(key)` for translation.
class LocalizationService {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Language list (loaded once)
  List<LanguageModel> _languages = [];
  List<LanguageModel> get languages => _languages;

  // Current locale
  String _currentLocale = 'en';
  String get currentLocale => _currentLocale;
  bool get isRtl {
    final lang = _languages.firstWhere(
      (l) => l.code == _currentLocale,
      orElse: () => LanguageModel(code: 'en', name: 'English', nameNative: 'English'),
    );
    return lang.rtl;
  }

  // Translation cache: { 'en': { 'key': 'value' }, 'ar': {...} }
  final Map<String, Map<String, String>> _cache = {};

  /// Load all languages (once).
  Future<void> loadLanguages() async {
    if (_languages.isNotEmpty) return;
    final snap = await _db.collection('languages').limit(50).get();
    _languages = snap.docs
        .map((d) => LanguageModel.fromMap(d.id, d.data()))
        .where((l) => l.active)
        .toList();
    _languages.sort((a, b) => a.order.compareTo(b.order));
  }

  /// Load strings for a given language (once per language).
  Future<void> loadStrings(String langCode) async {
    if (_cache.containsKey(langCode)) return;
    final snap = await _db
        .collection('app_strings')
        .where('lang', isEqualTo: langCode)
        .limit(500)
        .get();
    final map = <String, String>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final key = d['key'] as String?;
      final value = d['value'] as String?;
      if (key != null && value != null) map[key] = value;
    }
    _cache[langCode] = map;
  }

  /// Set current locale + load strings if needed.
  Future<void> setLocale(String langCode) async {
    _currentLocale = langCode;
    await loadStrings(langCode);
    // Ensure fallback (en) is also loaded
    if (langCode != 'en') {
      await loadStrings('en');
    }
  }

  /// Translate a key. Fallback: en → key itself.
  String t(String key) {
    final current = _cache[_currentLocale]?[key];
    if (current != null && current.isNotEmpty) return current;
    final fallback = _cache['en']?[key];
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return key;
  }
}