import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/models/bundle_deal_model.dart';
import '../../core/services/bundle_deal_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../routes/app_pages.dart';
import '../cart/cart_controller.dart';

class BundleDetailController extends GetxController {
  static BundleDetailController get to => Get.find();

  final bundle = Rxn<BundleDealModel>();
  final quantity = 1.obs;
  final isLoading = true.obs;
  final isAdding = false.obs;

  double get regularTotal => (bundle.value?.regularPrice ?? 0) * quantity.value;
  double get dealTotal => (bundle.value?.dealPrice ?? 0) * quantity.value;
  bool get bundleInCart {
    final bundleId = bundle.value?.id;
    if (bundleId == null) return false;
    return CartController.to.bundleItems.any(
      (entry) => entry.bundle.id == bundleId,
    );
  }

  @override
  void onReady() {
    super.onReady();
    loadBundle();
  }

  Future<void> loadBundle() async {
    final passed = Get.arguments;
    if (passed is BundleDealModel) {
      bundle.value = passed;
      isLoading.value = false;
      return;
    }
    final id = int.tryParse(Get.parameters['id'] ?? '');
    if (id == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      bundle.value = await BundleDealService.fetchBundle(id);
    } catch (e, stackTrace) {
      debugPrint('[BundleDetailController] loadBundle error: $e');
      debugPrint('$stackTrace');
      AppSnackbar.show(
        'error'.tr,
        'bundle_load_failed'.tr,
        type: AppSnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void increment() => quantity.value++;

  void decrement() {
    if (quantity.value > 1) quantity.value--;
  }

  Future<void> handleCartAction() async {
    if (bundleInCart) {
      await Get.toNamed(Routes.checkout);
      return;
    }
    await addToCart();
  }

  Future<void> addToCart() async {
    final current = bundle.value;
    if (current == null || !current.isAvailable || isAdding.value) return;
    isAdding.value = true;
    try {
      await CartController.to.addBundle(current, quantity.value);
    } catch (e, stackTrace) {
      debugPrint('[BundleDetailController] addToCart error: $e');
      debugPrint('$stackTrace');
      AppSnackbar.show(
        'error'.tr,
        'bundle_add_failed'.tr,
        type: AppSnackbarType.error,
      );
    } finally {
      isAdding.value = false;
    }
  }
}
