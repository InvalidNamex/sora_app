import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/models/order_master_model.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_controller.dart';

class HistoryController extends GetxController {
  static HistoryController get to => Get.find();

  final orders = <OrderMasterModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;

  StreamSubscription? _subscription;

  @override
  void onReady() {
    super.onReady();
    fetchOrders();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> fetchOrders() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) {
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
        .listen((data) {
      orders.value = data
          .map((e) => OrderMasterModel.fromJson(e))
          .toList();
      isLoading.value = false;
    }, onError: (e) {
      debugPrint('[HistoryController] fetchOrders error: $e');
      orders.value = [];
      hasError.value = true;
      isLoading.value = false;
    });
  }
}
