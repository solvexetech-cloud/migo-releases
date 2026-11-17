import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/offer_model.dart';
import '../deals/offer_detail_screen.dart';
import 'link_helper.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final List<DocumentSnapshot> _docs = [];
  bool _isLoading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialReels();
  }

  Future<void> _loadInitialReels() async {
    // ഇൻഡക്സ് ഒഴിവാക്കാൻ വേണ്ടി ഞാൻ orderBy നീക്കം ചെയ്തിട്ടുണ്ട്. 
    // ഡാറ്റ കുറവായതിനാൽ ഇത് പ്രകടനത്തെ ബാധിക്കില്ല.
    final snapshot = await FirebaseFirestore.instance
        .collection('creator_content')
        .where('status', isEqualTo: 'approved')
        .limit(_limit)
        .get();

    setState(() {
      _docs.addAll(snapshot.docs);
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _isLoading = false;
      _hasMore = snapshot.docs.length == _limit;
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('creator_content')
        .where('status', isEqualTo: 'approved')
        .limit(_limit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();
    setState(() {
      _docs.addAll(snapshot.docs);
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
      _isLoading = false;
      _hasMore = snapshot.docs.length == _limit;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _docs.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_docs.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No active reels available.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _docs.length + (_hasMore ? 1 : 0),
        onPageChanged: (index) {
          if (index == _docs.length - 1) {
            _loadMore();
          }
        },
        itemBuilder: (context, index) {
          if (index == _docs.length) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final doc = _docs[index];
          final content = doc.data() as Map<String, dynamic>;
          final contentId = doc.id;
          return _FullScreenReel(
            content: content,
            contentId: contentId,
            isActive: true,
          );
        },
      ),
    );
  }
}

class _FullScreenReel extends StatefulWidget {
  final Map<String, dynamic> content;
  final String contentId;
  final bool isActive;

  const _FullScreenReel({
    required this.content,
    required this.contentId,
    required this.isActive,
  });

  @override
  State<_FullScreenReel> createState() => _FullScreenReelState();
}

class _FullScreenReelState extends State<_FullScreenReel> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _claiming = false;
  bool _muted = true;
  bool _liked = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
    _checkSaveStatus();
    _initWebView();
  }

  void _initWebView() {
    final url = (widget.content['url'] ?? '').toString().trim();
    final parsed = SocialLinkHelper.parse(url);

    if (kIsWeb || parsed['embedUrl'] == null) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(parsed['embedUrl']));
  }

  Future<void> _checkLikeStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('content_likes')
        .doc('${widget.contentId}_$uid')
        .get();
    if (mounted) setState(() => _liked = snap.exists);
  }

  Future<void> _checkSaveStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('saved_reels')
        .doc('${widget.contentId}_$uid')
        .get();
    if (mounted) setState(() => _saved = snap.exists);
  }

  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('content_likes')
        .doc('${widget.contentId}_$uid');

    try {
      if (_liked) {
        await docRef.delete();
      } else {
        await docRef.set({
          'userId': uid,
          'contentId': widget.contentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) setState(() => _liked = !_liked);
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('saved_reels')
        .doc('${widget.contentId}_$uid');

    if (_saved) {
      await docRef.delete();
    } else {
      await docRef.set({
        'userId': uid,
        'contentId': widget.contentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) setState(() => _saved = !_saved);
  }

  Future<void> _openExternal() async {
    final url = (widget.content['url'] ?? '').toString();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _claimOffer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _claiming = true);
    try {
      final offerId = widget.content['offerId'];
      if (offerId == null) throw Exception('No offer linked.');
      final offerSnap = await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .get();
      if (!offerSnap.exists) throw Exception('Offer not found.');

      final offer = OfferModel.fromMap(offerSnap.id, offerSnap.data()!);
      final creatorId = widget.content['creatorId'];
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfferDetailScreen(
            offer: offer,
            creatorId: creatorId, collabId: widget.content['collabId'], contentId: widget.contentId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.content['caption'] ?? 'Check out this deal!';
    final platform =
        (widget.content['platform'] ?? '').toString().toUpperCase();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.isActive && !_hasError && _webViewController != null)
          GestureDetector(
            onHorizontalDragUpdate: (_) {},
            child: WebViewWidget(controller: _webViewController!),
          )
        else if (_hasError)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white54, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Video not supported in-app.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openExternal,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open in App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MigoColors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_isLoading && widget.isActive)
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        Positioned(
          top: 50,
          right: 16,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                setState(() => _muted = !_muted);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              _ActionButton(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? Colors.red : Colors.white,
                label: '${widget.content['likesCount'] ?? 0}',
                onTap: _toggleLike,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                color: _saved ? MigoColors.accent : Colors.white,
                label: 'Save',
                onTap: _toggleSave,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.share,
                color: Colors.white,
                label: 'Share',
                onTap: () {
                  final shareUrl =
                      'https://migo-app-3030e.web.app/c/${widget.contentId}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share link: $shareUrl')),
                  );
                },
              ),
            ],
          ),
        ),

        Positioned(
          left: 16,
          right: 80,
          bottom: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (platform.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MigoColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    platform,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _claiming ? null : _claimOffer,
                  icon: _claiming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.local_offer, size: 18),
                  label: const Text('Claim Offer',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MigoColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}