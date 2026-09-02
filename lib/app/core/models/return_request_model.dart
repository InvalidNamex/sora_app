class ReturnRequestModel {
  const ReturnRequestModel({
    required this.id,
    required this.orderId,
    required this.orderDetailId,
    required this.itemName,
    required this.customerName,
    required this.customerPhone,
    required this.hasWhatsapp,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.deliveredAt,
    this.adminNote,
  });

  final int id;
  final int orderId;
  final int orderDetailId;
  final String itemName;
  final String customerName;
  final String customerPhone;
  final bool hasWhatsapp;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? adminNote;

  factory ReturnRequestModel.fromJson(Map<String, dynamic> json) {
    final detail = json['order_detail'] as Map<String, dynamic>? ?? {};
    final order = json['order_master'] as Map<String, dynamic>? ?? {};
    final user = json['users'] as Map<String, dynamic>? ?? {};
    return ReturnRequestModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      orderDetailId: (json['order_detail_id'] as num?)?.toInt() ?? 0,
      itemName: (detail['itemName'] as String?) ?? 'Item',
      customerName:
          (json['customer_name'] as String?) ?? (user['name'] as String?) ?? '',
      customerPhone:
          (json['customer_phone'] as String?) ??
          (user['phone'] as String?) ??
          '',
      hasWhatsapp: json['has_whatsapp'] as bool? ?? false,
      reason: (json['reason'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'Requested',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deliveredAt: DateTime.tryParse(
        (order['delivered_at'] ?? json['delivered_at']) as String? ?? '',
      ),
      adminNote: json['admin_note'] as String?,
    );
  }

  Duration? get deliveryAge =>
      deliveredAt == null ? null : DateTime.now().difference(deliveredAt!);
}
