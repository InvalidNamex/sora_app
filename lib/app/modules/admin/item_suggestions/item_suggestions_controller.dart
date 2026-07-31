import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/models/item_suggestion_model.dart';
import '../../../core/services/item_suggestion_service.dart';
import '../../../core/utils/app_snackbar.dart';

class ItemSuggestionsController extends GetxController {
  final suggestions = <ItemSuggestionModel>[].obs;
  final isLoading = true.obs;
  final reviewingId = Rxn<int>();
  final statusFilter = 'all'.obs;

  @override
  void onReady() {
    super.onReady();
    fetchSuggestions();
  }

  Future<void> setStatusFilter(String status) async {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
    await fetchSuggestions();
  }

  Future<void> fetchSuggestions() async {
    isLoading.value = true;
    try {
      suggestions.value = await ItemSuggestionService.fetchAdmin(
        status: statusFilter.value,
      );
    } catch (error) {
      debugPrint('[ItemSuggestionsController] load error: $error');
      AppSnackbar.show(
        'error'.tr,
        'suggestions_load_failed'.tr,
        type: AppSnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> review(
    ItemSuggestionModel suggestion, {
    required String status,
    required String adminNote,
  }) async {
    reviewingId.value = suggestion.id;
    try {
      await ItemSuggestionService.review(
        id: suggestion.id,
        status: status,
        adminNote: adminNote,
      );
      await fetchSuggestions();
      AppSnackbar.show(
        'success'.tr,
        'suggestion_updated'.tr,
        type: AppSnackbarType.success,
      );
      return true;
    } catch (error) {
      debugPrint('[ItemSuggestionsController] review error: $error');
      AppSnackbar.show(
        'error'.tr,
        'suggestion_update_failed'.tr,
        type: AppSnackbarType.error,
      );
      return false;
    } finally {
      reviewingId.value = null;
    }
  }
}
