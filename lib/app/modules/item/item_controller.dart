import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/models/item_model.dart';
import '../../core/models/item_property_model.dart';
import '../../core/services/supabase_service.dart';

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

  String get effectiveDescription {
    final propertyDescription = selectedProperty?.propertyDescription?.trim();
    if (propertyDescription != null && propertyDescription.isNotEmpty) {
      return propertyDescription;
    }

    return item.value?.itemDescription.trim() ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _itemId = args['itemId'] as int? ?? 0;
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

  void selectProperty(int index) => selectedPropertyIndex.value = index;

  Future<void> pulseCartFab() async {
    cartFabPulse.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    cartFabPulse.value = false;
  }
}
