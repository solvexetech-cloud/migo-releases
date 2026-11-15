import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/migo_colors.dart';

class AddContentScreen extends StatefulWidget {
  final String collabId;
  final String shopId;
  final String offerId;
  final String creatorId;
  const AddContentScreen({
    super.key,
    required this.collabId,
    required this.shopId,
    required this.offerId,
    required this.creatorId,
  });

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> {
  final _urlController = TextEditingController();
  final _captionController = TextEditingController();
  bool _loading = false;
  bool _disclosureConfirmed = false;
  String _platform = 'instagram';

  Future<void> _submit() async {
    if (_urlController.text.trim().isEmpty) return;
    if (!_disclosureConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm the disclosure checkbox.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('creator_content').add({
        'collabId': widget.collabId,
        'creatorId': widget.creatorId,
        'shopId': widget.shopId,
        'offerId': widget.offerId,
        'platform': _platform,
        'url': _urlController.text.trim(),
        'caption': _captionController.text.trim(),
        'disclosureConfirmed': true,
        'status': 'submitted',
        'viewsCount': 0,
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Content submitted for approval!')),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Video Link'),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _platform,
            decoration: const InputDecoration(labelText: 'Platform', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
              DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
              DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
            ],
            onChanged: (val) => setState(() => _platform = val!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Video URL *',
              hintText: 'https://instagram.com/p/...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Caption (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('This post clearly says it is a paid partnership or advertisement (#ad)'),
            value: _disclosureConfirmed,
            onChanged: (val) => setState(() => _disclosureConfirmed = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: MigoColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit for Approval'),
          ),
        ],
      ),
    );
  }
}