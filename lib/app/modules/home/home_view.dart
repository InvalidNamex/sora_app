import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/banner_model.dart';
import '../../core/utils/responsive.dart';
import '../../modules/cart/cart_controller.dart';
import '../../modules/navigation/nav_controller.dart';
import '../../routes/app_pages.dart';
import 'home_controller.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/category_strip.dart';
import 'widgets/item_grid.dart';

class _HomeSearchDelegate extends SearchDelegate<ItemWithProperty?> {
  _HomeSearchDelegate(this.controller);

  final HomeController controller;

  List<ItemWithProperty> _results(String rawQuery) {
    final normalizedQuery = rawQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return controller.displayItems.toList();
    }

    return controller.displayItems.where((entry) {
      final itemName = entry.item.itemName.toLowerCase();
      final itemDescription = entry.item.itemDescription.toLowerCase();
      return itemName.contains(normalizedQuery) ||
          itemDescription.contains(normalizedQuery);
    }).toList();
  }

  Widget _buildResultsList(BuildContext context, List<ItemWithProperty> results) {
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No matching items',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = results[index];
        final prop = entry.primaryProperty;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: prop != null && prop.image.isNotEmpty
                  ? Image.network(
                      prop.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        AppConstants.placeholderPath,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      AppConstants.placeholderPath,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          title: Text(
            entry.item.itemName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: prop != null
              ? Text('${AppConstants.currency} ${prop.price.toStringAsFixed(2)}')
              : null,
          trailing: entry.item.isFeatured
              ? const Icon(Icons.star_rounded, color: AppConstants.darkBeige, size: 18)
              : null,
          onTap: () {
            close(context, entry);
            Get.toNamed(
              Routes.item,
              arguments: {
                'itemId': entry.item.id,
                'heroTag': 'hero_item_${entry.item.id}',
              },
            );
          },
        );
      },
    );
  }

  @override
  String get searchFieldLabel => 'Search items';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(context, _results(query));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsList(context, _results(query));
  }
}

/// Home tab: banner carousel, category filter strip, staggered product grid.
/// Uses a [CustomScrollView] with slivers for smooth unified scrolling.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return RefreshIndicator(
      color: AppConstants.darkBeige,
      onRefresh: controller.refresh,
      child: CustomScrollView(
        slivers: [
          // ── App bar (mobile/tablet only — desktop uses AppScaffold's bar) ──
          if (!isDesktop)
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 54,
              leading: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, top: 8, bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, size: 18),
                    onPressed: () =>
                        NavController.to.scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
              ),
              title: Text(
                'SORA',
                style: TextStyle(
                  fontFamily: AppConstants.fontFamily,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  fontSize: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_outlined),
                  onPressed: () => showSearch<ItemWithProperty?>(
                    context: context,
                    delegate: _HomeSearchDelegate(controller),
                  ),
                ),
                Obx(() {
                  final cartCount = CartController.to.totalItems;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: IconButton(
                      icon: Badge.count(
                        count: cartCount,
                        isLabelVisible: cartCount > 0,
                        backgroundColor: AppConstants.darkBeige,
                        child: const Icon(Icons.shopping_bag_outlined),
                      ),
                      onPressed: () => NavController.to.setIndex(1),
                    ),
                  );
                }),
              ],
              automaticallyImplyLeading: false,
            ),

          // ── Collapsing hero: banner + featured strip ─────────────────────
          Obx(() {
            final featured = controller.displayItems
                .where((e) => e.item.isFeatured)
                .take(10)
                .toList();
            final hasFeatured = featured.isNotEmpty;
            final showBanners = controller.isLoadingBanners.value || controller.banners.isNotEmpty;
            
            if (!hasFeatured && !showBanners) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            final bannerHeight = showBanners ? 180 : 0.0;
            final double height = bannerHeight + (hasFeatured ? 156.0 : 0.0);

            return SliverPersistentHeader(
              pinned: false,
              delegate: _CollapsingHeroDelegate(
                maxHeight: height,
                child: _TopHeroSection(
                  isLoadingBanners: controller.isLoadingBanners.value,
                  banners: controller.banners,
                  featured: featured,
                ),
              ),
            );
          }),

          // ── Exclusive Promo banner ─────────────────────────────────────────
          const SliverToBoxAdapter(
            child: _PromoBanner(),
          ),

          // ── Category & sub-category strip ──────────────────────────────────
          SliverToBoxAdapter(
            child: Obx(() => CategoryStrip(
                  categories: controller.categories.value,
                  subCategories: controller.subCategories.value,
                  selectedCategoryId: controller.selectedCategoryId.value,
                  selectedSubCategoryId: controller.selectedSubCategoryId.value,
                  onCategoryTap: controller.selectCategory,
                  onSubCategoryTap: controller.selectSubCategory,
                )),
          ),

          // ── Product grid ───────────────────────────────────────────────────
          const SliverToBoxAdapter(child: ItemGrid()),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _TopHeroSection extends StatelessWidget {
  const _TopHeroSection({
    required this.isLoadingBanners,
    required this.banners,
    required this.featured,
  });

  final bool isLoadingBanners;
  final List<BannerModel> banners;
  final List<ItemWithProperty> featured;

  @override
  Widget build(BuildContext context) {
    final showFeatured = featured.isNotEmpty;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoadingBanners || banners.isNotEmpty) ...[
              if (isLoadingBanners)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(color: AppConstants.lightBeige),
                )
              else
                BannerCarousel(banners: banners),
            ],
            if (showFeatured) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'featured'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${featured.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 86,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final e = featured[i];
                    final img = e.primaryProperty?.image ?? '';
                    return InkWell(
                      onTap: () => Get.toNamed(
                        Routes.item,
                        arguments: {
                          'itemId': e.item.id,
                          'heroTag': 'hero_item_${e.item.id}',
                        },
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 210,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppConstants.mediumBeige.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(13),
                                bottomLeft: Radius.circular(13),
                              ),
                              child: SizedBox(
                                width: 78,
                                height: double.infinity,
                                child: img.isNotEmpty
                                    ? Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Image.asset(
                                          AppConstants.placeholderPath,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        AppConstants.placeholderPath,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      e.item.itemName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      e.primaryProperty != null
                                          ? '${AppConstants.currency} ${e.primaryProperty!.price.toStringAsFixed(2)}'
                                          : '',
                                      style: const TextStyle(
                                        color: AppConstants.darkBeige,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemCount: featured.length,
                ),
              ),
            ],
            SizedBox(height: showFeatured ? 12 : 0),
          ],
        ),
      ),
    );
  }
}

class _CollapsingHeroDelegate extends SliverPersistentHeaderDelegate {
  _CollapsingHeroDelegate({required this.maxHeight, required this.child});

  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final opacity = 1.0 - t;
    final y = -18 * t;
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, y),
        child: SizedBox.expand(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingHeroDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight || oldDelegate.child != child;
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.darkBeige, AppConstants.mediumBeige],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.darkBeige.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'exclusive_offer'.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'promo_discount_text'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              children: [
                const Text(
                  'SORA20',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: 'SORA20'));
                    Get.snackbar(
                      'copied'.tr,
                      'SORA20',
                      snackPosition: SnackPosition.bottom,
                      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
                      colorText: theme.colorScheme.onSurface,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: const Icon(
                    Icons.copy,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
