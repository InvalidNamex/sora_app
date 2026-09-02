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
  final double discountPercentage;
  final bool inStock;
  final bool isDefault;

  bool get hasDiscount => discountPercentage > 0 && salePrice < price;

  double get discountAmount => hasDiscount ? price - salePrice : 0;

  double get salePrice {
    final percentage = discountPercentage.clamp(0, 100);
    return double.parse((price * (1 - percentage / 100)).toStringAsFixed(2));
  }

  /// The bottle size shown when no size has been selected by the user.
  static ItemPropertyModel? preferred(Iterable<ItemPropertyModel> properties) {
    for (final property in properties) {
      if (property.sizeMl == 50) return property;
    }
    for (final property in properties) {
      if (property.isDefault) return property;
    }
    return properties.isEmpty ? null : properties.first;
  }

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
    this.discountPercentage = 0,
    this.inStock = true,
    this.isDefault = false,
  }) : _propertyDescription = propertyDescription,
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
        discountPercentage:
            (json['discountPercentage'] as num?)?.toDouble() ?? 0,
        inStock: (json['inStock'] as bool?) ?? true,
        isDefault: (json['isDefault'] as bool?) ?? false,
      );
}
