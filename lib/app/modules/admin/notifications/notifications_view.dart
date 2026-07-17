import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Center'),
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.isProcessingQueue.value
                  ? null
                  : controller.processQueueNow,
              icon: controller.isProcessingQueue.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_play),
              tooltip: 'Process Queue Now',
            ),
          ),
          IconButton(
            onPressed: controller.loadItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: DesktopConstraint(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Audience Filters',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: controller.androidOnly.value,
                      onChanged: (v) => controller.androidOnly.value = v,
                      title: const Text('Android only'),
                    ),
                    SwitchListTile.adaptive(
                      value: controller.arabicOnly.value,
                      onChanged: (v) => controller.arabicOnly.value = v,
                      title: const Text('Arabic language only'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Manual Campaign',
                child: Column(
                  children: [
                    TextField(
                      controller: controller.campaignTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Summer discounts are live',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.campaignBodyCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Up to 30% off selected items this week.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: controller.isSending.value
                            ? null
                            : controller.sendManualCampaign,
                        icon: const Icon(Icons.send),
                        label: const Text('Send Broadcast'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Promotion Notification',
                child: Column(
                  children: [
                    TextField(
                      controller: controller.promoCodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Promotion code',
                        hintText: 'SUMMER30',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.promotionBodyCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Use SUMMER30 for a limited-time discount.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: controller.isSending.value
                            ? null
                            : controller.queuePromotionAnnouncement,
                        icon: const Icon(Icons.local_offer_outlined),
                        label: const Text('Send Promotion Alert'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Featured Item Notification',
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: controller.selectedItemId.value,
                      decoration: const InputDecoration(
                        labelText: 'Featured item',
                      ),
                      items: controller.items
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text('#${item.id} ${item.itemName}'),
                            ),
                          )
                          .toList(),
                      onChanged: controller.isLoadingItems.value
                          ? null
                          : (v) => controller.selectedItemId.value = v,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: controller.isSending.value
                            ? null
                            : controller.queueFeaturedItemAnnouncement,
                        icon: const Icon(Icons.star_outline),
                        label: const Text('Send Featured Item Alert'),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isSending.value) ...[
                const SizedBox(height: 12),
                const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.darkBeige,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
