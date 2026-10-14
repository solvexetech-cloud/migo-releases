import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/country_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/localization_service.dart';
import '../business/my_business_screen.dart';
import '../deals/my_claims_screen.dart';
import '../reserve/my_bookings_screen.dart';
import '../../models/creator_model.dart';
import '../../services/creator_service.dart';
import '../creator/creator_dashboard_screen.dart';
import '../creator/creator_signup_screen.dart';
import '../referrals/referral_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: FirestoreService.instance.streamUser(firebaseUser.uid),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return CustomScrollView(
            slivers: [
              // Gradient hero header
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
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: MigoGradients.gold,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              child: Text(
                                (user?.displayName ??
                                        firebaseUser.email ??
                                        'M')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: MigoColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.displayName ??
                                firebaseUser.email ??
                                'MIGO User',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firebaseUser.email ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _HeroStat(
                                  label: 'Coins',
                                  value: '${user?.coins ?? 0}',
                                  icon: Icons.monetization_on,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _HeroStat(
                                  label: 'Level',
                                  value: user?.loyaltyLevel ?? 'Bronze',
                                  icon: Icons.emoji_events,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _HeroStat(
                                  label: 'City',
                                  value: user?.city ?? 'Doha',
                                  icon: Icons.place,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // D6-A: Country switcher
                      if (user != null) ...[
                        const Text(
                          'LOCATION & CURRENCY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: MigoColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _CountrySwitcher(
                          currentCountryCode:
                              user.currentCountryCode ?? user.country,
                          currentCurrency: user.currency,
                          uid: user.uid,
                        ),
                        const SizedBox(height: 8),
                        const _LanguageSwitcher(),
                        const SizedBox(height: 20),
                      ],
                      const Text(
                        'ACTIVITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MenuTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'My Claims',
                        color: MigoColors.primary,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyClaimsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _MenuTile(
                        icon: Icons.event_available_outlined,
                        label: 'My Bookings',
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyBookingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const _CreatorMenuTile(),
                      const SizedBox(height: 8),
                      _MenuTile(
                        icon: Icons.card_giftcard,
                        label: 'Invite Friends',
                        color: MigoColors.accent,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReferralScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'BUSINESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MenuTile(
                        icon: Icons.storefront_outlined,
                        label: 'My Business',
                        color: MigoColors.success,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyBusinessScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () => _signOut(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MigoColors.accent, size: 14),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = MigoColors.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MigoColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: MigoShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MigoColors.textPrimaryLight,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: MigoColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PHASE E — E6: Creator Menu Tile
// ═══════════════════════════════════════════════════════════
class _CreatorMenuTile extends StatelessWidget {
  const _CreatorMenuTile();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<CreatorModel?>(
      stream: CreatorService.instance.streamCreator(uid),
      builder: (context, snap) {
        final creator = snap.data;
        final isCreator = creator != null && creator.isApproved;

        return _MenuTile(
          icon: isCreator
              ? Icons.dashboard_outlined
              : Icons.movie_creation_outlined,
          label: isCreator ? 'Creator Dashboard' : 'Become a Creator',
          color: const Color(0xFFD97706),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => isCreator
                    ? const CreatorDashboardScreen()
                    : const CreatorSignupScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// D6-A: Country Switcher Widget
// ═══════════════════════════════════════════════════════════
class _CountrySwitcher extends StatelessWidget {
  const _CountrySwitcher({
    required this.currentCountryCode,
    required this.currentCurrency,
    required this.uid,
  });

  final String currentCountryCode;
  final String currentCurrency;
  final String uid;

  Future<void> _pickCountry(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CountryPickerSheet(
        currentCode: currentCountryCode,
        uid: uid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _pickCountry(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: MigoColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MigoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.public,
                  color: MigoColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Country',
                      style: TextStyle(
                        fontSize: 11,
                        color: MigoColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currentCountryCode · $currentCurrency',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: MigoColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_right,
                color: MigoColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.currentCode,
    required this.uid,
  });

  final String currentCode;
  final String uid;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  List<CountryModel> _countries = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await FirestoreService.instance.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _select(CountryModel c) async {
    if (c.code == widget.currentCode) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.updateUser(widget.uid, {
        'currentCountryCode': c.code,
        'country': c.name,
        'currency': c.currency,
        'locale': c.locale,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Country updated to ${c.name} · ${c.currency}'),
          backgroundColor: MigoColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: MigoColors.error,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MigoColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose your country',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: MigoColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Currency changes automatically',
              style: TextStyle(
                fontSize: 12,
                color: MigoColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _countries.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: MigoColors.dividerLight,
                  ),
                  itemBuilder: (context, i) {
                    final c = _countries[i];
                    final selected = c.code == widget.currentCode;
                    return ListTile(
                      onTap: _saving ? null : () => _select(c),
                      leading: Text(
                        c.flag.isNotEmpty ? c.flag : '🌐',
                        style: const TextStyle(fontSize: 26),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${c.currency} · ${c.dialCode}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle,
                              color: MigoColors.success,
                            )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// D6-B: Language Switcher Widget
// ═══════════════════════════════════════════════════════════
class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher();

  Future<void> _pickLanguage(BuildContext context) async {
    final current = LocaleProvider.instance.locale;
    final languages = LocalizationService.instance.languages;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MigoColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose your language',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: MigoColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'App text updates instantly',
                style: TextStyle(
                  fontSize: 12,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final selected = lang.code == current;
                return ListTile(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await LocaleProvider.instance.setLocale(lang.code);
                  },
                  leading: Text(
                    lang.code == 'ar' ? '🇸🇦' : '🇬🇧',
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(
                    lang.nameNative,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    lang.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: selected
                      ? const Icon(
                          Icons.check_circle,
                          color: MigoColors.success,
                        )
                      : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final current = LocaleProvider.instance.locale;
        final label = current == 'ar' ? 'العربية (Arabic)' : 'English';

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _pickLanguage(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: MigoColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MigoColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.translate,
                      color: MigoColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 11,
                            color: MigoColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_right,
                    color: MigoColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}