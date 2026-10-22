import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/migo_theme.dart';
import '../../services/cloudinary_service.dart';

class MyFlyersScreen extends StatefulWidget {
  const MyFlyersScreen({super.key});

  @override
  State<MyFlyersScreen> createState() => _MyFlyersScreenState();
}

class _MyFlyersScreenState extends State<MyFlyersScreen> {
  String? _businessId;
  String? _businessName;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      _businessId = snap.docs.first.id;
      _businessName = snap.docs.first.data()['name'] as String?;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAndUploadFlyer() async {
    if (_businessId == null) return;

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

            if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();

      setState(() => _uploading = true);

      final url = await CloudinaryService.instance.upload(
        bytes: bytes,
        filename: file.name,
        folder: 'migo/flyers',
      );

      if (url == null) throw Exception('Upload failed');

      await FirebaseFirestore.instance.collection('flyers').add({
        'businessId': _businessId,
        'businessName': _businessName,
        'title': file.name.replaceAll('.pdf', ''),
        'pdfUrl': url,
        'status': 'pending',
        'totalPages': 0,
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'viewedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flyer uploaded! Waiting for approval.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteFlyer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Flyer?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: MigoColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('flyers').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flyer deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Flyers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _pickAndUploadFlyer,
                icon: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_uploading ? 'Uploading...' : 'Upload New Flyer (PDF)'),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('flyers')
                  .where('businessId', isEqualTo: _businessId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No flyers uploaded yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'pending';
                    final Color statusColor = status == 'approved'
                        ? MigoColors.success
                        : status == 'pending'
                            ? MigoColors.warning
                            : MigoColors.error;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: MigoColors.primary),
                        title: Text(data['title'] ?? 'Flyer'),
                        subtitle: Text(
                          'Status: ${status.toUpperCase()}',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: MigoColors.error),
                          onPressed: () => _deleteFlyer(docs[index].id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}