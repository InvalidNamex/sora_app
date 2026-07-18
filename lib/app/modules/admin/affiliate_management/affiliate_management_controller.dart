import 'dart:async';

import 'package:get/get.dart';

import '../../../core/models/affiliate_program_models.dart';
import '../../../core/models/payout_request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/affiliate_program_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_snackbar.dart';

class AffiliateManagementController extends GetxController {
  static AffiliateManagementController get to => Get.find();

  final pendingApplications = <AffiliateApplicationModel>[].obs;
  final loadingApplications = true.obs;
  final pendingPayouts = <PayoutRequestModel>[].obs;
  final loadingPayouts = true.obs;
  final reviewingId = Rxn<int>();

  // ── Users tab ────────────────────────────────────────────────────────────
  final searchResults = <UserModel>[].obs;
  final loadingUsers = false.obs;
  Timer? _debounce;

  @override
  void onReady() {
    super.onReady();
    fetchQueues();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // ── Payouts ───────────────────────────────────────────────────────────────

  Future<void> fetchQueues() async {
    loadingApplications.value = true;
    loadingPayouts.value = true;
    try {
      final data = await AffiliateProgramService.getAdminQueue();
      pendingApplications.value = ((data['applications'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (row) => AffiliateApplicationModel.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();
      pendingPayouts.value = ((data['payouts'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => PayoutRequestModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    } finally {
      loadingApplications.value = false;
      loadingPayouts.value = false;
    }
  }

  Future<void> reviewApplication(
    int id, {
    required bool approve,
    String adminNote = '',
  }) async {
    reviewingId.value = id;
    try {
      await AffiliateProgramService.reviewApplication(
        applicationId: id,
        approve: approve,
        adminNote: adminNote,
      );
      pendingApplications.removeWhere((application) => application.id == id);
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    } finally {
      reviewingId.value = null;
    }
  }

  Future<void> reviewPayout(
    int id, {
    required bool paid,
    String? paymentReference,
    String adminNote = '',
  }) async {
    reviewingId.value = id;
    try {
      await AffiliateProgramService.reviewPayout(
        requestId: id,
        paid: paid,
        paymentReference: paymentReference,
        adminNote: adminNote,
      );
      pendingPayouts.removeWhere((request) => request.id == id);
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    } finally {
      reviewingId.value = null;
    }
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
    try {
      await AffiliateProgramService.setAffiliateStatus(
        userId: userId,
        isAffiliate: !current,
      );
      final idx = searchResults.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        final updated = UserModel.fromJson({
          ...searchResults[idx].toJson(),
          'isAffiliate': !current,
        });
        searchResults[idx] = updated;
        searchResults.refresh();
      }
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    }
  }
}
