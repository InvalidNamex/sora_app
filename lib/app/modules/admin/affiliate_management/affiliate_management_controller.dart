import 'dart:async';

import 'package:get/get.dart';

import '../../../core/models/payout_request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/supabase_service.dart';

class AffiliateManagementController extends GetxController {
  static AffiliateManagementController get to => Get.find();

  // ── Payouts tab ──────────────────────────────────────────────────────────
  final pendingPayouts = <PayoutRequestModel>[].obs;
  final loadingPayouts = true.obs;

  // ── Users tab ────────────────────────────────────────────────────────────
  final searchResults = <UserModel>[].obs;
  final loadingUsers = false.obs;
  Timer? _debounce;

  @override
  void onReady() {
    super.onReady();
    fetchPendingPayouts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // ── Payouts ───────────────────────────────────────────────────────────────

  Future<void> fetchPendingPayouts() async {
    loadingPayouts.value = true;
    try {
      final response = await SupabaseService.client
          .from('payout_requests')
          .select('*, users(name, phone)')
          .eq('status', 'Pending')
          .order('created_at', ascending: false);
      pendingPayouts.value = (response as List)
          .map((e) =>
              PayoutRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } finally {
      loadingPayouts.value = false;
    }
  }

  Future<void> approveRequest(int id) async {
    await SupabaseService.client
        .from('payout_requests')
        .update({'status': 'Approved'}).eq('id', id);
    pendingPayouts.removeWhere((p) => p.id == id);
  }

  Future<void> rejectRequest(int id) async {
    await SupabaseService.client
        .from('payout_requests')
        .update({'status': 'Rejected'}).eq('id', id);
    pendingPayouts.removeWhere((p) => p.id == id);
  }

  // ── User search ───────────────────────────────────────────────────────────

  void onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    loadingUsers.value = true;
    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .ilike('phone', '%$query%')
          .limit(20);
      searchResults.value = (response as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } finally {
      loadingUsers.value = false;
    }
  }

  Future<void> toggleAffiliateStatus(int userId, bool current) async {
    await SupabaseService.client
        .from('users')
        .update({'isAffiliate': !current}).eq('id', userId);
    // Refresh the matching row in searchResults
    final idx = searchResults.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final updated = UserModel.fromJson({
        ...searchResults[idx].toJson(),
        'isAffiliate': !current,
      });
      searchResults[idx] = updated;
      searchResults.refresh();
    }
  }
}
