class PromoCodeValidation {
  const PromoCodeValidation({
    required this.valid,
    required this.code,
    required this.type,
    required this.discountAmount,
    this.discountPercentage,
  });

  final bool valid;
  final String code;
  final String? type;
  final double discountAmount;
  final double? discountPercentage;

  bool get isAffiliate => type == 'affiliate';

  factory PromoCodeValidation.fromJson(Map<String, dynamic> json) {
    return PromoCodeValidation(
      valid: json['valid'] == true,
      code: (json['code'] as String?) ?? '',
      type: json['type'] as String?,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
    );
  }
}

class AffiliateCodeProfile {
  const AffiliateCodeProfile({
    required this.code,
    required this.customerDiscountPercentage,
    required this.affiliateCommissionPercentage,
  });

  final String code;
  final double customerDiscountPercentage;
  final double affiliateCommissionPercentage;

  factory AffiliateCodeProfile.fromJson(Map<String, dynamic> json) {
    return AffiliateCodeProfile(
      code: (json['code'] as String?) ?? '',
      customerDiscountPercentage:
          (json['customerDiscountPercentage'] as num?)?.toDouble() ?? 0,
      affiliateCommissionPercentage:
          (json['affiliateCommissionPercentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AffiliateApplicationModel {
  const AffiliateApplicationModel({
    required this.id,
    required this.preferredCode,
    required this.message,
    required this.status,
    required this.createdAt,
    this.adminNote,
    this.reviewedAt,
    this.userName = '',
    this.userPhone = '',
  });

  final int id;
  final String preferredCode;
  final String message;
  final String status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String userName;
  final String userPhone;

  bool get isPending => status == 'Pending';

  factory AffiliateApplicationModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>? ?? const {};
    return AffiliateApplicationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      preferredCode: (json['preferredCode'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'Pending',
      adminNote: json['adminNote'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.tryParse('${json['reviewedAt']}'),
      userName: (user['name'] as String?) ?? '',
      userPhone: (user['phone'] as String?) ?? '',
    );
  }
}

class AffiliateAdminUserSummary {
  const AffiliateAdminUserSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.isAffiliate,
    required this.code,
    required this.customerDiscountPercentage,
    required this.commissionPercentage,
    required this.referredOrders,
    required this.referredRevenue,
    required this.totalCommission,
    required this.availableCommission,
    required this.pendingCommission,
    required this.paidCommission,
    required this.paidPayouts,
    this.phoneTwo,
    this.email,
  });

  final int id;
  final String name;
  final String phone;
  final String? phoneTwo;
  final String? email;
  final bool isAffiliate;
  final String code;
  final double customerDiscountPercentage;
  final double commissionPercentage;
  final int referredOrders;
  final double referredRevenue;
  final double totalCommission;
  final double availableCommission;
  final double pendingCommission;
  final double paidCommission;
  final double paidPayouts;

  factory AffiliateAdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AffiliateAdminUserSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      phoneTwo: json['phoneTwo'] as String?,
      email: json['email'] as String?,
      isAffiliate: json['isAffiliate'] == true,
      code: (json['code'] as String?) ?? '',
      customerDiscountPercentage:
          (json['customerDiscountPercentage'] as num?)?.toDouble() ?? 0,
      commissionPercentage:
          (json['commissionPercentage'] as num?)?.toDouble() ?? 0,
      referredOrders: (json['referredOrders'] as num?)?.toInt() ?? 0,
      referredRevenue: (json['referredRevenue'] as num?)?.toDouble() ?? 0,
      totalCommission: (json['totalCommission'] as num?)?.toDouble() ?? 0,
      availableCommission:
          (json['availableCommission'] as num?)?.toDouble() ?? 0,
      pendingCommission: (json['pendingCommission'] as num?)?.toDouble() ?? 0,
      paidCommission: (json['paidCommission'] as num?)?.toDouble() ?? 0,
      paidPayouts: (json['paidPayouts'] as num?)?.toDouble() ?? 0,
    );
  }

  AffiliateAdminUserSummary copyWith({bool? isAffiliate}) {
    return AffiliateAdminUserSummary(
      id: id,
      name: name,
      phone: phone,
      phoneTwo: phoneTwo,
      email: email,
      isAffiliate: isAffiliate ?? this.isAffiliate,
      code: code,
      customerDiscountPercentage: customerDiscountPercentage,
      commissionPercentage: commissionPercentage,
      referredOrders: referredOrders,
      referredRevenue: referredRevenue,
      totalCommission: totalCommission,
      availableCommission: availableCommission,
      pendingCommission: pendingCommission,
      paidCommission: paidCommission,
      paidPayouts: paidPayouts,
    );
  }
}
