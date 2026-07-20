import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/bundle_deal_model.dart';
import '../../../global_widgets/network_image_with_placeholder.dart';
import 'bundle_management_controller.dart';

class BundleManagementView extends GetView<BundleManagementController> {
  const BundleManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('bundle_management'.tr),
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: controller.fetchAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.beginCreate();
          _showEditor(context);
        },
        icon: const Icon(Icons.add),
        label: Text('create_bundle'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }
        if (controller.bundles.isEmpty) {
          return _EmptyBundles(
            onCreate: () {
              controller.beginCreate();
              _showEditor(context);
            },
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchAll,
          color: AppConstants.darkBeige,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: controller.bundles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final bundle = controller.bundles[index];
              return _BundleAdminCard(
                bundle: bundle,
                onEdit: () {
                  controller.beginEdit(bundle);
                  _showEditor(context);
                },
                onDelete: () => _confirmDelete(context, bundle),
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _showEditor(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BundleEditorDialog(),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BundleDealModel bundle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('delete_bundle'.tr),
        content: Text('delete_bundle_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteBundle(bundle);
  }
}

class _EmptyBundles extends StatelessWidget {
  const _EmptyBundles({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppConstants.mediumBeige,
          ),
          const SizedBox(height: 12),
          Text('no_bundles'.tr),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text('create_bundle'.tr),
          ),
        ],
      ),
    );
  }
}

class _BundleAdminCard extends StatelessWidget {
  const _BundleAdminCard({
    required this.bundle,
    required this.onEdit,
    required this.onDelete,
  });

  final BundleDealModel bundle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 112,
                height: 70,
                child: NetworkImageWithPlaceholder(
                  imageUrl: bundle.bannerImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bundle.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!bundle.isActive)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('inactive'.tr),
                        ),
                    ],
                  ),
                  Text(
                    '${bundle.items.length} ${'bundle_items'.tr} · '
                    '${AppConstants.currency} '
                    '${bundle.dealPrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              color: Colors.red.shade400,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _BundleEditorDialog extends GetView<BundleManagementController> {
  const _BundleEditorDialog();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Text(
                        controller.editingId.value == null
                            ? 'create_bundle'.tr
                            : 'edit_bundle'.tr,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.isSaving.value ? null : Get.back,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.titleCtrl,
                            decoration: InputDecoration(
                              labelText: 'bundle_title_ar'.tr,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: controller.titleEnCtrl,
                            decoration: InputDecoration(
                              labelText: 'bundle_title_en'.tr,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _BundleItemPicker(),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller.descriptionCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'bundle_description_ar'.tr,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.descriptionEnCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'bundle_description_en'.tr,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'bundle_deal_price'.tr,
                              prefixText: '${AppConstants.currency} ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: controller.sortOrderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'sort_order'.tr,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'bundle_banner'.tr,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final bytes = controller.pickedBannerBytes.value;
                      final existing = controller.existingBannerUrl.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (bytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 16 / 6,
                                child: Image.memory(bytes, fit: BoxFit.cover),
                              ),
                            )
                          else if (existing.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 16 / 6,
                                child: NetworkImageWithPlaceholder(
                                  imageUrl: existing,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: controller.pickBanner,
                            icon: const Icon(Icons.image_outlined),
                            label: Text('choose_bundle_banner'.tr),
                          ),
                        ],
                      );
                    }),
                    Obx(
                      () => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: controller.isActive.value,
                        onChanged: (value) => controller.isActive.value = value,
                        title: Text('bundle_active'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => FilledButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                              final saved = await controller.save();
                              if (saved && Get.isDialogOpen == true) Get.back();
                            },
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text('save'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BundleItemPicker extends GetView<BundleManagementController> {
  const _BundleItemPicker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppConstants.mediumBeige.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.mediumBeige.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'bundle_items'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isCatalogLoading.value) {
                return const SizedBox(
                  height: 56,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.darkBeige,
                    ),
                  ),
                );
              }
              if (controller.properties.isEmpty) {
                return Column(
                  children: [
                    Text(
                      controller.catalogLoadFailed.value
                          ? 'bundle_catalog_load_failed'.tr
                          : 'bundle_catalog_empty'.tr,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: controller.fetchCatalog,
                      icon: const Icon(Icons.refresh),
                      label: Text('retry'.tr),
                    ),
                  ],
                );
              }
              final selectedId = controller.selectedPropertyId.value;
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(selectedId),
                      initialValue: selectedId,
                      isExpanded: true,
                      menuMaxHeight: 360,
                      decoration: InputDecoration(
                        labelText: 'select_item_property'.tr,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: controller.properties
                          .map(
                            (property) => DropdownMenuItem(
                              value: property.id,
                              child: Text(
                                '${controller.itemNameForProperty(property)}'
                                ' · ${property.sizeMl} ml'
                                ' · ${AppConstants.currency} '
                                '${property.price.toStringAsFixed(2)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          controller.selectedPropertyId.value = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'add_bundle_item'.tr,
                    onPressed: selectedId == null
                        ? null
                        : controller.addSelectedProperty,
                    icon: const Icon(Icons.add),
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.draftQuantities.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'no_bundle_items_selected'.tr,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: controller.draftQuantities.entries.map((entry) {
                  final property = controller.propertyById(entry.key);
                  if (property == null) return const SizedBox.shrink();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(controller.itemNameForProperty(property)),
                    subtitle: Text(
                      '${property.sizeMl} ml · '
                      '${AppConstants.currency} '
                      '${property.price.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              controller.decrementDraftItem(entry.key),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () =>
                              controller.incrementDraftItem(entry.key),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        IconButton(
                          onPressed: () =>
                              controller.removeDraftItem(entry.key),
                          color: Colors.red.shade400,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
