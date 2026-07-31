import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item_suggestion_model.dart';
import 'supabase_service.dart';

class ItemSuggestionException implements Exception {
  const ItemSuggestionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ItemSuggestionService {
  ItemSuggestionService._();

  static Future<void> submit({
    required String itemName,
    required String brandName,
    required String details,
  }) async {
    await _invoke({
      'action': 'submit',
      'item_name': itemName.trim(),
      'brand_name': brandName.trim(),
      'details': details.trim(),
    });
  }

  static Future<List<ItemSuggestionModel>> fetchAdmin({
    String status = 'all',
  }) async {
    final data = await _invoke({'action': 'list', 'status': status});
    return ((data['suggestions'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (row) => ItemSuggestionModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  static Future<void> review({
    required int id,
    required String status,
    required String adminNote,
  }) async {
    await _invoke({
      'action': 'review',
      'id': id,
      'status': status,
      'admin_note': adminNote.trim(),
    });
  }

  static Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw const ItemSuggestionException('Authentication required');
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        'item-suggestions',
        headers: {'Authorization': 'Bearer $token'},
        body: body,
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300 || data is! Map) {
        throw ItemSuggestionException(_messageFrom(data));
      }
      return Map<String, dynamic>.from(data);
    } on FunctionException catch (error) {
      throw ItemSuggestionException(_messageFrom(error.details));
    }
  }

  static String _messageFrom(Object? value) {
    if (value is Map && value['error'] is String) {
      return value['error'] as String;
    }
    return 'Suggestion request failed';
  }
}
