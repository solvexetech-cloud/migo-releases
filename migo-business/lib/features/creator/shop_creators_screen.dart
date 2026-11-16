import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/migo_theme.dart';
import 'view_creator_profile_screen.dart';

class ShopCreatorsScreen extends StatefulWidget {
  final String businessId;
  const ShopCreatorsScreen({super.key, required this.businessId});

  @override
  State<ShopCreatorsScreen> createState() => _ShopCreatorsScreenState();
}

class _ShopCreatorsScreenState extends State<ShopCreatorsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _recordCollab(Map<String, dynamic> creator) async {
    final feeController = TextEditingController();
    final offerIdController = TextEditingController();
    final endDateController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Collab with ${creator['displayName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: offerIdController,
              decoration: const InputDecoration(labelText: 'Offer ID (from My Offers)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fee per Redemption (QAR)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endDateController,
              decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (feeController.text.isEmpty || offerIdController.text.isEmpty) return;
              final fee = double.tryParse(feeController.text) ?? 0;
              final endDate = DateTime.tryParse(endDateController.text) ?? DateTime.now().add(const Duration(days: 30));

              await FirebaseFirestore.instance.collection('collabs').add({
                'shopId': widget.businessId,
                'creatorId': creator['userId'],
                'offerId': offerIdController.text.trim(),
                'feePerRedemption': fee,
                'currency': 'QAR',
                'endsAt': Timestamp.fromDate(endDate),
                'status': 'invited',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('âœ… Collab invitation sent to creator!')),
              );
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Creators', style: TextStyle(color: Colors.white)),
        backgroundColor: MigoColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search creators by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _search = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('creators')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  return name.contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No creators found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index].data() as Map<String, dynamic>;
                    final name = c['displayName'] ?? 'Unknown';
                    final photoUrl = c['profileImageUrl'];
                    // 🆕 Handle both 'categories' (list) and 'category' (single string)
                    final categories = c['categories'] != null
                        ? List<String>.from(c['categories'])
                        : (c['category'] != null ? [c['category'] as String] : <String>[]);
                    final followers = c['followersCount'] ?? c['followers'] ?? 0;
                    final bio = c['bio'] ?? 'No bio';
                    final insta = c['instagramUrl'];
                    final tiktok = c['tiktokUrl'];
                    final youtube = c['youtubeUrl'];
                    final facebook = c['facebookUrl'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Row (Clickable)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewCreatorProfileScreen(creatorId: c['userId'] ?? ''),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: MigoColors.accent.withValues(alpha: 0.2),
                                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                  child: photoUrl == null
                                      ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MigoColors.primary))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Text('$followers Followers', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _recordCollab(c),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MigoColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Invite'),
                                ),
                              ],
                            ),
                            ),
                            const SizedBox(height: 12),
                            // Bio
                            Text(bio, style: const TextStyle(fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 12),
                            // Categories
                            if (categories.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: categories.map((cat) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MigoColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(cat.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: MigoColors.primary)),
                                )).toList(),
                              ),
                            const SizedBox(height: 12),
                            // Social Links
                            Row(
                              children: [
                                if (insta != null) _SocialIcon(icon: Icons.camera_alt, color: Colors.pink, onTap: () => _launch(insta)),
                                if (tiktok != null) _SocialIcon(icon: Icons.music_note, color: Colors.black, onTap: () => _launch(tiktok)),
                                if (youtube != null) _SocialIcon(icon: Icons.play_circle_fill, color: Colors.red, onTap: () => _launch(youtube)),
                                if (facebook != null) _SocialIcon(icon: Icons.facebook, color: Colors.blue, onTap: () => _launch(facebook)),
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
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SocialIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}