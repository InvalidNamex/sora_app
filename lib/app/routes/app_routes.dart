part of 'app_pages.dart';

abstract class Routes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const home = '/home';
  static const item = '/item';
  static const itemDetail = '/item/:id';
  static const checkout = '/checkout';
  static const addressBook = '/address-book';
  static const wishlist = '/wishlist';
  static const orderDetail = '/orders/detail';
  static const orderDetailById = '/orders/:id';
  static const affiliateRef = '/ref/:uid';
  static const adminDashboard = '/admin';
  static const adminOrders = '/admin-orders';
  static const adminAffiliates = '/admin-affiliates';
  static const adminCatalog = '/admin-catalog';
  static const adminBundles = '/admin-bundles';
  static const adminReports = '/admin-reports';
  static const adminNotifications = '/admin-notifications';
  static const affiliateDashboard = '/affiliate';
  static const locationPicker = '/location-picker';
  static const bundleDetail = '/bundle/:id';
  static const privacyPolicy = '/privacy_policy';
  static const accountDeletion = '/delete-account';

  static String itemPath(int id) => '/item/$id';
  static String bundlePath(int id) => '/bundle/$id';
  static String orderDetailPath(int id) => '/orders/$id';
  static String affiliateRefPath(String uid) => '/ref/$uid';
}
