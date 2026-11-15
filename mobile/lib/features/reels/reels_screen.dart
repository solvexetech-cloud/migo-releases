import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/offer_model.dart';
import '../deals/offer_detail_screen.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('creator_content').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final allDocs = snapshot.data?.docs ?? [];
          
          // Filter approved content
          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'approved';
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No reels available yet.', style: TextStyle(color: Colors.white)));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final content = docs[index].data() as Map<String, dynamic>;
              final contentId = docs[index].id;
              return _FullScreenReel(content: content, contentId: contentId);
            },
          );
        },
      ),
    );
  }
}

class _FullScreenReel extends StatefulWidget {
  final Map<String, dynamic> content;
  final String contentId;
  const _FullScreenReel({required this.content, required this.contentId});

  @override
  State<_FullScreenReel> createState() => _FullScreenReelState();
}

class _FullScreenReelState extends State<_FullScreenReel> {
  bool _claiming = false;
  bool _liked = false;

  Future<void> _claimOffer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _claiming = true);
    try {
      final offerId = widget.content['offerId'];
      final offerSnap = await FirebaseFirestore.instance.collection('offers').doc(offerId).get();
      
      if (!offerSnap.exists) throw Exception('Offer not found.');
      
      final offer = OfferModel.fromMap(offerSnap.id, offerSnap.data()!);
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OfferDetailScreen(offer: offer)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.content['url'] ?? '';
    final caption = widget.content['caption'] ?? 'Check out this deal!';
    final platform = (widget.content['platform'] ?? '').toUpperCase();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Background (Placeholder for Video)
        Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_circle_fill, size: 80, color: Colors.white24),
          ),
        ),

        // 2. Gradient Overlay for better text visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),

        // 3. Right Side Action Buttons
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              _ActionButton(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? Colors.red : Colors.white,
                label: '${widget.content['likesCount'] ?? 0}',
                onTap: () => setState(() => _liked = !_liked),
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.share,
                color: Colors.white,
                label: 'Share',
                onTap: () {
                  final shareUrl = 'https://migo-app-3030e.web.app/c/${widget.contentId}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share link copied: $shareUrl')),
                  );
                },
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.link,
                color: Colors.white,
                label: 'Watch',
                onTap: () async {
                  final uri = Uri.parse(url);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    debugPrint('Could not launch $url');
                  }
                },
              ),
            ],
          ),
        ),

        // 4. Bottom Info & Claim Button
        Positioned(
          left: 16,
          right: 80,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MigoColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  platform,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                caption,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.local_offer, size: 18),
                  label: const Text('Claim Offer', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MigoColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}