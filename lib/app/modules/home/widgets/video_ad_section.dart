import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/video_ad_model.dart';
import '../../../core/services/cached_video_controller.dart';
import '../../../routes/app_pages.dart';

class VideoAdSection extends StatefulWidget {
  const VideoAdSection({super.key, required this.ad, this.fullScreen = false});

  final VideoAdModel ad;
  final bool fullScreen;

  @override
  State<VideoAdSection> createState() => _VideoAdSectionState();
}

class _VideoAdSectionState extends State<VideoAdSection> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.ad.hasVideo) _loadVideo();
  }

  @override
  void didUpdateWidget(covariant VideoAdSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.videoUrl != widget.ad.videoUrl) {
      _disposeController();
      _hasError = false;
      if (widget.ad.hasVideo) _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    final generation = ++_loadGeneration;
    final url = Uri.tryParse(widget.ad.videoUrl);
    if (url == null || !url.hasAbsolutePath) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    VideoPlayerController? controller;
    try {
      controller = await createCachedVideoController(url);
      if (!mounted || generation != _loadGeneration) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      await controller?.dispose();
      if (mounted && generation == _loadGeneration) {
        _controller = null;
        setState(() => _hasError = true);
      }
    }
  }

  void _disposeController() {
    _loadGeneration++;
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
    if (_hasError && !widget.ad.hasBanner) return const SizedBox.shrink();

    final aspectRatio = widget.ad.isVertical ? 9 / 16 : 16 / 6;
    final video = _controller;
    final isReady = video?.value.isInitialized == true;

    if (widget.fullScreen) {
      final child = widget.ad.hasVideo && isReady
          ? FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: video!.value.size.width,
                height: video.value.size.height,
                child: VideoPlayer(video),
              ),
            )
          : widget.ad.hasBanner
          ? CachedNetworkImage(
              imageUrl: widget.ad.bannerUrl,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => Image.asset(
                AppConstants.placeholderPath,
                fit: BoxFit.contain,
              ),
            )
          : Image.asset(AppConstants.placeholderPath, fit: BoxFit.contain);
      return SizedBox.expand(child: _mediaFrame(context, null, child));
    }

    final videoWidget = widget.ad.hasVideo
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.ad.isVertical ? 380 : 1100,
                ),
                child: _mediaFrame(
                  context,
                  aspectRatio,
                  isReady
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: video!.value.size.width,
                            height: video.value.size.height,
                            child: VideoPlayer(video),
                          ),
                        )
                      : Image.asset(
                          AppConstants.placeholderPath,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
    final bannerWidget = widget.ad.hasBanner
        ? Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              widget.ad.hasVideo ? 0 : 12,
              16,
              8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: _mediaFrame(
                  context,
                  16 / 6,
                  CachedNetworkImage(
                    imageUrl: widget.ad.bannerUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Image.asset(
                      AppConstants.placeholderPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Column(children: [videoWidget, bannerWidget]);
  }

  Widget _mediaFrame(BuildContext context, double? aspectRatio, Widget child) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.itemPath(widget.ad.itemId),
        arguments: {'heroTag': 'video_ad_${widget.ad.itemId}'},
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: aspectRatio == null
            ? Stack(fit: StackFit.expand, children: [child, _mediaGradient()])
            : AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [child, _mediaGradient()],
                ),
              ),
      ),
    );
  }

  Widget _mediaGradient() => Positioned.fill(
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
  );
}
