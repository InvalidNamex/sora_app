import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final pickedBannerName = ''.obs;
  final pickedBannerBytes = Rxn<Uint8List>();
  final existingBannerUrl = ''.obs;
  final clearExistingBanner = false.obs;

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
    existingBannerUrl.value = '';
    pickedBannerName.value = '';
    pickedBannerBytes.value = null;
    clearExistingBanner.value = false;
  }

  void beginEdit(VideoAdModel ad) {
    editingId.value = ad.id;
    urlCtrl.text = ad.videoUrl;
    isVertical.value = ad.isVertical;
    selectedItemId.value = ad.itemId;
    existingBannerUrl.value = ad.bannerUrl;
    pickedBannerName.value = '';
    pickedBannerBytes.value = null;
    clearExistingBanner.value = false;
  }

  Future<void> pickBanner() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (image == null) return;
      pickedBannerName.value = image.name;
      pickedBannerBytes.value = await image.readAsBytes();
      clearExistingBanner.value = false;
    } catch (e) {
      debugPrint('[VideoAdManagementController] pickBanner error: $e');
      AppSnackbar.show(
        'Error',
        'Failed to select banner',
        type: AppSnackbarType.error,
      );
    }
  }

  Future<bool> save() async {
    final url = urlCtrl.text.trim();
    final itemId = selectedItemId.value;
    final currentBannerUrl = clearExistingBanner.value
        ? ''
        : existingBannerUrl.value;
    final hasBanner =
        pickedBannerBytes.value != null || currentBannerUrl.isNotEmpty;
    if ((url.isEmpty && !hasBanner) ||
        itemId == null ||
        itemId <= 0) {
      AppSnackbar.show(
        'Error',
        'Add a video URL or banner and product',
        type: AppSnackbarType.error,
      );
      return false;
    }

    isSaving.value = true;
    try {
      var bannerUrl = currentBannerUrl;
      final bytes = pickedBannerBytes.value;
      if (bytes != null) {
        final extension = _safeExtension(pickedBannerName.value);
        final path = '${DateTime.now().millisecondsSinceEpoch}.$extension';
        await SupabaseService.client.storage
            .from('ad_banners')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: _contentType(extension),
                cacheControl: '31536000',
                upsert: true,
              ),
            );
        bannerUrl = SupabaseService.client.storage
            .from('ad_banners')
            .getPublicUrl(path);
      }
      await VideoAdService.saveAd(
        id: editingId.value,
        videoUrl: url,
        bannerUrl: bannerUrl,
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

  String _safeExtension(String name) {
    final extension = name.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)
        ? extension
        : 'jpg';
  }

  String _contentType(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

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
