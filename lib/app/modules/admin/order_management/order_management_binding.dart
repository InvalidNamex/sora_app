import 'package:get/get.dart';

import 'order_management_controller.dart';

class OrderManagementBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<OrderManagementController>(
            () => OrderManagementController()),
      ];
}
