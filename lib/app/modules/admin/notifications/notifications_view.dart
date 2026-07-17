import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/in_app_message_model.dart';
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
        child: Obx(() {
          controller.inAppPreviewRevision.value;
          return ListView(
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
                        labelText: 'Header',
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.campaignUrlCtrl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Destination URL (optional)',
                        hintText: '/item/1 or https://instagram.com/p/example',
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
                title: 'In-App Messaging',
                child: _InAppMessagingComposer(controller: controller),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Featured Item Notification',
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: controller.selectedItemId.value,
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
          );
        }),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

class _InAppMessagingComposer extends StatelessWidget {
  const _InAppMessagingComposer({required this.controller});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final type = controller.inAppType.value;
    final isImage = type == InAppMessageType.image;
    final isCard = type == InAppMessageType.card;
    final hasButton = isCard || type == InAppMessageType.modal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Format',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<InAppMessageType>(
            showSelectedIcon: false,
            segments: InAppMessageType.values
                .map(
                  (messageType) => ButtonSegment(
                    value: messageType,
                    icon: Icon(messageType.icon, size: 18),
                    label: Text(messageType.label),
                  ),
                )
                .toList(),
            selected: {type},
            onSelectionChanged: (selection) {
              controller.inAppType.value = selection.first;
            },
          ),
        ),
        const SizedBox(height: 16),
        if (!isImage) ...[
          TextField(
            controller: controller.inAppTitleCtrl,
            decoration: const InputDecoration(
              labelText: 'Header',
              hintText: 'A limited offer for you',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.inAppBodyCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Discover this week’s featured collection.',
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller.inAppImageUrlCtrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: isImage ? 'Image URL' : 'Image URL (optional)',
                  hintText: 'https://...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: controller.isUploadingInAppImage.value
                  ? null
                  : controller.pickInAppImage,
              icon: controller.isUploadingInAppImage.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              label: const Text('Upload'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!isImage) ...[
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                _HexColorField(
                  controller: controller.inAppBackgroundColorCtrl,
                  label: 'Background',
                  fallback: Colors.white,
                ),
                _HexColorField(
                  controller: controller.inAppTextColorCtrl,
                  label: 'Text',
                  fallback: const Color(0xFF171717),
                ),
                if (hasButton)
                  _HexColorField(
                    controller: controller.inAppButtonColorCtrl,
                    label: 'Button',
                    fallback: AppConstants.darkBeige,
                  ),
                if (hasButton)
                  _HexColorField(
                    controller: controller.inAppButtonTextColorCtrl,
                    label: 'Button text',
                    fallback: Colors.white,
                  ),
              ];

              if (constraints.maxWidth < 560) {
                return Column(
                  children: fields
                      .map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: field,
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fields
                    .map(
                      (field) => SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: field,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        const Text(
          'Action',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (hasButton) ...[
          TextField(
            controller: controller.inAppPrimaryButtonCtrl,
            decoration: const InputDecoration(
              labelText: 'Primary button text (optional)',
              hintText: 'Shop now',
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller.inAppPrimaryUrlCtrl,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: hasButton
                ? 'Primary destination URL'
                : 'Tap destination URL (optional)',
            hintText: '/item/1 or https://instagram.com/p/example',
          ),
        ),
        if (isCard) ...[
          const SizedBox(height: 8),
          TextField(
            controller: controller.inAppSecondaryButtonCtrl,
            decoration: const InputDecoration(
              labelText: 'Secondary button text',
              hintText: 'Not now',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.inAppSecondaryUrlCtrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Secondary destination URL (optional)',
              hintText: 'Leave empty to dismiss',
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Delivery',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              DropdownButtonFormField<String>(
                initialValue: controller.inAppPlatform.value,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All platforms')),
                  DropdownMenuItem(value: 'android', child: Text('Android')),
                  DropdownMenuItem(value: 'ios', child: Text('iPhone')),
                  DropdownMenuItem(value: 'web', child: Text('Web')),
                ],
                onChanged: (value) {
                  if (value != null) controller.inAppPlatform.value = value;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: controller.inAppLanguage.value,
                decoration: const InputDecoration(labelText: 'Language'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All languages')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                ],
                onChanged: (value) {
                  if (value != null) controller.inAppLanguage.value = value;
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: controller.inAppDurationDays.value,
                decoration: const InputDecoration(labelText: 'Expires'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('After 1 day')),
                  DropdownMenuItem(value: 3, child: Text('After 3 days')),
                  DropdownMenuItem(value: 7, child: Text('After 7 days')),
                  DropdownMenuItem(value: 30, child: Text('After 30 days')),
                  DropdownMenuItem(value: 0, child: Text('Never')),
                ],
                onChanged: (value) {
                  if (value != null) controller.inAppDurationDays.value = value;
                },
              ),
            ];

            if (constraints.maxWidth < 680) {
              return Column(
                children: fields
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: field,
                      ),
                    )
                    .toList(),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields
                  .map(
                    (field) => Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: field,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: controller.inAppDisplayOnce.value,
          onChanged: (value) => controller.inAppDisplayOnce.value = value,
          title: const Text('Show once per device'),
          subtitle: const Text(
            'When disabled, the message can appear once each app session.',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Preview',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _CampaignPreview(controller: controller),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: controller.isPublishingInApp.value
                ? null
                : controller.publishInAppMessage,
            icon: controller.isPublishingInApp.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_outlined),
            label: const Text('Publish In-App Message'),
          ),
        ),
      ],
    );
  }
}

class _HexColorField extends StatelessWidget {
  const _HexColorField({
    required this.controller,
    required this.label,
    required this.fallback,
  });

  final TextEditingController controller;
  final String label;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(controller.text, fallback: fallback);
    return TextField(
      controller: controller,
      autocorrect: false,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: label,
        hintText: '#FFFFFF',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignPreview extends StatelessWidget {
  const _CampaignPreview({required this.controller});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final type = controller.inAppType.value;
    final background = colorFromHex(
      controller.inAppBackgroundColorCtrl.text,
      fallback: Colors.white,
    );
    final textColor = colorFromHex(
      controller.inAppTextColorCtrl.text,
      fallback: const Color(0xFF171717),
    );
    final buttonColor = colorFromHex(
      controller.inAppButtonColorCtrl.text,
      fallback: AppConstants.darkBeige,
    );
    final imageUrl = controller.inAppImageUrlCtrl.text.trim();
    final title = controller.inAppTitleCtrl.text.trim();
    final body = controller.inAppBodyCtrl.text.trim();

    if (type == InAppMessageType.image) {
      return _PreviewFrame(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _PreviewImage(url: imageUrl),
        ),
      );
    }

    if (type == InAppMessageType.banner) {
      return _PreviewFrame(
        child: ColoredBox(
          color: background,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _PreviewImage(url: imageUrl),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _PreviewCopy(
                    title: title,
                    body: body,
                    textColor: textColor,
                  ),
                ),
                Icon(Icons.close, color: textColor, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    final isCard = type == InAppMessageType.card;
    return _PreviewFrame(
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: isCard ? 360 : 310,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Color(0x26000000), blurRadius: 12),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl.isNotEmpty)
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: _PreviewImage(url: imageUrl),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: isCard
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    _PreviewCopy(
                      title: title,
                      body: body,
                      textColor: textColor,
                      centered: !isCard,
                    ),
                    if (controller.inAppPrimaryButtonCtrl.text
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: buttonColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            controller.inAppPrimaryButtonCtrl.text.trim(),
                            style: TextStyle(
                              color: colorFromHex(
                                controller.inAppButtonTextColorCtrl.text,
                                fallback: Colors.white,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130, maxHeight: 330),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _PreviewCopy extends StatelessWidget {
  const _PreviewCopy({
    required this.title,
    required this.body,
    required this.textColor,
    this.centered = false,
  });

  final String title;
  final String body;
  final Color textColor;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title.isEmpty ? 'Message header' : title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body.isEmpty ? 'Your in-app message will appear here.' : body,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.82),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: const Center(child: Icon(Icons.image_outlined, size: 36)),
      );
    }

    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image_outlined, size: 36)),
    );
  }
}
