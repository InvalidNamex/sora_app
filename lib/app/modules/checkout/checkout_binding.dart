import 'package:get/get.dart';

import 'checkout_controller.dart';

class CheckoutBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<CheckoutController>(() => CheckoutController()),
      ];
}
