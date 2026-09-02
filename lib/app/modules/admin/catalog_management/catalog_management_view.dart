import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/item_property_model.dart';
import '../../../core/utils/responsive.dart';
import 'catalog_management_controller.dart';

List<String> _parsePerfumeTerms(String input) => input
    .split(RegExp(r'[\n,،]'))
    .map((term) => term.trim())
    .where((term) => term.isNotEmpty)
    .toList(growable: false);

List<int>? _parseAccordPercentages(String input) {
  final terms = input
      .split(RegExp(r'[\n,،]'))
      .map((term) => term.trim().replaceAll('%', ''))
      .where((term) => term.isNotEmpty);
  final percentages = <int>[];

  for (final term in terms) {
    final percentage = int.tryParse(term);
    if (percentage == null || percentage < 0 || percentage > 100) {
      return null;
    }
    percentages.add(percentage);
  }
  return percentages;
}

int _parsePerfumeRating(String input) {
  final rating = int.tryParse(input.trim()) ?? 3;
  return rating.clamp(1, 5);
}

class _AdminSearchField extends StatelessWidget {
  const _AdminSearchField({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }
}

class CatalogManagementView extends GetView<CatalogManagementController> {
  const CatalogManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('catalog_management'.tr),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'categories'.tr),
              Tab(text: 'subcategories'.tr),
              Tab(text: 'items'.tr),
              Tab(text: 'properties'.tr),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.fetchAll,
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppConstants.darkBeige),
            );
          }
          return DesktopConstraint(
            child: TabBarView(
              children: [
                _CategoriesTab(),
                _SubCategoriesTab(),
                _ItemsTab(),
                _PropertiesTab(),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CategoriesTab extends GetView<CatalogManagementController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _AdminSearchField(
            hintText: 'search_categories'.tr,
            onChanged: (value) => controller.categorySearch.value = value,
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredCategories.length,
                itemBuilder: (context, i) {
                  final cat = controller.filteredCategories[i];
                  return Card(
                    child: ListTile(
                      title: Text(cat.categoryName),
                      subtitle: Text('ID: ${cat.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showCategoryDialog(context, category: cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Get.defaultDialog(
                                title: 'delete_category'.tr,
                                middleText: 'delete_category_message'.tr,
                                textConfirm: 'delete'.tr,
                                textCancel: 'cancel'.tr,
                                confirmTextColor: Colors.white,
                                onConfirm: () {
                                  controller.deleteRecord(
                                    'categories',
                                    cat.id,
                                    imageUrl: cat.categoryImage,
                                  );
                                  if (Get.isDialogOpen == true) Get.back();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {dynamic category}) {
    final isEdit = category != null;
    final nameCtrl = TextEditingController(text: isEdit ? category.nameAr : '');
    final nameEnCtrl = TextEditingController(
      text: isEdit ? category.nameEn : '',
    );
    final imgCtrl = TextEditingController(
      text: isEdit ? category.categoryImage : '',
    );

    XFile? pickedImage;
    bool isUploading = false;

    Get.defaultDialog(
      title: isEdit ? 'edit_category'.tr : 'add_category'.tr,
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'name_ar'.tr),
              ),
              TextField(
                controller: nameEnCtrl,
                decoration: InputDecoration(labelText: 'name_en'.tr),
              ),
              const SizedBox(height: 10),
              if (pickedImage != null)
                Text('picked_image'.trParams({'name': pickedImage!.name})),
              if (pickedImage == null && imgCtrl.text.isNotEmpty)
                Text('using_existing_image'.tr),
              ElevatedButton.icon(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() {
                      pickedImage = image;
                    });
                  }
                },
                icon: const Icon(Icons.image),
                label: Text('pick_image'.tr),
              ),
              if (isUploading) ...[
                const SizedBox(height: 10),
                const CircularProgressIndicator(),
              ],
            ],
          );
        },
      ),
      confirm: StatefulBuilder(
        builder: (context, setState) {
          return ElevatedButton(
            onPressed: isUploading
                ? null
                : () async {
                    setState(() => isUploading = true);

                    String finalImageUrl = imgCtrl.text;

                    if (pickedImage != null) {
                      final uploadedUrl = await controller.uploadCategoryImage(
                        pickedImage!,
                      );
                      if (uploadedUrl != null) {
                        finalImageUrl = uploadedUrl;
                      } else {
                        setState(() => isUploading = false);
                        return; // Upload failed, don't proceed
                      }
                    }

                    final data = {
                      'categoryName': nameCtrl.text,
                      'categoryEN': nameEnCtrl.text,
                      'categoryImage': finalImageUrl,
                    };

                    if (isEdit) {
                      await controller.updateRecord(
                        'categories',
                        category.id,
                        data,
                      );
                    } else {
                      await controller.createRecord('categories', data);
                    }

                    if (Get.isDialogOpen == true) {
                      Get.back();
                    }
                  },
            child: Text('save'.tr),
          );
        },
      ),
    );
  }
}

class _SubCategoriesTab extends GetView<CatalogManagementController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubCatDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _AdminSearchField(
            hintText: 'search_subcategories'.tr,
            onChanged: (value) => controller.subCategorySearch.value = value,
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredSubCategories.length,
                itemBuilder: (context, i) {
                  final subCat = controller.filteredSubCategories[i];
                  return Card(
                    child: ListTile(
                      title: Text(subCat.subCategoryName),
                      subtitle: Text(
                        'ID: ${subCat.id} | Cat ID: ${subCat.categoryId}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showSubCatDialog(context, subCategory: subCat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Get.defaultDialog(
                                title: 'delete_subcategory'.tr,
                                middleText: 'delete_subcategory_message'.tr,
                                textConfirm: 'delete'.tr,
                                textCancel: 'cancel'.tr,
                                confirmTextColor: Colors.white,
                                onConfirm: () {
                                  controller.deleteRecord(
                                    'sub_categories',
                                    subCat.id,
                                    imageUrl: subCat.subCategoryImage,
                                  );
                                  if (Get.isDialogOpen == true) Get.back();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubCatDialog(BuildContext context, {dynamic subCategory}) {
    final isEdit = subCategory != null;
    final nameCtrl = TextEditingController(
      text: isEdit ? subCategory.nameAr : '',
    );
    final nameEnCtrl = TextEditingController(
      text: isEdit ? subCategory.nameEn : '',
    );
    final imgCtrl = TextEditingController(
      text: isEdit ? subCategory.subCategoryImage : '',
    );

    int? selectedCategoryId = isEdit ? subCategory.categoryId : null;

    XFile? pickedImage;
    bool isUploading = false;

    Get.defaultDialog(
      title: isEdit ? 'edit_subcategory'.tr : 'add_subcategory'.tr,
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedCategoryId,
                  decoration: InputDecoration(labelText: 'category'.tr),
                  items: controller.categories.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat.id,
                      child: Text(cat.categoryName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCategoryId = val;
                    });
                  },
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: 'name_ar'.tr),
                ),
                TextField(
                  controller: nameEnCtrl,
                  decoration: InputDecoration(labelText: 'name_en'.tr),
                ),
                const SizedBox(height: 10),
                if (pickedImage != null)
                  Text('picked_image'.trParams({'name': pickedImage!.name})),
                if (pickedImage == null && imgCtrl.text.isNotEmpty)
                  Text('using_existing_image'.tr),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        pickedImage = image;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text('pick_image'.tr),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 10),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          );
        },
      ),
      confirm: StatefulBuilder(
        builder: (context, setState) {
          return ElevatedButton(
            onPressed: isUploading
                ? null
                : () async {
                    setState(() => isUploading = true);

                    String finalImageUrl = imgCtrl.text;

                    if (pickedImage != null) {
                      final uploadedUrl = await controller.uploadCategoryImage(
                        pickedImage!,
                      );
                      if (uploadedUrl != null) {
                        finalImageUrl = uploadedUrl;
                      } else {
                        setState(() => isUploading = false);
                        return;
                      }
                    }

                    final data = {
                      'categoryID': selectedCategoryId ?? 0,
                      'subCategoryName': nameCtrl.text,
                      'subCategoryEN': nameEnCtrl.text,
                      'subCategoryImage': finalImageUrl,
                    };

                    if (isEdit) {
                      await controller.updateRecord(
                        'sub_categories',
                        subCategory.id,
                        data,
                      );
                    } else {
                      await controller.createRecord('sub_categories', data);
                    }

                    if (Get.isDialogOpen == true) {
                      Get.back();
                    }
                  },
            child: Text('save'.tr),
          );
        },
      ),
    );
  }
}

class _ItemsTab extends GetView<CatalogManagementController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _AdminSearchField(
            hintText: 'search_catalog_items'.tr,
            onChanged: (value) => controller.itemSearch.value = value,
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredItems.length,
                itemBuilder: (context, i) {
                  final item = controller.filteredItems[i];
                  return Card(
                    child: ListTile(
                      title: Text(item.itemName),
                      subtitle: Text(
                        [
                          if (item.brandName.isNotEmpty) item.brandName,
                          'ID: ${item.id}',
                          'Cat: ${item.categoryId}',
                          'SubCat: ${item.subCategoryId}',
                        ].join(' | '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showItemDialog(context, item: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Get.defaultDialog(
                                title: 'delete_item'.tr,
                                middleText: 'delete_item_message'.tr,
                                textConfirm: 'delete'.tr,
                                textCancel: 'cancel'.tr,
                                confirmTextColor: Colors.white,
                                onConfirm: () {
                                  controller.deleteRecord('items', item.id);
                                  if (Get.isDialogOpen == true) Get.back();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDialog(BuildContext context, {dynamic item}) {
    final isEdit = item != null;
    int? selectedCategoryId =
        isEdit &&
            controller.categories.any(
              (category) => category.id == item.categoryId,
            )
        ? item.categoryId
        : null;
    int? selectedSubCategoryId =
        isEdit &&
            controller.subCategories.any(
              (subCategory) => subCategory.id == item.subCategoryId,
            )
        ? item.subCategoryId
        : null;
    final nameCtrl = TextEditingController(text: isEdit ? item.nameAr : '');
    final nameEnCtrl = TextEditingController(text: isEdit ? item.nameEn : '');
    final brandCtrl = TextEditingController(text: isEdit ? item.brandName : '');
    final descCtrl = TextEditingController(text: isEdit ? item.descAr : '');
    final descEnCtrl = TextEditingController(text: isEdit ? item.descEn : '');
    final topNotesCtrl = TextEditingController(
      text: isEdit ? item.topNotesAr.join('\n') : '',
    );
    final topNotesEnCtrl = TextEditingController(
      text: isEdit ? item.topNotesEn.join('\n') : '',
    );
    final middleNotesCtrl = TextEditingController(
      text: isEdit ? item.middleNotesAr.join('\n') : '',
    );
    final middleNotesEnCtrl = TextEditingController(
      text: isEdit ? item.middleNotesEn.join('\n') : '',
    );
    final baseNotesCtrl = TextEditingController(
      text: isEdit ? item.baseNotesAr.join('\n') : '',
    );
    final baseNotesEnCtrl = TextEditingController(
      text: isEdit ? item.baseNotesEn.join('\n') : '',
    );
    final accordsCtrl = TextEditingController(
      text: isEdit ? item.accordsAr.join('\n') : '',
    );
    final accordsEnCtrl = TextEditingController(
      text: isEdit ? item.accordsEn.join('\n') : '',
    );
    final accordPercentagesCtrl = TextEditingController(
      text: isEdit ? item.accordPercentages.join('\n') : '',
    );
    final sillageCtrl = TextEditingController(
      text: isEdit ? item.sillage.toString() : '3',
    );
    final longevityCtrl = TextEditingController(
      text: isEdit ? item.longevity.toString() : '3',
    );
    bool isFeatured = isEdit ? item.isFeatured : false;

    Get.defaultDialog(
      title: isEdit ? 'edit_item'.tr : 'add_item'.tr,
      content: StatefulBuilder(
        builder: (context, setState) {
          final availableSubCategories = controller.subCategories
              .where(
                (subCategory) => subCategory.categoryId == selectedCategoryId,
              )
              .toList(growable: false);
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(context).height * 0.62,
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'category'.tr),
                      items: controller.categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.categoryName),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() {
                        selectedCategoryId = value;
                        selectedSubCategoryId = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedSubCategoryId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'subcategory'.tr),
                      items: availableSubCategories
                          .map(
                            (subCategory) => DropdownMenuItem(
                              value: subCategory.id,
                              child: Text(subCategory.subCategoryName),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: selectedCategoryId == null
                          ? null
                          : (value) =>
                                setState(() => selectedSubCategoryId = value),
                    ),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: 'name_ar'.tr),
                    ),
                    TextField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(labelText: 'name_en'.tr),
                    ),
                    TextField(
                      controller: brandCtrl,
                      decoration: InputDecoration(labelText: 'brand'.tr),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'description_ar'.tr,
                      ),
                    ),
                    TextField(
                      controller: descEnCtrl,
                      decoration: InputDecoration(
                        labelText: 'description_en'.tr,
                      ),
                    ),
                    TextField(
                      controller: topNotesCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "${'top_notes'.tr} (${'language_ar'.tr})",
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: topNotesEnCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "${'top_notes'.tr} (${'language_en'.tr})",
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: middleNotesCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "${'middle_notes'.tr} (${'language_ar'.tr})",
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: middleNotesEnCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "${'middle_notes'.tr} (${'language_en'.tr})",
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: baseNotesCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "${'base_notes'.tr} (${'language_ar'.tr})",
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: baseNotesEnCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "${'base_notes'.tr} (${'language_en'.tr})",
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: accordsCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "${'main_accords'.tr} (${'language_ar'.tr})",
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: accordsEnCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "${'main_accords'.tr} (${'language_en'.tr})",
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: accordPercentagesCtrl,
                      minLines: 2,
                      maxLines: 4,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${'accord_intensity'.tr} (%)',
                        helperText: 'one_term_per_line'.tr,
                      ),
                    ),
                    TextField(
                      controller: sillageCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'sillage_range'.tr,
                      ),
                    ),
                    TextField(
                      controller: longevityCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'longevity_range'.tr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          final topNotes = _parsePerfumeTerms(topNotesCtrl.text);
          final topNotesEn = _parsePerfumeTerms(topNotesEnCtrl.text);
          final middleNotes = _parsePerfumeTerms(middleNotesCtrl.text);
          final middleNotesEn = _parsePerfumeTerms(middleNotesEnCtrl.text);
          final baseNotes = _parsePerfumeTerms(baseNotesCtrl.text);
          final baseNotesEn = _parsePerfumeTerms(baseNotesEnCtrl.text);
          final accords = _parsePerfumeTerms(accordsCtrl.text);
          final accordsEn = _parsePerfumeTerms(accordsEnCtrl.text);
          final accordPercentages = _parseAccordPercentages(
            accordPercentagesCtrl.text,
          );

          if (accordPercentages == null ||
              accords.length != accordsEn.length ||
              accords.length != accordPercentages.length) {
            Get.snackbar('error'.tr, 'accord_percentage_mismatch'.tr);
            return;
          }

          final data = {
            'categoryID': selectedCategoryId ?? 0,
            'subCategoryID': selectedSubCategoryId ?? 0,
            'itemName': nameCtrl.text,
            'itemNameEN': nameEnCtrl.text,
            'brandName': brandCtrl.text.trim(),
            'itemDescription': descCtrl.text,
            'itemDescriptionEN': descEnCtrl.text,
            'topNotes': topNotes,
            'topNotesEN': topNotesEn,
            'middleNotes': middleNotes,
            'middleNotesEN': middleNotesEn,
            'baseNotes': baseNotes,
            'baseNotesEN': baseNotesEn,
            'notes': [...topNotes, ...middleNotes, ...baseNotes],
            'notesEN': [...topNotesEn, ...middleNotesEn, ...baseNotesEn],
            'accords': accords,
            'accordsEN': accordsEn,
            'accordPercentages': accordPercentages,
            'sillage': _parsePerfumeRating(sillageCtrl.text),
            'longevity': _parsePerfumeRating(longevityCtrl.text),
            'isFeatured': isFeatured,
          };
          if (isEdit) {
            await controller.updateRecord('items', item.id, data);
          } else {
            await controller.createRecord('items', data);
          }
          if (Get.isDialogOpen == true) {
            Get.back();
          }
        },
        child: Text('save'.tr),
      ),
    );
  }
}

class _PropertiesTab extends GetView<CatalogManagementController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPropertyDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _AdminSearchField(
            hintText: 'search_properties'.tr,
            onChanged: (value) => controller.propertySearch.value = value,
          ),
          Expanded(
            child: Obx(() {
              final groups = controller.groupedFilteredProperties;
              final itemIds = groups.keys.toList()
                ..sort((left, right) {
                  final leftName = controller.itemForId(left)?.itemName ?? '';
                  final rightName = controller.itemForId(right)?.itemName ?? '';
                  return leftName.toLowerCase().compareTo(
                    rightName.toLowerCase(),
                  );
                });
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: itemIds.length,
                itemBuilder: (context, i) {
                  final itemId = itemIds[i];
                  final item = controller.itemForId(itemId);
                  final properties = groups[itemId]!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        item?.itemName.isNotEmpty == true
                            ? item!.itemName
                            : 'item_id_label'.trParams({'id': '$itemId'}),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'property_count'.trParams({
                          'count': '${properties.length}',
                        }),
                      ),
                      children: [
                        for (final prop in properties)
                          ListTile(
                            dense: true,
                            title: Text(
                              '${prop.sizeMl} ml · ${prop.propertyDescription}',
                            ),
                            subtitle: Text(
                              '${'price'.tr}: ${prop.price.toStringAsFixed(2)}'
                              '${prop.hasDiscount ? ' · ${prop.discountPercentage.toStringAsFixed(0)}% ${'off'.tr}' : ''}',
                            ),
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showPropertyDialog(
                                    context,
                                    property: prop,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteProperty(context, prop),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProperty(
    BuildContext context,
    ItemPropertyModel property,
  ) {
    Get.defaultDialog(
      title: 'delete_property'.tr,
      middleText: 'delete_property_message'.tr,
      textConfirm: 'delete'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.deleteRecord(
          'item_properties',
          property.id,
          imageUrl: property.image,
        );
        if (Get.isDialogOpen == true) Get.back();
      },
    );
  }

  void _showPropertyDialog(BuildContext context, {dynamic property}) {
    final isEdit = property != null;
    final itemIdCtrl = TextEditingController(
      text: isEdit ? property.itemId.toString() : '',
    );
    final sizeCtrl = TextEditingController(
      text: isEdit ? property.sizeMl.toString() : '',
    );
    final priceCtrl = TextEditingController(
      text: isEdit ? property.price.toString() : '',
    );
    final discountCtrl = TextEditingController(
      text: isEdit ? property.discountPercentage.toString() : '0',
    );
    final imgCtrl = TextEditingController(text: isEdit ? property.image : '');
    final descCtrl = TextEditingController(text: isEdit ? property.descAr : '');
    final descEnCtrl = TextEditingController(
      text: isEdit ? property.descEn : '',
    );
    XFile? pickedImage;
    bool isUploading = false;

    Get.defaultDialog(
      title: isEdit ? 'edit_property'.tr : 'add_property'.tr,
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: itemIdCtrl,
                  decoration: InputDecoration(labelText: 'item_id'.tr),
                ),
                TextField(
                  controller: sizeCtrl,
                  decoration: InputDecoration(labelText: 'size_ml'.tr),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: InputDecoration(labelText: 'price'.tr),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: discountCtrl,
                  decoration: InputDecoration(
                    labelText: 'discount_percent'.tr,
                    helperText: 'discount_applies_to_size'.tr,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: 'description_ar'.tr),
                ),
                TextField(
                  controller: descEnCtrl,
                  decoration: InputDecoration(labelText: 'description_en'.tr),
                ),
                const SizedBox(height: 10),
                if (pickedImage != null)
                  Text('picked_image'.trParams({'name': pickedImage!.name})),
                if (pickedImage == null && imgCtrl.text.isNotEmpty)
                  Text('using_existing_image'.tr),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        pickedImage = image;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text('pick_image'.tr),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 10),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          );
        },
      ),
      confirm: StatefulBuilder(
        builder: (context, setState) {
          return ElevatedButton(
            onPressed: isUploading
                ? null
                : () async {
                    setState(() => isUploading = true);

                    String finalImageUrl = imgCtrl.text;

                    if (pickedImage != null) {
                      final uploadedUrl = await controller.uploadCategoryImage(
                        pickedImage!,
                      );
                      if (uploadedUrl != null) {
                        finalImageUrl = uploadedUrl;
                      } else {
                        setState(() => isUploading = false);
                        return;
                      }
                    }

                    final data = {
                      'itemID': int.tryParse(itemIdCtrl.text) ?? 0,
                      'size': int.tryParse(sizeCtrl.text) ?? 0,
                      'price': double.tryParse(priceCtrl.text) ?? 0.0,
                      'discountPercentage':
                          (double.tryParse(discountCtrl.text) ?? 0.0).clamp(
                            0,
                            100,
                          ),
                      'image': finalImageUrl,
                      'PropertyDescription': descCtrl.text,
                      'propertyDescriptionEN': descEnCtrl.text,
                    };

                    if (isEdit) {
                      await controller.updateRecord(
                        'item_properties',
                        property.id,
                        data,
                      );
                    } else {
                      await controller.createRecord('item_properties', data);
                    }

                    if (Get.isDialogOpen == true) {
                      Get.back();
                    }
                  },
            child: Text('save'.tr),
          );
        },
      ),
    );
  }
}
