import 'package:get/get.dart';

import '../core/middleware/route_guards.dart';
import '../global_widgets/app_scaffold.dart';
import '../modules/address_book/address_binding.dart';
import '../modules/address_book/address_view.dart';
import '../modules/admin/admin_binding.dart';
import '../modules/admin/admin_view.dart';
import '../modules/admin/affiliate_management/affiliate_management_binding.dart';
import '../modules/admin/affiliate_management/affiliate_management_view.dart';
import '../modules/admin/catalog_management/catalog_management_binding.dart';
import '../modules/admin/catalog_management/catalog_management_view.dart';
import '../modules/admin/notifications/notifications_binding.dart';
import '../modules/admin/notifications/notifications_view.dart';
import '../modules/admin/order_management/order_management_binding.dart';
import '../modules/admin/order_management/order_management_view.dart';
import '../modules/admin/reports/reports_binding.dart';
import '../modules/admin/reports/reports_view.dart';
import '../modules/affiliate/affiliate_binding.dart';
import '../modules/affiliate/affiliate_view.dart';
import '../modules/auth/auth_view.dart';
import '../modules/checkout/checkout_binding.dart';
import '../modules/checkout/checkout_view.dart';
import '../modules/item/item_binding.dart';
import '../modules/item/item_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/wishlist/wishlist_binding.dart';
import '../modules/wishlist/wishlist_view.dart';
import '../modules/history/order_detail_binding.dart';
import '../modules/history/order_detail_view.dart';
import '../modules/location_picker/location_picker_binding.dart';
import '../modules/location_picker/location_picker_page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = <GetPage>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(name: Routes.auth, page: () => const AuthView()),
    GetPage(name: Routes.home, page: () => const AppScaffold()),
    GetPage(
      name: Routes.item,
      page: () => const ItemView(),
      binding: ItemBinding(),
    ),
    GetPage(
      name: Routes.itemDetail,
      page: () => const ItemView(),
      binding: ItemBinding(),
    ),
    GetPage(
      name: Routes.checkout,
      page: () => const CheckoutView(),
      binding: CheckoutBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: Routes.addressBook,
      page: () => const AddressView(),
      binding: AddressBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: Routes.wishlist,
      page: () => const WishlistView(),
      binding: WishlistBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: Routes.adminDashboard,
      page: () => const AdminView(),
      binding: AdminBinding(),
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: Routes.adminOrders,
      page: () => const OrderManagementView(),
      binding: OrderManagementBinding(),
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: Routes.adminAffiliates,
      page: () => const AffiliateManagementView(),
      binding: AffiliateManagementBinding(),
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: Routes.adminCatalog,
      page: () => const CatalogManagementView(),
      binding: CatalogManagementBinding(),
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: Routes.adminReports,
      page: () => const ReportsView(),
      binding: ReportsBinding(),
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: Routes.adminNotifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      middlewares: [AdminGuard()],
    ),
    GetPage(
      name: Routes.affiliateDashboard,
      page: () => const AffiliateView(),
      binding: AffiliateBinding(),
      middlewares: [AffiliateGuard()],
    ),
    GetPage(
      name: Routes.orderDetail,
      page: () => const OrderDetailView(),
      binding: OrderDetailBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: Routes.orderDetailById,
      page: () => const OrderDetailView(),
      binding: OrderDetailBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(name: Routes.affiliateRef, page: () => const AppScaffold()),
    GetPage(
      name: Routes.locationPicker,
      page: () => const LocationPickerPage(),
      binding: LocationPickerBinding(),
    ),
  ];
}
