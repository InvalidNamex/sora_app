import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AccountDeletionService {
  AccountDeletionService._();

  static Future<void> deleteCurrentAccount() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const AccountDeletionException(
        'Please sign in again before deleting your account.',
      );
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer $token'},
        body: const {'confirmation': 'DELETE'},
      );
      if (response.status < 200 || response.status >= 300) {
        throw AccountDeletionException(_messageFrom(response.data));
      }

      final data = response.data;
      if (data is! Map || data['deleted'] != true) {
        throw const AccountDeletionException(
          'The server could not confirm account deletion.',
        );
      }
    } on FunctionException catch (error) {
      throw AccountDeletionException(_messageFrom(error.details));
    }
  }

  static String _messageFrom(Object? value) {
    if (value is Map) {
      for (final key in const ['error', 'message', 'details', 'hint']) {
        final candidate = value[key];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate;
        }
      }
    }
    if (value is String && value.trim().isNotEmpty) return value;
    return 'Could not delete the account. Please try again.';
  }
}
