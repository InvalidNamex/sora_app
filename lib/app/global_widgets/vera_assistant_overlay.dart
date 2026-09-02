import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../core/models/vera_response_model.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/vera/vera_controller.dart';
import 'network_image_with_placeholder.dart';

class VeraAssistantOverlay extends StatefulWidget {
  const VeraAssistantOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<VeraAssistantOverlay> createState() => _VeraAssistantOverlayState();
}

class _VeraAssistantOverlayState extends State<VeraAssistantOverlay> {
  static const _bubbleSize = 62.0;
  Offset? _position;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final minY = media.padding.top + 10;
        final maxX = constraints.maxWidth - _bubbleSize - 10;
        final maxY =
            constraints.maxHeight - _bubbleSize - media.padding.bottom - 92;
        final fallback = Offset(maxX, maxY);
        final current = _clamp(_position ?? fallback, maxX, minY, maxY);

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            Obx(() {
              if (!AuthController.to.isLoggedIn) {
                return const SizedBox.shrink();
              }
              return AnimatedPositioned(
                duration: _dragging
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: current.dx,
                top: current.dy,
                width: _bubbleSize,
                height: _bubbleSize,
                child: Semantics(
                  button: true,
                  label: 'vera_open'.tr,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) => setState(() => _dragging = true),
                    onPanUpdate: (details) {
                      setState(() {
                        _position = _clamp(
                          current + details.delta,
                          maxX,
                          minY,
                          maxY,
                        );
                      });
                    },
                    onPanEnd: (_) {
                      final position = _position ?? current;
                      setState(() {
                        _dragging = false;
                        _position = Offset(
                          position.dx < maxX / 2 ? 10 : maxX,
                          position.dy,
                        );
                      });
                    },
                    onTap: _openVera,
                    child: const _GlassVeraButton(),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Offset _clamp(Offset value, double maxX, double minY, double maxY) {
    return Offset(
      value.dx.clamp(10.0, maxX < 10 ? 10 : maxX),
      value.dy.clamp(minY, maxY < minY ? minY : maxY),
    );
  }

  Future<void> _openVera() async {
    HapticFeedback.lightImpact();
    final controller = VeraController.to;
    controller.ensureWelcome();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 760),
              child: const _VeraSheet(),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassVeraButton extends StatelessWidget {
  const _GlassVeraButton();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (dark ? Colors.black : Colors.white).withValues(alpha: 0.28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.46)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: dark ? Colors.white : AppConstants.darkBeige,
            size: 27,
          ),
        ),
      ),
    );
  }
}

class _VeraSheet extends GetView<VeraController> {
  const _VeraSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final background = dark ? Colors.black : Colors.white;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background.withValues(alpha: dark ? 0.78 : 0.82),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            children: [
              _VeraHeader(onReset: controller.clearConversation),
              Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                    itemCount:
                        controller.messages.length +
                        (controller.isSending.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.messages.length) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(
                        message: controller.messages[index],
                      );
                    },
                  ),
                ),
              ),
              const _VeraComposer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _VeraHeader extends StatelessWidget {
  const _VeraHeader({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppConstants.darkBeige.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppConstants.darkBeige,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vera_name'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'vera_subtitle'.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'vera_new_chat'.tr,
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'close'.tr,
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final VeraChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    return Align(
      alignment: user
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.fromLTRB(
          14,
          11,
          14,
          message.recommendations.isEmpty ? 11 : 14,
        ),
        decoration: BoxDecoration(
          color: user
              ? AppConstants.darkBeige.withValues(alpha: 0.92)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(18),
            topEnd: const Radius.circular(18),
            bottomStart: Radius.circular(user ? 18 : 4),
            bottomEnd: Radius.circular(user ? 4 : 18),
          ),
          border: user
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.38)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: user
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            if (message.recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final recommendation in message.recommendations)
                _RecommendationCard(recommendation: recommendation),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends GetView<VeraController> {
  const _RecommendationCard({required this.recommendation});

  final VeraRecommendationModel recommendation;

  @override
  Widget build(BuildContext context) {
    final property = recommendation.property;
    final shared = [
      ...recommendation.sharedAccords,
      ...recommendation.sharedNotes,
    ].take(5).toList(growable: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.mediumBeige.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 82,
                  child: property != null && property.image.isNotEmpty
                      ? NetworkImageWithPlaceholder(
                          imageUrl: property.image,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          AppConstants.placeholderPath,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (recommendation.brand.isNotEmpty)
                      Text(
                        recommendation.brand,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: shared
                          .map(
                            (term) => Chip(
                              label: Text(term),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              labelStyle: const TextStyle(fontSize: 10),
                              padding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: recommendation.score / 100,
                      strokeWidth: 4,
                      color: AppConstants.darkBeige,
                      backgroundColor: AppConstants.lightBeige,
                    ),
                    Text(
                      '${recommendation.score}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!recommendation.inStock)
                Expanded(
                  child: Text(
                    'vera_restock_soon'.tr,
                    style: const TextStyle(
                      color: AppConstants.darkBeige,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (property != null)
                Expanded(
                  child: property.hasDiscount
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${AppConstants.currency} ${property.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${AppConstants.currency} ${property.salePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '${AppConstants.currency} ${property.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                )
              else
                const Spacer(),
              TextButton(
                onPressed: () => controller.openProduct(recommendation.itemId),
                child: Text('vera_view_product'.tr),
              ),
              if (recommendation.inStock && property != null)
                Obx(() {
                  final adding =
                      controller.addingItemId.value == recommendation.itemId;
                  return IconButton.filled(
                    tooltip: 'add_to_cart'.tr,
                    onPressed: adding
                        ? null
                        : () => controller.addToCart(recommendation),
                    icon: adding
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _VeraComposer extends GetView<VeraController> {
  const _VeraComposer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          8,
          12,
          MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller.inputController,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendCurrentMessage(),
                decoration: InputDecoration(
                  hintText: 'vera_input_hint'.tr,
                  counterText: '',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.66),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => IconButton.filled(
                onPressed: controller.isSending.value
                    ? null
                    : controller.sendCurrentMessage,
                style: IconButton.styleFrom(
                  backgroundColor: AppConstants.darkBeige,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.square(50),
                ),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
