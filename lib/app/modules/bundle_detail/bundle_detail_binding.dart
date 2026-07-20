import 'package:get/get.dart';

import 'bundle_detail_controller.dart';

class BundleDetailBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<BundleDetailController>(() => BundleDetailController()),
  ];
}
