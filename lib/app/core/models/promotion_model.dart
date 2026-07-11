import '../utils/locale_utils.dart';

class PromotionModel {
  final int id;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final String promotionText;
  final String promotionTextEN;
  final String promotionCode;
  final int promotionDiscount;

  const PromotionModel({
    required this.id,
    required this.createdAt,
    this.expiryDate,
    required this.promotionText,
    required this.promotionTextEN,
    required this.promotionCode,
    required this.promotionDiscount,
  });

  /// Returns the locale-appropriate promotion text.
  String get localizedText {
    if (isEnglishLocale() && promotionTextEN.trim().isNotEmpty) {
      return promotionTextEN.trim();
    }
    return promotionText;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
        id: (json['id'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        expiryDate: json['expiry_date'] != null
            ? DateTime.parse(json['expiry_date'] as String)
            : null,
        promotionText: (json['promotionText'] as String?) ?? '',
        promotionTextEN: (json['promotionTextEN'] as String?) ?? '',
        promotionCode: (json['promotionCode'] as String?) ?? '',
        promotionDiscount: (json['promotionDiscount'] as num?)?.toInt() ?? 0,
      );
}
