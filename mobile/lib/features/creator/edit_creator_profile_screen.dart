import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/migo_colors.dart';
import '../../services/cloudinary_service.dart';

class EditCreatorProfileScreen extends StatefulWidget {
  final String creatorId;
  const EditCreatorProfileScreen({super.key, required this.creatorId});

  @override
  State<EditCreatorProfileScreen> createState() => _EditCreatorProfileScreenState();
}

class _EditCreatorProfileScreenState extends State<EditCreatorProfileScreen> {
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _facebookController = TextEditingController();
  
  String? _currentImageUrl;
  File? _newImageFile;
  Uint8List? _newImageBytes;
  bool _loading = false;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final snap = await FirebaseFirestore.instance.collection('creators').doc(widget.creatorId).get();
    if (snap.exists) {
      final data = snap.data()!;
      setState(() {
        _bioController.text = data['bio'] ?? '';
        _instagramController.text = data['instagramUrl'] ?? '';
        _tiktokController.text = data['tiktokUrl'] ?? '';
        _youtubeController.text = data['youtubeUrl'] ?? '';
        _facebookController.text = data['facebookUrl'] ?? '';
        _currentImageUrl = data['profileImageUrl'];
      });
    }
    setState(() => _fetching = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _newImageBytes = bytes);
      } else {
        setState(() => _newImageFile = File(picked.path));
      }
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      String? imageUrl = _currentImageUrl;

      if (kIsWeb && _newImageBytes != null) {
        imageUrl = await CloudinaryService.instance.uploadBytes(
          bytes: _newImageBytes!,
          filename: 'creator_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else if (_newImageFile != null) {
        imageUrl = await CloudinaryService.instance.uploadFile(_newImageFile!);
      }

      await FirebaseFirestore.instance.collection('creators').doc(widget.creatorId).update({
        'bio': _bioController.text.trim(),
        'instagramUrl': _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
        'tiktokUrl': _tiktokController.text.trim().isEmpty ? null : _tiktokController.text.trim(),
        'youtubeUrl': _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
        'facebookUrl': _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        'profileImageUrl': imageUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ã¢Å“â€¦ Profile updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ã°Å¸â€ â€¢ Premium Profile Photo
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [MigoColors.primary, MigoColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: MigoColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: kIsWeb 
                            ? (_newImageBytes != null 
                                ? MemoryImage(_newImageBytes!) as ImageProvider
                                : (_currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null))
                            : (_newImageFile != null 
                                ? FileImage(_newImageFile!) as ImageProvider
                                : (_currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null)),
                        child: (_newImageBytes == null && _newImageFile == null && _currentImageUrl == null) 
                            ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) 
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MigoColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Tap to change photo', style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 32),
            
            // Ã°Å¸â€ â€¢ Bio Section
            _buildSectionTitle('Bio', Icons.person_outline, Colors.blue),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tell us about yourself...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.blue.shade50.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),

            // Ã°Å¸â€ â€¢ Social Media Section
            _buildSectionTitle('Social Media Links', Icons.link, Colors.purple),
            const SizedBox(height: 12),

            _buildSocialField(
              icon: FontAwesomeIcons.instagram,
              label: 'Instagram',
              controller: _instagramController,
              color: Colors.pink,
            ),
            const SizedBox(height: 12),
            _buildSocialField(
              icon: FontAwesomeIcons.tiktok,
              label: 'TikTok',
              controller: _tiktokController,
              color: Colors.black,
            ),
            const SizedBox(height: 12),
            _buildSocialField(
              icon: FontAwesomeIcons.youtube,
              label: 'YouTube',
              controller: _youtubeController,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildSocialField(
              icon: FontAwesomeIcons.facebook,
              label: 'Facebook',
              controller: _facebookController,
              color: Colors.blue,
            ),

            const SizedBox(height: 32),
            
            // Ã°Å¸â€ â€¢ Premium Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  shadowColor: MigoColors.primary.withValues(alpha: 0.5),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MigoColors.primary, MigoColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _loading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _buildSocialField({
    required FaIconData icon,
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'https://...',
        prefixIcon: FaIcon(icon, color: color),
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