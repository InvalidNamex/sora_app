import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/order_master_model.dart';
import '../../core/models/payout_request_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../auth/auth_controller.dart';

class AffiliateController extends GetxController {
  static AffiliateController get to => Get.find();

  final referredOrders = <OrderMasterModel>[].obs;
  final payoutHistory = <PayoutRequestModel>[].obs;
  final totalEarnings = 0.0.obs;
  final pendingEarnings = 0.0.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;

  String get affiliateLink {
    final uid = AuthController.to.currentUser.value?.uid ?? '';
    final baseDomain = AppConstants.baseDomain.replaceFirst(RegExp(r'/$'), '');
    return '$baseDomain/ref/$uid';
  }

  @override
  void onReady() {
    super.onReady();
    fetchData();
  }

  Future<void> fetchData() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      // Fetch all orders where this user is the affiliate
      final ordersResp = await SupabaseService.client
          .from('order_master')
          .select()
          .eq('affiliateID', userId)
          .order('created_at', ascending: false);
      final orders = (ordersResp as List)
          .map((e) => OrderMasterModel.fromJson(e as Map<String, dynamic>))
          .toList();
      referredOrders.value = orders;

      if (orders.isEmpty) {
        totalEarnings.value = 0;
        pendingEarnings.value = 0;
        return;
      }

      final orderIds = orders.map((o) => o.id).toList();

      // Fetch order details with item_properties for commission calculation
      final detailsResp = await SupabaseService.client
          .from('order_detail')
          .select('quantity, price, item_properties(affiliatePercentage)')
          .inFilter('orderMasterID', orderIds);

      double total = 0;
      double pending = 0;

      // order_detail rows don't carry orderMasterID in the select above,
      // so we calculate totals across all referred orders without per-status split.
      for (final row in (detailsResp as List)) {
        final d = row as Map<String, dynamic>;
        final qty = (d['quantity'] as num?)?.toDouble() ?? 0;
        final price = (d['price'] as num?)?.toDouble() ?? 0;
        final prop = d['item_properties'] as Map<String, dynamic>? ?? {};
        final pct = (prop['affiliatePercentage'] as num?)?.toDouble() ?? 0;
        final commission = qty * price * pct / 100;
        total += commission;
      }

      // Separate pending orders earnings:
      // Fetch details only for pending orders
      final pendingOrderIds = orders
          .where((o) => o.orderStatus != 'Delivered')
          .map((o) => o.id)
          .toList();
      if (pendingOrderIds.isNotEmpty) {
        final pendingDetails = await SupabaseService.client
            .from('order_detail')
            .select('quantity, price, item_properties(affiliatePercentage)')
            .inFilter('orderMasterID', pendingOrderIds);
        for (final row in (pendingDetails as List)) {
          final d = row as Map<String, dynamic>;
          final qty = (d['quantity'] as num?)?.toDouble() ?? 0;
          final price = (d['price'] as num?)?.toDouble() ?? 0;
          final prop = d['item_properties'] as Map<String, dynamic>? ?? {};
          final pct = (prop['affiliatePercentage'] as num?)?.toDouble() ?? 0;
          pending += qty * price * pct / 100;
        }
      }

      totalEarnings.value = total;
      pendingEarnings.value = pending;

      // Fetch payout history
      final payoutsResp = await SupabaseService.client
          .from('payout_requests')
          .select('*, users(name, phone)')
          .eq('affiliateID', userId)
          .order('created_at', ascending: false);
      payoutHistory.value = (payoutsResp as List)
          .map((e) => PayoutRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestPayout() async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;
    isSubmitting.value = true;
    try {
      await SupabaseService.client.from('payout_requests').insert({
        'affiliateID': userId,
        'amount': pendingEarnings.value,
        'status': 'Pending',
      });
      AppSnackbar.show(
        'success'.tr,
        'payout_requested'.tr,
        type: AppSnackbarType.success,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
