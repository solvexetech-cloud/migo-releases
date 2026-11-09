import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider instance = ThemeProvider._();
  ThemeProvider._();

  // Default colors (same as migo_colors.dart)
  Color primary = const Color(0xFF0B2B5B);
  Color accent = const Color(0xFFD4A13A);
  Color background = const Color(0xFFF6F3EE);
  Color surface = const Color(0xFFFFFFFF);
  Color textPrimary = const Color(0xFF111418);
  Color textSecondary = const Color(0xFF6B7280);
  Color divider = const Color(0xFFECE7DE);
  Color border = const Color(0xFFE0E0E0);
  
  double buttonRadius = 12.0;
  double cardRadius = 16.0;
  
  double shadowOpacity = 0.1;
  double shadowBlur = 8.0;
  double shadowOffsetY = 4.0;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> loadTheme() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('theme')
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        primary = _hexToColor(data['primaryColor'] ?? '#0B2B5B');
        accent = _hexToColor(data['accentColor'] ?? '#D4A13A');
        background = _hexToColor(data['secondaryColor'] ?? '#F6F3EE');
        surface = _hexToColor(data['cardColor'] ?? '#FFFFFF');
        textPrimary = _hexToColor(data['textPrimaryColor'] ?? '#111418');
        textSecondary = _hexToColor(data['textSecondaryColor'] ?? '#6B7280');
        divider = _hexToColor(data['borderColor'] ?? '#ECE7DE');
        border = _hexToColor(data['borderColor'] ?? '#E0E0E0');
        
        buttonRadius = (data['buttonRadius'] as num?)?.toDouble() ?? 12.0;
        cardRadius = (data['cardRadius'] as num?)?.toDouble() ?? 16.0;
        
        shadowOpacity = (data['shadowOpacity'] as num?)?.toDouble() ?? 0.1;
        shadowBlur = (data['shadowBlur'] as num?)?.toDouble() ?? 8.0;
        shadowOffsetY = (data['shadowOffsetY'] as num?)?.toDouble() ?? 4.0;
        
        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}