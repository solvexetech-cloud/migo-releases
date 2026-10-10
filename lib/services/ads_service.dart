// ═══════════════════════════════════════════════════════
// MIGO — Ads Service (D4)
// ═══════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/config/ads_config.dart';

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  bool _adsEnabled = true;
  bool _bannerEnabled = true;
  bool _nativeEnabled = true;
  bool _interstitialEnabled = true;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShown;
  int _claimCount = 0;

  bool get adsEnabled => _adsEnabled;
  bool get bannerEnabled => _adsEnabled && _bannerEnabled;
  bool get nativeEnabled => _adsEnabled && _nativeEnabled;
  bool get interstitialEnabled => _adsEnabled && _interstitialEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      await _loadRemoteConfig();
      _initialized = true;
      debugPrint('✅ AdsService initialized');
      if (interstitialEnabled) _loadInterstitial();
    } catch (e) {
      debugPrint('❌ AdsService init error: $e');
    }
  }

  Future<void> _loadRemoteConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('ads')
          .get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      _adsEnabled = data['enabled'] ?? true;
      _bannerEnabled = data['bannerHome'] ?? true;
      _nativeEnabled = data['nativeList'] ?? true;
      _interstitialEnabled = data['interstitialClaim'] ?? true;
    } catch (e) {
      debugPrint('⚠️ Ads config error: $e');
    }
  }

  BannerAd createBannerAd({
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) {
    return BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed();
        },
      ),
    );
  }

  NativeAd createNativeAd({
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) {
    return NativeAd(
      adUnitId: AdsConfig.nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed();
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdsConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  Future<void> onClaimSuccess() async {
    if (!interstitialEnabled) return;
    _claimCount++;
    if (_claimCount % AdsConfig.interstitialEveryNClaims != 0) return;
    if (_lastInterstitialShown != null) {
      final gap = DateTime.now().difference(_lastInterstitialShown!);
      if (gap < AdsConfig.interstitialMinGap) return;
    }
    if (_interstitialAd == null) {
      _loadInterstitial();
      return;
    }
    await _interstitialAd!.show();
    _lastInterstitialShown = DateTime.now();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}