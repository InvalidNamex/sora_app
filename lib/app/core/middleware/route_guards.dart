import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/auth/auth_controller.dart';
import '../services/deep_link_service.dart';
import '../../routes/app_pages.dart';

/// Redirects to [Routes.home] if the current user is not an admin.
class AdminGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (AuthController.to.currentUser.value?.isAdmin != true) {
      return const RouteSettings(name: Routes.home);
    }
    return null;
  }
}

/// Redirects to [Routes.home] if the current user is not an affiliate.
class AffiliateGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (AuthController.to.currentUser.value?.isAffiliate != true) {
      return const RouteSettings(name: Routes.home);
    }
    return null;
  }
}

/// Redirects to [Routes.auth] if the user is not logged in.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!AuthController.to.isLoggedIn) {
      if (route != null && route.isNotEmpty) {
        DeepLinkService.to.setPendingAuthRoute(route);
      }
      return const RouteSettings(name: Routes.auth);
    }
    return null;
  }
}
