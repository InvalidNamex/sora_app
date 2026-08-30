import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Bounded media caches whose keys include the server content revision.
///
/// A database catalog update changes [contentVersion], so a URL that was
/// overwritten in-place is downloaded again instead of showing stale bytes.
class MediaCacheService {
  MediaCacheService._();

  static final CacheManager images = CacheManager(
    Config(
      'sora_images_v1',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 350,
    ),
  );

  static final CacheManager videos = CacheManager(
    Config(
      'sora_videos_v1',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 12,
    ),
  );

  static int _contentVersion = 0;

  static int get contentVersion => _contentVersion;

  static void setContentVersion(int version) {
    if (version > 0) _contentVersion = version;
  }

  static String imageKey(String url) => 'image:v$_contentVersion:$url';

  static String videoKey(String url) => 'video:v$_contentVersion:$url';
}
