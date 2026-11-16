import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/migo_colors.dart';

class CreatorProfileScreen extends StatelessWidget {
  final String creatorId;
  const CreatorProfileScreen({super.key, required this.creatorId});

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('creators')
            .where('userId', isEqualTo: creatorId)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Creator not found.'));
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final imageUrl = data['profileImageUrl'];
          final name = data['displayName'] ?? 'Creator';
          final bio = data['bio'] ?? 'No bio';
          final followers = data['followersCount'] ?? data['followers'] ?? 0;
          final insta = data['instagramUrl'];
          final tiktok = data['tiktokUrl'];
          final youtube = data['youtubeUrl'];
          final facebook = data['facebookUrl'];

          final categories = data['categories'] != null
              ? List<String>.from(data['categories'])
              : (data['category'] != null ? [data['category'] as String] : <String>[]);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: MigoColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [MigoColors.primary, MigoColors.primary.withValues(alpha: 0.6)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                          child: imageUrl == null || imageUrl.isEmpty
                              ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: MigoColors.primary))
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('$followers Followers', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Text(bio, style: const TextStyle(fontSize: 14, height: 1.5)),
                      ),
                      const SizedBox(height: 24),
                      if (categories.isNotEmpty) ...[
                        Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((c) => Chip(label: Text(c.toUpperCase()), backgroundColor: MigoColors.primary.withValues(alpha: 0.1), labelStyle: const TextStyle(color: MigoColors.primary, fontSize: 12, fontWeight: FontWeight.bold))).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text('Social Media', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (insta != null) _SocialButton(icon: FontAwesomeIcons.instagram, color: Colors.pink, label: 'Instagram', onTap: () => _launchUrl(insta)),
                          if (tiktok != null) _SocialButton(icon: FontAwesomeIcons.tiktok, color: Colors.black, label: 'TikTok', onTap: () => _launchUrl(tiktok)),
                          if (youtube != null) _SocialButton(icon: FontAwesomeIcons.youtube, color: Colors.red, label: 'YouTube', onTap: () => _launchUrl(youtube)),
                          if (facebook != null) _SocialButton(icon: FontAwesomeIcons.facebook, color: Colors.blue, label: 'Facebook', onTap: () => _launchUrl(facebook)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: FaIcon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}