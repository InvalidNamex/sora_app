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

  @override
  void onReady() {
    super.onReady();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    hasError.value = false;
    try {
      final response = await SupabaseService.client
          .from('order_master')
          .select()
          .eq('userID', userId)
          .order('created_at', ascending: false);
      orders.value = (response as List)
          .map((e) => OrderMasterModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[HistoryController] fetchOrders error: $e');
      orders.value = [];
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
