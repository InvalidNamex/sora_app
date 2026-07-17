import 'package:get/get.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/models/payout_request_model.dart';

class ReportsController extends GetxController {
  final totalRevenue = 0.0.obs;
  final ordersByStatus = <String, int>{}.obs;
  final recentPayouts = <PayoutRequestModel>[].obs;
  final isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    fetchReports();
  }

  Future<void> fetchReports() async {
    isLoading.value = true;
    try {
      // 1. Fetch total revenue and status breakdown
      final ordersResp = await SupabaseService.client
          .from('order_master')
          .select('totalPrice, orderStatus');
          
      double revenue = 0;
      final statusCounts = <String, int>{};
      
      for (final row in (ordersResp as List)) {
        final data = row as Map<String, dynamic>;
        final price = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
        final status = (data['orderStatus'] as String?) ?? 'Pending';
        
        if (status != 'Cancelled' && status != 'Returned') {
          revenue += price;
        }
        
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      
      totalRevenue.value = revenue;
      ordersByStatus.value = statusCounts;
      
      // 2. Fetch recent payouts
      final payoutsResp = await SupabaseService.client
          .from('payout_requests')
          .select('*, users(name, phone)')
          .order('created_at', ascending: false)
          .limit(10);
          
      recentPayouts.value = (payoutsResp as List)
          .map((e) => PayoutRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
          
    } finally {
      isLoading.value = false;
    }
  }
}
