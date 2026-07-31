import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/item_model.dart';
import '../../../core/models/video_ad_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/video_ad_service.dart';
import '../../../core/utils/app_snackbar.dart';

class VideoAdManagementController extends GetxController {
  static VideoAdManagementController get to => Get.find();

  final ads = <VideoAdModel>[].obs;
  final products = <ItemModel>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final editingId = Rxn<int>();
  final selectedItemId = Rxn<int>();
  final isVertical = true.obs;

  final urlCtrl = TextEditingController();

  @override
  void onReady() {
    super.onReady();
    fetchAll();
  }

  @override
  void onClose() {
    urlCtrl.dispose();
    super.onClose();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      await Future.wait([fetchAds(), fetchProducts()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAds() async {
    try {
      ads.value = await VideoAdService.fetchAds();
    } catch (e) {
      debugPrint('[VideoAdManagementController] fetchAds error: $e');
      AppSnackbar.show(
        'Error',
        'Failed to load video ads',
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await SupabaseService.client
          .from('items')
          .select(
            'id, categoryID, subCategoryID, gender, itemName, itemNameEN, '
            'brandName, itemDescription, itemDescriptionEN, notes, notesEN, '
            'accords, accordsEN, isFeatured',
          )
          .order('itemName', ascending: true);

      products.value = (response as List)
          .whereType<Map>()
          .map((row) => ItemModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (e) {
      debugPrint('[VideoAdManagementController] fetchProducts error: $e');
      AppSnackbar.show(
        'Error',
        'Failed to load products',
        type: AppSnackbarType.error,
      );
    }
  }

  ItemModel? productById(int id) =>
      products.firstWhereOrNull((product) => product.id == id);

  String productLabel(int id) {
    final product = productById(id);
    if (product == null) return 'Product #$id';
    final brand = product.brandName.trim();
    return brand.isEmpty ? product.itemName : '${product.itemName} · $brand';
  }

  List<ItemModel> matchingProducts(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return products.toList(growable: false);
    return products
        .where((product) {
          return product.itemName.toLowerCase().contains(normalized) ||
              product.brandName.toLowerCase().contains(normalized) ||
              '${product.id}'.contains(normalized);
        })
        .toList(growable: false);
  }

  void beginCreate() {
    editingId.value = null;
    urlCtrl.clear();
    isVertical.value = true;
    selectedItemId.value = null;
  }

  void beginEdit(VideoAdModel ad) {
    editingId.value = ad.id;
    urlCtrl.text = ad.videoUrl;
    isVertical.value = ad.isVertical;
    selectedItemId.value = ad.itemId;
  }

  Future<bool> save() async {
    final url = urlCtrl.text.trim();
    final itemId = selectedItemId.value;
    final parsed = Uri.tryParse(url);
    if (url.isEmpty ||
        parsed == null ||
        !parsed.hasScheme ||
        itemId == null ||
        itemId <= 0) {
      AppSnackbar.show(
        'Error',
        'Add a valid video URL and product',
        type: AppSnackbarType.error,
      );
      return false;
    }

    isSaving.value = true;
    try {
      await VideoAdService.saveAd(
        id: editingId.value,
        videoUrl: url,
        isVertical: isVertical.value,
        itemId: itemId,
      );
      await fetchAds();
      AppSnackbar.show(
        'Success',
        'Video ad saved',
        type: AppSnackbarType.success,
      );
      return true;
    } catch (e) {
      debugPrint('[VideoAdManagementController] save error: $e');
      AppSnackbar.show(
        'Error',
        'Failed to save video ad',
        type: AppSnackbarType.error,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteAd(VideoAdModel ad) async {
    try {
      await VideoAdService.deleteAd(ad.id);
      ads.removeWhere((entry) => entry.id == ad.id);
      AppSnackbar.show(
        'Success',
        'Video ad deleted',
        type: AppSnackbarType.success,
      );
    } catch (e) {
      debugPrint('[VideoAdManagementController] delete error: $e');
      AppSnackbar.show(
        'Error',
        'Failed to delete video ad',
        type: AppSnackbarType.error,
      );
    }
  }
}
