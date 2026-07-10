import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase initialization and client access.
///
/// NOTE: Per-user data isolation relies on Supabase third-party auth using the
/// Firebase JWT plus RLS policies. The anon key alone does NOT provide
/// per-user security — RLS must be configured in the Supabase project.
class SupabaseService {
  SupabaseService._();

  static Future<void> init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
