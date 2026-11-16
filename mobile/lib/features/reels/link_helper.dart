class SocialLinkHelper {
  static Map<String, dynamic> parse(String url) {
    if (url.isEmpty) {
      return {'platform': 'unknown', 'id': null, 'embedUrl': null, 'thumbnail': null};
    }
    final lower = url.toLowerCase();

    // YouTube (Shorts, youtu.be, watch?v=)
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      String? id;
      if (lower.contains('youtu.be/')) {
        id = url.split('youtu.be/')[1].split('?')[0].split('&')[0];
      } else if (lower.contains('/shorts/')) {
        id = url.split('/shorts/')[1].split('?')[0].split('&')[0];
      } else if (lower.contains('watch?v=')) {
        id = url.split('watch?v=')[1].split('&')[0];
      } else if (lower.contains('/embed/')) {
        id = url.split('/embed/')[1].split('?')[0].split('&')[0];
      }
      if (id != null) {
        return {
          'platform': 'youtube',
          'id': id,
          'embedUrl': 'https://www.youtube.com/embed/$id?autoplay=1&playsinline=1&mute=1',
          'thumbnail': 'https://img.youtube.com/vi/$id/hqdefault.jpg',
        };
      }
    }

    // TikTok
    if (lower.contains('tiktok.com')) {
      String? id;
      final parts = url.split('/');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i] == 'video' && i + 1 < parts.length) {
          id = parts[i + 1].split('?')[0];
          break;
        }
      }
      if (id != null) {
        return {
          'platform': 'tiktok',
          'id': id,
          'embedUrl': 'https://www.tiktok.com/embed/v2/$id?autoplay=1&mute=1',
          'thumbnail': null,
        };
      }
    }

    // Instagram (embed path)
    if (lower.contains('instagram.com')) {
      String? id;
      if (lower.contains('/reel/')) {
        id = url.split('/reel/')[1].split('/')[0].split('?')[0];
      } else if (lower.contains('/p/')) {
        id = url.split('/p/')[1].split('/')[0].split('?')[0];
      }
      if (id != null) {
        final cleanUrl = url.split('?')[0];
        return {
          'platform': 'instagram',
          'id': id,
          'embedUrl': '$cleanUrl/embed?autoplay=1&mute=1',
          'thumbnail': null,
        };
      }
    }

    // Fallback: no embed URL
    return {
      'platform': 'unknown',
      'id': null,
      'embedUrl': null,
      'thumbnail': null,
    };
  }
}