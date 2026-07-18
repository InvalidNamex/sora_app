import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/models/item_model.dart';
import '../../core/models/item_property_model.dart';
import '../../core/services/affiliate_program_service.dart';
import '../../core/services/share_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../auth/auth_controller.dart';

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
      properties.firstWhereOrNull((p) => p.isDefault);

  String get effectiveDescription {
    final propertyDescription = (selectedProperty?.propertyDescription ?? '')
        .trim();
    if (propertyDescription.isNotEmpty) {
      return propertyDescription;
    }

    return item.value?.itemDescription.trim() ?? '';
  }

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
    _fetchItem();
  }

  Future<void> _fetchItem() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final itemResponse = await SupabaseService.client
          .from('items')
          .select()
          .eq('id', _itemId)
          .single();
      item.value = ItemModel.fromJson(itemResponse);

      final propsResponse = await SupabaseService.client
          .from('item_properties')
          .select()
          .eq('itemID', _itemId)
          .order('size');
      properties.value = (propsResponse as List)
          .map((e) => ItemPropertyModel.fromJson(e as Map<String, dynamic>))
          .toList();

      selectedPropertyIndex.value = 0;
    } catch (e) {
      debugPrint('[ItemController] fetchItem error: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void retry() => _fetchItem();

  Future<void> refreshItem() => _fetchItem();

  void selectProperty(int index) => selectedPropertyIndex.value = index;

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
