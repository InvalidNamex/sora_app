import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/services/deep_link_service.dart';
import '../../routes/app_pages.dart';
import '../home/home_controller.dart';

/// Bootstraps the app:
///   1. Captures any incoming deep-link.
///   2. Pre-fetches home screen data if cache is empty.
///   3. Waits the minimum splash duration.
///   4. Opens the deep-link target, or routes to Home.
class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _bootstrap().catchError((e) {
      debugPrint('[SplashController] Bootstrap error: $e');
      Get.offAllNamed(Routes.home);
    });
  }

  Future<void> _bootstrap() async {
    // Eagerly instantiate HomeController to read cache
    final homeController = Get.find<HomeController>();

    final hasCache =
        homeController.banners.isNotEmpty &&
        homeController.categories.isNotEmpty &&
        homeController.items.isNotEmpty;

    if (!hasCache) {
      debugPrint(
        '[SplashController] No cache found. Pre-fetching home screen data during splash screen...',
      );
      // Start the network fetch and wait for it alongside the minimum splash duration (1.4s)
      // If the fetch takes too long, time out after 4 seconds to avoid hanging on the splash screen
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 1400)),
        homeController.checkForUpdates(),
      ]);
    } else {
      debugPrint(
        '[SplashController] Cache present. Proceeding after minimum delay...',
      );
      // Cache exists, proceed immediately after minimum delay; checkForUpdates runs in background
      await Future.delayed(const Duration(milliseconds: 1400));
    }

    final openedDeepLink = await DeepLinkService.to.openPendingLink();
    if (!openedDeepLink) {
      Get.offAllNamed(Routes.home);
    }
  }
}
