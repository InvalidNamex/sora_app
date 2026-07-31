import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/constants/app_constants.dart';
import '../../../core/models/item_suggestion_model.dart';
import '../../../core/utils/responsive.dart';
import 'item_suggestions_controller.dart';

class ItemSuggestionsView extends GetView<ItemSuggestionsController> {
  const ItemSuggestionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('item_suggestions'.tr),
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: controller.fetchSuggestions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: DesktopConstraint(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.statusFilter.value,
                  decoration: InputDecoration(
                    labelText: 'suggestion_status'.tr,
                    prefixIcon: const Icon(Icons.filter_list),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('all'.tr)),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('suggestion_pending'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('suggestion_approved'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('suggestion_rejected'.tr),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setStatusFilter(value);
                  },
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.darkBeige,
                    ),
                  );
                }
                if (controller.suggestions.isEmpty) {
                  return _EmptySuggestions(
                    onRefresh: controller.fetchSuggestions,
                  );
                }
                return RefreshIndicator(
                  color: AppConstants.darkBeige,
                  onRefresh: controller.fetchSuggestions,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: controller.suggestions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final suggestion = controller.suggestions[index];
                      return _SuggestionCard(
                        suggestion: suggestion,
                        isReviewing:
                            controller.reviewingId.value == suggestion.id,
                        onReview: () => _showReview(context, suggestion),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReview(
    BuildContext context,
    ItemSuggestionModel suggestion,
  ) async {
    final noteController = TextEditingController(text: suggestion.adminNote);
    var selectedStatus = suggestion.status;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('suggestion_review'.tr),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'suggestion_status'.tr,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('suggestion_pending'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('suggestion_approved'.tr),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('suggestion_rejected'.tr),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: 'suggestion_admin_note'.tr,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr),
            ),
            FilledButton.icon(
              onPressed: () async {
                final saved = await controller.review(
                  suggestion,
                  status: selectedStatus,
                  adminNote: noteController.text,
                );
                if (saved && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: Text('save'.tr),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.isReviewing,
    required this.onReview,
  });

  final ItemSuggestionModel suggestion;
  final bool isReviewing;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final contact = [
      suggestion.userName,
      suggestion.userPhone,
      suggestion.userEmail,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    final statusColor = switch (suggestion.status) {
      'approved' => Colors.green.shade700,
      'rejected' => Colors.red.shade700,
      _ => Colors.orange.shade800,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    suggestion.itemName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'suggestion_${suggestion.status}'.tr,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (suggestion.brandName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('${'brand'.tr}: ${suggestion.brandName}'),
            ],
            if (suggestion.details.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(suggestion.details),
            ],
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                contact,
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              intl.DateFormat.yMMMd(
                Get.locale?.languageCode,
              ).add_jm().format(suggestion.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (suggestion.adminNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${'suggestion_admin_note'.tr}: ${suggestion.adminNote}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                onPressed: isReviewing ? null : onReview,
                icon: isReviewing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rate_review_outlined),
                label: Text('suggestion_review'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySuggestions extends StatelessWidget {
  const _EmptySuggestions({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.playlist_add_outlined,
            size: 56,
            color: AppConstants.mediumBeige,
          ),
          const SizedBox(height: 12),
          Text('no_item_suggestions'.tr),
          const SizedBox(height: 12),
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
