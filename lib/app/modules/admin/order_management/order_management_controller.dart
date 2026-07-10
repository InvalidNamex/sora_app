import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/order_detail_model.dart';
import '../../../core/services/supabase_service.dart';

/// Combined order + user display model (view-local).
class OrderWithUser {
  final int id;
  final String userName;
  final String userPhone;
  final double totalPrice;
  String orderStatus;
  final DateTime createdAt;

  OrderWithUser({
    required this.id,
    required this.userName,
    required this.userPhone,
    required this.totalPrice,
    required this.orderStatus,
    required this.createdAt,
  });

  factory OrderWithUser.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>? ?? {};
    return OrderWithUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userName: (user['name'] as String?) ?? '',
      userPhone: (user['phone'] as String?) ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      orderStatus: (json['orderStatus'] as String?) ?? 'Pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get formattedDate =>
      DateFormat.yMMMd().add_Hm().format(createdAt);
}

class OrderManagementController extends GetxController {
  static OrderManagementController get to => Get.find();

  final orders = <OrderWithUser>[].obs;
  final filteredOrders = <OrderWithUser>[].obs;
  final details = <OrderDetailModel>[].obs;
  final isLoading = true.obs;
  final selectedFilter = 'all'.obs;
  final updatingOrderId = Rxn<int>();

  static const statuses = [
    'all',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
  ];

  @override
  void onReady() {
    super.onReady();
    fetchOrders();
    ever(selectedFilter, (_) => _applyFilter());
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('order_master')
          .select('*, users(name, phone)')
          .order('created_at', ascending: false);
      orders.value = (response as List)
          .map((e) => OrderWithUser.fromJson(e as Map<String, dynamic>))
          .toList();
      _applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilter() {
    final f = selectedFilter.value;
    if (f == 'all') {
      filteredOrders.value = orders.toList();
    } else {
      filteredOrders.value =
          orders.where((o) => o.orderStatus == f).toList();
    }
  }

  Future<void> fetchOrderDetails(int orderId) async {
    final response = await SupabaseService.client
        .from('order_detail')
        .select()
        .eq('orderMasterID', orderId);
    details.value = (response as List)
        .map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(OrderWithUser order, String newStatus) async {
    updatingOrderId.value = order.id;
    try {
      await SupabaseService.client
          .from('order_master')
          .update({'orderStatus': newStatus})
          .eq('id', order.id);
      order.orderStatus = newStatus;
      orders.refresh();
      _applyFilter();

      // TODO: Deploy the `notify_order_status_change` Supabase Edge Function.
      // It should look up the user's fcmTokens and send a push via Firebase Admin SDK.
      try {
        await SupabaseService.client.rpc('notify_order_status_change',
            params: {'p_order_id': order.id, 'p_status': newStatus});
      } catch (e) {
        debugPrint('FCM notification rpc failed: $e');
      }
    } finally {
      updatingOrderId.value = null;
    }
  }
}
