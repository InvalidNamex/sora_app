import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/order_detail_model.dart';
import '../../../core/services/supabase_service.dart';

/// Combined order + user display model (view-local).
class OrderWithUser {
  final int id;
  final String userName;
  final String userPhone;
  final double totalPrice;
  final double totalDiscount;
  final String address;
  final String? notes;
  final String checkoutPhone;
  String orderStatus;
  final DateTime createdAt;

  double get grossTotal => totalPrice + totalDiscount;

  OrderWithUser({
    required this.id,
    required this.userName,
    required this.userPhone,
    required this.totalPrice,
    required this.totalDiscount,
    required this.address,
    this.notes,
    required this.checkoutPhone,
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
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0,
      address: (json['address'] as String?) ?? '',
      notes: json['notes'] as String?,
      checkoutPhone: (json['phoneNumber'] as String?) ?? '',
      orderStatus: (json['orderStatus'] as String?) ?? 'Pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get formattedDate => DateFormat.yMMMd().add_Hm().format(createdAt);
}

class OrderManagementController extends GetxController {
  static OrderManagementController get to => Get.find();

  final orders = <OrderWithUser>[].obs;
  final filteredOrders = <OrderWithUser>[].obs;
  final details = <OrderDetailModel>[].obs;
  final isLoading = true.obs;
  final selectedFilter = 'all'.obs;
  final updatingOrderId = Rxn<int>();
  RealtimeChannel? _ordersChannel;
  Timer? _refreshDebounce;
  bool _notifyRpcEnabled = true;

  static const statuses = [
    'all',
    'Pending',
    'Confirmed',
    'Out for delivery',
    'Delivered',
    'Cancelled',
    'Returned',
  ];

  @override
  void onReady() {
    super.onReady();
    fetchOrders();
    _subscribeToOrderChanges();
    ever(selectedFilter, (_) => _applyFilter());
  }

  @override
  void onClose() {
    _refreshDebounce?.cancel();
    if (_ordersChannel != null) {
      SupabaseService.client.removeChannel(_ordersChannel!);
      _ordersChannel = null;
    }
    super.onClose();
  }

  void _subscribeToOrderChanges() {
    final channel = SupabaseService.client.channel('admin-order-master-feed');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_master',
          callback: (_) => _scheduleOrdersRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'order_master',
          callback: (_) => _scheduleOrdersRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'order_master',
          callback: (_) => _scheduleOrdersRefresh(),
        )
        .subscribe();
    _ordersChannel = channel;
  }

  void _scheduleOrdersRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), fetchOrders);
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final response = await SupabaseService.client
          .from('order_master')
          .select('*, users!order_master_userID_fkey(name, phone)')
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
      filteredOrders.value = orders.where((o) => o.orderStatus == f).toList();
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

      if (_notifyRpcEnabled) {
        try {
          await SupabaseService.client.rpc(
            'notify_order_status_change',
            params: {'p_order_id': order.id, 'p_status': newStatus},
          );
        } on PostgrestException catch (e) {
          if (e.code == 'PGRST202') {
            _notifyRpcEnabled = false;
            debugPrint(
              'notify_order_status_change RPC not found; notifications disabled until backend function is deployed.',
            );
          } else {
            debugPrint('FCM notification rpc failed: $e');
          }
        } catch (e) {
          debugPrint('FCM notification rpc failed: $e');
        }
      }
    } finally {
      updatingOrderId.value = null;
    }
  }
}
