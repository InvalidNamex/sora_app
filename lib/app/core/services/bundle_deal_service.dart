import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bundle_deal_model.dart';
import 'supabase_service.dart';

class BundleDealService {
  BundleDealService._();

  static const bundleSelect =
      'id, title, titleEN, description, descriptionEN, bannerImage, '
      'dealPrice, isActive, sortOrder, '
      'bundle_deal_items(id, bundleID, quantity, '
      'item_properties(id, itemID, size, image, PropertyDescription, '
      'propertyDescriptionEN, price, inStock, isDefault, '
      'items(itemName, itemNameEN)))';

  static Future<List<BundleDealModel>> fetchBundles({
    bool activeOnly = true,
  }) async {
    var query = SupabaseService.client
        .from('bundle_deals')
        .select(bundleSelect);
    if (activeOnly) query = query.eq('isActive', true);
    final response = await query
        .order('sortOrder')
        .order('id', ascending: false);
    return (response as List)
        .whereType<Map>()
        .map((row) => BundleDealModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<BundleDealModel> fetchBundle(int id) async {
    final response = await SupabaseService.client
        .from('bundle_deals')
        .select(bundleSelect)
        .eq('id', id)
        .single();
    return BundleDealModel.fromJson(response);
  }

  static Future<Map<String, dynamic>> createAdminUpload({
    required String extension,
  }) {
    return _invokeAdmin({'action': 'create_upload', 'extension': extension});
  }

  static Future<List<BundleDealModel>> fetchAdminBundles() async {
    final result = await _invokeAdmin({'action': 'list_bundles'});
    return ((result['bundles'] as List?) ?? const [])
        .whereType<Map>()
        .map((row) => BundleDealModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<int> saveBundle({
    int? id,
    required String title,
    required String titleEn,
    required String description,
    required String descriptionEn,
    required String bannerImage,
    required double dealPrice,
    required bool isActive,
    required int sortOrder,
    required Map<int, int> itemQuantities,
  }) async {
    final result = await _invokeAdmin({
      'action': 'save_bundle',
      'id': ?id,
      'title': title,
      'title_en': titleEn,
      'description': description,
      'description_en': descriptionEn,
      'banner_image': bannerImage,
      'deal_price': dealPrice,
      'is_active': isActive,
      'sort_order': sortOrder,
      'items': itemQuantities.entries
          .map((entry) => {'property_id': entry.key, 'quantity': entry.value})
          .toList(),
    });
    return (result['id'] as num?)?.toInt() ?? 0;
  }

  static Future<void> deleteBundle(int id) async {
    await _invokeAdmin({'action': 'delete_bundle', 'id': id});
  }

  static Future<Map<String, dynamic>> _invokeAdmin(
    Map<String, dynamic> body,
  ) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Authentication required');
    }
    try {
      final response = await SupabaseService.client.functions.invoke(
        'manage-bundles',
        headers: {'Authorization': 'Bearer $token'},
        body: body,
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300) {
        throw StateError(_messageFrom(data));
      }
      if (data is! Map) throw StateError('Invalid server response');
      return Map<String, dynamic>.from(data);
    } on FunctionException catch (e) {
      debugPrint('[BundleDealService] admin request failed: ${e.details}');
      throw StateError(_messageFrom(e.details));
    }
  }

  static String _messageFrom(Object? value) {
    if (value is Map) {
      for (final key in const ['message', 'error', 'details', 'hint']) {
        final candidate = value[key];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate;
        }
        if (candidate is Map) {
          final nested = _messageFrom(candidate);
          if (nested != 'Bundle request failed') return nested;
        }
      }
    }
    if (value is String && value.trim().isNotEmpty) return value;
    return 'Bundle request failed';
  }
}
