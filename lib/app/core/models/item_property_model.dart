import '../utils/locale_utils.dart';

class ItemPropertyModel {
  final int id;
  final int itemId;

  /// Size in ml
  final int sizeMl;
  final String image;
  final String _propertyDescription;
  final String _propertyDescriptionEn;
  final double price;
  final bool inStock;
  final bool isDefault;
  final double? affiliatePercentage;

  String get propertyDescription {
    if (isEnglishLocale() && _propertyDescriptionEn.trim().isNotEmpty) {
      return _propertyDescriptionEn.trim();
    }
    return _propertyDescription;
  }

  String get descAr => _propertyDescription;
  String get descEn => _propertyDescriptionEn;

  const ItemPropertyModel({
    required this.id,
    required this.itemId,
    required this.sizeMl,
    required this.image,
    String propertyDescription = '',
    String propertyDescriptionEn = '',
    required this.price,
    this.inStock = true,
    this.isDefault = false,
    this.affiliatePercentage,
  })  : _propertyDescription = propertyDescription,
        _propertyDescriptionEn = propertyDescriptionEn;

  factory ItemPropertyModel.fromJson(Map<String, dynamic> json) =>
      ItemPropertyModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        itemId: (json['itemID'] as num?)?.toInt() ?? 0,
        sizeMl: (json['size'] as num?)?.toInt() ?? 0,
        image: (json['image'] as String?) ?? '',
        propertyDescription: firstNonEmptyString(json, const [
          'propertyDescription',
          'PropertyDescription',
        ]),
        propertyDescriptionEn: firstNonEmptyString(json, const [
          'propertyDescriptionEN',
          'PropertyDescriptionEN',
        ]),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        inStock: (json['inStock'] as bool?) ?? true,
        isDefault: (json['isDefault'] as bool?) ?? false,
        affiliatePercentage: json['affiliatePercentage'] != null
            ? (json['affiliatePercentage'] as num).toDouble()
            : null,
      );
}
