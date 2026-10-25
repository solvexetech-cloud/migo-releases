import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../core/utils/migo_animations.dart';
import '../../models/business_model.dart';
import '../../models/offer_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/migo_empty_state.dart';
import '../business/business_detail_screen.dart';
import '../main/main_shell.dart';
import 'my_claims_screen.dart';

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
                // Hero Header
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
                                  : 'Your saved offers, businesses, and claims',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _HeroAction(
                              icon: Icons.receipt_long_outlined,
                              title: isAr ? 'مطالباتي' : 'My Claims',
                              body: isAr
                                  ? 'عرض جميع العروض التي طالبت بها'
                                  : 'View all your claimed offers',
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

                // SAVED OFFERS
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

                // SAVED BUSINESSES
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

                // Explore More Deals Banner
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
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final offers = snap.data ?? [];
        if (offers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 200,
              child: MigoEmptyState(
                icon: Icons.favorite_border,
                title: isAr ? 'لا توجد عروض محفوظة بعد' : 'No saved offers yet',
                body: isAr
                    ? 'اضغط على القلب في أي عرض لحفظه هنا لاحقًا.'
                    : 'Tap the heart on any offer to save it here for later.',
              ),
            ),
          );
        }
        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 240,
              child: TapScale(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BusinessDetailScreen(
                        businessId: offers[i].businessId,
                        businessName: offers[i].businessName,
                      ),
                    ),
                  );
                },
                child: _SavedOfferCard(offer: offers[i], isAr: isAr),
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 100,
              child: Center(child: Text(isAr ? 'لا توجد شركات محفوظة بعد' : 'No saved businesses yet')),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: businesses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final b = businesses[i];
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
          },
        );
      },
    );
  }
}