import 'package:get/get.dart';

import 'location_picker_controller.dart';

class LocationPickerBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut(() => LocationPickerController()),
      ];
}
