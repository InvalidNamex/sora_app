import 'package:video_player/video_player.dart';

import 'media_cache_service.dart';

Future<VideoPlayerController> createCachedVideoController(Uri url) async {
  final file = await MediaCacheService.videos.getSingleFile(
    url.toString(),
    key: MediaCacheService.videoKey(url.toString()),
  );
  return VideoPlayerController.file(file);
}
