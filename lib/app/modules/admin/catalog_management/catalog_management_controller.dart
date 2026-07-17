import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/sub_category_model.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/item_property_model.dart';
import '../../../core/utils/app_snackbar.dart';

class CatalogManagementController extends GetxController {
  static CatalogManagementController get to => Get.find();

  final categories = <CategoryModel>[].obs;
  final subCategories = <SubCategoryModel>[].obs;
  final items = <ItemModel>[].obs;
  final properties = <ItemPropertyModel>[].obs;

  final isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchCategories(),
        fetchSubCategories(),
        fetchItems(),
        fetchProperties(),
      ]);
    } catch (e) {
      AppSnackbar.show(
        'Error',
        'Failed to fetch catalog: $e',
        type: AppSnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    final resp = await SupabaseService.client.from('categories').select();
    categories.value = (resp as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> fetchSubCategories() async {
    final resp = await SupabaseService.client.from('sub_categories').select();
    subCategories.value = (resp as List)
        .map((e) => SubCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> fetchItems() async {
    final resp = await SupabaseService.client.from('items').select();
    items.value = (resp as List)
        .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> fetchProperties() async {
    final resp = await SupabaseService.client.from('item_properties').select();
    properties.value = (resp as List)
        .map((e) => ItemPropertyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Generic CRUD Methods ---

  Future<void> createRecord(String table, Map<String, dynamic> data) async {
    try {
      await SupabaseService.client.from(table).insert(data);
      AppSnackbar.show(
        'Success',
        'Record added',
        type: AppSnackbarType.success,
      );
      await fetchAll();
    } catch (e) {
      AppSnackbar.show(
        'Error',
        'Failed to add record: $e',
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> updateRecord(
    String table,
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      await SupabaseService.client.from(table).update(data).eq('id', id);
      AppSnackbar.show(
        'Success',
        'Record updated',
        type: AppSnackbarType.success,
      );
      await fetchAll();
    } catch (e) {
      AppSnackbar.show(
        'Error',
        'Failed to update record: $e',
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> deleteRecord(String table, int id, {String? imageUrl}) async {
    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _deleteImageFromUrl('categories', imageUrl);
      }
      await SupabaseService.client.from(table).delete().eq('id', id);
      AppSnackbar.show(
        'Success',
        'Record deleted',
        type: AppSnackbarType.success,
      );
      await fetchAll();
    } catch (e) {
      AppSnackbar.show(
        'Error',
        'Failed to delete record: $e',
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> _deleteImageFromUrl(String bucket, String imageUrl) async {
    try {
      final bucketPath = '/$bucket/';
      final idx = imageUrl.indexOf(bucketPath);
      if (idx != -1) {
        // Handle potential URL query parameters if any exist
        String filePath = imageUrl.substring(idx + bucketPath.length);
        if (filePath.contains('?')) {
          filePath = filePath.split('?').first;
        }
        if (filePath.isNotEmpty) {
          await SupabaseService.client.storage.from(bucket).remove([filePath]);
        }
      }
    } catch (e) {
      debugPrint('Failed to delete image from storage: $e');
    }
  }

  Future<String?> uploadCategoryImage(dynamic imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await SupabaseService.client.storage
          .from('categories')
          .uploadBinary(fileName, bytes);
      return SupabaseService.client.storage
          .from('categories')
          .getPublicUrl(fileName);
    } catch (e) {
      AppSnackbar.show(
        'Error',
        'Failed to upload image: $e',
        type: AppSnackbarType.error,
      );
      return null;
    }
  }
}
