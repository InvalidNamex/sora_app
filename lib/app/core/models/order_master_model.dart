import 'package:flutter/material.dart';

class OrderMasterModel {
  final int id;
  final int userId;
  final int addressId;
  final int? affiliateId;
  final double totalPrice;
  final double totalDiscount;
  final String? notes;
  final String orderStatus;
  final DateTime createdAt;

  const OrderMasterModel({
    required this.id,
    required this.userId,
    required this.addressId,
    this.affiliateId,
    required this.totalPrice,
    required this.totalDiscount,
    this.notes,
    required this.orderStatus,
    required this.createdAt,
  });

  factory OrderMasterModel.fromJson(Map<String, dynamic> json) =>
      OrderMasterModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['userID'] as num?)?.toInt() ?? 0,
        addressId: (json['addressID'] as num?)?.toInt() ?? 0,
        affiliateId: (json['affiliateID'] as num?)?.toInt(),
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
        totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
        orderStatus: (json['orderStatus'] as String?) ?? 'Pending',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  static Color statusColor(String status) {
    switch (status) {
      case 'Processing':
        return const Color(0xFF1565C0);
      case 'Shipped':
        return const Color(0xFF6A1B9A);
      case 'Delivered':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFFE65100); // Pending
    }
  }
}
