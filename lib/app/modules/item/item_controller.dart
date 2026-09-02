import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/models/item_model.dart';
import '../../core/models/item_property_model.dart';
import '../../core/models/cart_item_model.dart';
import '../../core/services/affiliate_program_service.dart';
import '../../core/services/share_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../home/home_controller.dart';

class ItemController extends GetxController {
  static ItemController get to => Get.find();

  late final int _itemId;
  late final String heroTag;

  final item = Rxn<ItemModel>();
  final properties = <ItemPropertyModel>[].obs;
  final selectedPropertyIndex = 0.obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final addingToCart = false.obs;
  final cartFabPulse = false.obs;

  ItemPropertyModel? get selectedProperty =>
      properties.isNotEmpty ? properties[selectedPropertyIndex.value] : null;

  ItemPropertyModel? get defaultProperty =>
      ItemPropertyModel.preferred(properties);

  CartItemModel? get selectedCartItem {
    final propertyId = selectedProperty?.id;
    if (propertyId == null) return null;
    return CartController.to.cartItems.firstWhereOrNull(
      (cartItem) => cartItem.itemPropertyId == propertyId,
    );
  }

  bool get selectedPropertyInCart => selectedCartItem != null;

  int get selectedPropertyQuantity => selectedCartItem?.quantity ?? 0;

  String get effectiveDescription => item.value?.itemDescription.trim() ?? '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final rawItemId = args['itemId'] ?? Get.parameters['id'];
    _itemId = rawItemId is int ? rawItemId : int.tryParse('$rawItemId') ?? 0;
    heroTag = (args['heroTag'] as String?) ?? 'hero_item_$_itemId';
  }

  @override
  void onReady() {
    super.onReady();
    final cached = Get.isRegistered<HomeController>()
        ? HomeController.to.cachedItemRow(_itemId)
        : null;
    if (cached != null) {
      _applyItemRow(cached);
      isLoading.value = false;
      unawaited(_fetchItem(showLoading: false));
    } else {
      unawaited(_fetchItem());
    }
  }

  void _applyItemRow(Map<String, dynamic> row) {
    final selectedPropertyId = selectedProperty?.id;
    item.value = ItemModel.fromJson(row);
    final rawProperties = (row['item_properties'] as List?) ?? const [];
    properties.value =
        rawProperties
            .whereType<Map>()
            .map(
              (property) => ItemPropertyModel.fromJson(
                Map<String, dynamic>.from(property),
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => left.sizeMl.compareTo(right.sizeMl));
    final restoredIndex = selectedPropertyId == null
        ? -1
        : properties.indexWhere(
            (property) => property.id == selectedPropertyId,
          );
    if (restoredIndex >= 0) {
      selectedPropertyIndex.value = restoredIndex;
    } else {
      final preferred = ItemPropertyModel.preferred(properties);
      selectedPropertyIndex.value = preferred == null
          ? 0
          : properties.indexOf(preferred);
    }
  }

  Future<void> _fetchItem({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    hasError.value = false;
    try {
      final responses = await Future.wait<dynamic>([
        SupabaseService.client
            .from('items')
            .select()
            .eq('id', _itemId)
            .single(),
        SupabaseService.client
            .from('item_properties')
            .select()
            .eq('itemID', _itemId)
            .order('size'),
      ]);
      final itemRow = Map<String, dynamic>.from(responses[0] as Map);
      final propertyRows = (responses[1] as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      _applyItemRow({...itemRow, 'item_properties': propertyRows});
      if (Get.isRegistered<HomeController>()) {
        HomeController.to.cacheItemRow(itemRow, propertyRows);
      }
    } catch (e) {
      debugPrint('[ItemController] fetchItem error: $e');
      if (item.value == null) hasError.value = true;
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  void retry() => _fetchItem();

  Future<void> refreshItem() => _fetchItem();

  void selectProperty(int index) => selectedPropertyIndex.value = index;

  Future<void> handleCartAction() async {
    if (selectedPropertyInCart) {
      await Get.toNamed(Routes.checkout);
      return;
    }

    final currentItem = item.value;
    final property = selectedProperty;
    if (currentItem == null || property == null || !property.inStock) return;
    if (addingToCart.value) return;

    await addSelectedPropertyToCart();
  }

  Future<void> addSelectedPropertyToCart() async {
    final currentItem = item.value;
    final property = selectedProperty;
    if (currentItem == null || property == null || !property.inStock) return;
    if (addingToCart.value) return;

    addingToCart.value = true;
    try {
      await CartController.to.addItem(
        property,
        currentItem.itemName,
        1,
        displayProperty: defaultProperty,
      );
      await pulseCartFab();
    } catch (e) {
      debugPrint('[ItemController] add to cart error: $e');
      AppSnackbar.show('error'.tr, e.toString(), type: AppSnackbarType.error);
    } finally {
      addingToCart.value = false;
    }
  }

  Future<void> incrementSelectedProperty() async {
    await addSelectedPropertyToCart();
  }

  Future<void> decrementSelectedProperty() async {
    final cartItem = selectedCartItem;
    if (cartItem == null || addingToCart.value) return;

    addingToCart.value = true;
    try {
      await CartController.to.decrement(cartItem);
    } catch (e) {
      debugPrint('[ItemController] decrement cart item error: $e');
      AppSnackbar.show('error'.tr, e.toString(), type: AppSnackbarType.error);
    } finally {
      addingToCart.value = false;
    }
  }

  Future<void> shareItem(BuildContext context) async {
    final currentItem = item.value;
    if (currentItem == null) return;

    final user = AuthController.to.currentUser.value;

    try {
      final affiliateCode = user?.isAffiliate == true
          ? (await AffiliateProgramService.getMyProfile()).code
          : null;
      if (!context.mounted) return;
      await ShareService.shareItem(
        context: context,
        itemId: currentItem.id,
        itemName: currentItem.itemName,
        message: 'share_item_message'.trParams({'item': currentItem.itemName}),
        affiliateCode: affiliateCode,
      );
    } catch (e) {
      debugPrint('[ItemController] shareItem error: $e');
      AppSnackbar.show(
        'error'.tr,
        'share_failed'.tr,
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> pulseCartFab() async {
    cartFabPulse.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    cartFabPulse.value = false;
  }
}
