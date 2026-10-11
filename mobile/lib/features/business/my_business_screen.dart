import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/business_model.dart';
import '../../models/offer_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import 'business_analytics_screen.dart';
import 'create_offer_screen.dart';
import 'redeem_screen.dart';
import 'shop_bookings_screen.dart';
import 'register_business_screen.dart';

class MyBusinessScreen extends StatefulWidget {
  const MyBusinessScreen({super.key});

  @override
  State<MyBusinessScreen> createState() => _MyBusinessScreenState();
}

class _MyBusinessScreenState extends State<MyBusinessScreen> {
  final _picker = ImagePicker();
  bool _uploadingLogo = false;
  bool _uploadingCover = false;

  Future<void> _openRegister(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterBusinessScreen()),
    );
  }

  Future<void> _openCreateOffer(
    BuildContext context,
    BusinessModel business,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOfferScreen(business: business),
      ),
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

  // ---------- LOGO UPLOAD ----------
  Future<void> _pickLogo(ImageSource source, String businessId) async {
    if (_uploadingLogo) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploadingLogo = true);

      String? url;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        url = await CloudinaryService.instance.upload(
          bytes: bytes,
          filename: picked.name,
          folder: 'migo/logos',
        );
      } else {
        url = await CloudinaryService.instance.upload(
          file: File(picked.path),
          folder: 'migo/logos',
        );
      }

      if (url == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo upload failed. Try again.')),
        );
        return;
      }

      await FirestoreService.instance.updateBusiness(
        businessId,
        {'logoUrl': url},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo updated ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logo upload error: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  // ---------- COVER UPLOAD ----------
  Future<void> _pickCover(ImageSource source, String businessId) async {
    if (_uploadingCover) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploadingCover = true);

      String? url;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        url = await CloudinaryService.instance.upload(
          bytes: bytes,
          filename: picked.name,
          folder: 'migo/covers',
        );
      } else {
        url = await CloudinaryService.instance.upload(
          file: File(picked.path),
          folder: 'migo/covers',
        );
      }

      if (url == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover upload failed. Try again.')),
        );
        return;
      }

      await FirestoreService.instance.updateBusiness(
        businessId,
        {'coverUrl': url},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover updated ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cover upload error: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  // ---------- REMOVE ----------
  Future<void> _removeLogo(String businessId) async {
    await FirestoreService.instance.updateBusiness(
      businessId,
      {'logoUrl': null},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo removed')),
    );
  }

  Future<void> _removeCover(String businessId) async {
    await FirestoreService.instance.updateBusiness(
      businessId,
      {'coverUrl': null},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cover removed')),
    );
  }

  // ---------- BOTTOM SHEETS ----------
  void _showLogoSheet(BusinessModel biz) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Business Logo',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.gallery, biz.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.camera, biz.id);
              },
            ),
            if (biz.logoUrl != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: MigoColors.error,
                ),
                title: const Text(
                  'Remove logo',
                  style: TextStyle(color: MigoColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeLogo(biz.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCoverSheet(BusinessModel biz) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Cover Photo',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickCover(ImageSource.gallery, biz.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickCover(ImageSource.camera, biz.id);
              },
            ),
            if (biz.coverUrl != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: MigoColors.error,
                ),
                title: const Text(
                  'Remove cover',
                  style: TextStyle(color: MigoColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeCover(biz.id);
                },
              ),
          ],
        ),
      ),
    );
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

                    return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ---------- COVER PHOTO ----------
              _CoverPhotoWidget(
                coverUrl: biz.coverUrl,
                uploading: _uploadingCover,
                onTap: () => _showCoverSheet(biz),
              ),
              const SizedBox(height: 8),

              // ---------- INFO CARD ----------
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        _LogoWidget(
                          logoUrl: biz.logoUrl,
                          uploading: _uploadingLogo,
                          onTap: () => _showLogoSheet(biz),
                        ),
                        const SizedBox(width: 14),
                        // Name + category + address
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      biz.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
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
                              const SizedBox(height: 4),
                              Text(
                                biz.category,
                                style: const TextStyle(
                                  color: MigoColors.textSecondaryLight,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: MigoColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      biz.addressLine,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap logo or cover to change',
                      style: TextStyle(
                        fontSize: 11,
                        color: MigoColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                          'Your business is under review.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              if (biz.status == 'approved') ...[
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
                          'Approved! Create your first offer below.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreateOffer(context, biz),
                    icon: const Icon(Icons.add),
                    label: const Text('Create offer'),
                  ),
                ),

                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                builder: (_) => ShopBookingsScreen(businessId: biz.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('Shop Bookings'),
                  ),
                ),

                                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RedeemScreen(business: biz),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Redeem claim'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BusinessAnalyticsScreen(business: biz),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('View analytics'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'YOUR OFFERS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: MigoColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 10),
             _MyOffersList(businessId: biz.id, business: biz),
            ],
          );
        },
      ),
    );
  }
}

class _MyOffersList extends StatelessWidget {
  const _MyOffersList({
    required this.businessId,
    required this.business,
  });
  final String businessId;
  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OfferModel>>(
      stream: FirestoreService.instance.streamMyOffers(businessId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final offers = snap.data ?? [];
        if (offers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MigoColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MigoColors.dividerLight),
            ),
            child: const Center(
              child: Text(
                'No offers yet',
                style: TextStyle(color: MigoColors.textSecondaryLight),
              ),
            ),
          );
        }

        return Column(
          children: offers.map((o) {
            final statusColor = o.status == 'live'
                ? MigoColors.success
                : o.status == 'pending'
                    ? MigoColors.warning
                    : MigoColors.textSecondaryLight;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MigoColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MigoColors.dividerLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
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
                          o.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    o.type.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MigoColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${o.currency} ${o.originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${o.currency} ${o.offerPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
                          'SAVE ${o.currency} ${o.savings.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (o.isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: MigoColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'EXPIRED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: MigoColors.error,
                            ),
                          ),
                        ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateOfferScreen(
                                business: business,
                                initialOffer: o,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined, size: 14),
                        label: const Text(
                          'Duplicate',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
// ---------- COVER PHOTO WIDGET ----------
class _CoverPhotoWidget extends StatelessWidget {
  const _CoverPhotoWidget({
    required this.coverUrl,
    required this.uploading,
    required this.onTap,
  });
  final String? coverUrl;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: MigoColors.surfaceLight,
              border: Border.all(color: MigoColors.dividerLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: coverUrl != null
                ? Image.network(
                    coverUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: MigoColors.primary,
                      ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: MigoColors.primary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add cover photo',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: MigoColors.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to upload',
                          style: TextStyle(
                            fontSize: 11,
                            color: MigoColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (uploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          if (coverUrl != null && !uploading)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- LOGO WIDGET ----------
class _LogoWidget extends StatelessWidget {
  const _LogoWidget({
    required this.logoUrl,
    required this.uploading,
    required this.onTap,
  });
  final String? logoUrl;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MigoColors.primary,
              border: Border.all(color: MigoColors.dividerLight, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null
                ? Image.network(
                    logoUrl!,
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.storefront_outlined,
                    size: 36,
                    color: Colors.white,
                  ),
          ),
          if (uploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: MigoColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}