import 'dart:typed_data';
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

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _discountController = TextEditingController();
  final _orderLinkController = TextEditingController();
  final _whatsappController = TextEditingController();
  
  String _selectedCategory = 'Food & Dining';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  List<({String name, Uint8List bytes})> _selectedImages = [];

  final List<String> _categories = [
    'Food & Dining',
    'Supermarket',
    'Electronics',
    'Fashion',
    'Beauty & Wellness',
    'Services',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _discountController.dispose();
    _orderLinkController.dispose();
    _whatsappController.dispose();
    super.dispose();
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

  Future<void> _pickImages() async {
    try {
      // allowMultiple: true ഒഴിവാക്കി
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isEmpty) return;

      final List<({String name, Uint8List bytes})> selected = [];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        selected.add((name: file.name, bytes: bytes));
      }

      setState(() {
        _selectedImages = selected;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _uploadFlyer() async {
    if (_businessId == null) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final List<String> imageUrls = [];
      for (final image in _selectedImages) {
        final url = await CloudinaryService.instance.upload(
          bytes: image.bytes,
          filename: image.name,
          folder: 'migo/flyers',
        );
        if (url != null) imageUrls.add(url);
      }

      if (imageUrls.isEmpty) throw Exception('No images uploaded');

      final bizSnap = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(_businessId)
          .get();
      final logoUrl = bizSnap.data()?['logoUrl'] as String? ?? '';
      final countryCode = bizSnap.data()?['countryCode'] as String? ?? 'QA';

      await FirebaseFirestore.instance.collection('flyers').add({
        'businessId': _businessId,
        'businessName': _businessName,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'discountTag': _discountController.text.trim(),
        'orderLink': _orderLinkController.text.trim(),
        'whatsappNumber': _whatsappController.text.trim(),
        'category': _selectedCategory,
        'pdfUrl': '',
        'imageUrls': imageUrls,
        'logoUrl': logoUrl,
        'thumbnailUrl': imageUrls.first,
        'countryCode': countryCode,
        'status': 'pending',
        'totalPages': imageUrls.length,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'viewedBy': [],
        'fullyViewedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Successful ✅'),
            content: const Text(
              'Your flyer has been submitted for approval.\n\n'
              'It will be visible to customers once approved by admin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          _selectedImages = [];
          _titleController.clear();
          _descController.clear();
          _discountController.clear();
          _orderLinkController.clear();
          _whatsappController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? now : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      } else {
        _endDate = picked;
      }
    });
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Upload Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Flyer Title (e.g., Month End Deals)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Short Description (Optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount / Offer Tag (e.g., 50% OFF)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _orderLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Online Order Link (Optional)',
                      hintText: 'https://yourwebsite.com',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _whatsappController,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Number (Optional)',
                      hintText: '+974 XXXX XXXX',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(isStart: true),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            'Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(isStart: false),
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(
                            'End: ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(
                      _selectedImages.isEmpty
                          ? 'Select Images (JPEG/PNG)'
                          : '${_selectedImages.length} images selected',
                    ),
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, i) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _selectedImages[i].bytes,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _uploadFlyer,
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
                      label: Text(
                        _uploading ? 'Uploading...' : 'Upload Flyer',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Flyers List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('flyers')
                  .where('businessId', isEqualTo: _businessId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No flyers uploaded yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'pending';
                    final Color statusColor = status == 'approved'
                        ? MigoColors.success
                        : status == 'pending'
                            ? MigoColors.warning
                            : MigoColors.error;
                    DateTime? endDate;
final rawEndDate = data['endDate'];
if (rawEndDate is Timestamp) {
  endDate = rawEndDate.toDate();
} else if (rawEndDate is Map && rawEndDate.containsKey('seconds')) {
  endDate = DateTime.fromMillisecondsSinceEpoch((rawEndDate['seconds'] as int) * 1000);
} else if (rawEndDate is String) {
  endDate = DateTime.tryParse(rawEndDate);
}
                    final viewed = (data['viewedBy'] as List?) ?? [];
                    final fullyRead = (data['fullyViewedBy'] as List?) ?? [];
                    final thumbnailUrl = data['thumbnailUrl'] as String? ?? '';
                    final discountTag = data['discountTag'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 60,
                                    height: 75,
                                    color: Colors.grey.shade200,
                                    child: thumbnailUrl.isNotEmpty
                                        ? Image.network(thumbnailUrl, fit: BoxFit.cover)
                                        : const Icon(Icons.image, color: MigoColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Flyer',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (discountTag.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          discountTag,
                                          style: const TextStyle(color: MigoColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (endDate != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              'Exp: ${endDate.day}/${endDate.month}/${endDate.year}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: MigoColors.error),
                                  onPressed: () => _deleteFlyer(docs[index].id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  icon: Icons.visibility,
                                  iconColor: Colors.blue,
                                  value: viewed.length.toString(),
                                  label: 'Total Views',
                                ),
                                Container(width: 1, height: 30, color: Colors.grey.shade300),
                                _buildStatItem(
                                  icon: Icons.menu_book,
                                  iconColor: Colors.green,
                                  value: fullyRead.length.toString(),
                                  label: 'Fully Read',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}