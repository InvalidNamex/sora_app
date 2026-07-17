import 'package:get/get.dart';
import 'catalog_management_controller.dart';

class CatalogManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CatalogManagementController>(() => CatalogManagementController());
  }
}
