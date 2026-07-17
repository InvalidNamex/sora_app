import 'package:get/get.dart';

import '../../modules/auth/auth_controller.dart';
import '../../modules/cart/cart_controller.dart';
import '../../modules/history/history_controller.dart';
import '../../modules/home/home_controller.dart';
import '../../modules/navigation/nav_controller.dart';
import '../../modules/wishlist/wishlist_controller.dart';
import '../services/deep_link_service.dart';
import '../services/notification_service.dart';

/// Registers all long-lived (permanent) and lazily-loaded tab controllers.
/// Called once from [main] before [runApp].
class AppBinding {
  static void init() {
    Get.put(AuthController(), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(NavController(), permanent: true);
    Get.put(WishlistController(), permanent: true);
    Get.put(DeepLinkService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<HistoryController>(() => HistoryController(), fenix: true);
  }
}
