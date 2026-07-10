import 'package:get/get.dart';

import 'splash_controller.dart';

class SplashBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.put<SplashController>(SplashController()),
    ];
  }
}
