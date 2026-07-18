import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/affiliate_program_models.dart';
import '../../core/models/order_master_model.dart';
import '../../core/models/payout_request_model.dart';
import '../../core/services/affiliate_program_service.dart';
import '../../core/services/share_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../auth/auth_controller.dart';

class AffiliateController extends GetxController {
  static AffiliateController get to => Get.find();

  final profile = Rxn<AffiliateCodeProfile>();
  final referredOrders = <OrderMasterModel>[].obs;
  final payoutHistory = <PayoutRequestModel>[].obs;
  final totalEarnings = 0.0.obs;
  final pendingEarnings = 0.0.obs;
  final availableBalance = 0.0.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final isSavingCode = false.obs;
  final payoutMethod = 'mobile_wallet'.obs;
  final codeCtrl = TextEditingController();
  final payoutAccountCtrl = TextEditingController();

  String get affiliateLink {
    final code = profile.value?.code ?? '';
    final baseDomain = AppConstants.baseDomain.replaceFirst(RegExp(r'/$'), '');
    return code.isEmpty ? baseDomain : '$baseDomain/ref/$code';
  }

  @override
  void onReady() {
    super.onReady();
    payoutAccountCtrl.text = AuthController.to.currentUser.value?.phone ?? '';
    fetchData();
  }

  @override
  void onClose() {
    codeCtrl.dispose();
    payoutAccountCtrl.dispose();
    super.onClose();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      final data = await AffiliateProgramService.getDashboard();
      final profileData = data['profile'];
      if (profileData is Map) {
        profile.value = AffiliateCodeProfile.fromJson(
          Map<String, dynamic>.from(profileData),
        );
        codeCtrl.text = profile.value!.code;
      }

      totalEarnings.value = (data['total_earnings'] as num?)?.toDouble() ?? 0;
      pendingEarnings.value =
          (data['pending_earnings'] as num?)?.toDouble() ?? 0;
      availableBalance.value =
          (data['available_balance'] as num?)?.toDouble() ?? 0;

      referredOrders.value = ((data['orders'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (row) => OrderMasterModel.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
      payoutHistory.value = ((data['payouts'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (row) =>
                PayoutRequestModel.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCode() async {
    isSavingCode.value = true;
    try {
      final updated = await AffiliateProgramService.updateMyCode(codeCtrl.text);
      profile.value = updated;
      codeCtrl.text = updated.code;
      AppSnackbar.show(
        'success'.tr,
        'affiliate_code_updated'.tr,
        type: AppSnackbarType.success,
      );
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    } finally {
      isSavingCode.value = false;
    }
  }

  Future<void> shareCode(BuildContext context) async {
    final code = profile.value?.code;
    if (code == null || code.isEmpty) return;
    try {
      await ShareService.shareAffiliate(
        context: context,
        code: code,
        link: affiliateLink,
        message: 'share_affiliate_message'.tr,
      );
    } catch (e) {
      AppSnackbar.show(
        'error'.tr,
        'share_failed'.tr,
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> requestPayout() async {
    final account = payoutAccountCtrl.text.trim();
    if (account.length < 5) {
      AppSnackbar.show(
        'error'.tr,
        'payout_account_required'.tr,
        type: AppSnackbarType.error,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      await AffiliateProgramService.requestPayout(
        payoutMethod: payoutMethod.value,
        payoutAccount: account,
      );
      AppSnackbar.show(
        'success'.tr,
        'payout_requested'.tr,
        type: AppSnackbarType.success,
      );
      await fetchData();
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    } finally {
      isSubmitting.value = false;
    }
  }
}
