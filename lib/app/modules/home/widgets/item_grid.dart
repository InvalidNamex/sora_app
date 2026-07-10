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
      final featuredCount =
          items.where((e) => e.item.isFeatured).length;
      final count = loading ? _shimmerCount : items.length;
      final cols = Responsive.gridColumns(context);

      if (!loading && controller.hasItemsError.value) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_outlined,
                    size: 48, color: AppConstants.mediumBeige),
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

      if (!loading && items.isEmpty) {
        return const SizedBox.shrink();
      }

      final showFeaturedMovedNotice = !loading && featuredCount > 0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            if (showFeaturedMovedNotice)
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${'featured'.tr}: $featuredCount',
                    style: const TextStyle(
                      color: AppConstants.mediumBeige,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            MasonryGridView.count(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: count,
              itemBuilder: (_, i) {
                final entry = loading ? null : items[i];
                return ItemCard(entry: entry);
              },
            ),
          ],
        ),
      );
    });
  }
}
