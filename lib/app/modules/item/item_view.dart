import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../cart/cart_controller.dart';
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
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: Obx(() {
        final count = CartController.to.totalItems;
        final pulse = controller.cartFabPulse.value;
        final prop = controller.selectedProperty;
        final item = controller.item.value;
        final inStock = prop?.inStock ?? false;
        return AnimatedScale(
          scale: pulse ? 1.14 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: FloatingActionButton.extended(
            backgroundColor: AppConstants.darkBeige,
            foregroundColor: Colors.white,
            onPressed: !inStock || prop == null || item == null
                ? null
                : () async {
                    HapticFeedback.mediumImpact();
                    await CartController.to.addItem(prop, item.itemName, 1);
                    await controller.pulseCartFab();
                    Get.snackbar(
                      'added_to_cart'.tr,
                      '${item.itemName} · ${prop.sizeMl} ml',
                      duration: const Duration(seconds: 2),
                    );
                  },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined),
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
            label: Text(inStock ? 'add_to_cart'.tr : 'out_of_stock'.tr),
          ),
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
                const Icon(Icons.wifi_off_outlined,
                    size: 56, color: AppConstants.mediumBeige),
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
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.controller});
  final ItemController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroImage(controller: controller),
          _ItemDetails(controller: controller),
        ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 80, right: 32, bottom: 32),
                child: _ItemDetails(controller: controller),
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
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: AppConstants.lightBeige,
                    ),
                  )
                : Image.asset('assets/images/place_holder.png', fit: BoxFit.cover),
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
            style: textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
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
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            decoration:
                inStock ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}
