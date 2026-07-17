import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import 'catalog_management_controller.dart';

class CatalogManagementView extends GetView<CatalogManagementController> {
  const CatalogManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('catalog_management'.tr),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Categories'),
              Tab(text: 'Subcategories'),
              Tab(text: 'Items'),
              Tab(text: 'Properties'),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.categories.length,
        itemBuilder: (context, i) {
          final cat = controller.categories[i];
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
                        title: 'Delete Category',
                        middleText: 'Are you sure you want to delete this category?',
                        textConfirm: 'Delete',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        onConfirm: () {
                          controller.deleteRecord('categories', cat.id, imageUrl: cat.categoryImage);
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
    );
  }

  void _showCategoryDialog(BuildContext context, {dynamic category}) {
    final isEdit = category != null;
    final nameCtrl = TextEditingController(
      text: isEdit ? category.nameAr : '',
    );
    final nameEnCtrl = TextEditingController(
      text: isEdit ? category.nameEn : '',
    );
    final imgCtrl = TextEditingController(
      text: isEdit ? category.categoryImage : '',
    );

    XFile? pickedImage;
    bool isUploading = false;

    Get.defaultDialog(
      title: isEdit ? 'Edit Category' : 'Add Category',
      content: StatefulBuilder(builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (Arabic)'),
            ),
            TextField(
              controller: nameEnCtrl,
              decoration: const InputDecoration(labelText: 'Name (English)'),
            ),
            const SizedBox(height: 10),
            if (pickedImage != null)
              Text('Picked Image: ${pickedImage!.name}'),
            if (pickedImage == null && imgCtrl.text.isNotEmpty)
              const Text('Using existing image URL'),
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
              label: const Text('Pick Image'),
            ),
            if (isUploading) ...[
              const SizedBox(height: 10),
              const CircularProgressIndicator(),
            ],
          ],
        );
      }),
      confirm: StatefulBuilder(builder: (context, setState) {
        return ElevatedButton(
          onPressed: isUploading
              ? null
              : () async {
                  setState(() => isUploading = true);
                  
                  String finalImageUrl = imgCtrl.text;
                  
                  if (pickedImage != null) {
                    final uploadedUrl =
                        await controller.uploadCategoryImage(pickedImage!);
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
                    'image': finalImageUrl,
                  };
                  
                  if (isEdit) {
                    await controller.updateRecord('categories', category.id, data);
                  } else {
                    await controller.createRecord('categories', data);
                  }
                  
                  if (Get.isDialogOpen == true) {
                    Get.back();
                  }
                },
          child: const Text('Save'),
        );
      }),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.subCategories.length,
        itemBuilder: (context, i) {
          final subCat = controller.subCategories[i];
          return Card(
            child: ListTile(
              title: Text(subCat.subCategoryName),
              subtitle: Text('ID: ${subCat.id} | Cat ID: ${subCat.categoryId}'),
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
                        title: 'Delete Subcategory',
                        middleText: 'Are you sure you want to delete this subcategory?',
                        textConfirm: 'Delete',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        onConfirm: () {
                          controller.deleteRecord('sub_categories', subCat.id, imageUrl: subCat.subCategoryImage);
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
      title: isEdit ? 'Edit Subcategory' : 'Add Subcategory',
      content: StatefulBuilder(builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
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
                decoration: const InputDecoration(labelText: 'Name (Arabic)'),
              ),
              TextField(
                controller: nameEnCtrl,
                decoration: const InputDecoration(labelText: 'Name (English)'),
              ),
              const SizedBox(height: 10),
              if (pickedImage != null)
                Text('Picked Image: ${pickedImage!.name}'),
              if (pickedImage == null && imgCtrl.text.isNotEmpty)
                const Text('Using existing image URL'),
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
                label: const Text('Pick Image'),
              ),
              if (isUploading) ...[
                const SizedBox(height: 10),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        );
      }),
      confirm: StatefulBuilder(builder: (context, setState) {
        return ElevatedButton(
          onPressed: isUploading
              ? null
              : () async {
                  setState(() => isUploading = true);

                  String finalImageUrl = imgCtrl.text;

                  if (pickedImage != null) {
                    final uploadedUrl =
                        await controller.uploadCategoryImage(pickedImage!);
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
                    'subCategoryNameEN': nameEnCtrl.text,
                    'image': finalImageUrl,
                  };

                  if (isEdit) {
                    await controller.updateRecord('sub_categories', subCategory.id, data);
                  } else {
                    await controller.createRecord('sub_categories', data);
                  }

                  if (Get.isDialogOpen == true) {
                    Get.back();
                  }
                },
          child: const Text('Save'),
        );
      }),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.items.length,
        itemBuilder: (context, i) {
          final item = controller.items[i];
          return Card(
            child: ListTile(
              title: Text(item.itemName),
              subtitle: Text(
                'ID: ${item.id} | Cat: ${item.categoryId} | SubCat: ${item.subCategoryId}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showItemDialog(context, item: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Delete Item',
                        middleText: 'Are you sure you want to delete this item?',
                        textConfirm: 'Delete',
                        textCancel: 'Cancel',
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
    );
  }

  void _showItemDialog(BuildContext context, {dynamic item}) {
    final isEdit = item != null;
    final catIdCtrl = TextEditingController(
      text: isEdit ? item.categoryId.toString() : '',
    );
    final subCatIdCtrl = TextEditingController(
      text: isEdit ? item.subCategoryId.toString() : '',
    );
    final nameCtrl = TextEditingController(text: isEdit ? item.nameAr : '');
    final nameEnCtrl = TextEditingController(text: isEdit ? item.nameEn : '');
    final descCtrl = TextEditingController(
      text: isEdit ? item.descAr : '',
    );
    final descEnCtrl = TextEditingController(
      text: isEdit ? item.descEn : '',
    );
    bool isFeatured = isEdit ? item.isFeatured : false;

    Get.defaultDialog(
      title: isEdit ? 'Edit Item' : 'Add Item',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: catIdCtrl,
              decoration: const InputDecoration(labelText: 'Category ID'),
            ),
            TextField(
              controller: subCatIdCtrl,
              decoration: const InputDecoration(labelText: 'SubCategory ID'),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (Arabic)'),
            ),
            TextField(
              controller: nameEnCtrl,
              decoration: const InputDecoration(labelText: 'Name (English)'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description (Arabic)'),
            ),
            TextField(
              controller: descEnCtrl,
              decoration: const InputDecoration(labelText: 'Description (English)'),
            ),
          ],
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          final data = {
            'categoryID': int.tryParse(catIdCtrl.text) ?? 0,
            'subCategoryID': int.tryParse(subCatIdCtrl.text) ?? 0,
            'itemName': nameCtrl.text,
            'itemNameEN': nameEnCtrl.text,
            'itemDescription': descCtrl.text,
            'itemDescriptionEN': descEnCtrl.text,
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
        child: const Text('Save'),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.properties.length,
        itemBuilder: (context, i) {
          final prop = controller.properties[i];
          return Card(
            child: ListTile(
              title: Text(
                'Item ID: ${prop.itemId} - ${prop.propertyDescription}',
              ),
              subtitle: Text(
                'ID: ${prop.id} | Size: ${prop.sizeMl}ml | Price: ${prop.price}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () =>
                        _showPropertyDialog(context, property: prop),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Delete Property',
                        middleText: 'Are you sure you want to delete this property?',
                        textConfirm: 'Delete',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        onConfirm: () {
                          controller.deleteRecord('item_properties', prop.id, imageUrl: prop.image);
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
    final imgCtrl = TextEditingController(text: isEdit ? property.image : '');
    final descCtrl = TextEditingController(
      text: isEdit ? property.descAr : '',
    );
    final descEnCtrl = TextEditingController(
      text: isEdit ? property.descEn : '',
    );
    final affCtrl = TextEditingController(
      text: isEdit ? (property.affiliatePercentage?.toString() ?? '') : '',
    );

    XFile? pickedImage;
    bool isUploading = false;

    Get.defaultDialog(
      title: isEdit ? 'Edit Property' : 'Add Property',
      content: StatefulBuilder(builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemIdCtrl,
                decoration: const InputDecoration(labelText: 'Item ID'),
              ),
              TextField(
                controller: sizeCtrl,
                decoration: const InputDecoration(labelText: 'Size (ml)'),
              ),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (Arabic)'),
              ),
              TextField(
                controller: descEnCtrl,
                decoration: const InputDecoration(labelText: 'Description (English)'),
              ),
              TextField(
                controller: affCtrl,
                decoration: const InputDecoration(
                  labelText: 'Affiliate Percentage',
                ),
              ),
              const SizedBox(height: 10),
              if (pickedImage != null)
                Text('Picked Image: ${pickedImage!.name}'),
              if (pickedImage == null && imgCtrl.text.isNotEmpty)
                const Text('Using existing image URL'),
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
                label: const Text('Pick Image'),
              ),
              if (isUploading) ...[
                const SizedBox(height: 10),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        );
      }),
      confirm: StatefulBuilder(builder: (context, setState) {
        return ElevatedButton(
          onPressed: isUploading
              ? null
              : () async {
                  setState(() => isUploading = true);

                  String finalImageUrl = imgCtrl.text;

                  if (pickedImage != null) {
                    final uploadedUrl =
                        await controller.uploadCategoryImage(pickedImage!);
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
                    'image': finalImageUrl,
                    'PropertyDescription': descCtrl.text,
                    'PropertyDescriptionEN': descEnCtrl.text,
                    'affiliatePercentage': double.tryParse(affCtrl.text),
                  };

                  if (isEdit) {
                    await controller.updateRecord('item_properties', property.id, data);
                  } else {
                    await controller.createRecord('item_properties', data);
                  }

                  if (Get.isDialogOpen == true) {
                    Get.back();
                  }
                },
          child: const Text('Save'),
        );
      }),
    );
  }
}
