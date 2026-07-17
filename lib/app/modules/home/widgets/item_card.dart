import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/item_property_model.dart';
import '../../../global_widgets/network_image_with_placeholder.dart';
import '../../wishlist/wishlist_controller.dart';
import '../home_controller.dart';
import '../../../routes/app_pages.dart';

/// A single item card for the staggered product grid.
/// When [entry] is null, renders a shimmer skeleton.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.entry});

  final ItemWithProperty? entry;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const _ShimmerCard();
    return _LiveCard(entry: entry!);
  }
}

// ── Live card ────────────────────────────────────────────────────────────────

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.entry});

  final ItemWithProperty entry;

  @override
  Widget build(BuildContext context) {
    final prop = entry.primaryProperty;
    final heroTag = 'hero_item_${entry.item.id}';
    final ctrl = HomeController.to;

    Widget cardBody = Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _CardBody(entry: entry, prop: prop, heroTag: heroTag),
        ),
        // Wishlist button overlay
        Obx(() {
          final isLiked = WishlistController.to.isLiked(entry.item.id);
          return PositionedDirectional(
            top: 10,
            end: 10,
            child: Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: isLiked ? Colors.brown : Colors.black87,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  WishlistController.to.toggleLike(entry.item.id);
                },
              ),
            ),
          );
        }),
        // Featured Badge
        if (entry.item.isFeatured)
          PositionedDirectional(
            top: 10,
            start: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.darkBeige,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.darkBeige.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                  const SizedBox(width: 3),
                  Text(
                    'featured'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (entry.isOutOfStock) {
      cardBody = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Banner(
          message: 'out_of_stock'.tr,
          location: BannerLocation.topEnd,
          color: Colors.red.shade700,
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
          child: Stack(
            children: [
              _CardBody(entry: entry, prop: prop, heroTag: heroTag),
              // Still show wishlist icon on out of stock items
              Obx(() {
                final isLiked = WishlistController.to.isLiked(entry.item.id);
                return PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isLiked ? Colors.redAccent : Colors.black87,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        WishlistController.to.toggleLike(entry.item.id);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    return Obx(() {
      final hovered = ctrl.hoveredItemId.value == entry.item.id;
      final pressed = ctrl.pressedItemId.value == entry.item.id;
      final scale = pressed
          ? 0.97
          : hovered
          ? 1.02
          : 1.0;

      return MouseRegion(
        onEnter: (_) {
          ctrl.setHoveredItem(entry.item.id);
          HapticFeedback.selectionClick();
        },
        onExit: (_) => ctrl.setHoveredItem(null),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            onTapDown: (_) {
              ctrl.pulseItemTap(entry.item.id);
              HapticFeedback.lightImpact();
            },
            onTap: () {
              HapticFeedback.mediumImpact();
              Get.toNamed(
                Routes.itemPath(entry.item.id),
                arguments: {'heroTag': heroTag},
              );
            },
            child: cardBody,
          ),
        ),
      );
    });
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.entry,
    required this.prop,
    required this.heroTag,
  });

  final ItemWithProperty entry;
  final ItemPropertyModel? prop;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Hero(
                tag: heroTag,
                child: prop != null && prop!.image.isNotEmpty
                    ? NetworkImageWithPlaceholder(
                        imageUrl: prop!.image,
                        fit: BoxFit.cover,
                      )
                    : _PlaceholderImage(),
              ),
            ),
          ),

          // ── Info ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (prop != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${AppConstants.currency} ${prop!.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppConstants.darkBeige,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.placeholderPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        color: AppConstants.lightBeige,
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: AppConstants.mediumBeige,
            size: 40,
          ),
        ),
      ),
    );
  }
}

// ── Shimmer card ─────────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(color: Colors.white),
            ),
            Container(
              height: 60,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 60, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
