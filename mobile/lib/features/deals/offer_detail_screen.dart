import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/claim_model.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';

class OfferDetailScreen extends StatefulWidget {
  const OfferDetailScreen({super.key, required this.offer});
  final OfferModel offer;

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  bool _loading = false;
  bool _checkingExisting = true;
  ClaimModel? _existingClaim;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _checkingExisting = false);
      return;
    }
    final claim = await FirestoreService.instance.findActiveClaim(
      userUid: uid,
      offerId: widget.offer.id,
    );
    if (!mounted) return;
    setState(() {
      _existingClaim = claim;
      _checkingExisting = false;
    });
  }

  Future<void> _claim() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('Please sign in first.');
      return;
    }

    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final claim = ClaimModel(
        id: '',
        userUid: uid,
        businessId: widget.offer.businessId,
        businessName: widget.offer.businessName,
        offerId: widget.offer.id,
        offerTitle: widget.offer.title,
        currency: widget.offer.currency,
        originalPrice: widget.offer.originalPrice,
        offerPrice: widget.offer.offerPrice,
        claimedAt: now,
        expiresAt: widget.offer.endAt,
        source: 'home',
      );

      await FirestoreService.instance.createClaim(claim);
      if (!mounted) return;

      _snack('Claimed! Check My Claims in your Profile.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to claim: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      o.businessName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  // Image
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      color: MigoColors.primary.withValues(alpha: 0.08),
                      child: o.imageUrl == null
                          ? const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: MigoColors.primary,
                              ),
                            )
                          : Image.network(o.imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: o.type == OfferType.flash
                                    ? MigoColors.error
                                    : MigoColors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                o.type.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: o.type == OfferType.flash
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    MigoColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${o.percentOff}% OFF',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: MigoColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          o.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          o.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: MigoColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Pricing
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MigoColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Original',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: MigoColors.textSecondaryLight,
                                    ),
                                  ),
                                  Text(
                                    '${o.currency} ${o.originalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: MigoColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'MIGO price',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: MigoColors.textSecondaryLight,
                                    ),
                                  ),
                                  Text(
                                    '${o.currency} ${o.offerPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: MigoColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.savings_outlined,
                              size: 18,
                              color: MigoColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'You save ${o.currency} ${o.savings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: MigoColors.success,
                              ),
                            ),
                          ],
                        ),
                        if (o.terms != null && o.terms!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Terms',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            o.terms!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: MigoColors.textSecondaryLight,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: MigoColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Valid until ${o.endAt.toLocal().toString().split('.').first}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: MigoColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom claim bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MigoColors.surfaceLight,
                border: Border(
                  top: BorderSide(color: MigoColors.dividerLight),
                ),
              ),
              child: _checkingExisting
                  ? const Center(child: CircularProgressIndicator())
                  : _existingClaim != null
                      ? _claimedBanner()
                      : _claimButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _claimButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _claim,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Claim this offer'),
      ),
    );
  }

  Widget _claimedBanner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: MigoColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You already claimed this offer',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}