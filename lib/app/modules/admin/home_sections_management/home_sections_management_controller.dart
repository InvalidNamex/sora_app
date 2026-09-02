import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/models/home_section_model.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../home/home_controller.dart';

class HomeSectionsManagementController extends GetxController {
  static HomeSectionsManagementController get to => Get.find();

  final sections = <HomeSectionModel>[].obs;
  final sectionOrder = <int>[].obs;
  final products = <ItemModel>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isSavingOrder = false.obs;
  final hasUnsavedOrder = false.obs;

  @override
  void onReady() {
    super.onReady();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      await Future.wait([fetchSections(), fetchProducts()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSections() async {
    try {
      final fetchedSections = await _fetchSectionsFromDatabase();
      sections.assignAll(fetchedSections);
      sectionOrder.assignAll(fetchedSections.map((section) => section.id));
      hasUnsavedOrder.value = false;
    } catch (error) {
      debugPrint('[HomeSectionsManagement] fetch sections error: $error');
      AppSnackbar.show(
        'error'.tr,
        'home_sections_load_failed'.trParams({'error': '$error'}),
        type: AppSnackbarType.error,
      );
    }
  }

  Future<List<HomeSectionModel>> _fetchSectionsFromDatabase() async {
    final response = await SupabaseService.client
        .from('home_sections')
        .select(
          'id, title, titleEN, section_type, item_limit, display_order, '
          'is_active, home_section_items(itemID, display_order)',
        )
        .order('display_order', ascending: true)
        .order('id', ascending: true);
    final parsed = (response as List)
        .whereType<Map>()
        .map((row) => HomeSectionModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
    parsed.sort((left, right) {
      final byDisplayOrder = left.displayOrder.compareTo(right.displayOrder);
      return byDisplayOrder == 0 ? left.id.compareTo(right.id) : byDisplayOrder;
    });
    return List<HomeSectionModel>.unmodifiable(parsed);
  }

  HomeSectionModel sectionAt(int index) {
    final sectionId = sectionOrder[index];
    return sections.firstWhere((section) => section.id == sectionId);
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
          .order('itemName');
      products.value = (response as List)
          .whereType<Map>()
          .map((row) => ItemModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      debugPrint('[HomeSectionsManagement] fetch products error: $error');
    }
  }

  Future<bool> saveSection({
    HomeSectionModel? existing,
    required String titleAr,
    required String titleEn,
    required String type,
    required int itemLimit,
    required bool isActive,
    required List<int> itemIds,
  }) async {
    final trimmedTitle = titleAr.trim();
    if (trimmedTitle.isEmpty) {
      AppSnackbar.show(
        'error'.tr,
        'arabic_title_required'.tr,
        type: AppSnackbarType.warning,
      );
      return false;
    }
    if (type == 'manual' && itemIds.isEmpty) {
      AppSnackbar.show(
        'error'.tr,
        'manual_section_product_required'.tr,
        type: AppSnackbarType.warning,
      );
      return false;
    }

    isSaving.value = true;
    try {
      final data = {
        'title': trimmedTitle,
        'titleEN': titleEn.trim(),
        'section_type': type,
        'item_limit': itemLimit.clamp(1, 30),
        'is_active': isActive,
      };
      final int sectionId;
      if (existing == null) {
        data['display_order'] = sections.length;
        final inserted = await SupabaseService.client
            .from('home_sections')
            .insert(data)
            .select('id')
            .single();
        sectionId = (inserted['id'] as num).toInt();
      } else {
        sectionId = existing.id;
        await SupabaseService.client
            .from('home_sections')
            .update(data)
            .eq('id', sectionId);
      }

      await SupabaseService.client
          .from('home_section_items')
          .delete()
          .eq('section_id', sectionId);
      if (type == 'manual') {
        await SupabaseService.client.from('home_section_items').insert([
          for (var index = 0; index < itemIds.length; index++)
            {
              'section_id': sectionId,
              'itemID': itemIds[index],
              'display_order': index,
            },
        ]);
      }
      await fetchSections();
      AppSnackbar.show(
        'success'.tr,
        'home_section_saved'.tr,
        type: AppSnackbarType.success,
      );
      return true;
    } catch (error) {
      debugPrint('[HomeSectionsManagement] save error: $error');
      AppSnackbar.show(
        'error'.tr,
        'home_section_save_failed'.trParams({'error': '$error'}),
        type: AppSnackbarType.error,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteSection(HomeSectionModel section) async {
    try {
      await SupabaseService.client
          .from('home_sections')
          .delete()
          .eq('id', section.id);
      await fetchSections();
      AppSnackbar.show(
        'success'.tr,
        'home_section_deleted'.tr,
        type: AppSnackbarType.success,
      );
    } catch (error) {
      AppSnackbar.show(
        'error'.tr,
        'home_section_delete_failed'.trParams({'error': '$error'}),
        type: AppSnackbarType.error,
      );
    }
  }

  void reorderSections(int oldIndex, int newIndex) {
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex--;
      // With an explicit drag handle Flutter can report an adjacent downward
      // drop as the next item's index rather than the gap after it. Treat that
      // as a swap instead of reducing it back to the original position.
      if (targetIndex == oldIndex && newIndex < sectionOrder.length) {
        targetIndex = newIndex;
      }
    }
    final reordered = sectionOrder.toList();
    final sectionId = reordered.removeAt(oldIndex);
    targetIndex = targetIndex.clamp(0, reordered.length);
    if (targetIndex == oldIndex) return;
    reordered.insert(targetIndex, sectionId);
    sectionOrder.assignAll(reordered);
    hasUnsavedOrder.value = !listEquals(
      reordered,
      sections.map((section) => section.id).toList(growable: false),
    );
  }

  Future<void> saveSectionOrder() async {
    if (!hasUnsavedOrder.value || isSavingOrder.value) return;
    isSavingOrder.value = true;
    final requestedOrder = sectionOrder.toList(growable: false);
    try {
      final response = await SupabaseService.client.rpc(
        'admin_reorder_home_sections',
        params: {'p_section_ids': requestedOrder},
      );
      final persistedRows =
          (response as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false)
            ..sort(
              (left, right) => ((left['persisted_order'] as num?)?.toInt() ?? 0)
                  .compareTo((right['persisted_order'] as num?)?.toInt() ?? 0),
            );
      final persistedOrder = persistedRows
          .map((row) => (row['section_id'] as num?)?.toInt())
          .whereType<int>()
          .toList(growable: false);
      if (!listEquals(requestedOrder, persistedOrder)) {
        throw StateError(
          'The database returned a different order. '
          'Requested $requestedOrder, received $persistedOrder.',
        );
      }
      final sectionsById = {
        for (final section in sections) section.id: section,
      };
      sections.assignAll(
        requestedOrder
            .map((id) => sectionsById[id])
            .whereType<HomeSectionModel>(),
      );
      sectionOrder.assignAll(persistedOrder);
      hasUnsavedOrder.value = false;
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().applyHomeSectionOrder(persistedOrder);
      }
      AppSnackbar.show(
        'success'.tr,
        'section_order_saved'.tr,
        type: AppSnackbarType.success,
      );
    } catch (error) {
      debugPrint('[HomeSectionsManagement] reorder error: $error');
      AppSnackbar.show(
        'error'.tr,
        'section_order_save_failed'.trParams({'error': '$error'}),
        type: AppSnackbarType.error,
      );
    } finally {
      isSavingOrder.value = false;
    }
  }
}
