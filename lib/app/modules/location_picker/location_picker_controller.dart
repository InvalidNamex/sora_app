import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerController extends GetxController {
  static LocationPickerController get to => Get.find();

  final selectedLatLng = Rxn<LatLng>();
  late final MapController mapController;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    final args = Get.arguments;
    if (args is LatLng) {
      selectedLatLng.value = args;
    }
  }

  void setLocation(LatLng point) {
    selectedLatLng.value = point;
  }

  void confirm() {
    Get.back(result: selectedLatLng.value);
  }
}
