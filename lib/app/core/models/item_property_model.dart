class ItemPropertyModel {
  final int id;
  final int itemId;

  /// Size in ml
  final int sizeMl;
  final String image;
  final String? propertyDescription;
  final double price;
  final bool inStock;
  final double? affiliatePercentage;

  const ItemPropertyModel({
    required this.id,
    required this.itemId,
    required this.sizeMl,
    required this.image,
    this.propertyDescription,
    required this.price,
    this.inStock = true,
    this.affiliatePercentage,
  });

  factory ItemPropertyModel.fromJson(Map<String, dynamic> json) =>
      ItemPropertyModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        itemId: (json['itemID'] as num?)?.toInt() ?? 0,
        sizeMl: (json['size'] as num?)?.toInt() ?? 0,
        image: (json['image'] as String?) ?? '',
        propertyDescription: json['propertyDescription'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        inStock: (json['inStock'] as bool?) ?? true,
        affiliatePercentage: json['affiliatePercentage'] != null
            ? (json['affiliatePercentage'] as num).toDouble()
            : null,
      );
}
