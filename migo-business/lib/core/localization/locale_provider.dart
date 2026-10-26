import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();
  static final LocaleProvider instance = LocaleProvider._();

  String _locale = 'en';
  String get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('locale') ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    if (code == _locale) return;
    _locale = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
    notifyListeners();
  }
}