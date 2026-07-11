import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import 'location_picker_controller.dart';

// Default center: Cairo, Egypt
const _kDefaultCenter = LatLng(30.0444, 31.2357);
const _kDefaultZoom = 14.0;

class LocationPickerPage extends GetView<LocationPickerController> {
  const LocationPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final initialCenter =
        controller.selectedLatLng.value ?? _kDefaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text('pick_location'.tr),
        backgroundColor: AppConstants.darkBeige,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: _kDefaultZoom,
              onTap: (_, point) => controller.setLocation(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sora.app',
              ),
              Obx(() {
                final latLng = controller.selectedLatLng.value;
                if (latLng == null) return const SizedBox.shrink();
                return MarkerLayer(
                  markers: [
                    Marker(
                      point: latLng,
                      width: 48,
                      height: 56,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),

          // Hint banner at top
          Obx(() {
            if (controller.selectedLatLng.value != null) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: 16,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'tap_to_pin'.tr,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),

          // Selected coordinates display
          Obx(() {
            final latLng = controller.selectedLatLng.value;
            if (latLng == null) return const SizedBox.shrink();
            return Positioned(
              top: 16,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.my_location,
                        size: 16, color: AppConstants.darkBeige),
                    const SizedBox(width: 6),
                    Text(
                      '${latLng.latitude.toStringAsFixed(6)}, '
                      '${latLng.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.darkBeige,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Confirm button at bottom
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: Obx(() => SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.darkBeige,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: controller.selectedLatLng.value == null
                        ? null
                        : controller.confirm,
                    icon: const Icon(Icons.check),
                    label: Text('confirm_location'.tr),
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
