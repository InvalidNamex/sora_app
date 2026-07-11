import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/app_constants.dart';
import '../utils/locale_utils.dart';

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
  bool _loadIsDark() {
    final storedMode = _box.read<String>(AppConstants.kThemeMode);
    if (storedMode == 'dark') return true;
    if (storedMode == 'light') return false;

    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  String _loadLocaleCode() {
    final storedLocale =
        normalizeAppLocaleCode(_box.read<String>(AppConstants.kLocale));
    if (storedLocale != null) return storedLocale;

    return _preferredLocaleCode();
  }

  String _preferredLocaleCode() {
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
      final code = normalizeAppLocaleCode(locale.languageCode);
      if (code != null) return code;
    }

    return 'en';
  }

  // ── Actions ──────────────────────────────────────────────────────
  void toggleTheme() {
    isDark.toggle();
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    _box.write(AppConstants.kThemeMode, isDark.value ? 'dark' : 'light');
  }

  void changeLocale(String code) {
    final normalized = normalizeAppLocaleCode(code) ?? 'en';
    localeCode.value = normalized;
    Get.updateLocale(Locale(normalized));
    _box.write(AppConstants.kLocale, normalized);
  }
}
