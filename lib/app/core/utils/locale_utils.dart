import 'package:flutter/material.dart';
import 'package:get/get.dart';

const supportedAppLocaleCodes = ['ar', 'en'];

bool isEnglishLocale([Locale? locale]) {
  final resolvedLocale = locale ??
      Get.locale ??
      WidgetsBinding.instance.platformDispatcher.locale;
  return resolvedLocale.languageCode.toLowerCase() == 'en';
}

String? normalizeAppLocaleCode(String? code) {
  final normalized = code?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  return supportedAppLocaleCodes.contains(normalized) ? normalized : null;
}

String firstNonEmptyString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
  }
  return '';
}

String localizedString(
  Map<String, dynamic> json, {
  required List<String> primaryKeys,
  required List<String> englishKeys,
}) {
  if (isEnglishLocale()) {
    final englishValue = firstNonEmptyString(json, englishKeys);
    if (englishValue.isNotEmpty) return englishValue;
  }

  final primaryValue = firstNonEmptyString(json, primaryKeys);
  if (primaryValue.isNotEmpty) return primaryValue;

  return firstNonEmptyString(json, englishKeys);
}