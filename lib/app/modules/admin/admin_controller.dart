import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/services/supabase_service.dart';

class AdminController extends GetxController {
  static AdminController get to => Get.find();

  final totalOrders = 0.obs;
  final pendingOrders = 0.obs;
  final pendingPayouts = 0.obs;
  final isLoading = true.obs;

  StreamSubscription? _ordersSub;
  StreamSubscription? _payoutsSub;

  @override
  void onReady() {
    super.onReady();
    fetchMetrics();
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    _payoutsSub?.cancel();
    super.onClose();
  }

  Future<void> fetchMetrics() async {
    isLoading.value = true;
    _ordersSub?.cancel();
    _payoutsSub?.cancel();

    final orderCompleter = Completer<void>();
    final payoutCompleter = Completer<void>();

    _ordersSub = SupabaseService.client
        .from('order_master')
        .stream(primaryKey: ['id'])
        .listen((data) {
      totalOrders.value = data.length;
      pendingOrders.value = data.where((e) => e['orderStatus'] == 'Pending').length;
      if (!orderCompleter.isCompleted) orderCompleter.complete();
      isLoading.value = false;
    }, onError: (e) {
      debugPrint('[AdminController] _ordersSub error: $e');
      if (!orderCompleter.isCompleted) orderCompleter.complete();
    });

    _payoutsSub = SupabaseService.client
        .from('payout_requests')
        .stream(primaryKey: ['id'])
        .listen((data) {
      pendingPayouts.value = data.where((e) => e['status'] == 'Pending').length;
      if (!payoutCompleter.isCompleted) payoutCompleter.complete();
    }, onError: (e) {
      debugPrint('[AdminController] _payoutsSub error: $e');
      if (!payoutCompleter.isCompleted) payoutCompleter.complete();
    });

    await Future.wait([orderCompleter.future, payoutCompleter.future]);
  }
}
