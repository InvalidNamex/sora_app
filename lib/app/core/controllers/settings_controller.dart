import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/app_constants.dart';

/// Handles theme mode and locale persistence via get_storage.
class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  final _box = GetStorage();

  /// Reactive dark-mode flag — observe this in Obx() widgets.
  late final isDark = _loadIsDark().obs;

  /// Reactive locale code — observe this in Obx() widgets.
  late final localeCode = _loadLocaleCode().obs;

  // ── Plain getters used by GetMaterialApp at startup ──────────────
  ThemeMode get themeMode =>
      isDark.value ? ThemeMode.dark : ThemeMode.light;

  Locale get locale => Locale(localeCode.value);

  // ── Init helpers ─────────────────────────────────────────────────
  bool _loadIsDark() =>
      _box.read<String>(AppConstants.kThemeMode) == 'dark';

  String _loadLocaleCode() =>
      _box.read<String>(AppConstants.kLocale) ?? 'ar';

  // ── Actions ──────────────────────────────────────────────────────
  void toggleTheme() {
    isDark.toggle();
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    _box.write(AppConstants.kThemeMode, isDark.value ? 'dark' : 'light');
  }

  void changeLocale(String code) {
    localeCode.value = code;
    Get.updateLocale(Locale(code));
    _box.write(AppConstants.kLocale, code);
  }
}
