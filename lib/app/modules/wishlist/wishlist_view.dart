import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../global_widgets/network_image_with_placeholder.dart';
import '../../routes/app_pages.dart';
import 'wishlist_controller.dart';

/// Wishlist (Liked Items) screen.
class WishlistView extends GetView<WishlistController> {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final cols = Responsive.gridColumns(context);

    return Scaffold(
      appBar: AppBar(title: Text('wishlist'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }
        if (controller.likedItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: AppConstants.mediumBeige,
                ),
                const SizedBox(height: 12),
                Text('wishlist_empty'.tr),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppConstants.darkBeige,
          onRefresh: controller.fetchLikedItems,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemCount: controller.likedItems.length,
            itemBuilder: (_, i) {
              final liked = controller.likedItems[i];
              return _WishlistCard(liked: liked, controller: controller);
            },
          ),
        );
      }),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({required this.liked, required this.controller});
  final dynamic liked;
  final WishlistController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.itemPath(liked.itemId),
        arguments: {'heroTag': 'wishlist_${liked.itemId}'},
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: liked.primaryImage != null
                        ? NetworkImageWithPlaceholder(
                            imageUrl: liked.primaryImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/place_holder.png',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liked.itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (liked.price != null)
                          Text(
                            '${AppConstants.currency} ${liked.price!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppConstants.darkBeige,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => controller.toggleLike(liked.itemId),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.brown,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
