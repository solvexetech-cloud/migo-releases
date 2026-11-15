import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/migo_colors.dart';

class CreatorSignupScreen extends StatefulWidget {
  const CreatorSignupScreen({super.key});

  @override
  State<CreatorSignupScreen> createState() => _CreatorSignupScreenState();
}

class _CreatorSignupScreenState extends State<CreatorSignupScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _facebookController = TextEditingController();
  final _followersController = TextEditingController();

  final Set<String> _selectedCategories = {};
  bool _loading = false;
  bool _checking = true;
  bool _alreadyApplied = false;
  String? _error;

  static const List<Map<String, String>> _categories = [
    {'id': 'food', 'label': 'Food & Restaurants'},
    {'id': 'tech', 'label': 'Tech & Gadgets'},
    {'id': 'lifestyle', 'label': 'Lifestyle'},
    {'id': 'fashion', 'label': 'Fashion & Beauty'},
    {'id': 'travel', 'label': 'Travel'},
    {'id': 'fitness', 'label': 'Fitness & Sports'},
    {'id': 'family', 'label': 'Family'},
    {'id': 'general', 'label': 'General'},
  ];

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    _facebookController.dispose();
    _followersController.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _checking = false);
      return;
    }
    final snap = await FirebaseFirestore.instance
        .collection('creators')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
        
    if (!mounted) return;
    setState(() {
      _alreadyApplied = snap.docs.isNotEmpty;
      _checking = false;
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'Please sign in first.');
      return;
    }

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final followersText = _followersController.text.trim();

    if (name.isEmpty || bio.isEmpty) {
      setState(() => _error = 'Please fill name and bio.');
      return;
    }

    if (_selectedCategories.isEmpty) {
      setState(() => _error = 'Please select at least one category.');
      return;
    }

    final followers = int.tryParse(followersText) ?? 0;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('creators').add({
        'userId': uid,
        'displayName': name,
        'bio': bio,
        'instagramUrl': _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
        'tiktokUrl': _tiktokController.text.trim().isEmpty ? null : _tiktokController.text.trim(),
        'youtubeUrl': _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
        'facebookUrl': _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        'followers': followers,
        'followersCount': followers,
        'categories': _selectedCategories.toList(),
        'status': 'pending',
        'totalViews': 0,
        'totalClaims': 0,
        'totalRedemptions': 0,
        'totalShares': 0,
        'coinsEarned': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Application submitted! Admin will review soon.'),
          backgroundColor: MigoColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_alreadyApplied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Creator Status', style: TextStyle(color: Colors.white)), backgroundColor: MigoColors.primary),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 72, color: MigoColors.success),
                const SizedBox(height: 20),
                const Text('Application submitted', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Our team will review your application soon.', textAlign: TextAlign.center, style: TextStyle(color: MigoColors.textSecondaryLight)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Creator', style: TextStyle(color: Colors.white)),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [MigoColors.primary, MigoColors.primary.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Creator Program', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Share MIGO deals with your followers and earn coins. Free to join!', style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Display Name *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Your creator name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),

            const Text('Bio *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tell us about your content', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            const Text('Categories * (Select all that apply)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategories.contains(cat['id']);
                return FilterChip(
                  label: Text(cat['label']!),
                  selected: isSelected,
                  selectedColor: MigoColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: MigoColors.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(cat['id']!);
                      } else {
                        _selectedCategories.remove(cat['id']!);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text('Social Media Links', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),

            _buildSocialField(icon: Icons.camera_alt, label: 'Instagram URL', controller: _instagramController, hint: 'https://instagram.com/...'),
            const SizedBox(height: 12),
            _buildSocialField(icon: Icons.music_note, label: 'TikTok URL', controller: _tiktokController, hint: 'https://tiktok.com/@...'),
            const SizedBox(height: 12),
            _buildSocialField(icon: Icons.play_circle_outline, label: 'YouTube URL', controller: _youtubeController, hint: 'https://youtube.com/@...'),
            const SizedBox(height: 12),
            _buildSocialField(icon: Icons.facebook, label: 'Facebook URL', controller: _facebookController, hint: 'https://facebook.com/...'),

            const SizedBox(height: 24),

            const Text('Followers (approx)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _followersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '1000', border: OutlineInputBorder(), prefixIcon: Icon(Icons.people_outline)),
            ),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: MigoColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: MigoColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: MigoColors.error, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MigoColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }
}