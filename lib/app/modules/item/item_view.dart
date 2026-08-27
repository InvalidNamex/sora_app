import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/item_model.dart';
import '../../core/utils/responsive.dart';
import '../../global_widgets/network_image_with_placeholder.dart';
import '../../routes/app_pages.dart';
import '../cart/cart_controller.dart';
import '../navigation/nav_controller.dart';
import '../wishlist/wishlist_controller.dart';
import 'item_controller.dart';

/// Item detail screen.
/// Mobile/Tablet: vertical layout (image top, info below).
/// Desktop:       horizontal split (image left, info right).
class ItemView extends GetView<ItemController> {
  const ItemView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withAlpha(150),

            child: const BackButtonIcon(),
          ),
          onPressed: () => _handleBack(context),
        ),
        actions: [
          Obx(() {
            final item = controller.item.value;
            final canLike = !controller.isLoading.value && item != null;
            final isLiked =
                item != null && WishlistController.to.isLiked(item.id);
            return IconButton(
              tooltip: 'wishlist'.tr,
              icon: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withAlpha(150),
                radius: 20,
                child: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked ? AppConstants.darkBeige : null,
                ),
              ),
              onPressed: canLike
                  ? () {
                      HapticFeedback.lightImpact();
                      WishlistController.to.toggleLike(item.id);
                    }
                  : null,
            );
          }),
          Obx(() {
            final canShare =
                !controller.isLoading.value && controller.item.value != null;
            return Builder(
              builder: (shareContext) => IconButton(
                tooltip: 'share'.tr,
                icon: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withAlpha(150),
                  radius: 20,
                  child: const Icon(Icons.share_outlined),
                ),
                onPressed: canShare
                    ? () => controller.shareItem(shareContext)
                    : null,
              ),
            );
          }),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Obx(() {
        if (controller.isLoading.value ||
            controller.hasError.value ||
            controller.item.value == null) {
          return const SizedBox.shrink();
        }

        // Hide bottom sheet style add to cart on desktop since it will exist in the right column
        if (Responsive.isDesktop(context)) {
          return const SizedBox.shrink();
        }

        final pulse = controller.cartFabPulse.value;
        final prop = controller.selectedProperty;
        final item = controller.item.value;
        final count = CartController.to.totalItems;
        final inStock = prop?.inStock ?? false;

        return ResponsiveLayout(
          mobile: _AddToCartBottomBar(
            pulse: pulse,
            inStock: inStock,
            prop: prop,
            item: item,
            count: count,
            isInCart: controller.selectedPropertyInCart,
            quantity: controller.selectedPropertyQuantity,
            isAdding: controller.addingToCart.value,
            controller: controller,
          ),
          desktop: const SizedBox.shrink(),
        );
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }

        if (controller.hasError.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_outlined,
                  size: 56,
                  color: AppConstants.mediumBeige,
                ),
                const SizedBox(height: 12),
                Text('error_loading'.tr),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.retry,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        final item = controller.item.value;
        if (item == null) {
          return Center(child: Text('item_not_found'.tr));
        }

        return ResponsiveLayout(
          mobile: _MobileLayout(controller: controller),
          desktop: _DesktopLayout(controller: controller),
        );
      }),
    );
  }

  void _handleBack(BuildContext context) {
    if (Get.isRegistered<NavController>()) {
      NavController.to.setIndex(0);
    }

    final previousRoute = Get.previousRoute;
    final canPop = Navigator.of(context).canPop();
    if (canPop && previousRoute.isNotEmpty && previousRoute != Routes.splash) {
      Get.back<void>();
      return;
    }

    Get.offAllNamed(Routes.home);
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.controller});
  final ItemController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppConstants.darkBeige,
      onRefresh: controller.refreshItem,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(controller: controller),
            _ItemDetails(controller: controller),
          ],
        ),
      ),
    );
  }
}

// ── Desktop layout ────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.controller});
  final ItemController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: image (40% width)
            Expanded(
              flex: 4,
              child: _HeroImage(controller: controller, roundAllCorners: true),
            ),
            const SizedBox(width: 40),
            // Right: details (60% width)
            Expanded(
              flex: 6,
              child: RefreshIndicator(
                color: AppConstants.darkBeige,
                onRefresh: controller.refreshItem,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 80,
                    right: 32,
                    bottom: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ItemDetails(controller: controller),
                      const SizedBox(height: 32),
                      Obx(() {
                        final count = CartController.to.totalItems;
                        return _AddToCartDesktopBtn(
                          pulse: controller.cartFabPulse.value,
                          inStock:
                              controller.selectedProperty?.inStock ?? false,
                          prop: controller.selectedProperty,
                          item: controller.item.value,
                          count: count,
                          isInCart: controller.selectedPropertyInCart,
                          quantity: controller.selectedPropertyQuantity,
                          isAdding: controller.addingToCart.value,
                          controller: controller,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.controller, this.roundAllCorners = false});
  final ItemController controller;
  final bool roundAllCorners;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final prop = controller.selectedProperty;
      final imageUrl = prop?.image ?? '';
      return Hero(
        tag: controller.heroTag,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: roundAllCorners
                ? BorderRadius.circular(20)
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
            child: imageUrl.isNotEmpty
                ? NetworkImageWithPlaceholder(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    enablePreview: true,
                  )
                : Image.asset(
                    'assets/images/place_holder.png',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      );
    });
  }
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.controller});
  final ItemController controller;

  @override
  Widget build(BuildContext context) {
    final item = controller.item.value!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name ─────────────────────────────────────────────────
          Text(
            item.itemName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.brandName.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              item.brandName,
              style: textTheme.titleSmall?.copyWith(
                color: AppConstants.mediumBeige,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // ── Price ─────────────────────────────────────────────────
          Obx(() {
            final price = controller.selectedProperty?.price;
            return Text(
              price != null
                  ? '${AppConstants.currency} ${price.toStringAsFixed(2)}'
                  : '',
              style: TextStyle(
                color: AppConstants.darkBeige,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            );
          }),

          const SizedBox(height: 20),

          _PerfumeRatings(sillage: item.sillage, longevity: item.longevity),

          const SizedBox(height: 24),

          // ── Variant pills ──────────────────────────────────────────
          Obx(() {
            if (controller.properties.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 10,
              runSpacing: 8,
              children: List.generate(
                controller.properties.length,
                (i) => _VariantChip(
                  label: '${controller.properties[i].sizeMl} ml',
                  isSelected: controller.selectedPropertyIndex.value == i,
                  inStock: controller.properties[i].inStock,
                  onTap: () => controller.selectProperty(i),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // ── Description ────────────────────────────────────────────
          Obx(() {
            final description = controller.effectiveDescription;
            if (description.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'description'.tr,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(description, style: textTheme.bodyMedium),
                const SizedBox(height: 28),
              ],
            );
          }),

          if (item.accordProfile.isNotEmpty) ...[
            _AccordChart(accords: item.accordProfile),
            const SizedBox(height: 24),
          ] else if (item.accords.isNotEmpty) ...[
            _PerfumeMetadata(
              title: 'main_accords'.tr,
              icon: Icons.palette_outlined,
              values: item.accords,
            ),
            const SizedBox(height: 24),
          ],

          if (item.hasGroupedNotes)
            _GroupedFragranceNotes(
              topNotes: item.topNotes,
              middleNotes: item.middleNotes,
              baseNotes: item.baseNotes,
            )
          else if (item.notes.isNotEmpty)
            _PerfumeMetadata(
              title: 'fragrance_notes'.tr,
              icon: Icons.local_florist_outlined,
              values: item.notes,
            ),
        ],
      ),
    );
  }
}

class _PerfumeRatings extends StatelessWidget {
  const _PerfumeRatings({required this.sillage, required this.longevity});

  final int sillage;
  final int longevity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RatingRow(label: 'sillage'.tr, rating: sillage),
        const SizedBox(height: 8),
        _RatingRow(label: 'longevity'.tr, rating: longevity),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.rating});

  final String label;
  final int rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $rating/5',
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          ...List.generate(
            5,
            (index) => Icon(
              index < rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: 21,
              color: AppConstants.darkBeige,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccordChart extends StatelessWidget {
  const _AccordChart({required this.accords});

  static const _colors = [
    Color(0xFF2F7F77),
    Color(0xFF8A4F68),
    Color(0xFFB4893A),
    Color(0xFF3D6F8E),
    Color(0xFFB75D58),
    Color(0xFF607D4B),
  ];

  final List<PerfumeAccord> accords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetadataHeading(
          title: 'main_accords'.tr,
          icon: Icons.bar_chart_rounded,
        ),
        const SizedBox(height: 14),
        ...List.generate(accords.length, (index) {
          final accord = accords[index];
          final color = _colors[index % _colors.length];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == accords.length - 1 ? 0 : 12,
            ),
            child: Semantics(
              label: '${accord.name}, ${accord.percentage}%',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          accord.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 10,
                      child: ColoredBox(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.09,
                        ),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(
                            begin: 0,
                            end: accord.percentage / 100,
                          ),
                          builder: (context, value, child) =>
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: value,
                                child: ColoredBox(color: color),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _GroupedFragranceNotes extends StatelessWidget {
  const _GroupedFragranceNotes({
    required this.topNotes,
    required this.middleNotes,
    required this.baseNotes,
  });

  final List<String> topNotes;
  final List<String> middleNotes;
  final List<String> baseNotes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetadataHeading(
          title: 'fragrance_notes'.tr,
          icon: Icons.local_florist_outlined,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final tierWidth = isWide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (topNotes.isNotEmpty)
                  SizedBox(
                    width: tierWidth,
                    child: _NoteTier(
                      title: 'top_notes'.tr,
                      icon: Icons.wb_sunny_outlined,
                      color: const Color(0xFFB78327),
                      notes: topNotes,
                    ),
                  ),
                if (middleNotes.isNotEmpty)
                  SizedBox(
                    width: tierWidth,
                    child: _NoteTier(
                      title: 'middle_notes'.tr,
                      icon: Icons.favorite_border_rounded,
                      color: const Color(0xFFA65369),
                      notes: middleNotes,
                    ),
                  ),
                if (baseNotes.isNotEmpty)
                  SizedBox(
                    width: tierWidth,
                    child: _NoteTier(
                      title: 'base_notes'.tr,
                      icon: Icons.nights_stay_outlined,
                      color: const Color(0xFF3E7562),
                      notes: baseNotes,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NoteTier extends StatelessWidget {
  const _NoteTier({
    required this.title,
    required this.icon,
    required this.color,
    required this.notes,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.12 : 0.07,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: notes
                  .map(
                    (note) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(note, style: theme.textTheme.bodySmall),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataHeading extends StatelessWidget {
  const _MetadataHeading({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: AppConstants.darkBeige),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PerfumeMetadata extends StatelessWidget {
  const _PerfumeMetadata({
    required this.title,
    required this.icon,
    required this.values,
  });

  final String title;
  final IconData icon;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetadataHeading(title: title, icon: icon),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.lightBeige.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.12 : 0.7,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppConstants.mediumBeige.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(value, style: theme.textTheme.bodySmall),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.label,
    required this.isSelected,
    required this.inStock,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool inStock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: inStock ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.darkBeige : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppConstants.darkBeige
                : inStock
                ? AppConstants.mediumBeige
                : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : inStock
                ? Theme.of(context).colorScheme.onSurface
                : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            decoration: inStock ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}

class _AddToCartBottomBar extends StatelessWidget {
  const _AddToCartBottomBar({
    required this.pulse,
    required this.inStock,
    required this.prop,
    required this.item,
    required this.count,
    required this.isInCart,
    required this.quantity,
    required this.isAdding,
    required this.controller,
  });

  final bool pulse;
  final bool inStock;
  final dynamic prop;
  final dynamic item;
  final int count;
  final bool isInCart;
  final int quantity;
  final bool isAdding;
  final ItemController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: AnimatedScale(
          scale: pulse ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: isInCart
              ? Row(
                  children: [
                    _SelectedItemQuantityControl(
                      quantity: quantity,
                      isBusy: isAdding,
                      controller: controller,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CartActionButton(
                        inStock: inStock,
                        isInCart: isInCart,
                        isAdding: isAdding,
                        prop: prop,
                        item: item,
                        count: count,
                        controller: controller,
                      ),
                    ),
                  ],
                )
              : _CartActionButton(
                  inStock: inStock,
                  isInCart: isInCart,
                  isAdding: isAdding,
                  prop: prop,
                  item: item,
                  count: count,
                  controller: controller,
                ),
        ),
      ),
    );
  }
}

class _CartActionButton extends StatelessWidget {
  const _CartActionButton({
    required this.inStock,
    required this.isInCart,
    required this.isAdding,
    required this.prop,
    required this.item,
    required this.count,
    required this.controller,
  });

  final bool inStock;
  final bool isInCart;
  final bool isAdding;
  final dynamic prop;
  final dynamic item;
  final int count;
  final ItemController controller;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.darkBeige,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        disabledBackgroundColor: Colors.grey.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: !inStock || prop == null || item == null || isAdding
          ? null
          : () async {
              HapticFeedback.mediumImpact();
              await controller.handleCartAction();
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isInCart
                    ? Icons.shopping_cart_checkout
                    : Icons.shopping_bag_outlined,
              ),
              if (count > 0)
                PositionedDirectional(
                  top: -7,
                  end: -9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              inStock
                  ? (isInCart ? 'proceed_to_checkout'.tr : 'add_to_cart'.tr)
                  : 'out_of_stock'.tr,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToCartDesktopBtn extends StatelessWidget {
  const _AddToCartDesktopBtn({
    required this.pulse,
    required this.inStock,
    required this.prop,
    required this.item,
    required this.count,
    required this.isInCart,
    required this.quantity,
    required this.isAdding,
    required this.controller,
  });

  final bool pulse;
  final bool inStock;
  final dynamic prop;
  final dynamic item;
  final int count;
  final bool isInCart;
  final int quantity;
  final bool isAdding;
  final ItemController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pulse ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: isInCart
          ? Row(
              children: [
                _SelectedItemQuantityControl(
                  quantity: quantity,
                  isBusy: isAdding,
                  controller: controller,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CartActionButton(
                    inStock: inStock,
                    isInCart: isInCart,
                    isAdding: isAdding,
                    prop: prop,
                    item: item,
                    count: count,
                    controller: controller,
                  ),
                ),
              ],
            )
          : _CartActionButton(
              inStock: inStock,
              isInCart: isInCart,
              isAdding: isAdding,
              prop: prop,
              item: item,
              count: count,
              controller: controller,
            ),
    );
  }
}

class _SelectedItemQuantityControl extends StatelessWidget {
  const _SelectedItemQuantityControl({
    required this.quantity,
    required this.isBusy,
    required this.controller,
  });

  final int quantity;
  final bool isBusy;
  final ItemController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: AppConstants.mediumBeige.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: quantity <= 1 ? 'delete'.tr : 'decrease'.tr,
            icon: Icon(
              quantity <= 1 ? Icons.delete_outline : Icons.remove_rounded,
            ),
            color: AppConstants.darkBeige,
            onPressed: isBusy
                ? null
                : () async {
                    HapticFeedback.selectionClick();
                    await controller.decrementSelectedProperty();
                  },
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'increase'.tr,
            icon: const Icon(Icons.add_rounded),
            color: AppConstants.darkBeige,
            onPressed: isBusy
                ? null
                : () async {
                    HapticFeedback.selectionClick();
                    await controller.incrementSelectedProperty();
                  },
          ),
        ],
      ),
    );
  }
}
