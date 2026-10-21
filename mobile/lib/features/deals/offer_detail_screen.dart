import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; // Clipboard-ന് വേണ്ടി
import '../reserve/booking_screen.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/claim_model.dart';
import '../../models/group_deal_model.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
import '../business/business_detail_screen.dart'; // ✅ ഇത് മാറ്റി
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
  GroupDealModel? _groupDeal;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _checkExisting();
    if (widget.offer.type == OfferType.group) {
      _listenGroupDeal();
    }
  }

  void _listenGroupDeal() {
    FirestoreService.instance
        .streamGroupDeal(widget.offer.id)
        .listen((deal) {
      if (!mounted) return;
      setState(() => _groupDeal = deal);
    });
  }

  Future<void> _checkExisting() async {
    if (_uid == null) {
      setState(() => _checkingExisting = false);
      return;
    }
    final claim = await FirestoreService.instance.findActiveClaim(
      userUid: _uid!,
      offerId: widget.offer.id,
    );
    if (!mounted) return;
    setState(() {
      _existingClaim = claim;
      _checkingExisting = false;
    });
  }

  Future<void> _claim() async {
    if (_uid == null) {
      _snack('Please sign in first.');
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
        claimedAt: now,
        expiresAt: widget.offer.endAt,
        source: 'home',
      );

      await FirestoreService.instance.createClaim(claim);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClaimSuccessScreen(offer: widget.offer),
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
    if (_uid == null || _groupDeal == null) return;
    final joined = _groupDeal!.participantUids.contains(_uid);
    setState(() => _loading = true);
    try {
      if (joined) {
        await FirestoreService.instance.leaveGroupDeal(
          offerId: widget.offer.id,
          userUid: _uid!,
        );
        _snack('You left the group deal.');
      } else {
        await FirestoreService.instance.joinGroupDeal(
          offerId: widget.offer.id,
          userUid: _uid!,
        );
        _snack('You joined the group deal!');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
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
    final isGroup = o.type == OfferType.group;
    final deal = _groupDeal;
    final joined =
        deal != null && _uid != null && deal.participantUids.contains(_uid);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // ✅ Business Detail Screen-ലേക്ക് മാറ്റി
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
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: MigoColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                          
                                       // ── Copy Link Button ──
                  IconButton(
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                      final url = 'https://migo-app-3030e.web.app/o/${o.id}?ref=$uid';
                      
                      await Clipboard.setData(ClipboardData(text: url));
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied! Share it with your friends.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy link',
                  ),


                                    IconButton(
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                      final url = 'https://migo-app-3030e.web.app/o/${o.id}?ref=$uid';
                      final price = '${o.currency} ${o.offerPrice.toStringAsFixed(0)}';
                      final original = '${o.currency} ${o.originalPrice.toStringAsFixed(0)}';
                      SharePlus.instance.share(
                        ShareParams(
                          text: '🔥 Check out this deal on MIGO!\n\n'
                              '${o.title}\n'
                              'Price: $price (was $original)\n'
                              'Save ${o.currency} ${o.savings.toStringAsFixed(0)}\n\n'
                              '$url',
                          subject: o.title,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Share offer',
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
                                    : o.type == OfferType.group
                                        ? MigoColors.primaryLight
                                        : MigoColors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                o.type.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: o.type == OfferType.flash ||
                                          o.type == OfferType.group
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
                                color: MigoColors.success
                                    .withValues(alpha: 0.15),
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                MigoColors.primary.withValues(alpha: 0.05),
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
                                      decoration:
                                          TextDecoration.lineThrough,
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
                        if (isGroup && deal != null) ...[
                          const SizedBox(height: 20),
                          _GroupProgressCard(
                            deal: deal,
                            currency: o.currency,
                            joined: joined,
                          ),
                        ],
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
                border: Border(
                  top: BorderSide(color: MigoColors.dividerLight),
                ),
              ),
              child: _checkingExisting
                  ? const Center(child: CircularProgressIndicator())
                  : isGroup
                      ? _groupAction(deal, joined)
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.offer.reserveEnabled) ...[
          // Reserve ON ആണെങ്കിൽ "Reserve Now" മാത്രം കാണിക്കുക
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(offerId: widget.offer.id),
                  ),
                );
              },
              icon: const Icon(Icons.event_available, size: 20),
              label: const Text(
                'Reserve Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else ...[
          // Reserve OFF ആണെങ്കിൽ "Get QR Code" കാണിക്കുക
          SizedBox(
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
                  : const Text('Get QR Code'),
            ),
          ),
        ],
      ],
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
            const Expanded(
              child: Text(
               'Offer is ready! Show this at the store.',
                style: TextStyle(
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

  Widget _groupAction(GroupDealModel? deal, bool joined) {
    if (deal == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (deal.status == GroupDealStatus.unlocked) {
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _existingClaim != null ? null : _claim,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(
            _existingClaim != null
                ? 'Already claimed'
                : 'Deal unlocked — Claim now',
          ),
        ),
      );
    }
    if (deal.status == GroupDealStatus.failed ||
        deal.status == GroupDealStatus.expired) {
      return const Center(
        child: Text(
          'This group deal is closed',
          style: TextStyle(color: MigoColors.textSecondaryLight),
        ),
      );
    }

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _toggleJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: joined ? MigoColors.error : MigoColors.primary,
        ),
        icon: Icon(joined ? Icons.exit_to_app : Icons.group_add),
        label: Text(
          joined
              ? 'Leave group'
              : 'Join group · ${deal.joinedCount}/${deal.minParticipants}',
        ),
      ),
    );
  }
}

class _GroupProgressCard extends StatelessWidget {
  const _GroupProgressCard({
    required this.deal,
    required this.currency,
    required this.joined,
  });

  final GroupDealModel deal;
  final String currency;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    final progress = deal.progress.clamp(0.0, 1.0);
    final statusColor = deal.status == GroupDealStatus.unlocked
        ? MigoColors.success
        : deal.status == GroupDealStatus.failed
            ? MigoColors.error
            : MigoColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                deal.status == GroupDealStatus.unlocked
                    ? Icons.lock_open
                    : Icons.groups,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                deal.status == GroupDealStatus.unlocked
                    ? 'Deal unlocked!'
                    : 'Group deal in progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deal.status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${deal.joinedCount}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '/ ${deal.minParticipants} people',
                  style: const TextStyle(
                    fontSize: 14,
                    color: MigoColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (deal.maxParticipants != null)
                Text(
                  'Max ${deal.maxParticipants}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: MigoColors.textSecondaryLight,
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
              backgroundColor: statusColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            deal.status == GroupDealStatus.unlocked
                ? 'Everyone in the group can now claim this deal.'
                : '${deal.spotsLeft} more needed. Deadline: ${deal.deadline.toLocal().toString().split('.').first}',
            style: const TextStyle(
              fontSize: 12,
              color: MigoColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
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

  // ✅ ഈ ഫങ്ക്ഷൻ ആണ് വിട്ടുപോയത്
  Future<void> _load() async {
    if (widget.uid.isEmpty) return;
    final saved = await FirestoreService.instance
        .isOfferSaved(widget.uid, widget.offerId);
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _loaded = true;
    });
  }

  Future<void> _toggle() async {
    if (widget.uid.isEmpty) return;

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
        content: Text(_saved ? 'Saved to My Deals' : 'Removed from saved'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(width: 44, height: 44);
    }
    return IconButton(
      onPressed: _toggle,
      icon: Icon(
        _saved ? Icons.favorite : Icons.favorite_border,
        color: _saved ? MigoColors.error : MigoColors.textPrimaryLight,
      ),
    );
  }
}