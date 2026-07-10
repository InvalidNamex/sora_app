import 'package:get/get.dart';

import 'wishlist_controller.dart';

class WishlistBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<WishlistController>(() => WishlistController()),
      ];
}
