class VoucherModel {
  final int id;
  final String voucherCode;
  final double? voucherAmount;
  final double? voucherPercentage;
  final bool isActive;

  const VoucherModel({
    required this.id,
    required this.voucherCode,
    this.voucherAmount,
    this.voucherPercentage,
    required this.isActive,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) => VoucherModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        voucherCode: (json['voucherCode'] as String?) ?? '',
        voucherAmount: json['voucherAmount'] != null
            ? (json['voucherAmount'] as num).toDouble()
            : null,
        voucherPercentage: json['voucherPercentage'] != null
            ? (json['voucherPercentage'] as num).toDouble()
            : null,
        isActive: (json['isActive'] as bool?) ?? false,
      );
}
