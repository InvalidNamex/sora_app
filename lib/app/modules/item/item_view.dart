import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../global_widgets/network_image_with_placeholder.dart';
import '../../routes/app_pages.dart';
import '../cart/cart_controller.dart';
import '../navigation/nav_controller.dart';
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
        ],
      ),
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
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16) +
          MediaQuery.paddingOf(context).copyWith(top: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.3
                  : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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
