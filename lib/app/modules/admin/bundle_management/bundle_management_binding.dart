import 'package:get/get.dart';

import 'bundle_management_controller.dart';

class BundleManagementBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<BundleManagementController>(
      () => BundleManagementController(),
    ),
  ];
}
