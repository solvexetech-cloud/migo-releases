import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/migo_theme.dart';
import '../../services/cloudinary_service.dart';

/// PHASE I — Profile Screen
/// Shows business info + logo/cover management
class ProfileScreen extends StatefulWidget {
  final String businessId;

  const ProfileScreen({super.key, required this.businessId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _uploadingLogo = false;
  bool _uploadingCover = false;

  // ═══════════════════════════════════════════════════
  // UPLOAD LOGO
  // ═══════════════════════════════════════════════════
  Future<void> _pickLogo(ImageSource source) async {
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

      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .update({
        'logoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo updated ✅'),
          backgroundColor: MigoColors.success,
        ),
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

  // ═══════════════════════════════════════════════════
  // UPLOAD COVER
  // ═══════════════════════════════════════════════════
  Future<void> _pickCover(ImageSource source) async {
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

      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .update({
        'coverUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cover updated ✅'),
          backgroundColor: MigoColors.success,
        ),
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

  // ═══════════════════════════════════════════════════
  // REMOVE
  // ═══════════════════════════════════════════════════
  Future<void> _removeLogo() async {
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .update({'logoUrl': null});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo removed')),
    );
  }

  Future<void> _removeCover() async {
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .update({'coverUrl': null});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cover removed')),
    );
  }

  // ═══════════════════════════════════════════════════
  // BOTTOM SHEETS
  // ═══════════════════════════════════════════════════
  void _showLogoSheet(String? currentLogoUrl) {
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
                _pickLogo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.camera);
              },
            ),
            if (currentLogoUrl != null)
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
                  _removeLogo();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCoverSheet(String? currentCoverUrl) {
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
                _pickCover(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickCover(ImageSource.camera);
              },
            ),
            if (currentCoverUrl != null)
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
                  _removeCover();
                },
              ),
          ],
        ),
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
        return MigoColors.textSecondary;
    }
  }

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: Text('Business not found'));
        }

        final biz = snap.data!.data() as Map<String, dynamic>;
        final name = biz['name'] as String? ?? 'Your Business';
        final category = biz['category'] as String? ?? '';
        final address = biz['addressLine'] as String? ?? '';
        final status = biz['status'] as String? ?? 'pending';
        final logoUrl = biz['logoUrl'] as String?;
        final coverUrl = biz['coverUrl'] as String?;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Business Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your public business info',
                style: TextStyle(
                  fontSize: 13,
                  color: MigoColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Cover
              _CoverWidget(
                coverUrl: coverUrl,
                uploading: _uploadingCover,
                onTap: () => _showCoverSheet(coverUrl),
              ),
              const SizedBox(height: 12),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MigoColors.divider),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LogoWidget(
                          logoUrl: logoUrl,
                          uploading: _uploadingLogo,
                          onTap: () => _showLogoSheet(logoUrl),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status)
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category,
                                style: const TextStyle(
                                  color: MigoColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: MigoColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
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
                    const SizedBox(height: 10),
                    const Text(
                      'Tap logo or cover to change',
                      style: TextStyle(
                        fontSize: 11,
                        color: MigoColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status banner
              if (status == 'pending')
                _statusBanner(
                  Icons.schedule,
                  MigoColors.warning,
                  'Your business is under review.',
                ),
              if (status == 'approved')
                _statusBanner(
                  Icons.verified,
                  MigoColors.success,
                  'Approved! Your business is live.',
                ),
              if (status == 'rejected' || status == 'suspended')
                _statusBanner(
                  Icons.error_outline,
                  MigoColors.error,
                  'Your business is $status. Contact MIGO support.',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBanner(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// COVER WIDGET
// ═══════════════════════════════════════════════════
class _CoverWidget extends StatelessWidget {
  final String? coverUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _CoverWidget({
    required this.coverUrl,
    required this.uploading,
    required this.onTap,
  });

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
              color: Colors.white,
              border: Border.all(color: MigoColors.divider),
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
                            color: MigoColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to upload',
                          style: TextStyle(
                            fontSize: 11,
                            color: MigoColors.textSecondary,
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

// ═══════════════════════════════════════════════════
// LOGO WIDGET
// ═══════════════════════════════════════════════════
class _LogoWidget extends StatelessWidget {
  final String? logoUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _LogoWidget({
    required this.logoUrl,
    required this.uploading,
    required this.onTap,
  });

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
              border: Border.all(color: MigoColors.divider, width: 2),
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