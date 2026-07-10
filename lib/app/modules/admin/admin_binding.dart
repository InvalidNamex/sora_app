import 'package:get/get.dart';

import 'admin_controller.dart';
import 'order_management/order_management_controller.dart';
import 'affiliate_management/affiliate_management_controller.dart';

class AdminBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<AdminController>(() => AdminController()),
        Bind.lazyPut<OrderManagementController>(
            () => OrderManagementController()),
        Bind.lazyPut<AffiliateManagementController>(
            () => AffiliateManagementController()),
      ];
}
