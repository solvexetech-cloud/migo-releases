import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

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
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<UserModel?>(
        stream: FirestoreService.instance.streamUser(firebaseUser.uid),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const CircleAvatar(
                  radius: 44,
                  child: Icon(Icons.person_outline, size: 44),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.displayName ?? firebaseUser.email ?? 'MIGO User',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Center(
                  child: Text(
                    firebaseUser.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 24),
                _StatCard(
                  icon: Icons.monetization_on_outlined,
                  label: 'MIGO Coins',
                  value: '${user?.coins ?? 0}',
                  color: MigoColors.accent,
                ),
                const SizedBox(height: 10),
                _StatCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'Loyalty Level',
                  value: user?.loyaltyLevel ?? 'Bronze',
                  color: MigoColors.primary,
                ),
                const SizedBox(height: 10),
                _StatCard(
                  icon: Icons.place_outlined,
                  label: 'Location',
                  value: '${user?.city ?? 'Doha'}, ${user?.country ?? 'QA'}',
                  color: MigoColors.success,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MigoColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MigoColors.dividerLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: MigoColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: MigoColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}