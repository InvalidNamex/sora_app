import 'package:firebase_auth/firebase_auth.dart';

import '../models/admin_notification_model.dart';
import 'supabase_service.dart';

class AdminNotificationService {
  AdminNotificationService._();

  static Future<List<AdminNotificationModel>> fetch({int limit = 100}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];

    final rows = await SupabaseService.client
        .from('admin_notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    final reads = await SupabaseService.client
        .from('admin_notification_reads')
        .select('notification_id')
        .eq('admin_uid', uid);
    final dismissals = await SupabaseService.client
        .from('admin_notification_dismissals')
        .select('notification_id')
        .eq('admin_uid', uid);
    final readIds = (reads as List)
        .map((row) => (row['notification_id'] as num?)?.toInt())
        .whereType<int>()
        .toSet();
    final dismissedIds = (dismissals as List)
        .map((row) => (row['notification_id'] as num?)?.toInt())
        .whereType<int>()
        .toSet();

    return (rows as List)
        .where((row) => !dismissedIds.contains((row['id'] as num).toInt()))
        .map(
          (row) => AdminNotificationModel.fromJson(
            Map<String, dynamic>.from(row as Map),
            isRead: readIds.contains((row['id'] as num).toInt()),
          ),
        )
        .toList(growable: false);
  }

  static Future<void> markRead(int notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await SupabaseService.client.from('admin_notification_reads').upsert({
      'notification_id': notificationId,
      'admin_uid': uid,
    });
  }

  static Future<void> dismiss(int notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await SupabaseService.client.from('admin_notification_dismissals').upsert({
      'notification_id': notificationId,
      'admin_uid': uid,
    });
  }
}
