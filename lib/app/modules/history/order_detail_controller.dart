import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/models/order_detail_model.dart';
import '../../core/models/order_master_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/order_feedback_service.dart';
import '../../core/models/return_request_model.dart';
import '../../core/services/return_request_service.dart';
import '../auth/auth_controller.dart';

class OrderDetailController extends GetxController {
  late final int orderId;
  final orderMaster = Rxn<OrderMasterModel>();
  final details = <OrderDetailModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final hasReview = false.obs;
  final returnRequests = <ReturnRequestModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final rawOrderId = Get.arguments ?? Get.parameters['id'];
    orderId = rawOrderId is int ? rawOrderId : int.tryParse('$rawOrderId') ?? 0;
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
      returnRequests.value = await ReturnRequestService.forOrder(orderId);
      if (orderMaster.value?.orderStatus == 'Delivered') {
        hasReview.value =
            await OrderFeedbackService.fetchForOrder(orderId) != null;
      } else {
        hasReview.value = false;
      }
    } catch (e) {
      debugPrint('[OrderDetailController] fetchDetails error: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  ReturnRequestModel? returnFor(int detailId) {
    for (final request in returnRequests) {
      if (request.orderDetailId == detailId && request.status != 'Cancelled')
        return request;
    }
    return null;
  }

  Future<void> submitReturn({
    required int detailId,
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
    await ReturnRequestService.create(
      orderId: orderId,
      detailId: detailId,
      userId: user.id,
      name: name,
      phone: phone,
      hasWhatsapp: whatsapp,
      reason: reason,
    );
    await fetchDetails();
  }
}
