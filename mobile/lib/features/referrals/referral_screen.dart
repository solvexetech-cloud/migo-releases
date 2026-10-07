import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/referral_model.dart';
import '../../services/firestore_service.dart';

/// Base URL for referral links.
/// Current: Firebase Hosting (Option A).
/// Future: custom domain (e.g. migo.app) via B3.10 migration.
const String _referralBaseUrl = 'https://migo-app-3030e.web.app/r';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String? _code;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final code = await FirestoreService.instance.ensureReferralCode(uid);
    if (!mounted) return;
    setState(() {
      _code = code;
      _loading = false;
    });
  }

  String _buildReferralLink() => '$_referralBaseUrl/$_code';

  String _buildShareText() {
    return 'Join me on MIGO — exclusive deals in Qatar & Kerala! 🎁\n\n'
        'Use my code: $_code\n'
        'Sign up here: ${_buildReferralLink()}\n\n'
        'You get +30 MIGO Coins after your first deal, '
        'and I get +50! 💰';
  }

  Future<void> _copyCode() async {
    if (_code == null) return;
    await Clipboard.setData(ClipboardData(text: _code!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied')),
    );
  }

  Future<void> _copyLink() async {
    if (_code == null) return;
    await Clipboard.setData(ClipboardData(text: _buildShareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral link copied — share it!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        MigoColors.primary,
                        MigoColors.primaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: MigoColors.accent,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Invite friends, both earn coins',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You get +50, your friend gets +30 after their first claim.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _code ?? '------',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: MigoColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyCode,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white38,
                                ),
                              ),
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy code'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _copyLink,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MigoColors.accent,
                                foregroundColor: Colors.black,
                              ),
                              icon: const Icon(Icons.share, size: 16),
                              label: const Text('Copy link'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Preview of the share text
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MigoColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MigoColors.dividerLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 14,
                            color: MigoColors.textSecondaryLight,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: MigoColors.textSecondaryLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _code == null ? '...' : _buildShareText(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: MigoColors.textPrimaryLight,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your referrals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: MigoColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                if (uid != null) _ReferralList(referrerUid: uid),
              ],
            ),
    );
  }
}

class _ReferralList extends StatelessWidget {
  const _ReferralList({required this.referrerUid});
  final String referrerUid;

  Color _statusColor(ReferralStatus s) {
    switch (s) {
      case ReferralStatus.pending:
        return MigoColors.warning;
      case ReferralStatus.rewarded:
        return MigoColors.success;
      case ReferralStatus.rejected:
        return MigoColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReferralModel>>(
      stream: FirestoreService.instance.streamMyReferrals(referrerUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final refs = snap.data ?? [];
        if (refs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MigoColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MigoColors.dividerLight),
            ),
            child: const Center(
              child: Text(
                'No referrals yet — share your code!',
                style: TextStyle(
                  color: MigoColors.textSecondaryLight,
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: MigoColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MigoColors.dividerLight),
          ),
          child: Column(
            children: List.generate(refs.length, (i) {
              final r = refs[i];
              final isLast = i == refs.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.referredEmail,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.status == ReferralStatus.rewarded
                                    ? '+${r.referrerReward} coins earned'
                                    : 'Reward on their first claim',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: MigoColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(r.status)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.status.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _statusColor(r.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: MigoColors.dividerLight),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}