import 'package:flutter/material.dart';

/// Central place for all compile-time constants (branding, company details,
/// remote endpoints, storage keys). See instructions.md §2.
class AppConstants {
  AppConstants._();

  // ── Branding colors ───────────────────────────────────────────────
  static const Color lightBeige = Color(0xFFF1F0E9);
  static const Color mediumBeige = Color(0xFFC7B69B);
  static const Color darkBeige = Color(0xFFB09263);

  // ── Snackbar palette (derived from brand theme) ─────────────────────────
  static const Color snackbarInfo = mediumBeige;
  static const Color snackbarSuccess = darkBeige;
  static const Color snackbarWarning = Color(0xFFE8D5B5);
  static const Color snackbarError = Color(0xFF7A5F3D);
  static const Color snackbarTextLight = Colors.white;
  static const Color snackbarTextDark = Color(0xFF3D2E1E);

  // ── Typography ────────────────────────────────────────────────────
  static const String fontFamily = 'ElMessiri';
  static const String fontFamilyAlt = 'Kufi';

  // ── Assets ────────────────────────────────────────────────────────
  static const String logoPath = 'assets/images/logo.png';
  static const String placeholderPath = 'assets/images/place_holder.png';

  // ── Company details ───────────────────────────────────────────────
  // TODO: Replace placeholders with the real support contacts.
  static const String supportEmail = 'support@sora-eg.store';
  static const String supportPhone = '+201111058359';
  static const String baseDomain = 'https://www.sora-eg.store/';
  static const String currency = 'EGP';
  static const String googleWebClientId =
      '295714444020-62m441kgcrulkq08jhocrf4mkn5hj5tu.apps.googleusercontent.com';

  // ── Storage keys (get_storage) ────────────────────────────────────
  static const String kThemeMode = 'theme_mode';
  static const String kGuestCart = 'guest_cart';
  static const String kGuestBundleCart = 'guest_bundle_cart';
  static const String kActiveAffiliateCode = 'active_affiliate_code';
  static const String kActiveAffiliateSource = 'active_affiliate_source';
  static const String kLocale = 'locale';
  static const String kCachedBanners = 'cached_banners';
  static const String kCachedCategories = 'cached_categories';
  static const String kCachedItems = 'cached_items';
  static const String kFilterGender = 'filter_gender';
  static const String kFilterInStock = 'filter_in_stock';
}
