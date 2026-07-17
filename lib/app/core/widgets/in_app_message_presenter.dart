import 'dart:async';

import 'package:flutter/material.dart';

import '../models/in_app_message_model.dart';

typedef InAppMessageAction = Future<void> Function(String url);

class InAppMessagePresenter {
  InAppMessagePresenter._();

  static Future<void> show({
    required BuildContext context,
    required InAppMessageModel message,
    required InAppMessageAction onAction,
  }) {
    if (message.type == InAppMessageType.banner) {
      return _showBanner(context, message, onAction);
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) => _MessageDialog(
        message: message,
        onAction: (url) async {
          Navigator.of(dialogContext).pop();
          await onAction(url);
        },
      ),
    );
  }

  static Future<void> _showBanner(
    BuildContext context,
    InAppMessageModel message,
    InAppMessageAction onAction,
  ) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final completed = Completer<void>();
    late final OverlayEntry entry;
    Timer? timer;
    var removed = false;

    void close() {
      if (removed) return;
      removed = true;
      timer?.cancel();
      entry.remove();
      if (!completed.isCompleted) completed.complete();
    }

    entry = OverlayEntry(
      builder: (overlayContext) => _TopBanner(
        message: message,
        onClose: close,
        onAction: (url) async {
          close();
          await onAction(url);
        },
      ),
    );
    overlay.insert(entry);
    timer = Timer(const Duration(seconds: 10), close);
    return completed.future;
  }
}

class _MessageDialog extends StatelessWidget {
  const _MessageDialog({required this.message, required this.onAction});

  final InAppMessageModel message;
  final InAppMessageAction onAction;

  @override
  Widget build(BuildContext context) {
    if (message.type == InAppMessageType.image) {
      return _ImageOnlyDialog(message: message, onAction: onAction);
    }

    final isCard = message.type == InAppMessageType.card;
    final maxWidth = isCard ? 440.0 : 380.0;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: message.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message.imageUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: isCard ? 16 / 9 : 3 / 2,
                  child: _CampaignImage(url: message.imageUrl),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: isCard
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (message.title.isNotEmpty)
                      Text(
                        message.title,
                        textAlign: isCard ? TextAlign.start : TextAlign.center,
                        style: TextStyle(
                          color: message.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (message.title.isNotEmpty && message.body.isNotEmpty)
                      const SizedBox(height: 8),
                    if (message.body.isNotEmpty)
                      Text(
                        message.body,
                        textAlign: isCard ? TextAlign.start : TextAlign.center,
                        style: TextStyle(
                          color: message.textColor.withValues(alpha: 0.86),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    if (message.hasPrimaryAction ||
                        (isCard && message.hasSecondaryAction)) ...[
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isCard && message.hasSecondaryAction)
                            TextButton(
                              onPressed: () =>
                                  onAction(message.secondaryActionUrl),
                              style: TextButton.styleFrom(
                                foregroundColor: message.buttonColor,
                              ),
                              child: Text(
                                message.secondaryButtonText.isEmpty
                                    ? 'Learn more'
                                    : message.secondaryButtonText,
                              ),
                            ),
                          if (message.hasPrimaryAction)
                            FilledButton(
                              onPressed: () =>
                                  onAction(message.primaryActionUrl),
                              style: FilledButton.styleFrom(
                                backgroundColor: message.buttonColor,
                                foregroundColor: message.buttonTextColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                message.primaryButtonText.isEmpty
                                    ? 'Open'
                                    : message.primaryButtonText,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageOnlyDialog extends StatelessWidget {
  const _ImageOnlyDialog({required this.message, required this.onAction});

  final InAppMessageModel message;
  final InAppMessageAction onAction;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        child: Stack(
          children: [
            GestureDetector(
              onTap: message.primaryActionUrl.isEmpty
                  ? null
                  : () => onAction(message.primaryActionUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _CampaignImage(
                  url: message.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            PositionedDirectional(
              top: 8,
              end: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x99000000),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.message,
    required this.onClose,
    required this.onAction,
  });

  final InAppMessageModel message;
  final VoidCallback onClose;
  final InAppMessageAction onAction;

  @override
  Widget build(BuildContext context) {
    final canOpen = message.primaryActionUrl.isNotEmpty;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Material(
              color: message.backgroundColor,
              elevation: 10,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: canOpen
                    ? () => onAction(message.primaryActionUrl)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      if (message.imageUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: _CampaignImage(url: message.imageUrl),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.title.isNotEmpty)
                              Text(
                                message.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: message.textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            if (message.body.isNotEmpty)
                              Text(
                                message.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: message.textColor.withValues(
                                    alpha: 0.84,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        tooltip: 'Close',
                        color: message.textColor,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignImage extends StatelessWidget {
  const _CampaignImage({required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, _, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
      ),
    );
  }
}
