/// A payout/withdrawal request from an affiliate.
///
/// Built from:
/// ```dart
/// payout_requests.select('*, users(name, phone)')
/// ```
class PayoutRequestModel {
  final int id;
  final int affiliateId;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String affiliateName;
  final String affiliatePhone;

  const PayoutRequestModel({
    required this.id,
    required this.affiliateId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.affiliateName,
    required this.affiliatePhone,
  });

  factory PayoutRequestModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>? ?? {};
    return PayoutRequestModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      affiliateId: (json['affiliateID'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] as String?) ?? 'Pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      affiliateName: (user['name'] as String?) ?? '',
      affiliatePhone: (user['phone'] as String?) ?? '',
    );
  }
}
