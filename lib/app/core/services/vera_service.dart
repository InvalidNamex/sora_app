import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vera_response_model.dart';
import 'supabase_service.dart';

class VeraException implements Exception {
  const VeraException(this.message, {this.code = 'service_error'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

class VeraService {
  VeraService._();

  static Future<VeraResponseModel> send({
    required String message,
    required String locale,
    required VeraSessionContext context,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw const VeraException(
        'Authentication required',
        code: 'unauthorized',
      );
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        'perfume-assistant',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'message': message.trim(),
          'locale': locale == 'ar' ? 'ar' : 'en',
          'context': context.toJson(),
        },
      );
      final raw = response.data;
      if (raw is! Map) {
        throw const VeraException('Vera returned an invalid response');
      }
      final data = Map<String, dynamic>.from(raw);
      if (response.status < 200 || response.status >= 300) {
        throw VeraException(
          (data['message'] as String?)?.trim() ?? 'Vera is unavailable',
          code: (data['code'] as String?)?.trim() ?? 'service_error',
        );
      }
      return VeraResponseModel.fromJson(data);
    } on VeraException {
      rethrow;
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map) {
        throw VeraException(
          (details['message'] as String?)?.trim() ?? 'Vera is unavailable',
          code: (details['code'] as String?)?.trim() ?? 'service_error',
        );
      }
      throw VeraException(error.reasonPhrase ?? 'Vera is unavailable');
    }
  }
}
