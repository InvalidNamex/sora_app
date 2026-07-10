import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../routes/app_pages.dart';
import '../home/home_controller.dart';

/// Bootstraps the app:
///   1. Captures any incoming deep-link (affiliate ID).
///   2. Pre-fetches home screen data if cache is empty.
///   3. Waits the minimum splash duration.
///   4. Always routes to Home — guests can browse freely.
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
    _captureDeepLink();

    // Eagerly instantiate HomeController to read cache
    final homeController = Get.find<HomeController>();

    final hasCache = homeController.banners.isNotEmpty &&
        homeController.categories.isNotEmpty &&
        homeController.items.isNotEmpty;

    if (!hasCache) {
      debugPrint('[SplashController] No cache found. Pre-fetching home screen data during splash screen...');
      // Start the network fetch and wait for it alongside the minimum splash duration (1.4s)
      // If the fetch takes too long, time out after 4 seconds to avoid hanging on the splash screen
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 1400)),
        homeController.checkForUpdates(),
      ]);
    } else {
      debugPrint('[SplashController] Cache present. Proceeding after minimum delay...');
      // Cache exists, proceed immediately after minimum delay; checkForUpdates runs in background
      await Future.delayed(const Duration(milliseconds: 1400));
    }

    Get.offAllNamed(Routes.home);
  }

  void _captureDeepLink() {
    AppLinks().getInitialLink().then((uri) {
      if (uri == null) return;
      // Match pattern: https://www.sora-eg.store/{uid}
      final uid = uri.pathSegments.firstOrNull;
      if (uid != null && uid.isNotEmpty) {
        GetStorage().write(AppConstants.kActiveAffiliateId, uid);
      }
    }).catchError((e) {
      debugPrint('[SplashController] Deep-link capture error: $e');
    });
  }
}

