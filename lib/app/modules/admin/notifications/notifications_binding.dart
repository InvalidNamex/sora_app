import 'package:get/get.dart';

import 'notifications_controller.dart';

class NotificationsBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<NotificationsController>(() => NotificationsController()),
      ];
}
