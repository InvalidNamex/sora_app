import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../models/affiliate_program_models.dart';
import 'supabase_service.dart';

class AffiliateProgramException implements Exception {
  const AffiliateProgramException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AffiliateProgramService {
  AffiliateProgramService._();

  static final _storage = GetStorage();
  static AffiliateCodeProfile? _cachedProfile;

  static String normalizeCode(String? value) {
    return (value ?? '').trim().toUpperCase();
  }

  static String promoCodeFromInput(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) return '';

    final uri = Uri.tryParse(input);
    if (uri != null) {
      final queryCode = uri.queryParameters['ref'];
      if (queryCode != null && queryCode.isNotEmpty) {
        return normalizeCode(queryCode);
      }

      final segments = uri.pathSegments;
      final refIndex = segments.indexWhere(
        (segment) => segment.toLowerCase() == 'ref',
      );
      if (refIndex >= 0 && refIndex + 1 < segments.length) {
        return normalizeCode(segments[refIndex + 1]);
      }
    }

    final embeddedCode = RegExp(
      r'(?:[?&]ref=|/ref/)([a-z0-9]{4,20})(?:[^a-z0-9]|$)',
      caseSensitive: false,
    ).firstMatch(input);
    return normalizeCode(embeddedCode?.group(1) ?? input);
  }

  static String? get activeCode {
    final value = normalizeCode(
      _storage.read<String>(AppConstants.kActiveAffiliateCode),
    );
    return value.isEmpty ? null : value;
  }

  static String? get activeSource {
    final value = _storage.read<String>(AppConstants.kActiveAffiliateSource);
    return value == 'link' || value == 'manual' ? value : null;
  }

  static Future<void> captureLinkCode(String? value, {int? itemId}) async {
    final code = normalizeCode(value);
    if (!RegExp(r'^[A-Z0-9]{4,20}$').hasMatch(code)) return;

    await _rememberCode(code, source: 'link');
    unawaited(syncPendingAttribution(itemId: itemId));
  }

  static Future<void> rememberManualAffiliateCode(String code) {
    return _rememberCode(normalizeCode(code), source: 'manual');
  }

  static Future<void> rememberAffiliateCode(
    String code, {
    required String source,
  }) {
    return _rememberCode(
      normalizeCode(code),
      source: source == 'link' ? 'link' : 'manual',
    );
  }

  static Future<void> _rememberCode(
    String code, {
    required String source,
  }) async {
    await _storage.write(AppConstants.kActiveAffiliateCode, code);
    await _storage.write(AppConstants.kActiveAffiliateSource, source);
  }

  static Future<void> clearActiveAttribution() async {
    await _storage.remove(AppConstants.kActiveAffiliateCode);
    await _storage.remove(AppConstants.kActiveAffiliateSource);
  }

  static Future<void> syncPendingAttribution({int? itemId}) async {
    final code = activeCode;
    if (code == null || activeSource != 'link') return;
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      await _invoke('save_attribution', {
        'code': code,
        'item_id': ?itemId,
      }, requiresAuth: true);
    } on AffiliateProgramException catch (e) {
      debugPrint('[AffiliateProgramService] attribution sync failed: $e');
      if (e.message.contains('Invalid affiliate code') ||
          e.message.contains('own code')) {
        await clearActiveAttribution();
      }
    } catch (e) {
      debugPrint('[AffiliateProgramService] attribution sync failed: $e');
    }
  }

  static Future<PromoCodeValidation> validateCode({
    required String code,
    required double subtotal,
  }) async {
    final normalizedCode = promoCodeFromInput(code);
    final data = await _invoke('validate_code', {
      'code': normalizedCode,
      'subtotal': subtotal,
      'check_self': FirebaseAuth.instance.currentUser != null,
    }, requiresAuth: FirebaseAuth.instance.currentUser != null);
    return PromoCodeValidation.fromJson(data);
  }

  static Future<Map<String, dynamic>> placeOrder({
    required int addressId,
    required String phone,
    required String notes,
    String? promoCode,
    String? affiliateSource,
  }) {
    return _invoke('place_order', {
      'address_id': addressId,
      'phone': phone,
      'notes': notes,
      'promo_code': promoCodeFromInput(promoCode),
      'affiliate_source': affiliateSource,
    }, requiresAuth: true);
  }

  static Future<AffiliateCodeProfile> getMyProfile({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedProfile != null) return _cachedProfile!;
    final data = await _invoke(
      'affiliate_profile',
      const {},
      requiresAuth: true,
    );
    final profile = AffiliateCodeProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map),
    );
    _cachedProfile = profile;
    return profile;
  }

  static Future<Map<String, dynamic>?> getActiveAttribution() async {
    final data = await _invoke(
      'active_attribution',
      const {},
      requiresAuth: true,
    );
    final attribution = data['attribution'];
    if (attribution is! Map) return null;
    return Map<String, dynamic>.from(attribution);
  }

  static Future<Map<String, dynamic>> getDashboard() {
    return _invoke('affiliate_dashboard', const {}, requiresAuth: true);
  }

  static Future<Map<String, dynamic>> getApplicationStatus() {
    return _invoke(
      'affiliate_application_status',
      const {},
      requiresAuth: true,
    );
  }

  static Future<Map<String, dynamic>> submitApplication({
    required String preferredCode,
    required String message,
  }) {
    return _invoke('submit_affiliate_application', {
      'preferred_code': normalizeCode(preferredCode),
      'message': message.trim(),
    }, requiresAuth: true);
  }

  static Future<Map<String, dynamic>> getAdminQueue() {
    return _invoke('admin_affiliate_queue', const {}, requiresAuth: true);
  }

  static Future<Map<String, dynamic>> reviewApplication({
    required int applicationId,
    required bool approve,
    String adminNote = '',
  }) {
    return _invoke('review_affiliate_application', {
      'application_id': applicationId,
      'decision': approve ? 'approve' : 'reject',
      'admin_note': adminNote.trim(),
    }, requiresAuth: true);
  }

  static Future<Map<String, dynamic>> reviewPayout({
    required int requestId,
    required bool paid,
    String? paymentReference,
    String adminNote = '',
  }) {
    return _invoke('review_payout', {
      'request_id': requestId,
      'decision': paid ? 'paid' : 'reject',
      'payment_reference': paymentReference?.trim(),
      'admin_note': adminNote.trim(),
    }, requiresAuth: true);
  }

  static Future<Map<String, dynamic>> setAffiliateStatus({
    required int userId,
    required bool isAffiliate,
  }) {
    return _invoke('set_affiliate_status', {
      'user_id': userId,
      'is_affiliate': isAffiliate,
    }, requiresAuth: true);
  }

  static Future<AffiliateCodeProfile> updateMyCode(String value) async {
    final data = await _invoke('update_code', {
      'code': normalizeCode(value),
    }, requiresAuth: true);
    final profile = AffiliateCodeProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map),
    );
    _cachedProfile = profile;
    return profile;
  }

  static Future<Map<String, dynamic>> requestPayout({
    required String payoutMethod,
    required String payoutAccount,
  }) {
    return _invoke('request_payout', {
      'payout_method': payoutMethod,
      'payout_account': payoutAccount.trim(),
    }, requiresAuth: true);
  }

  static void clearSessionCache() {
    _cachedProfile = null;
  }

  static Future<Map<String, dynamic>> _invoke(
    String action,
    Map<String, dynamic> body, {
    required bool requiresAuth,
  }) async {
    final headers = <String, String>{};
    if (requiresAuth) {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        throw const AffiliateProgramException('Authentication required');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        'affiliate-program',
        headers: headers,
        body: {'action': action, ...body},
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300) {
        throw AffiliateProgramException(_messageFrom(data));
      }
      if (data is! Map) {
        throw const AffiliateProgramException('Invalid server response');
      }
      return Map<String, dynamic>.from(data);
    } on FunctionException catch (e) {
      throw AffiliateProgramException(_messageFrom(e.details));
    }
  }

  static String _messageFrom(Object? value) {
    if (value is Map && value['error'] is String) {
      return value['error'] as String;
    }
    if (value is String && value.trim().isNotEmpty) return value;
    return 'Affiliate request failed';
  }
}
