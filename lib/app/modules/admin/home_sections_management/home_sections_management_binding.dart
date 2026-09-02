import 'package:get/get.dart';

import 'home_sections_management_controller.dart';

class HomeSectionsManagementBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<HomeSectionsManagementController>(
      () => HomeSectionsManagementController(),
    ),
  ];
}
