import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../modules/auth/auth_controller.dart';
import '../../modules/navigation/nav_controller.dart';
import '../../routes/app_pages.dart';
import 'affiliate_program_service.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService get to => Get.find();

  final _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;
  Future<void>? _initialLinkCapture;
  Uri? _pendingUri;
  String? _pendingAuthRoute;
  bool _navigationReady = false;

  @override
  void onInit() {
    super.onInit();
    _initialLinkCapture = _captureInitialLink();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (Object e) => debugPrint('[DeepLinkService] stream error: $e'),
    );
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }

  Future<bool> openPendingLink() async {
    await _initialLinkCapture?.timeout(
      const Duration(milliseconds: 700),
      onTimeout: () => debugPrint('[DeepLinkService] initial link timeout'),
    );

    _navigationReady = true;
    final uri = _pendingUri;
    if (uri == null) return false;
    _pendingUri = null;
    return _routeUri(uri);
  }

  void setPendingAuthRoute(String route) {
    _pendingAuthRoute = route;
  }

  Future<bool> openPendingAuthRoute() async {
    final route = _pendingAuthRoute;
    if (route == null || route.isEmpty) return false;
    _pendingAuthRoute = null;
    await _openRoute(route);
    return true;
  }

  Future<bool> handleDeepLink(String? value) async {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    return handleUri(uri);
  }

  Future<bool> handleUri(Uri uri) async {
    if (!_navigationReady) {
      _pendingUri = uri;
      return true;
    }
    return _routeUri(uri);
  }

  Future<void> _captureInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) unawaited(handleUri(uri));
    } catch (e) {
      debugPrint('[DeepLinkService] initial link error: $e');
    }
  }

  void _handleIncomingLink(Uri uri) {
    if (!_navigationReady) {
      unawaited(handleUri(uri));
      return;
    }
    unawaited(_routeUri(uri));
  }

  Future<bool> _routeUri(Uri uri) async {
    if (!_isSupportedUri(uri)) return false;

    final segments = _pathSegmentsFor(uri);
    if (segments.isEmpty) return false;

    switch (segments.first) {
      case 'home':
        await _openHome();
        return true;
      case 'item':
        final itemId = _idFrom(segments, uri);
        if (itemId == null) return false;
        await AffiliateProgramService.captureLinkCode(
          uri.queryParameters['ref'],
          itemId: itemId,
        );
        await _openRoute(Routes.itemPath(itemId));
        return true;
      case 'orders':
        final orderId = _idFrom(segments, uri);
        if (orderId == null) return false;
        await _openRoute(Routes.orderDetailPath(orderId));
        return true;
      case 'ref':
        final code = segments.length > 1 ? segments[1].trim() : '';
        if (code.isEmpty) return false;
        await AffiliateProgramService.captureLinkCode(code);
        await _openHome();
        return true;
      case 'admin-orders':
        if (AuthController.to.currentUser.value?.isAdmin != true) return false;
        await _openRoute(Routes.adminOrders);
        return true;
      case 'admin-affiliates':
        if (AuthController.to.currentUser.value?.isAdmin != true) return false;
        await _openRoute(Routes.adminAffiliates);
        return true;
      case 'affiliate':
        if (AuthController.to.currentUser.value?.isAffiliate != true) {
          await AuthController.to.refreshCurrentUser();
        }
        if (AuthController.to.currentUser.value?.isAffiliate != true) {
          return false;
        }
        await _openRoute(Routes.affiliateDashboard);
        return true;
      default:
        return false;
    }
  }

  bool _isSupportedUri(Uri uri) {
    if (!uri.hasScheme) return true;
    if (uri.scheme == 'sora') return true;
    if (uri.scheme != 'https') return false;
    return uri.host == 'www.sora-eg.store';
  }

  List<String> _pathSegmentsFor(Uri uri) {
    if (uri.scheme == 'sora' && uri.host.isNotEmpty) {
      return [uri.host, ...uri.pathSegments];
    }
    return uri.pathSegments;
  }

  int? _idFrom(List<String> segments, Uri uri) {
    final rawId = segments.length > 1 ? segments[1] : uri.queryParameters['id'];
    if (rawId == null) return null;
    final id = int.tryParse(rawId);
    return id != null && id > 0 ? id : null;
  }

  Future<void> _openHome() async {
    if (Get.isRegistered<NavController>()) {
      NavController.to.setIndex(0);
    }
    if (Get.currentRoute != Routes.home) {
      Get.offAllNamed(Routes.home);
    }
  }

  Future<void> _openRoute(String route) async {
    if (Get.currentRoute != Routes.home) {
      Get.offAllNamed(Routes.home);
      await Future<void>.delayed(Duration.zero);
    }
    await Get.toNamed(route);
  }
}
