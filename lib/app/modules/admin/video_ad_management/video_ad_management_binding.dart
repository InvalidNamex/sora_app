import 'package:get/get.dart';

import 'video_ad_management_controller.dart';

class VideoAdManagementBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<VideoAdManagementController>(
      () => VideoAdManagementController(),
    ),
  ];
}
