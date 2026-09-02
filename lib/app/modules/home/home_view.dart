import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/banner_model.dart';
import '../../core/utils/responsive.dart';
import '../../modules/cart/cart_controller.dart';
import '../../modules/admin/notifications/admin_notification_inbox_controller.dart';
import '../../modules/navigation/nav_controller.dart';
import '../../global_widgets/network_image_with_placeholder.dart';
import '../../routes/app_pages.dart';
import 'home_controller.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/bundle_deal_carousel.dart';
import 'widgets/home_sections.dart';

class _HomeSearchDelegate extends SearchDelegate<ItemWithProperty?> {
  _HomeSearchDelegate(this.controller);

  final HomeController controller;
  Future<List<ItemWithProperty>>? _searchFuture;
  String _searchFutureQuery = '';

  Future<List<ItemWithProperty>> _results(String rawQuery) {
    final normalizedQuery = rawQuery.trim();
    if (normalizedQuery.isEmpty) {
      return Future.value(controller.displayItems.toList());
    }
    if (_searchFuture == null || _searchFutureQuery != normalizedQuery) {
      _searchFutureQuery = normalizedQuery;
      _searchFuture = controller.searchItems(normalizedQuery);
    }
    return _searchFuture!;
  }

  Widget _buildResultsList(
    BuildContext context,
    List<ItemWithProperty> results,
  ) {
    if (results.isEmpty) {
      return Center(
        child: Text(
          'no_matching_items'.tr,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = results[index];
        final prop = entry.primaryProperty;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: prop != null && prop.image.isNotEmpty
                  ? NetworkImageWithPlaceholder(
                      imageUrl: prop.image,
                      fit: BoxFit.cover,
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
          subtitle: Text(
            [
              if (entry.item.brandName.isNotEmpty) entry.item.brandName,
              if (prop != null)
                '${AppConstants.currency} ${(prop.hasDiscount ? prop.salePrice : prop.price).toStringAsFixed(2)}',
            ].join(' • '),
          ),
          trailing: entry.item.isFeatured
              ? const Icon(
                  Icons.star_rounded,
                  color: AppConstants.darkBeige,
                  size: 18,
                )
              : null,
          onTap: () {
            close(context, entry);
            Get.toNamed(
              Routes.itemPath(entry.item.id),
              arguments: {'heroTag': 'hero_item_${entry.item.id}'},
            );
          },
        );
      },
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    return FutureBuilder<List<ItemWithProperty>>(
      future: _results(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('search_failed'.tr));
        }
        return _buildResultsList(context, snapshot.data ?? const []);
      },
    );
  }

  @override
  String get searchFieldLabel => 'search_items'.tr;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
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
    return _buildSearchContent(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchContent(context);
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
              backgroundColor: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.92),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 54,
              leading: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 12,
                  top: 8,
                  bottom: 8,
                ),
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
                const _AdminNotificationButton(),
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

          // ── Collapsing hero: banner ───────────────────────────────────────
          Obx(() {
            final showBanners =
                controller.isLoadingBanners.value ||
                controller.banners.isNotEmpty;

            if (!showBanners) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            final bannerHeight = showBanners ? 180.0 : 0.0;

            return SliverPersistentHeader(
              pinned: false,
              delegate: _CollapsingHeroDelegate(
                maxHeight: bannerHeight,
                child: _TopHeroSection(
                  isLoadingBanners: controller.isLoadingBanners.value,
                  banners: controller.banners,
                ),
              ),
            );
          }),

          // ── Bundle deals ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Obx(() {
              final loading = controller.isLoadingBundles.value;
              final bundles = controller.bundleDeals.toList();
              if (!loading && bundles.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.all_inbox_outlined,
                            color: AppConstants.darkBeige,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'bundle_deal'.tr,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (loading)
                      Container(
                        height: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppConstants.lightBeige,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      )
                    else
                      BundleDealCarousel(bundles: bundles),
                  ],
                ),
              );
            }),
          ),

          // ── Curated, admin-configured product sections ──────────────────────
          SliverToBoxAdapter(
            child: HomeSections(onBrowseAll: () => Get.toNamed(Routes.catalog)),
          ),

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
  });

  final bool isLoadingBanners;
  final List<BannerModel> banners;

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}

class _AdminNotificationButton extends StatelessWidget {
  const _AdminNotificationButton();

  @override
  Widget build(BuildContext context) {
    final inbox = AdminNotificationInboxController.to;
    return Obx(() {
      if (!inbox.isAdmin) return const SizedBox.shrink();
      final unread = inbox.unreadCount;
      return IconButton(
        tooltip: 'Admin notifications',
        icon: Badge.count(
          count: unread,
          isLabelVisible: unread > 0,
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.notifications_outlined),
        ),
        onPressed: () => Get.toNamed(Routes.adminNotifications),
      );
    });
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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
