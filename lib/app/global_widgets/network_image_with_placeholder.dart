import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

class NetworkImageWithPlaceholder extends StatelessWidget {
  NetworkImageWithPlaceholder({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.enablePreview = false,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;
  final bool enablePreview;
  final OverlayPortalController _hoverPreviewController = OverlayPortalController();
  final LayerLink _previewLayerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final Widget image = imageUrl.isEmpty
        ? _buildPlaceholderImage()
        : _buildNetworkImage(
            imageFit: fit,
            imageWidth: width,
            imageHeight: height,
            imageAlignment: alignment,
          );

    if (imageUrl.isEmpty || !enablePreview) {
      return image;
    }

    return OverlayPortal(
      controller: _hoverPreviewController,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildHoverPreview,
      child: CompositedTransformTarget(
        link: _previewLayerLink,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _hoverPreviewController.show(),
          onExit: (_) => _hoverPreviewController.hide(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _hoverPreviewController.hide();
              _showFullImageDialog(context);
            },
            child: image,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage({
    BoxFit? imageFit,
    double? imageWidth,
    double? imageHeight,
    AlignmentGeometry? imageAlignment,
  }) {
    return Image.asset(
      AppConstants.placeholderPath,
      width: imageWidth ?? width,
      height: imageHeight ?? height,
      fit: imageFit ?? fit,
      alignment: imageAlignment ?? alignment,
    );
  }

  Widget _buildNetworkImage({
    required BoxFit imageFit,
    double? imageWidth,
    double? imageHeight,
    AlignmentGeometry imageAlignment = Alignment.center,
  }) {
    return Image.network(
      imageUrl,
      width: imageWidth,
      height: imageHeight,
      fit: imageFit,
      alignment: imageAlignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            _buildPlaceholderImage(
              imageFit: imageFit,
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              imageAlignment: imageAlignment,
            ),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(
        imageFit: imageFit,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        imageAlignment: imageAlignment,
      ),
    );
  }

  Widget _buildHoverPreview(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double previewSize = math.min(math.min(screenSize.width * 0.35, screenSize.height * 0.35), 360);

    return IgnorePointer(
      child: CompositedTransformFollower(
        link: _previewLayerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.center,
        followerAnchor: Alignment.center,
        offset: Offset.zero,
        child: Material(
          color: Colors.transparent,
          elevation: 12,
          child: Container(
            width: previewSize,
            height: previewSize,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: _buildNetworkImage(
              imageFit: BoxFit.contain,
              imageWidth: previewSize,
              imageHeight: previewSize,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFullImageDialog(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double previewWidth = screenSize.width * 0.9;
    final double previewHeight = screenSize.height * 0.85;

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Container(
                width: previewWidth,
                height: previewHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: _buildNetworkImage(
                    imageFit: BoxFit.contain,
                    imageWidth: previewWidth,
                    imageHeight: previewHeight,
                  ),
                ),
              ),
              PositionedDirectional(
                top: 12,
                end: 12,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x66000000),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}