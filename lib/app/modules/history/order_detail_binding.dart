import 'package:get/get.dart';

import 'order_detail_controller.dart';

class OrderDetailBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<OrderDetailController>(() => OrderDetailController()),
  ];
}
