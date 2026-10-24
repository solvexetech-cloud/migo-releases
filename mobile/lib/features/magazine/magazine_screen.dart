import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/migo_colors.dart';

class MagazineScreen extends StatefulWidget {
  const MagazineScreen({super.key});

  @override
  State<MagazineScreen> createState() => _MagazineScreenState();
}

class _MagazineScreenState extends State<MagazineScreen> {
  String? _userCountry;
  List<String> _savedFlyers = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _userCountry = 'QA');
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted) {
        String rawCountry = userDoc.data()?['country'] as String? ?? 'QA';
        String finalCountry = 'QA';
        if (rawCountry.toLowerCase() == 'qatar') {
          finalCountry = 'QA';
        } else if (rawCountry.length > 2) {
          finalCountry = rawCountry.substring(0, 2).toUpperCase();
        } else {
          finalCountry = rawCountry.toUpperCase();
        }
        
        List<dynamic> saved = userDoc.data()?['savedFlyers'] ?? [];
        _savedFlyers = saved.map((e) => e.toString()).toList();

        setState(() {
          _userCountry = finalCountry;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _userCountry = 'QA');
      }
    }
  }

  Future<void> _toggleSaveFlyer(String flyerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final isSaved = _savedFlyers.contains(flyerId);
    if (isSaved) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'savedFlyers': FieldValue.arrayRemove([flyerId])
      });
      setState(() => _savedFlyers.remove(flyerId));
    } else {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'savedFlyers': FieldValue.arrayUnion([flyerId])
      });
      setState(() => _savedFlyers.add(flyerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userCountry == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MIGO Magazine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: MigoColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SavedFlyersScreen(),
                ),
              ).then((_) => _loadUserData());
            },
          ),
        ],
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

          final activeFlyers = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            String flyerCountry = (data['countryCode'] ?? data['country']) as String? ?? 'QA';
            if (flyerCountry.toLowerCase() == 'qatar') {
              flyerCountry = 'QA';
            } else if (flyerCountry.length > 2) {
              flyerCountry = flyerCountry.substring(0, 2).toUpperCase();
            } else {
              flyerCountry = flyerCountry.toUpperCase();
            }

            if (flyerCountry != _userCountry) return false;

            DateTime? endDate;
            final rawEndDate = data['endDate'];
            if (rawEndDate is Timestamp) {
              endDate = rawEndDate.toDate();
            } else if (rawEndDate is Map && rawEndDate.containsKey('seconds')) {
              endDate = DateTime.fromMillisecondsSinceEpoch((rawEndDate['seconds'] as int) * 1000);
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
                  Text('No magazines available', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // രണ്ട് കോളങ്ങൾ
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65, // ഉയരവും വീതിയും ക്രമീകരിക്കാൻ
            ),
            itemCount: activeFlyers.length,
            itemBuilder: (context, index) {
              final data = activeFlyers[index].data() as Map<String, dynamic>;
              final flyerId = activeFlyers[index].id;
              final title = data['title'] as String? ?? 'Flyer';
              final businessName = data['businessName'] as String? ?? '';
              final category = data['category'] as String? ?? '';
              final pdfUrl = data['pdfUrl'] as String? ?? '';
              final logoUrl = data['logoUrl'] as String? ?? '';
              final imageUrls = data['imageUrls'] as List?;
              
              String thumbnailUrl = data['thumbnailUrl'] as String? ?? '';
              if (thumbnailUrl.isEmpty && imageUrls != null && imageUrls.isNotEmpty) {
                thumbnailUrl = imageUrls.first.toString();
              }
              
              DateTime? endDate;
              final rawEndDate = data['endDate'];
              if (rawEndDate is Timestamp) {
                endDate = rawEndDate.toDate();
              } else if (rawEndDate is Map && rawEndDate.containsKey('seconds')) {
                endDate = DateTime.fromMillisecondsSinceEpoch((rawEndDate['seconds'] as int) * 1000);
              } else if (rawEndDate is String) {
                endDate = DateTime.tryParse(rawEndDate);
              }

              final isSaved = _savedFlyers.contains(flyerId);

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlyerReaderScreen(
                          flyerId: flyerId,
                          title: title,
                          businessName: businessName,
                          pdfUrl: pdfUrl,
                          imageUrls: imageUrls,
                          logoUrl: logoUrl,
                          isSaved: isSaved,
                          onSaveToggle: () => _toggleSaveFlyer(flyerId),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ഇമേജ് ഭാഗം
                      Expanded(
                        flex: 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported, size: 40, color: MigoColors.primary),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.menu_book, size: 40, color: MigoColors.primary),
                                    ),
                                  ),
                            // ബുക്ക്മാർക്ക് ഐക്കൺ
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                                    color: isSaved ? MigoColors.primary : Colors.black54,
                                  ),
                                  onPressed: () => _toggleSaveFlyer(flyerId),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ടെക്സ്റ്റ് ഭാഗം
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          businessName,
                                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: MigoColors.accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      category.toUpperCase(),
                                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: MigoColors.accentDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (endDate != null)
                                    Text(
                                      '${endDate.day}/${endDate.month}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class SavedFlyersScreen extends StatefulWidget {
  const SavedFlyersScreen({super.key});

  @override
  State<SavedFlyersScreen> createState() => _SavedFlyersScreenState();
}

class _SavedFlyersScreenState extends State<SavedFlyersScreen> {
  List<String> _savedIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedIds();
  }

  Future<void> _fetchSavedIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    List<dynamic> saved = userDoc.data()?['savedFlyers'] ?? [];
    if (mounted) {
      setState(() {
        _savedIds = saved.map((e) => e.toString()).toList();
        _loading = false;
      });
    }
  }

  Future<void> _removeSave(String flyerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'savedFlyers': FieldValue.arrayRemove([flyerId])
    });
    setState(() => _savedIds.remove(flyerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Flyers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: MigoColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _savedIds.isEmpty
              ? const Center(child: Text('No saved flyers yet.'))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('flyers')
                      .where(FieldPath.documentId, whereIn: _savedIds)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final flyerId = docs[index].id;
                        final title = data['title'] as String? ?? 'Flyer';
                        final businessName = data['businessName'] as String? ?? '';
                        final imageUrls = data['imageUrls'] as List?;
                        
                        String thumbnailUrl = data['thumbnailUrl'] as String? ?? '';
                        if (thumbnailUrl.isEmpty && imageUrls != null && imageUrls.isNotEmpty) {
                          thumbnailUrl = imageUrls.first.toString();
                        }

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FlyerReaderScreen(
                                    flyerId: flyerId,
                                    title: title,
                                    businessName: businessName,
                                    pdfUrl: data['pdfUrl'] as String? ?? '',
                                    imageUrls: imageUrls,
                                    logoUrl: data['logoUrl'] as String? ?? '',
                                    isSaved: true,
                                    onSaveToggle: () => _removeSave(flyerId),
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: thumbnailUrl.isNotEmpty
                                      ? Image.network(thumbnailUrl, fit: BoxFit.cover, width: double.infinity)
                                      : Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                businessName,
                                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              iconSize: 18,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.bookmark, color: MigoColors.primary),
                                              onPressed: () => _removeSave(flyerId),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
  final String title;
  final String businessName;
  final String pdfUrl;
  final List? imageUrls;
  final String logoUrl;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const FlyerReaderScreen({
    super.key,
    required this.flyerId,
    required this.title,
    required this.businessName,
    required this.pdfUrl,
    this.imageUrls,
    required this.logoUrl,
    required this.isSaved,
    required this.onSaveToggle,
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
  late bool _isSaved;

  String _orderLink = '';
  String _whatsappNumber = '';

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
    _markAsViewed();
    _fetchFlyerData(); 
    _totalPages = widget.imageUrls?.length ?? 1;
    
    if (_totalPages == 1) {
      _hasReachedLastPage = true;
    }
  }

  Future<void> _fetchFlyerData() async {
    final doc = await FirebaseFirestore.instance.collection('flyers').doc(widget.flyerId).get();
    if (mounted && doc.exists) {
      setState(() {
        _orderLink = doc.data()?['orderLink'] as String? ?? '';
        _whatsappNumber = doc.data()?['whatsappNumber'] as String? ?? '';
      });
    }
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

    setState(() => _markedAsRead = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have fully read this flyer! ✅')),
      );
    }
  }

  void _shareFlyer() {
    Share.share('Check out this flyer from ${widget.businessName} on MIGO app: ${widget.title}');
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.imageUrls != null && widget.imageUrls!.isNotEmpty;
    final isPdf = widget.pdfUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true, 
        title: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.businessName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              widget.onSaveToggle();
              setState(() => _isSaved = !_isSaved);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFlyer,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isImage)
            PageView.builder(
              itemCount: widget.imageUrls!.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index + 1;
                  if (_currentPage == _totalPages) {
                    _hasReachedLastPage = true;
                  }
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image.network(
                    widget.imageUrls![index].toString(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(child: Text('Image not available')),
                  ),
                );
              },
            )
          else if (isPdf)
            SfPdfViewer.network(
              widget.pdfUrl,
              controller: _pdfViewerController,
              onDocumentLoaded: (details) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() => _totalPages = _pdfViewerController.pageCount);
                  }
                });
              },
              onPageChanged: (details) {
                setState(() => _currentPage = details.newPageNumber);
                if (details.newPageNumber == _totalPages) {
                  setState(() => _hasReachedLastPage = true); 
                }
              },
            )
          else
            const Center(child: Text('No content available')),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          if (_hasReachedLastPage && !_markedAsRead)
            Positioned(
              bottom: 70,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _markAsFullyRead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MigoColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('✅ I have read this flyer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_markedAsRead)
            Positioned(
              bottom: 70,
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
                    Text('You have already read this flyer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          if (_orderLink.isNotEmpty || _whatsappNumber.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_whatsappNumber.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          String phone = _whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
                          _launchUrl("https://wa.me/$phone");
                        },
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  if (_orderLink.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          String url = _orderLink;
                          if (!url.startsWith('http')) {
                            url = 'https://$url';
                          }
                          _launchUrl(url);
                        },
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        label: const Text('Shop Online', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}