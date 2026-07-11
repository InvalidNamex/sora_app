import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_constants.dart';

enum AppSnackbarType { info, success, warning, error }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    String title,
    String message, {
    AppSnackbarType type = AppSnackbarType.info,
    SnackPosition snackPosition = SnackPosition.bottom,
    Duration duration = const Duration(seconds: 3),
  }) {
    final backgroundColor = _backgroundFor(type);
    final textColor = _textFor(type);

    Get.snackbar(
      title,
      message,
      snackPosition: snackPosition,
      backgroundColor: backgroundColor,
      colorText: textColor,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: duration,
    );
  }

  static Color _backgroundFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return AppConstants.snackbarSuccess;
      case AppSnackbarType.warning:
        return AppConstants.snackbarWarning;
      case AppSnackbarType.error:
        return AppConstants.snackbarError;
      case AppSnackbarType.info:
        return AppConstants.snackbarInfo;
    }
  }

  static Color _textFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.warning:
        return AppConstants.snackbarTextDark;
      case AppSnackbarType.info:
      case AppSnackbarType.success:
      case AppSnackbarType.error:
        return AppConstants.snackbarTextLight;
    }
  }
}