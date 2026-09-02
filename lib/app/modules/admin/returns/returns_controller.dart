import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../core/models/return_request_model.dart';
import '../../../core/services/return_request_service.dart';
import '../../../core/services/supabase_service.dart';

class ReturnsController extends GetxController {
  final requests = <ReturnRequestModel>[].obs;
  final isLoading = true.obs;
  final updatingId = Rxn<int>();
  static const statuses = [
    'Requested',
    'Under Review',
    'Approved',
    'Rejected',
    'Pickup Scheduled',
    'Received',
    'Completed',
    'Cancelled',
  ];
  @override
  void onReady() {
    super.onReady();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    try {
      requests.value = await ReturnRequestService.forAdmin();
    } catch (e) {
      debugPrint('[Returns] $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatus(ReturnRequestModel request, String status) async {
    updatingId.value = request.id;
    try {
      await ReturnRequestService.updateStatus(request.id, status);
      await fetch();
      final token = await fb.FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null && token.isNotEmpty) {
        await SupabaseService.client.functions.invoke(
          'process-notification-jobs',
          headers: {'Authorization': 'Bearer $token'},
          body: {'limit': 50},
        );
      }
    } finally {
      updatingId.value = null;
    }
  }
}
