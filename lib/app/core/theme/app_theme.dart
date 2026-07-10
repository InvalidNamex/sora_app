import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Light and dark themes built around the Sora beige palette.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppConstants.darkBeige,
      primary: AppConstants.darkBeige,
      secondary: AppConstants.mediumBeige,
      surface: AppConstants.lightBeige,
      brightness: Brightness.light,
    );
    return _base(scheme, AppConstants.lightBeige);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppConstants.darkBeige,
      primary: AppConstants.darkBeige,
      secondary: AppConstants.mediumBeige,
      brightness: Brightness.dark,
    );
    return _base(scheme, scheme.surface);
  }

  static ThemeData _base(ColorScheme scheme, Color scaffold) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: AppConstants.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.darkBeige,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
