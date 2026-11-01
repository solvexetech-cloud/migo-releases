import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_shadows.dart';
import '../../models/business_model.dart';
import '../../models/coin_settings_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../models/offer_model.dart';

class PayWithCoinsScreen extends StatefulWidget {
  final BusinessModel business;
  final OfferModel offer;

  const PayWithCoinsScreen({
    super.key,
    required this.business,
    required this.offer,
  });

  @override
  State<PayWithCoinsScreen> createState() => _PayWithCoinsScreenState();
}

class _PayWithCoinsScreenState extends State<PayWithCoinsScreen> {
  int _coinsToUse = 0;
  bool _isGeneratingQR = false;

  UserModel? _user;
  CoinSettingsModel? _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final user = await FirestoreService.instance.getUser(uid);
    final settings = await FirestoreService.instance.getCoinSettings();

    if (mounted) {
      setState(() {
        _user = user;
        _settings = settings;
        _loading = false;
        if (user != null && settings != null) {
          _calculateCoins();
        }
      });
    }
  }

  void _calculateCoins() {
    if (_settings == null || _user == null) return;

    final rate = _settings!.getValueFor100Coins(_user!.currentCountryCode ?? 'QA');
    final maxPercent = _settings!.maxRedemptionPercent / 100.0;
    final billAmount = widget.offer.offerPrice; // 🆕 ഓഫറിന്റെ വില
    final maxValue = billAmount * maxPercent;
    final maxCoins = (maxValue / (rate / 100)).floor();

    setState(() {
      _coinsToUse = maxCoins > _user!.coins ? _user!.coins : maxCoins;
    });
  }

  Future<void> _generateQR() async {
    if (_coinsToUse <= 0) return;

    setState(() => _isGeneratingQR = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("Not signed in");

      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      final paymentData = {
        'id': paymentId,
        'userId': uid,
        'userName': _user?.displayName ?? _user?.email ?? 'Customer',
        'userEmail': _user?.email ?? '',
        'businessId': widget.business.id,
        'businessName': widget.business.name,
        'offerId': widget.offer.id,
        'offerTitle': widget.offer.title,
        'billAmount': widget.offer.offerPrice, // 🆕 ഓഫറിന്റെ വില
        'coinsUsed': _coinsToUse,
        'currency': widget.business.currency,
        'status': 'pending',
        'createdAt': DateTime.now(),
      };

      await FirestoreService.instance.createCoinPaymentRequest(paymentData);

      if (!mounted) return;

      setState(() => _isGeneratingQR = false);

      // 🆕 QR കോഡും സ്റ്റാറ്റസും കാണിക്കാൻ പോപ്പ്അപ്പ്
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('coin_payments')
                .doc(paymentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final status = data['status'] as String?;

                if (status == 'accepted') {
                  return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: MigoColors.success.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: MigoColors.success, size: 64),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Payment Successful! ✅',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MigoColors.success),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You paid with $_coinsToUse coins.',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          
                          FutureBuilder<UserModel?>(
                            future: FirestoreService.instance.getUser(_user!.uid),
                            builder: (context, userSnap) {
                              final remainingCoins = userSnap.data?.coins ?? 0;
                              return Column(
                                children: [
                                  const Text(
                                    'Remaining Coin Balance:',
                                    style: TextStyle(fontSize: 13, color: MigoColors.textSecondaryLight),
                                  ),
                                  Text(
                                    '$remainingCoins Coins',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: MigoColors.primary),
                                  ),
                                ],
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }

              // സ്റ്റാറ്റസ് pending ആണെങ്കിൽ QR കാണിക്കും
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Show this QR to the shop',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: 'MIGO_PAY_$paymentId',
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bill: ${widget.business.currency} ${widget.offer.offerPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Using $_coinsToUse Coins',
                        style: const TextStyle(fontSize: 14, color: MigoColors.success),
                      ),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Waiting for shop to scan...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingQR = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        if (_loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'الدفع بالعملات' : 'Pay with Coins'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business & Offer Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MigoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: MigoShadows.soft,
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.business.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.business.category} · ${widget.business.city}',
                          style: const TextStyle(fontSize: 13, color: MigoColors.textSecondaryLight),
                        ),
                        const Divider(),
                        Text(
                          widget.offer.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.business.currency} ${widget.offer.offerPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MigoColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Summary
                  if (_user != null && _settings != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MigoColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MigoColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'ملخص الدفع' : 'Payment Summary',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isAr ? 'رصيد العملات:' : 'Coin Balance:',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('${_user!.coins}'),
                            ],
                          ),
                          
                          const SizedBox(height: 6),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isAr ? 'الحد الأقصى للاستخدام (${_settings!.maxRedemptionPercent}%):' : 'Max Usage (${_settings!.maxRedemptionPercent}%):',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('$_coinsToUse Coins'),
                            ],
                          ),
                          
                          const Divider(),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isAr ? 'المبلغ المتبقي:' : 'Remaining to pay:',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${widget.business.currency} ${(widget.offer.offerPrice - (_coinsToUse * (_settings!.getValueFor100Coins(_user!.currentCountryCode ?? 'QA') / 100))).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingQR ? null : _generateQR,
                        icon: _isGeneratingQR 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.qr_code),
                        label: Text(
                          _isGeneratingQR 
                              ? (isAr ? 'جارٍ التحميل...' : 'Generating...') 
                              : (isAr ? 'إنشاء رمز QR للدفع' : 'Generate Payment QR'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}