import 'package:get/get.dart';

import 'catalog_management_controller.dart';

class CatalogManagementBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<CatalogManagementController>(
      () => CatalogManagementController(),
    ),
  ];
}
