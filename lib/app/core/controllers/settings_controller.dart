import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';

import '../constants/app_constants.dart';
import '../utils/locale_utils.dart';

/// Handles theme mode and locale persistence via get_storage.
class SettingsController extends GetxController {
  SettingsController._({
    required GetStorage storage,
    required bool initialIsDark,
    required String initialLocaleCode,
  }) : _box = storage,
       isDark = initialIsDark.obs,
       localeCode = initialLocaleCode.obs;

  static SettingsController get to => Get.find();

  final GetStorage _box;

  /// Reactive dark-mode flag — observe this in Obx() widgets.
  final RxBool isDark;

  /// Reactive locale code — observe this in Obx() widgets.
  final RxString localeCode;

  /// Resolves and persists first-launch device preferences before [runApp].
  static Future<SettingsController> load() async {
    final box = GetStorage();
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final storedMode = box.read<String>(AppConstants.kThemeMode);
    final storedLocale = box.read<String>(AppConstants.kLocale);
    final isDark = resolveInitialDarkMode(
      storedMode,
      dispatcher.platformBrightness,
    );
    final localeCode = resolveInitialLocaleCode(
      storedLocale,
      dispatcher.locales,
    );

    await Future.wait([
      box.writeIfNull(AppConstants.kThemeMode, isDark ? 'dark' : 'light'),
      box.writeIfNull(AppConstants.kLocale, localeCode),
    ]);

    return SettingsController._(
      storage: box,
      initialIsDark: isDark,
      initialLocaleCode: localeCode,
    );
  }

  // ── Plain getters used by GetMaterialApp at startup ──────────────
  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  Locale get locale => Locale(localeCode.value);

  // ── Actions ──────────────────────────────────────────────────────
  Future<void> toggleTheme() async {
    isDark.toggle();
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    await _box.write(AppConstants.kThemeMode, isDark.value ? 'dark' : 'light');
  }

  Future<void> changeLocale(String code) async {
    final normalized = normalizeAppLocaleCode(code) ?? 'en';
    localeCode.value = normalized;
    Get.updateLocale(Locale(normalized));
    await _box.write(AppConstants.kLocale, normalized);
  }
}

bool resolveInitialDarkMode(String? storedMode, Brightness platformBrightness) {
  if (storedMode == 'dark') return true;
  if (storedMode == 'light') return false;
  return platformBrightness == Brightness.dark;
}

String resolveInitialLocaleCode(
  String? storedLocale,
  Iterable<Locale> platformLocales,
) {
  final normalizedStored = normalizeAppLocaleCode(storedLocale);
  if (normalizedStored != null) return normalizedStored;

  for (final locale in platformLocales) {
    final code = normalizeAppLocaleCode(locale.languageCode);
    if (code != null) return code;
  }
  return 'en';
}
