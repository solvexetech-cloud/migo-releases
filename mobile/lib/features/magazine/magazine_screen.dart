import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/theme/migo_colors.dart';

class MagazineScreen extends StatelessWidget {
  const MagazineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIGO Magazine'),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('flyers')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          // എക്സ്പയർ ആയവ ഒഴിവാക്കുക
          final activeFlyers = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            DateTime? endDate;
            final rawEndDate = data['endDate'];
            if (rawEndDate is Timestamp) {
              endDate = rawEndDate.toDate();
            } else if (rawEndDate is Map && rawEndDate.containsKey('seconds')) {
              endDate = DateTime.fromMillisecondsSinceEpoch(
                (rawEndDate['seconds'] as int) * 1000,
              );
            } else if (rawEndDate is String) {
              endDate = DateTime.tryParse(rawEndDate);
            }
            if (endDate == null) return true;
            return endDate.isAfter(DateTime.now());
          }).toList();

          if (activeFlyers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No magazines available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeFlyers.length,
            itemBuilder: (context, index) {
              final data = activeFlyers[index].data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Flyer';
              final businessName = data['businessName'] as String? ?? '';
              final category = data['category'] as String? ?? '';
              final pdfUrl = data['pdfUrl'] as String? ?? '';
              final logoUrl = data['logoUrl'] as String? ?? '';
              DateTime? endDate;
              final rawEndDate = data['endDate'];
              if (rawEndDate is Timestamp) {
                endDate = rawEndDate.toDate();
              } else if (rawEndDate is Map && rawEndDate.containsKey('seconds')) {
                endDate = DateTime.fromMillisecondsSinceEpoch(
                  (rawEndDate['seconds'] as int) * 1000,
                );
              } else if (rawEndDate is String) {
                endDate = DateTime.tryParse(rawEndDate);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlyerReaderScreen(
                          flyerId: activeFlyers[index].id,
                          pdfUrl: pdfUrl,
                          logoUrl: logoUrl,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                                        ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 80,
                                height: 100,
                                color: Colors.grey.shade200,
                                child: thumbnailUrl.isNotEmpty
                                    ? Image.network(
                                        thumbnailUrl,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 100,
                                        errorBuilder: (_, _, _) => const Center(
                                          child: Icon(Icons.broken_image, size: 40, color: MigoColors.primary),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.picture_as_pdf, size: 40, color: MigoColors.primary),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (logoUrl.isNotEmpty)
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundImage: NetworkImage(logoUrl),
                                          backgroundColor: Colors.transparent,
                                        )
                                      else
                                        const Icon(Icons.storefront, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        businessName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: MigoColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: MigoColors.accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          category.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: MigoColors.accentDark,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (endDate != null)
                                        Text(
                                          'Valid till: ${endDate.day}/${endDate.month}/${endDate.year}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FlyerReaderScreen extends StatefulWidget {
  final String flyerId;
  final String pdfUrl;
  final String logoUrl;

  const FlyerReaderScreen({
    super.key,
    required this.flyerId,
    required this.pdfUrl,
    required this.logoUrl,
  });

  @override
  State<FlyerReaderScreen> createState() => _FlyerReaderScreenState();
}

class _FlyerReaderScreenState extends State<FlyerReaderScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _hasReachedLastPage = false;
  bool _markedAsRead = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _markAsViewed();
  }

  Future<void> _markAsViewed() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('flyers').doc(widget.flyerId).update({
      'viewedBy': FieldValue.arrayUnion([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _markAsFullyRead() async {
    if (_markedAsRead) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('flyers').doc(widget.flyerId).update({
      'fullyViewedBy': FieldValue.arrayUnion([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _markedAsRead = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have fully read this flyer! ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.logoUrl.isNotEmpty)
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(widget.logoUrl),
                backgroundColor: Colors.white,
              ),
            const SizedBox(width: 8),
            Text('Page $_currentPage / $_totalPages'),
          ],
        ),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            controller: _pdfViewerController,
                        onDocumentLoaded: (details) {
              // പേജ് എണ്ണം കണക്കാക്കാൻ അൽപ്പം കാത്തിരിക്കുക
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _totalPages = _pdfViewerController.pageCount;
                  });
                }
              });
            },
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
              if (details.newPageNumber == _totalPages) {
                setState(() {
                  _hasReachedLastPage = true;
                });
              }
            },
          ),
          // Previous Button (Overlay - semi-transparent)
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: _currentPage > 1
                  ? GestureDetector(
                      onTap: () => _pdfViewerController.previousPage(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Next Button (Overlay - semi-transparent)
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: _currentPage < _totalPages
                  ? GestureDetector(
                      onTap: () => _pdfViewerController.nextPage(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // "I have read this flyer" Button
          if (_hasReachedLastPage && !_markedAsRead)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _markAsFullyRead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MigoColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '✅ I have read this flyer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_markedAsRead)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MigoColors.success.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'You have already read this flyer',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}