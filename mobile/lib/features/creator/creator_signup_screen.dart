import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/migo_colors.dart';
import '../../services/creator_service.dart';

/// PHASE E — E6: Creator/Vlogger Application
class CreatorSignupScreen extends StatefulWidget {
  const CreatorSignupScreen({super.key});

  @override
  State<CreatorSignupScreen> createState() => _CreatorSignupScreenState();
}

class _CreatorSignupScreenState extends State<CreatorSignupScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _channelController = TextEditingController();
  final _followersController = TextEditingController();

  String _category = 'food';
  bool _loading = false;
  bool _checking = true;
  bool _alreadyApplied = false;
  String? _error;

  static const List<Map<String, String>> _categories = [
    {'id': 'food', 'label': '🍕 Food & Restaurants'},
    {'id': 'tech', 'label': '💻 Tech & Gadgets'},
    {'id': 'lifestyle', 'label': '✨ Lifestyle'},
    {'id': 'fashion', 'label': '👗 Fashion & Beauty'},
    {'id': 'travel', 'label': '✈️ Travel'},
    {'id': 'fitness', 'label': '💪 Fitness & Sports'},
    {'id': 'family', 'label': '👨‍👩‍👧 Family'},
    {'id': 'general', 'label': '🎬 General'},
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
    _channelController.dispose();
    _followersController.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _checking = false);
      return;
    }
    final exists = await CreatorService.instance.isCreator(uid);
    if (!mounted) return;
    setState(() {
      _alreadyApplied = exists;
      _checking = false;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;

    if (uid == null || email == null) {
      setState(() => _error = 'Please sign in first.');
      return;
    }

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final channel = _channelController.text.trim();
    final followersText = _followersController.text.trim();

    if (name.isEmpty || bio.isEmpty || channel.isEmpty) {
      setState(() => _error = 'Please fill name, bio and channel URL.');
      return;
    }

    final followers = int.tryParse(followersText) ?? 0;

    setState(() => _loading = true);
    try {
      await CreatorService.instance.applyAsCreator(
        uid: uid,
        displayName: name,
        email: email,
        bio: bio,
        channelUrl: channel,
        category: _category,
        followers: followers,
      );

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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_alreadyApplied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Creator Status')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 72,
                  color: MigoColors.success,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Application submitted',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our team will review your application soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MigoColors.textSecondaryLight),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Creator'),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MigoColors.primary,
                    MigoColors.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎬 Creator Program',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Share MIGO deals with your followers and earn coins. '
                    'Free to join!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            const Text('Display Name *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Your creator name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Bio
            const Text('Bio *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tell us about your content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Channel URL
            const Text('Channel URL *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _channelController,
              decoration: const InputDecoration(
                hintText: 'https://youtube.com/@yourchannel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),

            // Followers
            const Text('Followers (approx)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _followersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '1000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            const Text('Category *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem<String>(
                        value: c['id'],
                        child: Text(c['label']!),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 24),

            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MigoColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: MigoColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: MigoColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MigoColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Submit Application',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}