import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/video_ad_model.dart';
import 'home_controller.dart';
import 'widgets/video_ad_section.dart';
import 'widgets/category_strip.dart';
import 'widgets/catalog_ad_feed.dart';

/// Full, filterable catalogue reached after the curated home sections.
class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final _scrollController = ScrollController();
  final _viewportKey = GlobalKey();
  final _activeAd = ValueNotifier<VideoAdModel?>(null);
  final _slotKeys = <int, GlobalKey>{};
  bool _positionUpdateScheduled = false;

  HomeController get controller => HomeController.to;

  GlobalKey _slotKeyFor(VideoAdModel ad) =>
      _slotKeys.putIfAbsent(ad.id, GlobalKey.new);

  bool _onScroll(ScrollNotification notification) {
    _schedulePositionUpdate();
    return false;
  }

  void _schedulePositionUpdate() {
    if (_positionUpdateScheduled) return;
    _positionUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _positionUpdateScheduled = false;
      if (!mounted) return;
      _updateActiveAd();
    });
  }

  void _updateActiveAd() {
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return;

    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewport.size.height;
    VideoAdModel? visibleAd;

    for (final ad in controller.videoAds) {
      final slot =
          _slotKeys[ad.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (slot == null || !slot.hasSize) continue;
      final slotTop = slot.localToGlobal(Offset.zero).dy;
      final slotBottom = slotTop + slot.size.height;
      if (slotBottom > viewportTop && slotTop < viewportBottom) {
        visibleAd = ad;
        break;
      }
    }

    if (_activeAd.value?.id != visibleAd?.id) {
      _activeAd.value = visibleAd;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _activeAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('browse_all_perfumes'.tr), backgroundColor: Theme.of(context).scaffoldBackgroundColor),
      body: SizedBox.expand(
        key: _viewportKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder<VideoAdModel?>(
              valueListenable: _activeAd,
              builder: (context, ad, _) {
                if (ad == null) {
                  return ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  );
                }
                return VideoAdSection(
                  key: ValueKey('catalog_ad_${ad.id}'),
                  ad: ad,
                  fullScreen: true,
                );
              },
            ),
            RefreshIndicator(
              color: AppConstants.darkBeige,
              onRefresh: controller.refresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: CustomScrollView(
                  key: const PageStorageKey<String>('catalog_scroll'),
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Obx(
                          () => CategoryStrip(
                            categories: controller.categories,
                            subCategories: controller.subCategories,
                            selectedCategoryId:
                                controller.selectedCategoryId.value,
                            selectedSubCategoryId:
                                controller.selectedSubCategoryId.value,
                            onCategoryTap: controller.selectCategory,
                            onSubCategoryTap: controller.selectSubCategory,
                          ),
                        ),
                      ),
                    ),
                    CatalogAdFeed(slotKeyFor: _slotKeyFor),
                    SliverToBoxAdapter(
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: const SizedBox(height: 32),
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
  }
}
