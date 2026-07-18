import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/in_app_message_model.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/in_app_messaging_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_snackbar.dart';

class NotificationsController extends GetxController {
  final isSending = false.obs;
  final isProcessingQueue = false.obs;
  final isPublishingInApp = false.obs;
  final isUploadingInAppImage = false.obs;
  final isLoadingItems = false.obs;
  final items = <ItemModel>[].obs;
  final selectedItemId = Rxn<int>();

  final campaignTitleCtrl = TextEditingController();
  final campaignBodyCtrl = TextEditingController();
  final campaignUrlCtrl = TextEditingController();
  final inAppTitleCtrl = TextEditingController();
  final inAppBodyCtrl = TextEditingController();
  final inAppImageUrlCtrl = TextEditingController();
  final inAppPrimaryButtonCtrl = TextEditingController();
  final inAppPrimaryUrlCtrl = TextEditingController();
  final inAppSecondaryButtonCtrl = TextEditingController(text: 'Not now');
  final inAppSecondaryUrlCtrl = TextEditingController();
  final inAppBackgroundColorCtrl = TextEditingController(text: '#FFFFFF');
  final inAppTextColorCtrl = TextEditingController(text: '#171717');
  final inAppButtonColorCtrl = TextEditingController(text: '#B09263');
  final inAppButtonTextColorCtrl = TextEditingController(text: '#FFFFFF');

  final androidOnly = false.obs;
  final arabicOnly = false.obs;
  final inAppType = InAppMessageType.card.obs;
  final inAppPlatform = 'all'.obs;
  final inAppLanguage = 'all'.obs;
  final inAppDurationDays = 7.obs;
  final inAppDisplayOnce = true.obs;
  final inAppPreviewRevision = 0.obs;

  late final List<TextEditingController> _inAppControllers;

  @override
  void onInit() {
    super.onInit();
    _inAppControllers = [
      inAppTitleCtrl,
      inAppBodyCtrl,
      inAppImageUrlCtrl,
      inAppPrimaryButtonCtrl,
      inAppPrimaryUrlCtrl,
      inAppSecondaryButtonCtrl,
      inAppSecondaryUrlCtrl,
      inAppBackgroundColorCtrl,
      inAppTextColorCtrl,
      inAppButtonColorCtrl,
      inAppButtonTextColorCtrl,
    ];
    for (final textController in _inAppControllers) {
      textController.addListener(_refreshInAppPreview);
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadItems();
  }

  @override
  void onClose() {
    campaignTitleCtrl.dispose();
    campaignBodyCtrl.dispose();
    campaignUrlCtrl.dispose();
    for (final textController in _inAppControllers) {
      textController
        ..removeListener(_refreshInAppPreview)
        ..dispose();
    }
    super.onClose();
  }

  void _refreshInAppPreview() => inAppPreviewRevision.value++;

  Future<void> loadItems() async {
    isLoadingItems.value = true;
    try {
      final resp = await SupabaseService.client
          .from('items')
          .select()
          .order('id', ascending: false);
      items.value = (resp as List)
          .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      selectedItemId.value ??= items.firstOrNull?.id;
    } catch (e) {
      AppSnackbar.show(
        'Error',
        'Failed to load items: $e',
        type: AppSnackbarType.error,
      );
    } finally {
      isLoadingItems.value = false;
    }
  }

  Future<void> sendManualCampaign() async {
    final title = campaignTitleCtrl.text.trim();
    final body = campaignBodyCtrl.text.trim();
    final targetUrl = campaignUrlCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      AppSnackbar.show(
        'Missing data',
        'Please provide both title and message body.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    if (targetUrl.isNotEmpty && !_isValidNotificationTarget(targetUrl)) {
      AppSnackbar.show(
        'Invalid URL',
        'Use an app path such as /item/1, a sora:// link, or a full http(s) URL.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    await _enqueueNotificationJob(
      eventType: 'manual_campaign',
      title: title,
      body: body,
      payload: {if (targetUrl.isNotEmpty) 'deep_link': targetUrl},
    );
  }

  bool _isValidNotificationTarget(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;

    if (!uri.hasScheme) {
      return value.startsWith('/') && uri.pathSegments.isNotEmpty;
    }

    if (uri.scheme == 'sora') {
      return uri.host.isNotEmpty || uri.pathSegments.isNotEmpty;
    }

    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> pickInAppImage() async {
    if (isUploadingInAppImage.value) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1800,
    );
    if (image == null) return;

    isUploadingInAppImage.value = true;
    try {
      final extension = image.name.split('.').last.toLowerCase();
      final safeExtension = {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)
          ? extension
          : 'jpg';
      final bytes = await image.readAsBytes();
      final signedUpload = await _invokeInAppAdmin({
        'action': 'create_upload',
        'extension': safeExtension,
      });
      final uploadPath = signedUpload['path'] as String?;
      final uploadToken = signedUpload['token'] as String?;
      final publicUrl = signedUpload['publicUrl'] as String?;
      if (uploadPath == null || uploadToken == null || publicUrl == null) {
        throw StateError('The upload service returned an invalid response.');
      }
      await SupabaseService.client.storage
          .from('in_app_messages')
          .uploadBinaryToSignedUrl(
            uploadPath,
            uploadToken,
            bytes,
            FileOptions(contentType: _imageContentType(safeExtension)),
          );
      inAppImageUrlCtrl.text = publicUrl;
    } catch (e) {
      AppSnackbar.show(
        'Upload failed',
        'Could not upload the campaign image.\n$e',
        type: AppSnackbarType.error,
      );
    } finally {
      isUploadingInAppImage.value = false;
    }
  }

  String _imageContentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> publishInAppMessage() async {
    if (isPublishingInApp.value) return;

    final type = inAppType.value;
    final title = inAppTitleCtrl.text.trim();
    final body = inAppBodyCtrl.text.trim();
    final imageUrl = inAppImageUrlCtrl.text.trim();
    final primaryUrl = inAppPrimaryUrlCtrl.text.trim();
    final secondaryUrl = inAppSecondaryUrlCtrl.text.trim();

    if (type == InAppMessageType.image && !_isValidWebUrl(imageUrl)) {
      AppSnackbar.show(
        'Image required',
        'Image messages need a valid http(s) image URL.',
        type: AppSnackbarType.warning,
      );
      return;
    }
    if (type != InAppMessageType.image && title.isEmpty && body.isEmpty) {
      AppSnackbar.show(
        'Message required',
        'Add a title or message body.',
        type: AppSnackbarType.warning,
      );
      return;
    }
    if (imageUrl.isNotEmpty && !_isValidWebUrl(imageUrl)) {
      AppSnackbar.show(
        'Invalid image URL',
        'Use a complete http(s) image URL or upload an image.',
        type: AppSnackbarType.warning,
      );
      return;
    }
    if (primaryUrl.isNotEmpty && !_isValidNotificationTarget(primaryUrl)) {
      _showInvalidActionUrl();
      return;
    }
    if (secondaryUrl.isNotEmpty && !_isValidNotificationTarget(secondaryUrl)) {
      _showInvalidActionUrl();
      return;
    }
    if (inAppPrimaryButtonCtrl.text.trim().isNotEmpty &&
        primaryUrl.isEmpty &&
        type != InAppMessageType.banner) {
      AppSnackbar.show(
        'Primary action missing',
        'Add a destination URL or clear the primary button text.',
        type: AppSnackbarType.warning,
      );
      return;
    }
    final colors = [
      inAppBackgroundColorCtrl.text,
      inAppTextColorCtrl.text,
      inAppButtonColorCtrl.text,
      inAppButtonTextColorCtrl.text,
    ];
    if (colors.any((color) => !isValidHexColor(color))) {
      AppSnackbar.show(
        'Invalid color',
        'Colors must use six-digit hex values such as #B09263.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    isPublishingInApp.value = true;
    try {
      final now = DateTime.now().toUtc();
      final durationDays = inAppDurationDays.value;
      await _invokeInAppAdmin({
        'action': 'publish',
        'message': {
          'type': type.databaseValue,
          'title': title,
          'body': body,
          'image_url': imageUrl,
          'background_color': inAppBackgroundColorCtrl.text
              .trim()
              .toUpperCase(),
          'text_color': inAppTextColorCtrl.text.trim().toUpperCase(),
          'button_color': inAppButtonColorCtrl.text.trim().toUpperCase(),
          'button_text_color': inAppButtonTextColorCtrl.text
              .trim()
              .toUpperCase(),
          'primary_button_text': inAppPrimaryButtonCtrl.text.trim(),
          'primary_action_url': primaryUrl,
          'secondary_button_text': type == InAppMessageType.card
              ? inAppSecondaryButtonCtrl.text.trim()
              : '',
          'secondary_action_url': type == InAppMessageType.card
              ? secondaryUrl
              : '',
          'target_platform': inAppPlatform.value,
          'target_language': inAppLanguage.value,
          'display_once': inAppDisplayOnce.value,
          'starts_at': now.toIso8601String(),
          'ends_at': durationDays == 0
              ? null
              : now.add(Duration(days: durationDays)).toIso8601String(),
        },
      });

      AppSnackbar.show(
        'Published',
        'The in-app message is now live for active users.',
        type: AppSnackbarType.success,
      );
      if (Get.isRegistered<InAppMessagingService>()) {
        unawaited(InAppMessagingService.to.refreshNow());
      }
    } catch (e) {
      AppSnackbar.show(
        'Publish failed',
        'Could not publish the in-app message.\n$e',
        type: AppSnackbarType.error,
      );
    } finally {
      isPublishingInApp.value = false;
    }
  }

  bool _isValidWebUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void _showInvalidActionUrl() {
    AppSnackbar.show(
      'Invalid action URL',
      'Use an app path such as /item/1, a sora:// link, or a full http(s) URL.',
      type: AppSnackbarType.warning,
    );
  }

  Future<Map<String, dynamic>> _invokeInAppAdmin(
    Map<String, dynamic> body,
  ) async {
    final idToken = await fb.FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('You need to be signed in as an administrator.');
    }

    final result = await SupabaseService.client.functions.invoke(
      'manage-in-app-messages',
      headers: {'Authorization': 'Bearer $idToken'},
      body: body,
    );
    final data = result.data;
    if (result.status < 200 || result.status >= 300 || data is! Map) {
      throw StateError('Campaign service error: $data');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> queueFeaturedItemAnnouncement() async {
    final itemId = selectedItemId.value;
    if (itemId == null) {
      AppSnackbar.show(
        'Missing item',
        'Please select a featured item.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    final item = items.firstWhereOrNull((e) => e.id == itemId);
    await _enqueueNotificationJob(
      eventType: 'featured_item_published',
      title: 'Featured Item',
      body: item == null
          ? 'Check our new featured item now.'
          : 'Now featured: ${item.itemName}',
      payload: {'item_id': itemId, 'deep_link': '/item/$itemId'},
    );
  }

  Future<void> _enqueueNotificationJob({
    required String eventType,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    if (isSending.value) return;
    isSending.value = true;

    try {
      await SupabaseService.client.from('notification_jobs').insert({
        'eventType': eventType,
        'title': title,
        'body': body,
        'payload': payload,
        'isAndroidOnly': androidOnly.value,
        'isArabicOnly': arabicOnly.value,
        'status': 'pending',
      });

      AppSnackbar.show(
        'Queued',
        'Notification job has been queued successfully.',
        type: AppSnackbarType.success,
      );

      await processQueueNow();
    } catch (e) {
      AppSnackbar.show(
        'Error',
        'Failed to queue notification. Make sure notification_jobs table exists.\n$e',
        type: AppSnackbarType.error,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> processQueueNow() async {
    if (isProcessingQueue.value) return;
    isProcessingQueue.value = true;
    try {
      final idToken = await fb.FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        AppSnackbar.show(
          'Worker error',
          'You need to be signed in before processing the notification queue.',
          type: AppSnackbarType.error,
        );
        return;
      }

      final result = await SupabaseService.client.functions.invoke(
        'process-notification-jobs',
        headers: {'Authorization': 'Bearer $idToken'},
        body: {'limit': 50},
      );

      if (result.status >= 200 && result.status < 300) {
        final data = result.data;
        final claimed = data is Map ? data['claimed'] : null;
        final processed = data is Map ? data['processed'] : null;
        AppSnackbar.show(
          'Queue processed',
          'Notification worker executed successfully. Claimed: ${claimed ?? '-'}, processed: ${processed ?? '-'}.',
          type: AppSnackbarType.success,
        );
      } else {
        AppSnackbar.show(
          'Worker error',
          'Failed to process queue: ${result.data}',
          type: AppSnackbarType.error,
        );
      }
    } catch (e) {
      AppSnackbar.show(
        'Worker error',
        'Failed to invoke process-notification-jobs.\n$e',
        type: AppSnackbarType.error,
      );
    } finally {
      isProcessingQueue.value = false;
    }
  }
}
