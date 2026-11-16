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
    {'id': 'food', 'label': 'Food & Restaurants', 'color': 'orange'},
    {'id': 'tech', 'label': 'Tech & Gadgets', 'color': 'blue'},
    {'id': 'lifestyle', 'label': 'Lifestyle', 'color': 'purple'},
    {'id': 'fashion', 'label': 'Fashion & Beauty', 'color': 'pink'},
    {'id': 'travel', 'label': 'Travel', 'color': 'teal'},
    {'id': 'fitness', 'label': 'Fitness & Sports', 'color': 'green'},
    {'id': 'family', 'label': 'Family', 'color': 'brown'},
    {'id': 'general', 'label': 'General', 'color': 'grey'},
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
        'category': _selectedCategories.first,
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
        const SnackBar(content: Text('✅ Application submitted!'), backgroundColor: MigoColors.success),
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
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Become a Creator', style: TextStyle(color: Colors.white)),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🆕 Premium Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [MigoColors.primary, Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.stars, color: Colors.amber, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text('Creator Program', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Share MIGO deals with your followers and earn coins.', style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4)),
                ],
              ),
            ),
            
            // Form Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio Section
                  _buildSectionTitle('Basic Info', Icons.person_outline, Colors.blue),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Display Name *',
                    icon: Icons.badge_outlined,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _bioController,
                    hint: 'Short Bio *',
                    icon: Icons.description_outlined,
                    color: Colors.blue,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Categories Section
                  _buildSectionTitle('Categories', Icons.category_outlined, Colors.purple),
                  const SizedBox(height: 12),
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

                  // Social Media Section
                  _buildSectionTitle('Social Media Links', Icons.link, Colors.pink),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _instagramController, hint: 'Instagram URL', icon: Icons.camera_alt, color: Colors.pink),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _tiktokController, hint: 'TikTok URL', icon: Icons.music_note, color: Colors.black),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _youtubeController, hint: 'YouTube URL', icon: Icons.play_circle_outline, color: Colors.red),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _facebookController, hint: 'Facebook URL', icon: Icons.facebook, color: Colors.blue),
                  const SizedBox(height: 24),

                  // Followers Section
                  _buildSectionTitle('Followers', Icons.people_outline, Colors.orange),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _followersController,
                    hint: 'Approx Followers',
                    icon: Icons.people,
                    color: Colors.orange,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 32),

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

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        shadowColor: MigoColors.primary.withValues(alpha: 0.5),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [MigoColors.primary, Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: color.withValues(alpha: 0.05),
      ),
    );
  }
}