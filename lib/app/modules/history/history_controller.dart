import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/models/order_master_model.dart';
import '../../core/models/order_detail_model.dart';
import '../../core/services/return_request_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/order_feedback_service.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';
import '../navigation/nav_controller.dart';

class HistoryController extends GetxController {
  static HistoryController get to => Get.find();

  final orders = <OrderMasterModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;

  StreamSubscription? _subscription;
  final List<Worker> _workers = [];
  final Set<int> _promptedOrderIds = {};
  bool _feedbackPromptOpen = false;

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever<int>(NavController.to.currentIndex, (index) {
        if (index == 2) unawaited(fetchOrders());
      }),
      ever(AuthController.to.currentUser, (_) {
        if (NavController.to.currentIndex.value == 2) {
          unawaited(fetchOrders());
        }
      }),
    ]);
  }

  @override
  void onReady() {
    super.onReady();
    fetchOrders();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }

  Future<void> fetchOrders() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) {
      await _subscription?.cancel();
      _subscription = null;
      orders.clear();
      hasError.value = false;
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    hasError.value = false;

    _subscription?.cancel();
    _subscription = SupabaseService.client
        .from('order_master')
        .stream(primaryKey: ['id'])
        .eq('userID', userId)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            orders.value = data
                .map((e) => OrderMasterModel.fromJson(e))
                .toList();
            isLoading.value = false;
            unawaited(_promptForUnreviewedDelivery());
          },
          onError: (e) {
            debugPrint('[HistoryController] fetchOrders error: $e');
            orders.value = [];
            hasError.value = true;
            isLoading.value = false;
          },
        );
  }

  Future<void> _promptForUnreviewedDelivery() async {
    if (_feedbackPromptOpen || Get.context == null) return;
    final delivered = orders
        .where(
          (order) =>
              order.orderStatus == 'Delivered' &&
              !_promptedOrderIds.contains(order.id),
        )
        .toList(growable: false);
    if (delivered.isEmpty) return;

    try {
      final reviewed = await OrderFeedbackService.reviewedOrderIds();
      final pending = delivered.where((order) => !reviewed.contains(order.id));
      if (pending.isEmpty || Get.context == null) return;
      final order = pending.first;
      _promptedOrderIds.add(order.id);
      _feedbackPromptOpen = true;
      await Get.dialog<void>(
        Builder(
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 42,
            ),
            title: Text('order_delivered'.tr),
            content: Text(
              'rate_order_prompt'.trParams({'order': '${order.id}'}),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(),
                child: Text('maybe_later'.tr),
              ),
              FilledButton.icon(
                onPressed: () =>
                    unawaited(_openReview(order.id, dialogContext)),
                icon: const Icon(Icons.star_outline),
                label: Text('rate_now'.tr),
              ),
            ],
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[HistoryController] feedback prompt error: $error');
      debugPrint('$stackTrace');
    } finally {
      _feedbackPromptOpen = false;
    }
  }

  Future<void> _openReview(int orderId, BuildContext dialogContext) async {
    Navigator.of(dialogContext, rootNavigator: true).pop();

    await Future<void>.delayed(const Duration(milliseconds: 120));
    await Get.toNamed(Routes.orderReviewPath(orderId), arguments: orderId);
  }

  Future<OrderReturnOptions> loadReturnOptions(int orderId) async {
    final detailsFuture = SupabaseService.client
        .from('order_detail')
        .select()
        .eq('orderMasterID', orderId);
    final requestsFuture = ReturnRequestService.forOrder(orderId);
    final detailRows = await detailsFuture;
    final requests = await requestsFuture;
    final details = (detailRows as List)
        .map((row) => OrderDetailModel.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
    final requestedIds = requests
        .map((request) => request.orderDetailId)
        .toSet();
    return OrderReturnOptions(
      items: details,
      unavailableDetailIds: requestedIds,
    );
  }

  Future<void> submitReturns({
    required int orderId,
    required Iterable<int> detailIds,
    required String name,
    required String phone,
    required bool whatsapp,
    required String reason,
  }) async {
    final user = AuthController.to.currentUser.value;
    if (user == null) return;
    if (user.name.trim().isEmpty) await AuthController.to.updateName(name);
    if (user.phone.trim().isEmpty) {
      await AuthController.to.updatePhoneNumbers(phone: phone);
    }
    await ReturnRequestService.createMany(
      orderId: orderId,
      detailIds: detailIds,
      userId: user.id,
      name: name,
      phone: phone,
      hasWhatsapp: whatsapp,
      reason: reason,
    );
  }
}

class OrderReturnOptions {
  const OrderReturnOptions({
    required this.items,
    required this.unavailableDetailIds,
  });

  final List<OrderDetailModel> items;
  final Set<int> unavailableDetailIds;
}
