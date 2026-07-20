import 'package:get/get.dart';

import 'reports_controller.dart';

class ReportsBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<ReportsController>(() => ReportsController()),
  ];
}
