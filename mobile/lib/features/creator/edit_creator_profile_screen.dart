import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  Uint8List? _newImageBytes; // ðŸ†• For web
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('âœ… Profile updated!')));
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
      appBar: AppBar(title: const Text('Edit Profile', style: TextStyle(color: Colors.white)), backgroundColor: MigoColors.primary, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: kIsWeb 
                    ? (_newImageBytes != null 
                        ? MemoryImage(_newImageBytes!) as ImageProvider
                        : (_currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null))
                    : (_newImageFile != null 
                        ? FileImage(_newImageFile!) as ImageProvider
                        : (_currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null)),
                child: (_newImageBytes == null && _newImageFile == null && _currentImageUrl == null) 
                    ? const Icon(Icons.camera_alt, size: 30) 
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Tap to change photo', style: TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 24),
          
          TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _instagramController, decoration: const InputDecoration(labelText: 'Instagram URL', prefixIcon: Icon(Icons.camera_alt), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _tiktokController, decoration: const InputDecoration(labelText: 'TikTok URL', prefixIcon: Icon(Icons.music_note), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _youtubeController, decoration: const InputDecoration(labelText: 'YouTube URL', prefixIcon: Icon(Icons.play_circle), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _facebookController, decoration: const InputDecoration(labelText: 'Facebook URL', prefixIcon: Icon(Icons.facebook), border: OutlineInputBorder())),
          
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: MigoColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}