import 'package:get/get.dart';

import '../../core/services/supabase_service.dart';

class AdminController extends GetxController {
  static AdminController get to => Get.find();

  final totalOrders = 0.obs;
  final pendingOrders = 0.obs;
  final pendingPayouts = 0.obs;
  final isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    fetchMetrics();
  }

  Future<void> fetchMetrics() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        SupabaseService.client.from('order_master').select('id'),
        SupabaseService.client
            .from('order_master')
            .select('id')
            .eq('orderStatus', 'Pending'),
        SupabaseService.client
            .from('payout_requests')
            .select('id')
            .eq('status', 'Pending'),
      ]);
      totalOrders.value = (results[0] as List).length;
      pendingOrders.value = (results[1] as List).length;
      pendingPayouts.value = (results[2] as List).length;
    } finally {
      isLoading.value = false;
    }
  }
}
