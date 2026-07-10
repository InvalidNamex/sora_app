import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/constants/app_constants.dart';

import '../../core/models/banner_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/item_model.dart';
import '../../core/models/item_property_model.dart';
import '../../core/models/sub_category_model.dart';
import '../../core/services/supabase_service.dart';

/// View-local model combining an item with its first (primary) property.
class ItemWithProperty {
  final ItemModel item;
  final ItemPropertyModel? primaryProperty;

  const ItemWithProperty({required this.item, this.primaryProperty});

  /// True only when the item has properties and all are out of stock.
  bool get isOutOfStock {
    final p = primaryProperty;
    return p == null || !p.inStock;
  }
}

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  final banners = <BannerModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final subCategories = <SubCategoryModel>[].obs;
  final items = <ItemWithProperty>[].obs;
  final displayItems = <ItemWithProperty>[].obs;

  final isLoadingBanners = true.obs;
  final isLoadingCategories = true.obs;
  final isLoadingItems = true.obs;
  final hasItemsError = false.obs;
  final isCheckingForUpdates = false.obs;

  final selectedCategoryId = Rxn<int>();
  final selectedSubCategoryId = Rxn<int>();
  final genderFilter = Rxn<int>(); // null=All, 0=Unisex, 1=Men, 2=Women
  final inStockOnly = false.obs;
  final hoveredItemId = Rxn<int>();
  final pressedItemId = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
  }

  @override
  void onReady() {
    super.onReady();
    checkForUpdates();
    ever(selectedCategoryId, (_) => _onCategoryChanged());
    ever(selectedSubCategoryId, (_) => _fetchItems());
    ever(genderFilter, (_) => _applyFilters());
    ever<bool>(inStockOnly, (_) => _applyFilters());
  }

  List<ItemWithProperty> _parseItems(List rawItems) {
    final parsed = <ItemWithProperty>[];
    for (final raw in rawItems) {
      try {
        final json = Map<String, dynamic>.from(raw as Map);
        final item = ItemModel.fromJson(json);
        final props = (json['item_properties'] as List?)
            ?.map((p) => ItemPropertyModel.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList();
        final primary = (props != null && props.isNotEmpty) ? props.first : null;
        parsed.add(ItemWithProperty(item: item, primaryProperty: primary));
      } catch (e) {
        debugPrint('[HomeController] item parse error: $e');
      }
    }
    return parsed;
  }

  Future<List<dynamic>> _fetchSubCategoriesForCategory(int categoryId) async {
    try {
      return await SupabaseService.client
          .from('sub_catergories')
          .select()
          .eq('categoryID', categoryId);
    } catch (e1) {
      debugPrint('[HomeController] Failed to fetch sub_catergories: $e1');
      return await SupabaseService.client
          .from('sub_categories')
          .select()
          .eq('categoryID', categoryId);
    }
  }

  Future<void> checkForUpdates() async {
    if (isCheckingForUpdates.value) return;
    isCheckingForUpdates.value = true;

    try {
      final storage = GetStorage();

      // Fetch banners
      final bannerRes = await SupabaseService.client.from('banners').select();
      final freshBannersJson = bannerRes as List;

      // Fetch categories
      List categoryRes;
      try {
        categoryRes = await SupabaseService.client.from('catergories').select();
      } catch (e1) {
        debugPrint('[HomeController] Failed to fetch catergories: $e1');
        categoryRes = await SupabaseService.client.from('categories').select();
      }
      final freshCategoriesJson = categoryRes;

      // Fetch items (default landing list)
      final itemRes = await SupabaseService.client
          .from('items')
          .select('*, item_properties(id, itemID, size, image, price, inStock)')
          .order('isFeatured', ascending: false)
          .order('id', ascending: false)
          .limit(50);
      final freshItemsJson = itemRes as List;

      // Compare with cache
      final cachedBanners = storage.read<List>(AppConstants.kCachedBanners);
      final cachedCategories = storage.read<List>(AppConstants.kCachedCategories);
      final cachedItems = storage.read<List>(AppConstants.kCachedItems);

      final bannersChanged = jsonEncode(cachedBanners) != jsonEncode(freshBannersJson);
      final categoriesChanged = jsonEncode(cachedCategories) != jsonEncode(freshCategoriesJson);
      final itemsChanged = jsonEncode(cachedItems) != jsonEncode(freshItemsJson);

      final hasChanges = bannersChanged || categoriesChanged || itemsChanged ||
          cachedBanners == null || cachedCategories == null || cachedItems == null ||
          banners.isEmpty || categories.isEmpty || items.isEmpty;

      if (hasChanges) {
        // Save to cache
        await storage.write(AppConstants.kCachedBanners, freshBannersJson);
        await storage.write(AppConstants.kCachedCategories, freshCategoriesJson);
        // Only update items cache if we are on the default view
        if (selectedCategoryId.value == null && selectedSubCategoryId.value == null) {
          await storage.write(AppConstants.kCachedItems, freshItemsJson);
        }

        // Apply new data to UI
        banners.value = freshBannersJson
            .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        categories.value = freshCategoriesJson
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // Update default items if currently displaying default
        if (selectedCategoryId.value == null && selectedSubCategoryId.value == null) {
          items.value = _parseItems(freshItemsJson);
          _applyFilters();
        }
      }

      // Reset loading states
      isLoadingBanners.value = false;
      isLoadingCategories.value = false;
      isLoadingItems.value = false;
      hasItemsError.value = false;

      if (selectedCategoryId.value != null) {
        final subCategoryResponse =
            await _fetchSubCategoriesForCategory(selectedCategoryId.value!);
        subCategories.value = subCategoryResponse
            .map((e) => SubCategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        final selectedSubCategory = selectedSubCategoryId.value;
        if (selectedSubCategory != null &&
            !subCategories.any((subCategory) => subCategory.id == selectedSubCategory)) {
          selectedSubCategoryId.value = null;
        }

        await _fetchItems();
      }

    } catch (e, st) {
      debugPrint('[HomeController] checkForUpdates error: $e');
      debugPrint('[HomeController] stacktrace: $st');
      if (items.isEmpty) {
        hasItemsError.value = true;
      }
      isLoadingBanners.value = false;
      isLoadingCategories.value = false;
      isLoadingItems.value = false;
    } finally {
      isCheckingForUpdates.value = false;
    }
  }

  void _loadFromCache() {
    try {
      final storage = GetStorage();
      final cachedBanners = storage.read<List>(AppConstants.kCachedBanners);
      final cachedCategories = storage.read<List>(AppConstants.kCachedCategories);
      final cachedItems = storage.read<List>(AppConstants.kCachedItems);

      if (cachedBanners != null) {
        banners.value = cachedBanners
            .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        isLoadingBanners.value = false;
      }
      if (cachedCategories != null) {
        categories.value = cachedCategories
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        isLoadingCategories.value = false;
      }
      if (cachedItems != null) {
        items.value = _parseItems(cachedItems);
        _applyFilters();
        isLoadingItems.value = false;
      }
    } catch (e) {
      debugPrint('[HomeController] loadFromCache error: $e');
    }
  }

  Future<void> _onCategoryChanged() async {
    selectedSubCategoryId.value = null;
    subCategories.clear();
    final catId = selectedCategoryId.value;
    if (catId == null) {
      await _fetchItems();
      return;
    }
    try {
      final response = await _fetchSubCategoriesForCategory(catId);
      subCategories.value = response
          .map((e) => SubCategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[HomeController] fetchSubCategories error: $e');
      Get.snackbar(
        'Error Loading Subcategories',
        e.toString(),
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      subCategories.value = [];
    }
    await _fetchItems();
  }

  Future<void> _fetchItems() async {
    isLoadingItems.value = true;
    hasItemsError.value = false;
    try {
      var query = SupabaseService.client
          .from('items')
          .select('*, item_properties(id, itemID, size, image, price, inStock)');

      if (selectedSubCategoryId.value != null) {
        query = query.eq('subCategoryID', selectedSubCategoryId.value as Object);
      } else if (selectedCategoryId.value != null) {
        query = query.eq('categoryID', selectedCategoryId.value as Object);
      }

      final response = await query
          .order('isFeatured', ascending: false)
          .order('id', ascending: false)
          .limit(50);

      items.value = _parseItems(response as List);
    } catch (e) {
      debugPrint('[HomeController] fetchItems error: $e');
      items.value = [];
      hasItemsError.value = true;
    } finally {
      _applyFilters();
      isLoadingItems.value = false;
    }
  }

  void selectCategory(int? id) => selectedCategoryId.value = id;
  void selectSubCategory(int? id) => selectedSubCategoryId.value = id;
  void setGenderFilter(int? v) => genderFilter.value = v;
  void setInStockOnly(bool v) => inStockOnly.value = v;
  void setHoveredItem(int? id) => hoveredItemId.value = id;

  Future<void> pulseItemTap(int id) async {
    pressedItemId.value = id;
    await Future<void>.delayed(const Duration(milliseconds: 130));
    if (pressedItemId.value == id) pressedItemId.value = null;
  }

  void _applyFilters() {
    var result = items.toList();
    final gender = genderFilter.value;
    if (gender != null) {
      result = result.where((i) => i.item.gender == gender).toList();
    }
    if (inStockOnly.value) {
      result = result.where((i) => !i.isOutOfStock).toList();
    }
    displayItems.value = result;
  }

  @override
  Future<void> refresh() async {
    await checkForUpdates();

    if (selectedCategoryId.value == null) {
      subCategories.clear();
      await _fetchItems();
    }
  }
}
