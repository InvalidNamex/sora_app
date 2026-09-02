import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../home_controller.dart';
import 'item_card.dart';

/// Staggered masonry product grid.
/// Shows shimmer placeholders while [isLoading] is true.
class ItemGrid extends GetView<HomeController> {
  const ItemGrid({super.key});

  static const int _shimmerCount = 6;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoadingItems.value;
      final items = controller.displayItems;
      final count = loading ? _shimmerCount : items.length;
      final cols = Responsive.gridColumns(context);

      if (!loading && controller.hasItemsError.value) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_outlined,
                  size: 48,
                  color: AppConstants.mediumBeige,
                ),
                const SizedBox(height: 12),
                Text('error_loading'.tr),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refresh,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          ),
        );
      }

      if (!loading && controller.items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  size: 44,
                  color: AppConstants.mediumBeige,
                ),
                const SizedBox(height: 12),
                Text(
                  'coming_soon'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppConstants.darkBeige,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (!loading && items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Center(child: Text('no_items'.tr)),
        );
      }


      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [

            MasonryGridView.count(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: count,
              itemBuilder: (_, i) {
                final entry = loading ? null : items[i];
                return ItemCard(
                  entry: entry,
                  heroTag: entry == null
                      ? null
                      : 'grid_item_${i}_${entry.item.id}',
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
