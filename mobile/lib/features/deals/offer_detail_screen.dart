import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../reserve/booking_screen.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/claim_model.dart';
import '../../models/offer_model.dart';
import '../../models/review_model.dart';
import '../../services/firestore_service.dart';
import '../business/business_detail_screen.dart';
import 'claim_success_screen.dart';

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
  bool _isJoinedGroup = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get _isPlanA => widget.offer.type == OfferType.groupAllOrNothing || widget.offer.type == OfferType.group;
  bool get _isPlanB => widget.offer.type == OfferType.groupProgressive;
  bool get _isGroupDeal => _isPlanA || _isPlanB;

  @override
  void initState() {
    super.initState();
    _checkExisting();
    _checkGroupJoined();
  }

  Future<void> _checkGroupJoined() async {
    if (_uid == null || !_isGroupDeal) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('group_joins')
          .doc('${widget.offer.id}_$_uid')
          .get();
      if (mounted) {
        setState(() {
          _isJoinedGroup = doc.exists;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkExisting() async {
    if (_uid == null) {
      setState(() => _checkingExisting = false);
      return;
    }
    try {
      final claim = await FirestoreService.instance.findActiveClaim(
        userUid: _uid!,
        offerId: widget.offer.id,
      );
      if (!mounted) return;
      setState(() {
        _existingClaim = claim;
        _checkingExisting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkingExisting = false);
    }
  }

  Future<void> _claim() async {
    final isAr = LocaleProvider.instance.locale == 'ar';
    if (_uid == null) {
      _snack(isAr ? 'Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â° ÃƒËœÃ‚ÂªÃƒËœÃ‚Â³ÃƒËœÃ‚Â¬Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â®Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â£Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¹.' : 'Please sign in first.');
      return;
    }

    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final claim = ClaimModel(
        id: '',
        userUid: _uid!,
        businessId: widget.offer.businessId,
        businessName: widget.offer.businessName,
        offerId: widget.offer.id,
        offerTitle: widget.offer.title,
        currency: widget.offer.currency,
        originalPrice: widget.offer.originalPrice,
        offerPrice: widget.offer.offerPrice,
        pickupCode: (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString(),
        status: ClaimStatus.active, // ðŸ†• à´‡à´¤àµ à´šàµ‡àµ¼à´¤àµà´¤àµ
        claimedAt: now,
        expiresAt: widget.offer.endAt,
        source: 'home',
      );

      await FirestoreService.instance.createClaim(claim);

      final settings = await FirestoreService.instance.getCoinSettings();
      final int claimCoins = settings.claimReward;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClaimSuccessScreen(
            offer: widget.offer,
            coinsAwarded: claimCoins,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to claim: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleJoin() async {
    if (_uid == null) return;
    final isAr = LocaleProvider.instance.locale == 'ar';
    setState(() => _loading = true);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('group_joins')
          .doc('${widget.offer.id}_$_uid');

      if (_isJoinedGroup) {
        await docRef.delete();
        // Decrement count in offer
        await FirebaseFirestore.instance.collection('offers').doc(widget.offer.id).update({
          'claimedCount': FieldValue.increment(-1),
        });
        if (mounted) setState(() => _isJoinedGroup = false);
        _snack(isAr ? 'Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Â¯ ÃƒËœÃ‚ÂºÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â±ÃƒËœÃ‚Âª ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â .' : 'You left the group deal.');
      } else {
        await docRef.set({
          'offerId': widget.offer.id,
          'userUid': _uid,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        // Increment count in offer
        await FirebaseFirestore.instance.collection('offers').doc(widget.offer.id).update({
          'claimedCount': FieldValue.increment(1),
        });
        if (mounted) setState(() => _isJoinedGroup = true);
        _snack(isAr ? 'Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¶Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¥Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â° ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â !' : 'You joined the group deal!');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';
        final o = widget.offer;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BusinessDetailScreen(
                                    businessId: o.businessId,
                                    businessName: o.businessName,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    o.businessName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.star, size: 14, color: MigoColors.accent),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final url = 'https://migo-app-3030e.web.app/o/${o.id}?ref=$_uid';
                            await Clipboard.setData(ClipboardData(text: url));
                            if (context.mounted) {
                              _snack(isAr ? 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â³ÃƒËœÃ‚Â® ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â·!' : 'Link copied! Share it with your friends.');
                            }
                          },
                          icon: const Icon(Icons.copy),
                          tooltip: isAr ? 'Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â³ÃƒËœÃ‚Â® ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â·' : 'Copy link',
                        ),
                        IconButton(
                          onPressed: () async {
                            final url = 'https://migo-app-3030e.web.app/o/${o.id}?ref=$_uid';
                            final price = '${o.currency} ${o.offerPrice.toStringAsFixed(0)}';
                            final original = '${o.currency} ${o.originalPrice.toStringAsFixed(0)}';
                            final shareText = isAr
                                ? 'ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ‚Â¥ ÃƒËœÃ‚ÂªÃƒËœÃ‚Â­Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã¢â‚¬Å¡ Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â  Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â°ÃƒËœÃ‚Â§ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¹Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â° Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¬Ãƒâ„¢Ã‹â€ !\n\n${o.titleAr}\nÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±: $price (Ãƒâ„¢Ã†â€™ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â  $original)\nÃƒâ„¢Ã‹â€ Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â± ${o.currency} ${o.savings.toStringAsFixed(0)}\n\n$url'
                                : 'ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ‚Â¥ Check out this deal on MIGO!\n\n${o.titleEn}\nPrice: $price (was $original)\nSave ${o.currency} ${o.savings.toStringAsFixed(0)}\n\n$url';

                            SharePlus.instance.share(
                              ShareParams(text: shareText, subject: isAr ? o.titleAr : o.titleEn),
                            );
                          },
                          icon: const Icon(Icons.share_outlined),
                          tooltip: isAr ? 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â´ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±Ãƒâ„¢Ã†â€™ÃƒËœÃ‚Â© ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶' : 'Share offer',
                        ),
                        _SaveButton(
                          uid: _uid ?? '',
                          offerId: o.id,
                          businessId: o.businessId,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Container(
                            color: MigoColors.primary.withValues(alpha: 0.08),
                            child: o.imageUrl == null || o.imageUrl!.isEmpty
                                ? const Center(
                                    child: Icon(Icons.image_outlined,
                                        size: 64, color: MigoColors.primary),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: o.type == OfferType.flash
                                          ? MigoColors.error
                                          : _isGroupDeal
                                              ? MigoColors.primaryLight
                                              : MigoColors.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _getOfferTypeLabel(o.type, isAr).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: o.type == OfferType.flash || _isGroupDeal
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: MigoColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${o.percentOff}% ${isAr ? 'ÃƒËœÃ‚Â®ÃƒËœÃ‚ÂµÃƒâ„¢Ã¢â‚¬Â¦' : 'OFF'}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: MigoColors.success,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (o.isPromoted && (o.promotedUntil == null || o.promotedUntil!.isAfter(DateTime.now())))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, size: 12, color: Colors.black),
                                          const SizedBox(width: 3),
                                          Text(
                                            isAr ? 'Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â²' : 'FEATURED',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isAr ? o.titleAr : o.titleEn,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: MigoColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isAr ? o.descriptionAr : o.descriptionEn,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: MigoColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Price Box
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
                                        Text(isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â± ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â£ÃƒËœÃ‚ÂµÃƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã…Â ' : 'Original',
                                            style: const TextStyle(fontSize: 11, color: MigoColors.textSecondaryLight)),
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
                                        Text(isAr ? 'ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â± Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¬Ãƒâ„¢Ã‹â€ ' : 'MIGO price',
                                            style: const TextStyle(fontSize: 11, color: MigoColors.textSecondaryLight)),
                                        Text(
                                          '${o.currency} ${(_isPlanB ? o.currentPrice : o.offerPrice).toStringAsFixed(0)}',
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
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.savings_outlined, size: 18, color: MigoColors.success),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Text(
                                        isAr
                                            ? 'Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â± ${o.currency} ${(_isPlanB ? o.originalPrice - o.currentPrice : o.savings).toStringAsFixed(0)}'
                                            : 'You save ${o.currency} ${(_isPlanB ? o.originalPrice - o.currentPrice : o.savings).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: MigoColors.success,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // ÃƒÂ°Ã…Â¸Ã¢â‚¬Â Ã¢â‚¬Â¢ Plan A (All-or-Nothing) UI
                              if (_isPlanA) ...[
                                const SizedBox(height: 20),
                                _buildPlanACard(isAr, o),
                              ],

                              // ÃƒÂ°Ã…Â¸Ã¢â‚¬Â Ã¢â‚¬Â¢ Plan B (Progressive) UI
                              if (_isPlanB) ...[
                                const SizedBox(height: 20),
                                _buildPlanBCard(isAr, o),
                              ],

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BusinessDetailScreen(
                                          businessId: o.businessId,
                                          businessName: o.businessName,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.storefront, color: MigoColors.primary),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‚Â ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¬ÃƒËœÃ‚Â±' : 'View Shop Profile',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: MigoColors.primary,
                                      ),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: MigoColors.primary, width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),

                              // Reviews Section
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Text(
                                    isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã…Â Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Âª' : 'Reviews',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                ],
                              ),
                              const SizedBox(height: 10),
                              StreamBuilder<List<ReviewModel>>(
                                stream: FirestoreService.instance.streamBusinessReviews(o.businessId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Text(
                                      isAr ? 'Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ ÃƒËœÃ‚ÂªÃƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â¯ ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã…Â Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¯.' : 'No reviews yet.',
                                      style: const TextStyle(color: Colors.grey),
                                    );
                                  }
                                  final reviews = snapshot.data!.take(3).toList();
                                  return Column(
                                    children: reviews.map((r) {
                                      final name = r.userDisplayName.isEmpty ? 'U' : r.userDisplayName[0].toUpperCase();
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(child: Text(name)),
                                        title: Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              i < r.rating ? Icons.star : Icons.star_border,
                                              size: 14,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ),
                                        subtitle: Text(r.comment),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),

                              if (o.terms != null && o.terms!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â´ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â·' : 'Terms',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(o.terms!,
                                    style: const TextStyle(fontSize: 13, color: MigoColors.textSecondaryLight)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MigoColors.surfaceLight,
                      border: Border(top: BorderSide(color: MigoColors.dividerLight)),
                    ),
                    child: _checkingExisting
                        ? const Center(child: CircularProgressIndicator())
                        : _isGroupDeal
                            ? _groupAction(isAr)
                            : _existingClaim != null
                                ? _claimedBanner(isAr)
                                : _claimButton(isAr),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanACard(bool isAr, OfferModel o) {
    final required = o.requiredClaims ?? 5;
    final current = o.claimedCount;
    final progress = (current / required).clamp(0.0, 1.0);
    final isUnlocked = current >= required;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MigoColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MigoColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUnlocked ? Icons.lock_open : Icons.groups,
                color: isUnlocked ? MigoColors.success : MigoColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isUnlocked
                      ? (isAr ? 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ Ãƒâ„¢Ã‚ÂÃƒËœÃ‚ÂªÃƒËœÃ‚Â­ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶!' : 'Deal unlocked!')
                      : (isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â : Ãƒâ„¢Ã†â€™Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â´Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¡ ÃƒËœÃ‚Â£Ãƒâ„¢Ã‹â€  Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ ÃƒËœÃ‚Â´Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¡' : 'Group Deal: All-or-Nothing'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isUnlocked ? MigoColors.success : MigoColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$current',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isUnlocked ? MigoColors.success : MigoColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isAr ? '/ $required ÃƒËœÃ‚Â´ÃƒËœÃ‚Â®ÃƒËœÃ‚Âµ' : '/ $required people',
                    style: const TextStyle(fontSize: 14, color: MigoColors.textSecondaryLight, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: MigoColors.primary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(isUnlocked ? MigoColors.success : MigoColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isUnlocked
                ? (isAr ? 'Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã†â€™Ãƒâ„¢Ã¢â‚¬Â  Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¹ Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã…Â  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â© ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¢Ãƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â·ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â© ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â°ÃƒËœÃ‚Â§ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶.' : 'Everyone in the group can now claim this deal.')
                : (isAr
                    ? 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â·Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¨ ${required - current} ÃƒËœÃ‚Â£ÃƒËœÃ‚Â´ÃƒËœÃ‚Â®ÃƒËœÃ‚Â§ÃƒËœÃ‚Âµ ÃƒËœÃ‚Â¥ÃƒËœÃ‚Â¶ÃƒËœÃ‚Â§Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã…Â Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Â .'
                    : '${required - current} more people needed.'),
            style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBCard(bool isAr, OfferModel o) {
    final currentPrice = o.currentPrice;
    final floor = o.floorPrice ?? o.offerPrice;
    final step = o.stepPrice ?? 0;
    final nextPrice = (currentPrice - step) < floor ? floor : (currentPrice - step);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_down, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â : ÃƒËœÃ‚ÂªÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â± ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¯ÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¬Ãƒâ„¢Ã…Â ' : 'Group Deal: Progressive',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.purple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â± ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â­ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã…Â ' : 'Current Price',
                    style: const TextStyle(fontSize: 11, color: MigoColors.textSecondaryLight),
                  ),
                  Text(
                    '${o.currency} ${currentPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.purple),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â± ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂªÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã…Â ' : 'Next Price',
                    style: const TextStyle(fontSize: 11, color: MigoColors.textSecondaryLight),
                  ),
                  Text(
                    '${o.currency} ${nextPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MigoColors.textSecondaryLight),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'Ãƒâ„¢Ã†â€™Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ ÃƒËœÃ‚Â²ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â£ÃƒËœÃ‚Â´ÃƒËœÃ‚Â®ÃƒËœÃ‚Â§ÃƒËœÃ‚ÂµÃƒËœÃ…â€™ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â®Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±!'
                : 'The more people join, the lower the price!',
            style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _claimButton(bool isAr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.offer.reserveEnabled) ...[
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookingScreen(offerId: widget.offer.id)),
                );
              },
              icon: const Icon(Icons.event_available, size: 20),
              label: Text(
                isAr ? 'ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â² ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¢Ãƒâ„¢Ã¢â‚¬Â ' : 'Reserve Now',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _claim,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isAr ? 'ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­ÃƒËœÃ‚ÂµÃƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â¹Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â° ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â² QR' : 'Get QR Code'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _claimedBanner(bool isAr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: MigoColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAr ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â²! ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â°ÃƒËœÃ‚Â§ Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã…Â  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¬ÃƒËœÃ‚Â±.' : 'Offer is ready! Show this at the store.',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isAr ? 'ÃƒËœÃ‚Â¥ÃƒËœÃ‚ÂºÃƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¡' : 'Close'),
        ),
      ],
    );
  }

  Widget _groupAction(bool isAr) {
    if (_existingClaim != null) {
      return _claimedBanner(isAr);
    }

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _toggleJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isJoinedGroup ? MigoColors.error : MigoColors.primary,
        ),
        icon: Icon(_isJoinedGroup ? Icons.exit_to_app : Icons.group_add),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _isJoinedGroup
                ? (isAr ? 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂºÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â±ÃƒËœÃ‚Â© ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â©' : 'Leave group')
                : (isAr
                    ? 'ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¶Ãƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚Â¥Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â° ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â© Ãƒâ€šÃ‚Â· ${widget.offer.claimedCount}/${widget.offer.requiredClaims ?? 5}'
                    : 'Join group Ãƒâ€šÃ‚Â· ${widget.offer.claimedCount}/${widget.offer.requiredClaims ?? 5}'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _getOfferTypeLabel(OfferType type, bool isAr) {
    switch (type) {
      case OfferType.standard:
        return isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â§ÃƒËœÃ‚Â³Ãƒâ„¢Ã…Â ' : 'Standard Deal';
      case OfferType.flash:
        return isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â³ÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¹' : 'Flash Deal';
      case OfferType.group:
        return isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â ' : 'Group Deal';
      case OfferType.groupAllOrNothing:
        return isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â  (ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã†â€™Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚Â£Ãƒâ„¢Ã‹â€  Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ ÃƒËœÃ‚Â´Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¡)' : 'Group Deal (All-or-Nothing)';
      case OfferType.groupProgressive:
        return isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¬Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â  (ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¯ÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¬Ãƒâ„¢Ã…Â )' : 'Group Deal (Progressive)';
      case OfferType.hidden:
        return isAr ? 'ÃƒËœÃ‚Â¬Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â±ÃƒËœÃ‚Â© Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â®Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã…Â ÃƒËœÃ‚Â©' : 'Hidden Gem';
      case OfferType.birthday:
        return isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶ ÃƒËœÃ‚Â¹Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¯ Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã…Â Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯' : 'Birthday Deal';
      default:
        return isAr ? 'ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¶' : 'Deal';
    }
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({
    required this.uid,
    required this.offerId,
    required this.businessId,
  });
  final String uid;
  final String offerId;
  final String businessId;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saved = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.uid.isEmpty) return;
    final saved = await FirestoreService.instance.isOfferSaved(widget.uid, widget.offerId);
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _loaded = true;
    });
  }

  Future<void> _toggle() async {
    if (widget.uid.isEmpty) return;
    final isAr = LocaleProvider.instance.locale == 'ar';

    await FirestoreService.instance.toggleSaveOffer(
      uid: widget.uid,
      offerId: widget.offerId,
      businessId: widget.businessId,
    );
    await FirestoreService.instance.toggleSaveBusiness(
      uid: widget.uid,
      businessId: widget.businessId,
    );
    if (!mounted) return;
    setState(() => _saved = !_saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _saved
            ? (isAr ? 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â­Ãƒâ„¢Ã‚ÂÃƒËœÃ‚Â¸ Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã…Â  ÃƒËœÃ‚Â¹ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¶Ãƒâ„¢Ã…Â ' : 'Saved to My Deals')
            : (isAr ? 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Âª ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¥ÃƒËœÃ‚Â²ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â© Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â­Ãƒâ„¢Ã‚ÂÃƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¸ÃƒËœÃ‚Â§ÃƒËœÃ‚Âª' : 'Removed from saved')
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(width: 44, height: 44);
    return IconButton(
      onPressed: _toggle,
      icon: Icon(
        _saved ? Icons.favorite : Icons.favorite_border,
        color: _saved ? MigoColors.error : MigoColors.textPrimaryLight,
      ),
    );
  }
}