import 'package:flutter/material.dart';

/// Central place for all compile-time constants (branding, company details,
/// remote endpoints, storage keys). See instructions.md §2.
class AppConstants {
  AppConstants._();

  // ── Branding colors ───────────────────────────────────────────────
  static const Color lightBeige = Color(0xFFF1F0E9);
  static const Color mediumBeige = Color(0xFFC7B69B);
  static const Color darkBeige = Color(0xFFB09263);

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

  // ── Storage keys (get_storage) ────────────────────────────────────
  static const String kThemeMode = 'theme_mode';
  static const String kGuestCart = 'guest_cart';
  static const String kActiveAffiliateId = 'active_affiliate_id';
  static const String kLocale = 'locale';
  static const String kCachedBanners = 'cached_banners';
  static const String kCachedCategories = 'cached_categories';
  static const String kCachedItems = 'cached_items';
}
