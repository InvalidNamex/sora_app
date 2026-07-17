import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'deep_link_service.dart';

class LinkNavigationService {
  LinkNavigationService._();

  static Future<bool> open(String? target) async {
    if (target == null || target.trim().isEmpty) return false;

    final value = target.trim();
    if (Get.isRegistered<DeepLinkService>() &&
        await DeepLinkService.to.handleDeepLink(value)) {
      return true;
    }

    final uri = Uri.tryParse(value);
    final isExternalWebUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isExternalWebUrl) {
      debugPrint('[LinkNavigationService] ignored target: $value');
      return false;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      debugPrint('[LinkNavigationService] could not open URL: $value');
    }
    return opened;
  }
}
