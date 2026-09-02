import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/models/admin_notification_model.dart';
import '../../../core/services/admin_notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/auth_controller.dart';

class AdminNotificationInboxController extends GetxController {
  static AdminNotificationInboxController get to => Get.find();

  final notifications = <AdminNotificationModel>[].obs;
  final isLoading = false.obs;
  Timer? _refreshTimer;
  Worker? _authWorker;
  bool _isProcessingPushQueue = false;

  bool get isAdmin => AuthController.to.currentUser.value?.isAdmin == true;
  int get unreadCount => notifications.where((item) => !item.isRead).length;

  @override
  void onReady() {
    super.onReady();
    _authWorker = ever(AuthController.to.currentUser, (_) => _syncForUser());
    _syncForUser();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncForUser(silent: true),
    );
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> _syncForUser({bool silent = false}) async {
    if (!isAdmin) {
      notifications.clear();
      return;
    }
    if (!silent) isLoading.value = true;
    try {
      // Keep the RxList's backing store growable. Assigning a fixed-length
      // list via `.value` makes a later sign-out `.clear()` throw.
      notifications.assignAll(await AdminNotificationService.fetch(limit: 100));
      unawaited(_processPendingPushJobs());
    } catch (error) {
      debugPrint('[AdminNotificationInboxController] refresh error: $error');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() => _syncForUser();

  Future<void> _processPendingPushJobs() async {
    if (_isProcessingPushQueue) return;
    _isProcessingPushQueue = true;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) return;
      await SupabaseService.client.functions.invoke(
        'process-notification-jobs',
        headers: {'Authorization': 'Bearer $token'},
        body: {'limit': 50},
      );
    } catch (error) {
      debugPrint('[AdminNotificationInboxController] push queue error: $error');
    } finally {
      _isProcessingPushQueue = false;
    }
  }
}
