import 'package:video_player/video_player.dart';

Future<VideoPlayerController> createCachedVideoController(Uri url) async =>
    VideoPlayerController.networkUrl(url);
