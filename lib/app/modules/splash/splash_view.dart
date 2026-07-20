import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import 'splash_controller.dart';

/// Keeps the Flutter boot screen visually continuous with the native splash.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'SORA',
          style: TextStyle(
            color: AppConstants.darkBeige,
            fontFamily: AppConstants.fontFamily,
            fontSize: 58,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
