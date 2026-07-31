import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/core/controllers/settings_controller.dart';

void main() {
  group('first-launch settings', () {
    test('uses the device brightness when no theme was saved', () {
      expect(resolveInitialDarkMode(null, Brightness.dark), isTrue);
      expect(resolveInitialDarkMode(null, Brightness.light), isFalse);
    });

    test('saved theme takes precedence over device brightness', () {
      expect(resolveInitialDarkMode('light', Brightness.dark), isFalse);
      expect(resolveInitialDarkMode('dark', Brightness.light), isTrue);
    });

    test('uses the first supported device locale', () {
      expect(
        resolveInitialLocaleCode(null, const [
          Locale('fr'),
          Locale('ar', 'EG'),
          Locale('en'),
        ]),
        'ar',
      );
    });

    test('saved locale takes precedence over device locales', () {
      expect(resolveInitialLocaleCode('en', const [Locale('ar', 'EG')]), 'en');
    });
  });
}
