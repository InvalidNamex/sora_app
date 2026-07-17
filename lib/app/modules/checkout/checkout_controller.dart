import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/address_model.dart';
import '../../core/models/promotion_model.dart';
import '../../core/models/voucher_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../history/history_controller.dart';
import '../navigation/nav_controller.dart';
import '../../routes/app_pages.dart';

class CheckoutController extends GetxController {
  static CheckoutController get to => Get.find();

  final addresses = <AddressModel>[].obs;
  final selectedAddress = Rxn<AddressModel>();
  final discount = 0.0.obs;
  final promoLoading = false.obs;
  final placingOrder = false.obs;
  final promoCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  double get cartTotal => CartController.to.totalPrice;
  double get finalTotal => (cartTotal - discount.value).clamp(0, double.infinity);

  @override
  void onReady() {
    super.onReady();
    loadAddresses();
    // Pre-populate phone from user profile.
    final user = AuthController.to.currentUser.value;
    if (user != null) {
      phoneCtrl.text = user.phoneTwo?.isNotEmpty == true ? user.phoneTwo! : user.phone;
    }
  }

  @override
  void onClose() {
    promoCtrl.dispose();
    notesCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }

  // ── Address ───────────────────────────────────────────────────────────────

    Future<void> loadAddresses() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;
    final previousSelectedId = selectedAddress.value?.id;
    final response = await SupabaseService.client
        .from('address_book')
        .select()
        .eq('userID', userId)
        .order('isDefault', ascending: false);
    addresses.value = (response as List)
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();

    selectedAddress.value =
      addresses.firstWhereOrNull((a) => a.id == previousSelectedId) ??
        addresses.firstWhereOrNull((a) => a.isDefault) ??
        addresses.firstOrNull;
  }

  void selectAddress(AddressModel addr) {
    selectedAddress.value = addr;
  }

  Future<void> refreshCheckout() async {
    await AuthController.to.refreshCurrentUser();
    final user = AuthController.to.currentUser.value;
    if (user != null) {
      phoneCtrl.text = user.phoneTwo?.isNotEmpty == true
          ? user.phoneTwo!
          : user.phone;
    }
    await loadAddresses();
    await CartController.to.refreshCart();
  }

  // ── Promo code ────────────────────────────────────────────────────────────

  Future<void> applyPromo() async {
    final code = promoCtrl.text.trim();
    if (code.isEmpty) return;
    promoLoading.value = true;
    try {
      // ── 1. Check vouchers ────────────────────────────────────────────────
      final voucherRes = await SupabaseService.client
          .from('vouchers')
          .select()
          .eq('voucherCode', code)
          .eq('isActive', true)
          .maybeSingle();

      if (voucherRes != null) {
        final voucher = VoucherModel.fromJson(voucherRes);
        if (voucher.voucherAmount != null) {
          discount.value = voucher.voucherAmount!;
        } else if (voucher.voucherPercentage != null) {
          discount.value = cartTotal * voucher.voucherPercentage! / 100;
        }
        AppSnackbar.show(
          'success'.tr,
          'voucher_applied'.tr,
          type: AppSnackbarType.success,
        );
        return;
      }

      // ── 2. Check promotions ──────────────────────────────────────────────
      final promoRes = await SupabaseService.client
          .from('promotions')
          .select()
          .eq('promotionCode', code)
          .or('expiry_date.is.null,expiry_date.gt.${DateTime.now().toUtc().toIso8601String()}')
          .maybeSingle();

      if (promoRes != null) {
        final promo = PromotionModel.fromJson(
            Map<String, dynamic>.from(promoRes as Map));
        if (!promo.isExpired) {
          discount.value = promo.promotionDiscount.toDouble();
          AppSnackbar.show(
            'success'.tr,
            'voucher_applied'.tr,
            type: AppSnackbarType.success,
          );
          return;
        }
      }

      // ── 3. Not found ─────────────────────────────────────────────────────
      AppSnackbar.show(
        'error'.tr,
        'invalid_voucher'.tr,
        type: AppSnackbarType.error,
      );
      discount.value = 0;
    } finally {
      promoLoading.value = false;
    }
  }

  // ── Place order ───────────────────────────────────────────────────────────

  Future<void> placeOrder() async {
    final address = selectedAddress.value;
    final user = AuthController.to.currentUser.value;
    final phone = phoneCtrl.text.trim();
    if (address == null || user == null) {
      AppSnackbar.show(
        'error'.tr,
        'select_address'.tr,
        type: AppSnackbarType.error,
      );
      return;
    }
    if (phone.isEmpty) {
      AppSnackbar.show(
        'error'.tr,
        'phone_required'.tr,
        type: AppSnackbarType.error,
      );
      return;
    }
    if (CartController.to.cartItems.isEmpty) return;

    // Build address snapshot
    final addressSnapshot = [
      address.address,
      if (address.landmark.isNotEmpty) address.landmark,
    ].join(' - ');

    placingOrder.value = true;
    try {
      final affiliateId = await _lookupAffiliateId();

      // 1. Insert order_master
      final orderRow = await SupabaseService.client
          .from('order_master')
          .insert({
            'userID': user.id,
            'addressID': address.id,
            'address': addressSnapshot,
            'phoneNumber': phone,
            if (affiliateId != null) 'affiliateID': affiliateId,
            'totalPrice': finalTotal,
            'totalDiscount': discount.value,
            'notes': notesCtrl.text.trim(),
            'orderStatus': 'Pending',
          })
          .select()
          .single();

      final orderId = (orderRow['id'] as num).toInt();

      // 2. Insert order_detail for each item
      for (final item in CartController.to.cartItems) {
        await SupabaseService.client.from('order_detail').insert({
          'orderMasterID': orderId,
          'itemPropertyID': item.itemPropertyId,
          'itemName': item.itemName,
          'quantity': item.quantity,
          'price': item.price,
        });
      }

      // 3. Clear cart + affiliate id
      await CartController.to.clear();
      GetStorage().remove(AppConstants.kActiveAffiliateId);

      if (Get.isRegistered<HistoryController>()) {
        await HistoryController.to.fetchOrders();
      }

      Get.offAllNamed(Routes.home);
      NavController.to.setIndex(2);
      AppSnackbar.show(
        'order_placed'.tr,
        'order_placed_msg'.tr,
        type: AppSnackbarType.success,
      );
    } finally {
      placingOrder.value = false;
    }
  }

  /// Resolves the stored affiliate Firebase UID → Supabase users.id (int).
  Future<int?> _lookupAffiliateId() async {
    final uid = GetStorage().read<String>(AppConstants.kActiveAffiliateId);
    if (uid == null) return null;
    try {
      final row = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('uid', uid)
          .eq('isAffiliate', true)
          .maybeSingle();
      return (row?['id'] as num?)?.toInt();
    } catch (e) {
      debugPrint('[CheckoutController] Affiliate lookup error: $e');
      return null;
    }
  }
}
