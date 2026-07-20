import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerController extends GetxController {
  static LocationPickerController get to => Get.find();

  final selectedLatLng = Rxn<LatLng>();
  final isLocating = false.obs;
  final locationErrorKey = RxnString();
  final permissionDeniedForever = false.obs;
  final locationServicesDisabled = false.obs;
  late final MapController mapController;
  bool _mapReady = false;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    final args = Get.arguments;
    if (args is LatLng) {
      selectedLatLng.value = args;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (selectedLatLng.value == null) {
      findCurrentLocation();
    }
  }

  void onMapReady() {
    _mapReady = true;
    _moveToSelected();
  }

  void setLocation(LatLng point) {
    selectedLatLng.value = point;
    locationErrorKey.value = null;
  }

  Future<void> findCurrentLocation() async {
    if (isLocating.value) return;
    isLocating.value = true;
    locationErrorKey.value = null;
    permissionDeniedForever.value = false;
    locationServicesDisabled.value = false;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        locationErrorKey.value = 'location_permission_denied';
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        permissionDeniedForever.value = true;
        locationErrorKey.value = 'location_permission_denied_forever';
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationServicesDisabled.value = true;
        locationErrorKey.value = _opensAppSettingsForLocationSettings
            ? 'location_services_disabled_ios'
            : 'location_services_disabled';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      selectedLatLng.value = LatLng(position.latitude, position.longitude);
      _moveToSelected();
    } catch (e) {
      debugPrint('[LocationPickerController] current location error: $e');
      locationErrorKey.value = 'location_unavailable';
    } finally {
      isLocating.value = false;
    }
  }

  bool get canOpenLocationSettings {
    if (kIsWeb) return false;
    if (permissionDeniedForever.value) return true;
    if (locationServicesDisabled.value &&
        _opensAppSettingsForLocationSettings) {
      return false;
    }
    return locationServicesDisabled.value;
  }

  Future<void> openLocationSettings() async {
    if (!canOpenLocationSettings) return;
    if (permissionDeniedForever.value) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }
  }

  void _moveToSelected() {
    final point = selectedLatLng.value;
    if (!_mapReady || point == null) return;
    mapController.move(point, 16);
  }

  void confirm() {
    Get.back(result: selectedLatLng.value);
  }

  bool get _opensAppSettingsForLocationSettings =>
      defaultTargetPlatform == TargetPlatform.iOS;
}
