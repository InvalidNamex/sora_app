part of 'app_pages.dart';

abstract class Routes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const home = '/home';
  static const catalog = '/catalog';
  static const item = '/item';
  static const itemDetail = '/item/:id';
  static const checkout = '/checkout';
  static const addressBook = '/address-book';
  static const wishlist = '/wishlist';
  static const orderDetail = '/orders/detail';
  static const orderDetailById = '/orders/:id';
  static const orderReview = '/orders/:id/review';
  static const affiliateRef = '/ref/:uid';
  static const adminDashboard = '/admin';
  static const adminOrders = '/admin-orders';
  static const adminAffiliates = '/admin-affiliates';
  static const adminCatalog = '/admin-catalog';
  static const adminHomeSections = '/admin-home-sections';
  static const adminBundles = '/admin-bundles';
  static const adminReports = '/admin-reports';
  static const adminVideoAds = '/admin-video-ads';
  static const adminNotifications = '/admin-notifications';
  static const adminItemSuggestions = '/admin-item-suggestions';
  static const adminFeedback = '/admin-feedback';
  static const adminReturns = '/admin-returns';
  static const affiliateDashboard = '/affiliate';
  static const locationPicker = '/location-picker';
  static const bundleDetail = '/bundle/:id';
  static const privacyPolicy = '/privacy_policy';
  static const accountDeletion = '/delete-account';

  static String itemPath(int id) => '/item/$id';
  static String bundlePath(int id) => '/bundle/$id';
  static String orderDetailPath(int id) => '/orders/$id';
  static String orderReviewPath(int id) => '/orders/$id/review';
  static String affiliateRefPath(String uid) => '/ref/$uid';
}
