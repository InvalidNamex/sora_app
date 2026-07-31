import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/video_ad_model.dart';
import '../../../routes/app_pages.dart';

class VideoAdSection extends StatefulWidget {
  const VideoAdSection({super.key, required this.ad});

  final VideoAdModel ad;

  @override
  State<VideoAdSection> createState() => _VideoAdSectionState();
}

class _VideoAdSectionState extends State<VideoAdSection> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant VideoAdSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.videoUrl != widget.ad.videoUrl) {
      _disposeController();
      _hasError = false;
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    final url = Uri.tryParse(widget.ad.videoUrl);
    if (url == null || !url.hasAbsolutePath) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(url);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox.shrink();

    final aspectRatio = widget.ad.isVertical ? 9 / 16 : 16 / 6;
    final video = _controller;
    final isReady = video?.value.isInitialized == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.ad.isVertical ? 380 : 1100,
          ),
          child: GestureDetector(
            onTap: () => Get.toNamed(
              Routes.itemPath(widget.ad.itemId),
              arguments: {'heroTag': 'video_ad_${widget.ad.itemId}'},
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isReady)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: video!.value.size.width,
                          height: video.value.size.height,
                          child: VideoPlayer(video),
                        ),
                      )
                    else
                      Image.asset(
                        AppConstants.placeholderPath,
                        fit: BoxFit.cover,
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.04),
                              Colors.black.withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
