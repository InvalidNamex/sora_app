import 'package:get/get.dart';

import 'address_controller.dart';

class AddressBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<AddressController>(() => AddressController()),
      ];
}
