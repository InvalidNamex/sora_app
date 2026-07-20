import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/bundle_deal_model.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/item_property_model.dart';
import '../../../core/services/bundle_deal_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_snackbar.dart';

class BundleManagementController extends GetxController {
  static BundleManagementController get to => Get.find();

  final bundles = <BundleDealModel>[].obs;
  final items = <ItemModel>[].obs;
  final properties = <ItemPropertyModel>[].obs;
  final draftQuantities = <int, int>{}.obs;
  final selectedPropertyId = Rxn<int>();
  final editingId = Rxn<int>();
  final pickedBannerName = ''.obs;
  final pickedBannerBytes = Rxn<Uint8List>();
  final existingBannerUrl = ''.obs;
  final isActive = true.obs;
  final isLoading = true.obs;
  final isCatalogLoading = false.obs;
  final catalogLoadFailed = false.obs;
  final isSaving = false.obs;

  final titleCtrl = TextEditingController();
  final titleEnCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final descriptionEnCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final sortOrderCtrl = TextEditingController(text: '0');

  @override
  void onReady() {
    super.onReady();
    fetchAll();
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    titleEnCtrl.dispose();
    descriptionCtrl.dispose();
    descriptionEnCtrl.dispose();
    priceCtrl.dispose();
    sortOrderCtrl.dispose();
    super.onClose();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      await Future.wait([fetchBundles(), fetchCatalog()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBundles() async {
    try {
      bundles.value = await BundleDealService.fetchAdminBundles();
    } catch (e, stackTrace) {
      debugPrint('[BundleManagementController] fetchBundles error: $e');
      debugPrint('$stackTrace');
      AppSnackbar.show(
        'error'.tr,
        'bundle_load_failed'.tr,
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> fetchCatalog() async {
    if (isCatalogLoading.value) return;
    isCatalogLoading.value = true;
    catalogLoadFailed.value = false;
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.client.from('items').select(),
        SupabaseService.client.from('item_properties').select(),
      ]);
      items.value = (results[0] as List)
          .whereType<Map>()
          .map((row) => ItemModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      properties.value = (results[1] as List)
          .whereType<Map>()
          .map(
            (row) => ItemPropertyModel.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[BundleManagementController] fetchCatalog error: $e');
      debugPrint('$stackTrace');
      catalogLoadFailed.value = true;
      items.clear();
      properties.clear();
      AppSnackbar.show(
        'error'.tr,
        'bundle_catalog_load_failed'.tr,
        type: AppSnackbarType.error,
      );
    } finally {
      isCatalogLoading.value = false;
    }
  }

  String itemNameForProperty(ItemPropertyModel property) {
    return items
            .firstWhereOrNull((item) => item.id == property.itemId)
            ?.itemName ??
        '${'item'.tr} #${property.itemId}';
  }

  ItemPropertyModel? propertyById(int id) =>
      properties.firstWhereOrNull((property) => property.id == id);

  void beginCreate() {
    editingId.value = null;
    titleCtrl.clear();
    titleEnCtrl.clear();
    descriptionCtrl.clear();
    descriptionEnCtrl.clear();
    priceCtrl.clear();
    sortOrderCtrl.text = '0';
    existingBannerUrl.value = '';
    pickedBannerName.value = '';
    pickedBannerBytes.value = null;
    selectedPropertyId.value = null;
    draftQuantities.clear();
    isActive.value = true;
  }

  void beginEdit(BundleDealModel bundle) {
    editingId.value = bundle.id;
    titleCtrl.text = bundle.titleAr;
    titleEnCtrl.text = bundle.titleEn;
    descriptionCtrl.text = bundle.descriptionAr;
    descriptionEnCtrl.text = bundle.descriptionEn;
    priceCtrl.text = bundle.dealPrice.toStringAsFixed(2);
    sortOrderCtrl.text = '${bundle.sortOrder}';
    existingBannerUrl.value = bundle.bannerImage;
    pickedBannerName.value = '';
    pickedBannerBytes.value = null;
    selectedPropertyId.value = null;
    draftQuantities.assignAll({
      for (final item in bundle.items) item.property.id: item.quantity,
    });
    isActive.value = bundle.isActive;
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
    } catch (e) {
      debugPrint('[BundleManagementController] pickBanner error: $e');
      AppSnackbar.show(
        'error'.tr,
        'bundle_banner_pick_failed'.tr,
        type: AppSnackbarType.error,
      );
    }
  }

  void addSelectedProperty() {
    final propertyId = selectedPropertyId.value;
    if (propertyId == null) return;
    draftQuantities[propertyId] = draftQuantities[propertyId] ?? 1;
    selectedPropertyId.value = null;
  }

  void incrementDraftItem(int propertyId) {
    draftQuantities[propertyId] = (draftQuantities[propertyId] ?? 0) + 1;
  }

  void decrementDraftItem(int propertyId) {
    final current = draftQuantities[propertyId] ?? 0;
    if (current <= 1) {
      draftQuantities.remove(propertyId);
    } else {
      draftQuantities[propertyId] = current - 1;
    }
  }

  void removeDraftItem(int propertyId) {
    draftQuantities.remove(propertyId);
  }

  Future<bool> save() async {
    final price = double.tryParse(priceCtrl.text.trim());
    if (titleCtrl.text.trim().isEmpty ||
        price == null ||
        price <= 0 ||
        draftQuantities.isEmpty ||
        (existingBannerUrl.value.isEmpty && pickedBannerBytes.value == null)) {
      AppSnackbar.show(
        'error'.tr,
        'bundle_required_fields'.tr,
        type: AppSnackbarType.error,
      );
      return false;
    }

    isSaving.value = true;
    try {
      var bannerUrl = existingBannerUrl.value;
      final bytes = pickedBannerBytes.value;
      if (bytes != null) {
        final extension = _safeExtension(pickedBannerName.value);
        final signed = await BundleDealService.createAdminUpload(
          extension: extension,
        );
        final path = signed['path'] as String?;
        final token = signed['token'] as String?;
        final publicUrl = signed['publicUrl'] as String?;
        if (path == null || token == null || publicUrl == null) {
          throw StateError('Invalid signed upload response');
        }
        await SupabaseService.client.storage
            .from('bundle_banner')
            .uploadBinaryToSignedUrl(
              path,
              token,
              bytes,
              FileOptions(contentType: _contentType(extension)),
            );
        bannerUrl = publicUrl;
      }

      await BundleDealService.saveBundle(
        id: editingId.value,
        title: titleCtrl.text.trim(),
        titleEn: titleEnCtrl.text.trim(),
        description: descriptionCtrl.text.trim(),
        descriptionEn: descriptionEnCtrl.text.trim(),
        bannerImage: bannerUrl,
        dealPrice: price,
        isActive: isActive.value,
        sortOrder: int.tryParse(sortOrderCtrl.text.trim()) ?? 0,
        itemQuantities: Map<int, int>.from(draftQuantities),
      );
      await fetchAll();
      AppSnackbar.show(
        'success'.tr,
        'bundle_saved'.tr,
        type: AppSnackbarType.success,
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('[BundleManagementController] save error: $e');
      debugPrint('$stackTrace');
      AppSnackbar.show(
        'error'.tr,
        'bundle_save_failed'.tr,
        type: AppSnackbarType.error,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteBundle(BundleDealModel bundle) async {
    try {
      await BundleDealService.deleteBundle(bundle.id);
      await fetchAll();
      AppSnackbar.show(
        'success'.tr,
        'bundle_deleted'.tr,
        type: AppSnackbarType.success,
      );
    } catch (e) {
      debugPrint('[BundleManagementController] delete error: $e');
      AppSnackbar.show(
        'error'.tr,
        'bundle_delete_failed'.tr,
        type: AppSnackbarType.error,
      );
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
}
