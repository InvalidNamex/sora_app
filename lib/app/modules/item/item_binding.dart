import 'package:get/get.dart';

import 'item_controller.dart';

class ItemBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<ItemController>(() => ItemController()),
      ];
}
