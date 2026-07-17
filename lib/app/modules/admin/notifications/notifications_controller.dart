import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:get/get.dart';

import '../../../core/models/item_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_snackbar.dart';

class NotificationsController extends GetxController {
  final isSending = false.obs;
  final isProcessingQueue = false.obs;
  final isLoadingItems = false.obs;
  final items = <ItemModel>[].obs;
  final selectedItemId = Rxn<int>();

  final campaignTitleCtrl = TextEditingController();
  final campaignBodyCtrl = TextEditingController();
  final promoCodeCtrl = TextEditingController();
  final promotionBodyCtrl = TextEditingController();

  final androidOnly = false.obs;
  final arabicOnly = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadItems();
  }

  @override
  void onClose() {
    campaignTitleCtrl.dispose();
    campaignBodyCtrl.dispose();
    promoCodeCtrl.dispose();
    promotionBodyCtrl.dispose();
    super.onClose();
  }

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

    if (title.isEmpty || body.isEmpty) {
      AppSnackbar.show(
        'Missing data',
        'Please provide both title and message body.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    await _enqueueNotificationJob(
      eventType: 'manual_campaign',
      title: title,
      body: body,
      payload: {'deep_link': '/home'},
    );
  }

  Future<void> queuePromotionAnnouncement() async {
    final code = promoCodeCtrl.text.trim();
    final body = promotionBodyCtrl.text.trim();
    if (code.isEmpty || body.isEmpty) {
      AppSnackbar.show(
        'Missing data',
        'Please provide promotion code and message.',
        type: AppSnackbarType.warning,
      );
      return;
    }

    await _enqueueNotificationJob(
      eventType: 'promotion_published',
      title: 'New Promotion',
      body: body,
      payload: {'promotion_code': code, 'deep_link': '/home?promo=$code'},
    );
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
