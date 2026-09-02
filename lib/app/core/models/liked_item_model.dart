import '../utils/locale_utils.dart';

/// Represents a liked/wishlisted item with its display data.
///
/// Built from:
/// ```dart
/// liked_items.select('id, itemID, items(id, itemName, itemNameEN, item_properties(id, image, price, inStock, isDefault, size))')
/// ```
class LikedItemModel {
  final int id;
  final int itemId;
  final String _itemName;
  final String _itemNameEn;
  final int? primaryPropertyId;
  final String? primaryImage;
  final double? price;
  final double? regularPrice;
  final double discountPercentage;
  final bool inStock;

  bool get hasDiscount =>
      regularPrice != null && price != null && regularPrice! > price!;

  String get itemName => isEnglishLocale() && _itemNameEn.trim().isNotEmpty
      ? _itemNameEn.trim()
      : _itemName;

  const LikedItemModel({
    required this.id,
    required this.itemId,
    required String itemName,
    String itemNameEn = '',
    this.primaryPropertyId,
    this.primaryImage,
    this.price,
    this.regularPrice,
    this.discountPercentage = 0,
    this.inStock = true,
  }) : _itemName = itemName,
       _itemNameEn = itemNameEn;

  factory LikedItemModel.fromJson(Map<String, dynamic> json) {
    final item = json['items'] as Map<String, dynamic>? ?? {};
    final props = ((item['item_properties'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final primary = props.firstWhere(
      (p) => (p['size'] as num?)?.toInt() == 50,
      orElse: () => props.firstWhere(
        (p) => (p['isDefault'] as bool?) ?? false,
        orElse: () => props.isNotEmpty ? props.first : <String, dynamic>{},
      ),
    );

    return LikedItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemId: (json['itemID'] as num?)?.toInt() ?? 0,
      itemName: firstNonEmptyString(item, const ['itemName', 'name']),
      itemNameEn: firstNonEmptyString(item, const ['itemNameEN']),
      primaryPropertyId: (primary['id'] as num?)?.toInt(),
      primaryImage: primary['image'] as String?,
      regularPrice: (primary['price'] as num?)?.toDouble(),
      discountPercentage:
          (primary['discountPercentage'] as num?)?.toDouble() ?? 0,
      price: _salePrice(
        (primary['price'] as num?)?.toDouble(),
        (primary['discountPercentage'] as num?)?.toDouble() ?? 0,
      ),
      inStock: (primary['inStock'] as bool?) ?? true,
    );
  }

  static double? _salePrice(double? price, double discount) {
    if (price == null || discount <= 0) return price;
    final percentage = discount.clamp(0, 100).toDouble();
    return double.parse((price * (1 - percentage / 100)).toStringAsFixed(2));
  }
}
