import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/models/address_model.dart';
import '../../core/models/affiliate_program_models.dart';
import '../../core/services/affiliate_program_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../history/history_controller.dart';
import '../navigation/nav_controller.dart';

class CheckoutController extends GetxController {
  static CheckoutController get to => Get.find();

  final addresses = <AddressModel>[].obs;
  final selectedAddress = Rxn<AddressModel>();
  final appliedPromo = Rxn<PromoCodeValidation>();
  final discount = 0.0.obs;
  final promoLoading = false.obs;
  final placingOrder = false.obs;
  final promoCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  String? _appliedAffiliateSource;

  double get cartTotal => CartController.to.totalPrice;
  double get finalTotal =>
      (cartTotal - discount.value).clamp(0, double.infinity);

  @override
  void onReady() {
    super.onReady();
    unawaited(loadAddresses());
    unawaited(_loadSavedAffiliateCode());

    final user = AuthController.to.currentUser.value;
    if (user != null) {
      phoneCtrl.text = user.phoneTwo?.isNotEmpty == true
          ? user.phoneTwo!
          : user.phone;
    }
  }

  @override
  void onClose() {
    promoCtrl.dispose();
    notesCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }

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

  void selectAddress(AddressModel address) {
    selectedAddress.value = address;
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

    final validation = appliedPromo.value;
    if (validation != null) {
      await applyPromo(showFeedback: false);
    }
  }

  Future<void> _loadSavedAffiliateCode() async {
    try {
      var code = AffiliateProgramService.activeCode;
      var source = AffiliateProgramService.activeSource;

      if (code == null) {
        final remote = await AffiliateProgramService.getActiveAttribution();
        code = remote?['code'] as String?;
        source = remote?['source'] as String?;
        if (code != null && code.isNotEmpty) {
          await AffiliateProgramService.rememberAffiliateCode(
            code,
            source: source ?? 'link',
          );
        }
      }

      if (code == null || code.isEmpty) return;
      promoCtrl.text = code;
      _appliedAffiliateSource = source == 'link' ? 'link' : 'manual';
      await applyPromo(showFeedback: false);
    } catch (e) {
      debugPrint('[CheckoutController] saved affiliate code error: $e');
    }
  }

  void onPromoChanged(String value) {
    final validation = appliedPromo.value;
    if (validation == null) return;
    if (AffiliateProgramService.promoCodeFromInput(value) == validation.code) {
      return;
    }
    appliedPromo.value = null;
    discount.value = 0;
    _appliedAffiliateSource = null;
  }

  void editPromo() {
    appliedPromo.value = null;
    discount.value = 0;
    _appliedAffiliateSource = null;
    promoCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: promoCtrl.text.length,
    );
  }

  Future<bool> applyPromo({bool showFeedback = true}) async {
    final code = AffiliateProgramService.promoCodeFromInput(promoCtrl.text);
    if (code.isEmpty) {
      appliedPromo.value = null;
      discount.value = 0;
      return true;
    }

    promoLoading.value = true;
    try {
      final validation = await AffiliateProgramService.validateCode(
        code: code,
        subtotal: cartTotal,
      );
      if (!validation.valid) {
        appliedPromo.value = null;
        discount.value = 0;
        if (AffiliateProgramService.activeCode == code) {
          await AffiliateProgramService.clearActiveAttribution();
        }
        if (showFeedback) {
          AppSnackbar.show(
            'error'.tr,
            'invalid_voucher'.tr,
            type: AppSnackbarType.error,
          );
        }
        return false;
      }

      promoCtrl.text = validation.code;
      appliedPromo.value = validation;
      discount.value = validation.discountAmount;

      if (validation.isAffiliate) {
        final isSavedLink =
            AffiliateProgramService.activeCode == validation.code &&
            AffiliateProgramService.activeSource == 'link';
        _appliedAffiliateSource = isSavedLink ? 'link' : 'manual';
        if (!isSavedLink) {
          await AffiliateProgramService.rememberManualAffiliateCode(
            validation.code,
          );
        }
      } else {
        _appliedAffiliateSource = null;
      }

      if (showFeedback) {
        AppSnackbar.show(
          'success'.tr,
          'voucher_applied'.tr,
          type: AppSnackbarType.success,
        );
      }
      return true;
    } on AffiliateProgramException catch (e) {
      if (showFeedback) {
        AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
      }
      return false;
    } finally {
      promoLoading.value = false;
    }
  }

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

    final enteredCode = AffiliateProgramService.promoCodeFromInput(
      promoCtrl.text,
    );
    if (enteredCode.isNotEmpty && appliedPromo.value?.code != enteredCode) {
      final valid = await applyPromo();
      if (!valid) return;
    }

    placingOrder.value = true;
    try {
      await AffiliateProgramService.placeOrder(
        addressId: address.id,
        phone: phone,
        notes: notesCtrl.text.trim(),
        promoCode: enteredCode,
        affiliateSource: _appliedAffiliateSource,
      );

      await CartController.to.clear();
      if (appliedPromo.value?.isAffiliate == true) {
        await AffiliateProgramService.clearActiveAttribution();
      }

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
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
      await CartController.to.refreshCart();
    } catch (e) {
      debugPrint('[CheckoutController] placeOrder error: $e');
      AppSnackbar.show(
        'error'.tr,
        'order_failed'.tr,
        type: AppSnackbarType.error,
      );
    } finally {
      placingOrder.value = false;
    }
  }
}
