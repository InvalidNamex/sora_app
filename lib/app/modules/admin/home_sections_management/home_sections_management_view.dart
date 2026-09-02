import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/home_section_model.dart';
import 'home_sections_management_controller.dart';

class HomeSectionsManagementView
    extends GetView<HomeSectionsManagementController> {
  const HomeSectionsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home_sections'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchAll,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        icon: const Icon(Icons.add),
        label: Text('add_home_section'.tr),
      ),
      bottomNavigationBar: Obx(
        () => SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed:
                controller.hasUnsavedOrder.value &&
                    !controller.isSavingOrder.value
                ? controller.saveSectionOrder
                : null,
            icon: controller.isSavingOrder.value
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              controller.hasUnsavedOrder.value
                  ? 'save_section_order'.tr
                  : 'section_order_saved'.tr,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }
        if (controller.sectionOrder.isEmpty) {
          return Center(child: Text('create_first_home_section'.tr));
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: controller.sectionOrder.length,
          buildDefaultDragHandles: false,
          onReorder: controller.reorderSections,
          itemBuilder: (context, index) {
            final section = controller.sectionAt(index);
            return _SectionCard(
              key: ValueKey(section.id),
              section: section,
              index: index,
              onEdit: () => _showEditor(context, section),
              onDelete: () => _confirmDelete(context, section),
            );
          },
        );
      }),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HomeSectionModel section,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_home_section_title'.tr),
        content: Text(
          'delete_home_section_message'.trParams({'title': section.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteSection(section);
  }

  Future<void> _showEditor(
    BuildContext context, [
    HomeSectionModel? section,
  ]) async {
    final titleAr = TextEditingController(text: section?.titleAr ?? '');
    final titleEn = TextEditingController(text: section?.titleEn ?? '');
    final limit = TextEditingController(text: '${section?.itemLimit ?? 10}');
    var type = section?.type ?? 'manual';
    var active = section?.isActive ?? true;
    var selectedIds = {...?section?.itemIds};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      section == null
                          ? 'add_home_section'.tr
                          : 'edit_home_section'.tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: titleAr,
                      decoration: InputDecoration(labelText: 'arabic_title'.tr),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleEn,
                      decoration: InputDecoration(
                        labelText: 'english_title'.tr,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: InputDecoration(labelText: 'section_type'.tr),
                      items: [
                        DropdownMenuItem(
                          value: 'manual',
                          child: Text('custom_products'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'recently_added',
                          child: Text('recently_added'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'discounted',
                          child: Text('discounted_items'.tr),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => type = value ?? type),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: limit,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'maximum_products'.tr,
                      ),
                    ),
                    if (type == 'manual') ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ids = await _pickProducts(context, selectedIds);
                          if (ids != null) setState(() => selectedIds = ids);
                        },
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: Text(
                          'products_selected'.trParams({
                            'count': '${selectedIds.length}',
                          }),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: active,
                      activeThumbColor: AppConstants.darkBeige,
                      onChanged: (value) => setState(() => active = value),
                      title: Text('visible_on_home_page'.tr),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => FilledButton.icon(
                        onPressed: controller.isSaving.value
                            ? null
                            : () async {
                                final saved = await controller.saveSection(
                                  existing: section,
                                  titleAr: titleAr.text,
                                  titleEn: titleEn.text,
                                  type: type,
                                  itemLimit: int.tryParse(limit.text) ?? 10,
                                  isActive: active,
                                  itemIds: selectedIds.toList(),
                                );
                                if (saved && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        icon: controller.isSaving.value
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text('save_section'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The sheet's future completes when it starts closing, while its exit
    // animation can still rebuild the text fields for a few frames.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    titleAr.dispose();
    titleEn.dispose();
    limit.dispose();
  }

  Future<Set<int>?> _pickProducts(
    BuildContext context,
    Set<int> initial,
  ) async {
    var selected = {...initial};
    var query = '';
    return showDialog<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final matching = controller.products.where((product) {
            final normalized = query.trim().toLowerCase();
            return normalized.isEmpty ||
                product.itemName.toLowerCase().contains(normalized) ||
                product.brandName.toLowerCase().contains(normalized);
          }).toList();
          return AlertDialog(
            title: Text('select_products'.tr),
            content: SizedBox(
              width: 520,
              height: 460,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'search_products'.tr,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: matching.length,
                      itemBuilder: (_, index) {
                        final product = matching[index];
                        final label = product.brandName.isEmpty
                            ? product.itemName
                            : '${product.itemName} · ${product.brandName}';
                        return CheckboxListTile(
                          value: selected.contains(product.id),
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              selected.add(product.id);
                            } else {
                              selected.remove(product.id);
                            }
                          }),
                          title: Text(label),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, selected),
                child: Text('done'.tr),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.section,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final HomeSectionModel section;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeLabel = section.isRecentlyAdded
        ? 'recently_added'.tr
        : 'custom_products'.tr;
    final visibility = section.isActive ? '' : ' · ${'hidden'.tr}';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        title: Text(section.title),
        subtitle: Text(
          'home_section_summary'.trParams({
            'type': typeLabel,
            'count': '${section.itemLimit}',
            'visibility': visibility,
          }),
        ),
        trailing: Wrap(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
