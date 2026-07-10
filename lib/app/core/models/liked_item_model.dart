/// Represents a liked/wishlisted item with its display data.
///
/// Built from:
/// ```dart
/// liked_items.select('id, itemID, items(id, itemName, item_properties(id, image, price, inStock, size))')
/// ```
class LikedItemModel {
  final int id;
  final int itemId;
  final String itemName;
  final int? primaryPropertyId;
  final String? primaryImage;
  final double? price;
  final bool inStock;

  const LikedItemModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.primaryPropertyId,
    this.primaryImage,
    this.price,
    this.inStock = true,
  });

  factory LikedItemModel.fromJson(Map<String, dynamic> json) {
    final item = json['items'] as Map<String, dynamic>? ?? {};
    final props = (item['item_properties'] as List?) ?? [];
    final primary =
        props.isNotEmpty ? props.first as Map<String, dynamic> : null;

    return LikedItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemId: (json['itemID'] as num?)?.toInt() ?? 0,
      itemName: (item['itemName'] as String?) ?? '',
      primaryPropertyId: (primary?['id'] as num?)?.toInt(),
      primaryImage: primary?['image'] as String?,
      price: (primary?['price'] as num?)?.toDouble(),
      inStock: (primary?['inStock'] as bool?) ?? true,
    );
  }
}
