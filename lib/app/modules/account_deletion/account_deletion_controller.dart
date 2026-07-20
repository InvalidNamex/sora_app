import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/account_deletion_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../auth/auth_controller.dart';

class AccountDeletionController extends GetxController {
  final confirmationController = TextEditingController();
  final understandsConsequences = false.obs;
  final isDeleting = false.obs;
  final confirmationText = ''.obs;

  bool get canDelete =>
      understandsConsequences.value &&
      confirmationText.value.trim().toUpperCase() == 'DELETE' &&
      !isDeleting.value;

  @override
  void onInit() {
    super.onInit();
    confirmationController.addListener(() {
      confirmationText.value = confirmationController.text;
    });
  }

  @override
  void onClose() {
    confirmationController.dispose();
    super.onClose();
  }

  Future<void> deleteAccount() async {
    if (!canDelete || AuthController.to.currentUser.value == null) return;

    try {
      isDeleting.value = true;
      await AuthController.to.revokeAppleTokenForAccountDeletion();
      await AccountDeletionService.deleteCurrentAccount();
      await AuthController.to.finishAccountDeletion();
      AppSnackbar.show(
        'account_deleted'.tr,
        'account_deleted_message'.tr,
        type: AppSnackbarType.success,
      );
    } catch (error) {
      AppSnackbar.show(
        'account_deletion_failed'.tr,
        error.toString(),
        type: AppSnackbarType.error,
        duration: const Duration(seconds: 7),
      );
    } finally {
      isDeleting.value = false;
    }
  }
}
