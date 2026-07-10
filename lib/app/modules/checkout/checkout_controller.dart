import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/address_model.dart';
import '../../core/models/voucher_model.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
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

  double get cartTotal => CartController.to.totalPrice;
  double get finalTotal => (cartTotal - discount.value).clamp(0, double.infinity);

  @override
  void onReady() {
    super.onReady();
    _loadAddresses();
  }

  @override
  void onClose() {
    promoCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  // ── Address ───────────────────────────────────────────────────────────────

  Future<void> _loadAddresses() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;
    final response = await SupabaseService.client
        .from('address_book')
        .select()
        .eq('userID', userId)
        .order('isDefault', ascending: false);
    addresses.value = (response as List)
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
    selectedAddress.value =
        addresses.firstWhereOrNull((a) => a.isDefault) ??
            addresses.firstOrNull;
  }

  void selectAddress(AddressModel addr) {
    selectedAddress.value = addr;
    Navigator.of(Get.context!).pop(); // close address select sheet
  }

  // ── Promo code ────────────────────────────────────────────────────────────

  Future<void> applyPromo() async {
    final code = promoCtrl.text.trim();
    if (code.isEmpty) return;
    promoLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('vouchers')
          .select()
          .eq('voucherCode', code)
          .eq('isActive', true)
          .maybeSingle();
      if (response == null) {
        Get.snackbar('error'.tr, 'invalid_voucher'.tr);
        discount.value = 0;
        return;
      }
      final voucher = VoucherModel.fromJson(response);
      if (voucher.voucherAmount != null) {
        discount.value = voucher.voucherAmount!;
      } else if (voucher.voucherPercentage != null) {
        discount.value = cartTotal * voucher.voucherPercentage! / 100;
      }
      Get.snackbar('success'.tr, 'voucher_applied'.tr);
    } finally {
      promoLoading.value = false;
    }
  }

  // ── Place order ───────────────────────────────────────────────────────────

  Future<void> placeOrder() async {
    final address = selectedAddress.value;
    final user = AuthController.to.currentUser.value;
    if (address == null || user == null) {
      Get.snackbar('error'.tr, 'select_address'.tr);
      return;
    }
    if (CartController.to.cartItems.isEmpty) return;

    placingOrder.value = true;
    try {
      final affiliateId = await _lookupAffiliateId();

      // 1. Insert order_master
      final orderRow = await SupabaseService.client
          .from('order_master')
          .insert({
            'userID': user.id,
            'addressID': address.id,
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

      Get.offAllNamed(Routes.home);
      Get.snackbar('order_placed'.tr, 'order_placed_msg'.tr);
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
