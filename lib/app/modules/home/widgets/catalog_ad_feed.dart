import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/video_ad_model.dart';
import '../../../core/utils/responsive.dart';
import '../home_controller.dart';
import 'item_card.dart';

/// The all-perfumes feed. Ads occupy a viewport-sized slot behind a transparent
/// spacer, so pulling the product feed up reveals the ad as a full-screen panel.
class CatalogAdFeed extends GetView<HomeController> {
  const CatalogAdFeed({super.key, required this.slotKeyFor});

  final GlobalKey Function(VideoAdModel ad) slotKeyFor;

  static const _itemsPerAd = 6;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingItems.value) {
        return SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: Responsive.gridColumns(context),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: 6,
            itemBuilder: (_, index) => const ItemCard(entry: null),
          ),
        );
      }

      if (controller.hasItemsError.value) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('error_loading'.tr)),
          ),
        );
      }

      final items = controller.displayItems.toList(growable: false);
      if (items.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Center(
              child: Text(
                'no_items'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.darkBeige,
                ),
              ),
            ),
          ),
        );
      }

      final ads = controller.videoAds.toList(growable: false);
      final children = <Widget>[];
      for (
        var start = 0, adIndex = 0;
        start < items.length;
        start += _itemsPerAd
      ) {
        final end = (start + _itemsPerAd).clamp(0, items.length);
        final chunk = items.sublist(start, end);
        children.add(
          ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              child: MasonryGridView.count(
                crossAxisCount: Responsive.gridColumns(context),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chunk.length,
                itemBuilder: (_, index) => ItemCard(
                  entry: chunk[index],
                  heroTag:
                      'catalog_item_${start + index}_${chunk[index].item.id}',
                ),
              ),
            ),
          ),
        );

        if (adIndex < ads.length) {
          final ad = ads[adIndex++];
          children.add(_AdRevealSlot(key: slotKeyFor(ad)));
        }
      }

      return SliverList(delegate: SliverChildListDelegate(children));
    });
  }
}

class _AdRevealSlot extends StatelessWidget {
  const _AdRevealSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.sizeOf(context).height);
  }
}
