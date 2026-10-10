// ═══════════════════════════════════════════════════════
// MIGO — Ad Native Card (D4)
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';

class AdNativeCard extends StatefulWidget {
  const AdNativeCard({super.key});

  @override
  State<AdNativeCard> createState() => _AdNativeCardState();
}

class _AdNativeCardState extends State<AdNativeCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdsService.instance.nativeEnabled) return;
    final ad = AdsService.instance.createNativeAd(
      onLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _isLoaded = false);
      },
    );
    ad.load();
    _nativeAd = ad;
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsService.instance.nativeEnabled ||
        !_isLoaded ||
        _nativeAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Icon(Icons.campaign_outlined,
                    size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 4),
                Text('Sponsored',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).hintColor)),
              ],
            ),
          ),
          SizedBox(height: 280, child: AdWidget(ad: _nativeAd!)),
        ],
      ),
    );
  }
}