import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/models/liked_item_model.dart';
import '../../core/services/supabase_service.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';

class WishlistController extends GetxController {
  static WishlistController get to => Get.find();

  final likedItems = <LikedItemModel>[].obs;
  final isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    fetchLikedItems();
  }

  Future<void> fetchLikedItems() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('liked_items')
          .select(
          'id, itemID, items(id, itemName, item_properties(id, image, price, inStock, size))')
          .eq('userID', userId);
      likedItems.value = (response as List)
          .map((e) => LikedItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[WishlistController] fetchLikedItems error: $e');
      likedItems.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  bool isLiked(int itemId) =>
      likedItems.any((l) => l.itemId == itemId);

  Future<void> toggleLike(int itemId) async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) {
      Get.toNamed(Routes.auth);
      Get.snackbar(
        'login_required'.tr,
        'login_required'.tr,
        snackPosition: SnackPosition.bottom,
      );
      return;
    }

    final existing =
        likedItems.firstWhereOrNull((l) => l.itemId == itemId);
    if (existing != null) {
      await SupabaseService.client
          .from('liked_items')
          .delete()
          .eq('id', existing.id);
      likedItems.removeWhere((l) => l.itemId == itemId);
    } else {
      await SupabaseService.client.from('liked_items').insert({
        'userID': userId,
        'itemID': itemId,
      });
      await fetchLikedItems();
    }
  }
}
