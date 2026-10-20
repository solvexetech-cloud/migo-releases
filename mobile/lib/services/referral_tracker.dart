import 'package:flutter/services.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PHASE E — E1: Auto-Referral Tracker
/// Detects referral code from:
/// 1. Play Install Referrer (Android)
/// 2. Clipboard (fallback — all platforms)
/// 3. Deep link (handled by E3 — app_links)
class ReferralTracker {
  ReferralTracker._();
  static final ReferralTracker instance = ReferralTracker._();

  static const _prefsKey = 'pending_referral_code';
  static const _sharedByKey = 'shared_by_uid';

  /// ═══════════════════════════════════════════════════
  /// INIT — Called at app startup (main.dart)
  /// ═══════════════════════════════════════════════════
  Future<void> init() async {
    await _checkInstallReferrer();
  }

  /// ═══════════════════════════════════════════════════
  /// 1. INSTALL REFERRER (Android Play Store)
  /// ═══════════════════════════════════════════════════
  Future<void> _checkInstallReferrer() async {
    try {
      final details = await PlayInstallReferrer.installReferrer;
      final referrer = details.installReferrer;
      if (referrer == null || referrer.isEmpty) return;

      final code = _parseReferrer(referrer);
      if (code != null) {
        await savePendingCode(code);
      }
    } catch (_) {
      // iOS/web or error — silent
    }
  }

  String? _parseReferrer(String referrer) {
    // Try "ref=XXXXXX"
    final refMatch = RegExp(r'ref=([A-Z0-9]{6})').firstMatch(referrer);
    if (refMatch != null) return refMatch.group(1);

    // Try "utm_content=XXXXXX"
    final utmMatch =
        RegExp(r'utm_content=([A-Z0-9]{6})').firstMatch(referrer);
    if (utmMatch != null) return utmMatch.group(1);

    return null;
  }

  /// ═══════════════════════════════════════════════════
  /// 2. CLIPBOARD CHECK (Fallback — all platforms)
  /// ═══════════════════════════════════════════════════
  Future<String?> checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.isEmpty) return null;

      // Match: migo-app-3030e.web.app/r/XXXXXX
      final linkMatch =
          RegExp(r'\.web\.app/r/([A-Z0-9]{6})').firstMatch(text);
      if (linkMatch != null) return linkMatch.group(1);

      // Match raw 6-char code
      final codeMatch =
          RegExp(r'\b([A-Z0-9]{6})\b').firstMatch(text.toUpperCase());
      if (codeMatch != null) return codeMatch.group(1);

      return null;
    } catch (_) {
      return null;
    }
  }

  /// ═══════════════════════════════════════════════════
  /// SAVE / GET / CLEAR PENDING CODE
  /// ═══════════════════════════════════════════════════
  Future<void> savePendingCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing == null || existing.isEmpty) {
      await prefs.setString(_prefsKey, code);
    }
  }

  Future<String?> getPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  Future<void> clearPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// ═══════════════════════════════════════════════════
  /// COMBINED: Resolve best available code
  /// Priority: Pending (Install Referrer) > Clipboard
  /// ═══════════════════════════════════════════════════
  Future<String?> resolveCode() async {
    final pending = await getPendingCode();
    if (pending != null && pending.isNotEmpty) return pending;

    final clipboard = await checkClipboard();
    if (clipboard != null && clipboard.isNotEmpty) {
      await savePendingCode(clipboard);
      return clipboard;
    }

    return null;
  }

  // ═══════════════════════════════════════════════════
  // SHARE TRACKING (for coin rewards)
  // ═══════════════════════════════════════════════════
  Future<void> saveSharedBy(String sharedByUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sharedByKey, sharedByUid);
  }

  Future<String?> getSharedBy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sharedByKey);
  }

  Future<void> clearSharedBy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sharedByKey);
  }
}