import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/models/order_detail_model.dart';
import '../../core/models/order_master_model.dart';
import '../../core/services/supabase_service.dart';

class OrderDetailController extends GetxController {
  late final int orderId;
  final orderMaster = Rxn<OrderMasterModel>();
  final details = <OrderDetailModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments as int? ?? 0;
  }

  @override
  void onReady() {
    super.onReady();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    if (orderId == 0) {
      isLoading.value = false;
      hasError.value = true;
      return;
    }
    isLoading.value = true;
    hasError.value = false;
    try {
      final masterResp = await SupabaseService.client
          .from('order_master')
          .select()
          .eq('id', orderId)
          .single();
      orderMaster.value = OrderMasterModel.fromJson(masterResp);

      final detailResp = await SupabaseService.client
          .from('order_detail')
          .select()
          .eq('orderMasterID', orderId);
      details.value = (detailResp as List)
          .map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OrderDetailController] fetchDetails error: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
