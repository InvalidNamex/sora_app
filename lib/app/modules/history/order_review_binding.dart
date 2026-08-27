import 'package:get/get.dart';

import 'order_review_controller.dart';

class OrderReviewBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<OrderReviewController>(() => OrderReviewController()),
  ];
}
