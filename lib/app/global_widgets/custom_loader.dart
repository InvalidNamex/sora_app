import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_constants.dart';

/// Drives the color-fill animation for [CustomLoader].
///
/// Per instructions.md §3 this uses [GetSingleTickerProviderStateMixin] inside a
/// GetxController — never a StatefulWidget.
class LoaderController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animation;

  @override
  void onInit() {
    super.onInit();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void onClose() {
    animation.dispose();
    super.onClose();
  }
}

/// A brand-logo loader whose fill sweeps from bottom to top using the beige
/// palette. State/animation lives in [LoaderController], the widget is stateless.
class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoaderController(), tag: hashCode.toString());
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: controller.animation,
          builder: (context, child) {
            final t = controller.animation.value;
            return ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: const [
                    AppConstants.darkBeige,
                    AppConstants.mediumBeige,
                  ],
                  stops: [t, t],
                ).createShader(rect);
              },
              blendMode: BlendMode.srcATop,
              child: child,
            );
          },
          child: Image.asset(
            AppConstants.logoPath,
            width: size,
            height: size,
            color: AppConstants.lightBeige,
            colorBlendMode: BlendMode.srcATop,
          ),
        ),
      ),
    );
  }
}
