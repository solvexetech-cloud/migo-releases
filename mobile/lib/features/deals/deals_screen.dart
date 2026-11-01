import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // 🆕 Map, Call, WhatsApp എന്നിവയ്ക്ക് വേണ്ടി

import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../core/utils/migo_animations.dart';
import '../../models/business_model.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/offer_card.dart';
import '../business/business_detail_screen.dart';
import '../main/main_shell.dart';
import 'my_claims_screen.dart';
import 'offer_detail_screen.dart';
import 'qr_code_screen.dart'; // 🆕 QR കോഡിന് വേണ്ടി

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                // ── Hero Header ──
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: MigoGradients.heroBlue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'عروضي' : 'My Deals',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAr
                                  ? 'العروض والشركات والمطالبات المحفوظة'
                                  : 'Your claimed shops, saved offers & businesses',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _HeroAction(
                              icon: Icons.receipt_long_outlined,
                              title: isAr ? 'سجل المطالبات' : 'Claim History',
                              body: isAr
                                  ? 'عرض جميع العروض النشطة والمستخدمة'
                                  : 'View all your active and used offers',
                              isAr: isAr,
                              onTap: () {
                                Navigator.of(context).push(
                                  FadeSlideRoute(child: const MyClaimsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── 🆕 ACTIVE CLAIMS (ക്ലെയിം ചെയ്ത കടകൾ) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionLabel(isAr ? 'المطالبات النشطة' : 'ACTIVE CLAIMS'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _ActiveClaimsRow(uid: uid, isAr: isAr),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── SAVED OFFERS ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionLabel(isAr ? 'العروض المحفوظة' : 'SAVED OFFERS'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _SavedOffersRow(uid: uid, isAr: isAr),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── SAVED BUSINESSES ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionLabel(isAr ? 'الشركات المحفوظة' : 'SAVED BUSINESSES'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _SavedBusinessesRow(uid: uid, isAr: isAr),
                ),

                // ── Explore More Deals Banner ──
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: MigoGradients.softBlue,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MigoColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.explore_outlined, size: 40, color: MigoColors.primary),
                          const SizedBox(height: 12),
                          Text(
                            isAr ? 'تبحث عن المزيد؟' : 'Looking for more?',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr
                                ? 'اكتشف عروضًا مذهلة ووفر المزيد على علاماتك التجارية المفضلة.'
                                : 'Discover amazing offers and save more on your favorite brands.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: MigoColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const MainShell(initialIndex: 1),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              child: Text(isAr ? 'استكشف العروض' : 'Explore Deals'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w800,
        color: MigoColors.textSecondaryLight,
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    required this.isAr,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MigoColors.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isAr ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 🆕 ACTIVE CLAIMS ROW (ക്ലെയിം ചെയ്ത കടകൾ വിവരങ്ങളോടെ)
// ─────────────────────────────────────────────────────
class _ActiveClaimsRow extends StatelessWidget {
  const _ActiveClaimsRow({required this.uid, required this.isAr});
  final String uid;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('claims')
          .where('userUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final activeClaims = snap.data?.docs ?? [];
        
        if (activeClaims.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MigoColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MigoColors.dividerLight),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, size: 40, color: MigoColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    isAr ? 'لا توجد مطالبات نشطة' : 'No active claims',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr ? 'اطالب بعرض لرؤيته هنا مع تفاصيل المتجر.' : 'Claim an offer to see shop details here.',
                    style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 240, // Height for the horizontal list
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: activeClaims.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final claimDoc = activeClaims[i];
              final claimData = claimDoc.data() as Map<String, dynamic>;
              final businessId = claimData['businessId'] as String? ?? '';
              final offerTitle = claimData['offerTitle'] as String? ?? 'Offer';
              
              return FutureBuilder<BusinessModel?>(
                future: FirestoreService.instance.getBusiness(businessId),
                builder: (context, bizSnap) {
                  final business = bizSnap.data;
                  final businessName = business?.name ?? 'Business';

                  return Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MigoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: MigoShadows.soft,
                      border: Border.all(color: MigoColors.primary.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Business Name & Title
                        Text(
                          businessName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offerTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const Spacer(),
                        
                        // 🆕 Map, Call, WhatsApp Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (business?.mapUrl != null && business!.mapUrl!.isNotEmpty)
                              _IconActionBtn(
                                icon: Icons.location_on,
                                color: Colors.blue,
                                onTap: () => _launchUrl(business.mapUrl!),
                              ),
                            if (business?.phone != null && business!.phone!.isNotEmpty)
                              _IconActionBtn(
                                icon: Icons.phone,
                                color: Colors.green,
                                onTap: () => _launchUrl('tel:${business.phone}'),
                              ),
                            if (business?.whatsapp != null && business!.whatsapp!.isNotEmpty)
                              _IconActionBtn(
                                icon: Icons.chat,
                                color: const Color(0xFF25D366),
                                onTap: () => _launchUrl('https://wa.me/${business.whatsapp}'),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Show QR Button
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => QrCodeScreen(
                                    claimId: claimDoc.id,
                                    offerTitle: offerTitle,
                                    businessName: businessName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code, size: 16),
                            label: Text(isAr ? 'عرض رمز QR' : 'Show QR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MigoColors.primary,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// 🆕 ചെറിയ ഐക്കൺ ബട്ടൺ
class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

Future<void> _launchUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $url');
  }
}


// ─────────────────────────────────────────────────────
// Saved Offers Row (ഒഴിഞ്ഞാൽ ട്രെൻഡിംഗ് ഓഫറുകൾ കാണിക്കും)
// ─────────────────────────────────────────────────────
class _SavedOffersRow extends StatelessWidget {
  const _SavedOffersRow({required this.uid, required this.isAr});
  final String uid;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: FirestoreService.instance.streamMySavedOffers(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final savedOffers = snap.data ?? [];

        if (savedOffers.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  isAr
                      ? 'لم تقم بحفظ أي عروض بعد. اكتشف العروض الرائجة!'
                      : 'You haven\'t saved any offers yet. Discover trending deals!',
                  style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight),
                ),
              ),
              StreamBuilder<List<OfferModel>>(
                stream: FirestoreService.instance.streamLiveOffers(limit: 5),
                builder: (context, liveSnap) {
                  if (!liveSnap.hasData) return const SizedBox.shrink();
                  final trending = liveSnap.data!;
                  return SizedBox(
                    height: 300,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: trending.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => SizedBox(
                        width: 280,
                        child: TapScale(
                          onTap: () {
                            Navigator.of(context).push(
                              FadeSlideRoute(
                                child: OfferDetailScreen(offer: trending[i]),
                              ),
                            );
                          },
                          child: OfferCard(offer: trending[i]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: savedOffers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 240,
              child: TapScale(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BusinessDetailScreen(
                        businessId: savedOffers[i].businessId,
                        businessName: savedOffers[i].businessName,
                      ),
                    ),
                  );
                },
                child: _SavedOfferCard(offer: savedOffers[i], isAr: isAr),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedOfferCard extends StatelessWidget {
  const _SavedOfferCard({required this.offer, required this.isAr});
  final OfferModel offer;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MigoColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MigoShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MigoColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    size: 18,
                    color: MigoColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: MigoColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${offer.percentOff}% ${isAr ? 'خصم' : 'OFF'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: MigoColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              offer.businessName.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: MigoColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              offer.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: MigoColors.textPrimaryLight,
                height: 1.2,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${offer.currency} ${offer.offerPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: MigoColors.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '${offer.currency} ${offer.originalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      color: MigoColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Saved Businesses Row (ഒഴിഞ്ഞാൽ ടോപ്പ് ബിസിനസുകൾ കാണിക്കും)
// ─────────────────────────────────────────────────────
class _SavedBusinessesRow extends StatelessWidget {
  const _SavedBusinessesRow({required this.uid, required this.isAr});
  final String uid;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusinessModel>>(
      stream: FirestoreService.instance.streamMySavedBusinesses(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final businesses = snap.data ?? [];

        if (businesses.isEmpty) {
          return FutureBuilder<List<BusinessModel>>(
            future: FirestoreService.instance.getAllBusinesses(),
            builder: (context, allSnap) {
              if (!allSnap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final topBusinesses = allSnap.data!.take(3).toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      isAr
                          ? 'لم تقم بحفظ أي شركات بعد. اكتشف الأعلى تقييماً:'
                          : 'You haven\'t saved any businesses yet. Discover top-rated:',
                      style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: topBusinesses.map((b) => _BusinessTile(b: b, isAr: isAr)).toList(),
                    ),
                  )
                ],
              );
            }
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: businesses.map((b) => _BusinessTile(b: b, isAr: isAr)).toList(),
          ),
        );
      },
    );
  }
}

class _BusinessTile extends StatelessWidget {
  final BusinessModel b;
  final bool isAr;
  const _BusinessTile({required this.b, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MigoColors.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            FadeSlideRoute(
              child: BusinessDetailScreen(
                businessId: b.id,
                businessName: b.name,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: MigoShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: MigoGradients.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront, color: MigoColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.category,
                      style: const TextStyle(fontSize: 12, color: MigoColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: MigoColors.primary),
                onPressed: () {
                  final url = 'https://migo-app-3030e.web.app/b/${b.id}';
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Check out ${b.name} on MIGO!\n$url',
                      subject: 'MIGO Business',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}