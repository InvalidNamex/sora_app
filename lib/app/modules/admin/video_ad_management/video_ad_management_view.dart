import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/video_ad_model.dart';
import 'video_ad_management_controller.dart';

class VideoAdManagementView extends GetView<VideoAdManagementController> {
  const VideoAdManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Ads'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
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
        label: const Text('Create Ad'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }
        if (controller.ads.isEmpty) {
          return _EmptyAds(
            onCreate: () {
              controller.beginCreate();
              _showEditor(context);
            },
          );
        }
        return RefreshIndicator(
          color: AppConstants.darkBeige,
          onRefresh: controller.fetchAll,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: controller.ads.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ad = controller.ads[index];
              return _VideoAdCard(
                ad: ad,
                productLabel: controller.productLabel(ad.itemId),
                onEdit: () {
                  controller.beginEdit(ad);
                  _showEditor(context);
                },
                onDelete: () => _confirmDelete(context, ad),
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
      builder: (_) => const _VideoAdEditorDialog(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VideoAdModel ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Video Ad'),
        content: Text(
          'Delete the ad linked to ${controller.productLabel(ad.itemId)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteAd(ad);
  }
}

class _EmptyAds extends StatelessWidget {
  const _EmptyAds({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.smart_display_outlined,
            size: 64,
            color: AppConstants.mediumBeige,
          ),
          const SizedBox(height: 12),
          const Text('No video ads yet'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create Ad'),
          ),
        ],
      ),
    );
  }
}

class _VideoAdCard extends StatelessWidget {
  const _VideoAdCard({
    required this.ad,
    required this.productLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final VideoAdModel ad;
  final String productLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 54,
              decoration: BoxDecoration(
                color: AppConstants.lightBeige,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                ad.isVertical
                    ? Icons.stay_current_portrait
                    : Icons.stay_current_landscape,
                color: AppConstants.darkBeige,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ad.isVertical
                        ? 'Vertical · mobile and tablet'
                        : 'Horizontal · wide screens',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    [
                      if (ad.hasVideo) 'Video',
                      if (ad.hasBanner) 'Banner',
                    ].join(' + '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _VideoAdEditorDialog extends GetView<VideoAdManagementController> {
  const _VideoAdEditorDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
                            ? 'Create Video Ad'
                            : 'Edit Video Ad',
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller.urlCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Video URL (optional)',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final bytes = controller.pickedBannerBytes.value;
                      final existing = controller.existingBannerUrl.value;
                      final hasBanner =
                          bytes != null ||
                          (existing.isNotEmpty &&
                              !controller.clearExistingBanner.value);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: controller.pickBanner,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: Text(
                              bytes != null
                                  ? 'Replace banner (${controller.pickedBannerName.value})'
                                  : hasBanner
                                  ? 'Replace banner'
                                  : 'Upload banner (optional)',
                            ),
                          ),
                          if (hasBanner) ...[
                            const SizedBox(height: 8),
                            if (bytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  bytes,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Text(
                                'A banner is currently attached.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: () {
                                  controller.pickedBannerBytes.value = null;
                                  controller.pickedBannerName.value = '';
                                  controller.clearExistingBanner.value = true;
                                },
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove banner'),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    Obx(
                      () => SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.stay_current_portrait),
                            label: Text('Vertical'),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.stay_current_landscape),
                            label: Text('Horizontal'),
                          ),
                        ],
                        selected: {controller.isVertical.value},
                        onSelectionChanged: (value) =>
                            controller.isVertical.value = value.first,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _ProductSearchPicker(),
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => FilledButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                              final saved = await controller.save();
                              if (saved && Get.isDialogOpen == true) Navigator.of(context).pop();
                            },
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save'),
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

class _ProductSearchPicker extends GetView<VideoAdManagementController> {
  const _ProductSearchPicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedId = controller.selectedItemId.value;
      final selectedLabel = selectedId == null
          ? ''
          : controller.productLabel(selectedId);

      return SearchAnchor(
        viewConstraints: const BoxConstraints(maxHeight: 360),
        builder: (context, searchController) {
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => searchController.openView(),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Product',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                selectedLabel.isEmpty ? 'Select a product' : selectedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selectedLabel.isEmpty
                      ? Theme.of(context).hintColor
                      : null,
                ),
              ),
            ),
          );
        },
        suggestionsBuilder: (context, searchController) {
          final matches = controller.matchingProducts(searchController.text);
          if (matches.isEmpty) {
            return [
              const ListTile(
                enabled: false,
                title: Text('No matching products'),
              ),
            ];
          }
          return matches.take(40).map((product) {
            return ListTile(
              title: Text(product.itemName),
              subtitle: Text(_productSubtitle(product)),
              onTap: () {
                controller.selectedItemId.value = product.id;
                searchController.closeView(controller.productLabel(product.id));
              },
            );
          });
        },
      );
    });
  }

  String _productSubtitle(ItemModel product) {
    final brand = product.brandName.trim();
    return brand.isEmpty ? 'ID ${product.id}' : 'ID ${product.id} · $brand';
  }
}
