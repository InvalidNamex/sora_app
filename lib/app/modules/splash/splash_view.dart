import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../global_widgets/custom_loader.dart';
import 'splash_controller.dart';

/// Centers the brand logo with the custom loader while the app boots.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CustomLoader(size: 120),
      ),
    );
  }
}
