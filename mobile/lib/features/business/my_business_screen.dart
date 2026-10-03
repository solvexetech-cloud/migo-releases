import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/business_model.dart';
import '../../services/firestore_service.dart';
import 'register_business_screen.dart';

class MyBusinessScreen extends StatelessWidget {
  const MyBusinessScreen({super.key});

  Future<void> _openRegister(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return MigoColors.success;
      case 'pending':
        return MigoColors.warning;
      case 'rejected':
      case 'suspended':
        return MigoColors.error;
      default:
        return MigoColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Business')),
      body: StreamBuilder<BusinessModel?>(
        stream: FirestoreService.instance.streamMyBusiness(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final biz = snap.data;
          if (biz == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 72,
                    color: MigoColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No business yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Register your business to start publishing offers on MIGO.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MigoColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openRegister(context),
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Register business'),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MigoColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: MigoColors.dividerLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            biz.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(biz.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              biz.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(biz.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        biz.category,
                        style: const TextStyle(
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: MigoColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              biz.addressLine,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (biz.description != null &&
                          biz.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          biz.description!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (biz.status == 'pending')
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MigoColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MigoColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.schedule, color: MigoColors.warning),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your business is under review. MIGO team will approve it soon.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (biz.status == 'approved')
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MigoColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: MigoColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: MigoColors.success),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Approved! You can now create offers.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}