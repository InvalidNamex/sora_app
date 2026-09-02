import '../utils/locale_utils.dart';

/// Represents one line in the shopping cart.
///
/// Used for both guest (local storage) and authenticated (Supabase) carts.
/// [cartId] is 0 for guest entries.
class CartItemModel {
  final int cartId;
  final int itemPropertyId;
  final int itemId;
  final String _itemName;
  final String _itemNameEn;
  final String image;
  final String displayImage;
  final int sizeMl;

  /// The catalog price before the item-level discount.
  final double regularPrice;

  /// The price charged for this line after the item-level discount.
  final double price;
  final double discountPercentage;
  final double displayPrice;
  final double displayRegularPrice;
  int quantity;

  String get itemName => isEnglishLocale() && _itemNameEn.trim().isNotEmpty
      ? _itemNameEn.trim()
      : _itemName;

  CartItemModel({
    required this.cartId,
    required this.itemPropertyId,
    required this.itemId,
    required String itemName,
    String itemNameEn = '',
    required this.image,
    String? displayImage,
    required this.sizeMl,
    double? regularPrice,
    required this.price,
    this.discountPercentage = 0,
    double? displayPrice,
    double? displayRegularPrice,
    required this.quantity,
  }) : regularPrice = regularPrice ?? price,
       displayImage = displayImage ?? image,
       displayPrice = displayPrice ?? price,
       displayRegularPrice = displayRegularPrice ?? (regularPrice ?? price),
       _itemName = itemName,
       _itemNameEn = itemNameEn;

  double get subtotal => price * quantity;
  bool get hasDiscount => regularPrice > price;

  // ── Local (guest) ──────────────────────────────────────────────────────────

  Map<String, dynamic> toLocalJson() => {
    'itemPropertyId': itemPropertyId,
    'itemId': itemId,
    'itemName': itemName,
    'image': image,
    'displayImage': displayImage,
    'sizeMl': sizeMl,
    'regularPrice': regularPrice,
    'price': price,
    'discountPercentage': discountPercentage,
    'displayPrice': displayPrice,
    'displayRegularPrice': displayRegularPrice,
    'quantity': quantity,
  };

  factory CartItemModel.fromLocalJson(Map<String, dynamic> json) =>
      CartItemModel(
        cartId: 0,
        itemPropertyId: (json['itemPropertyId'] as num?)?.toInt() ?? 0,
        itemId: (json['itemId'] as num?)?.toInt() ?? 0,
        itemName: (json['itemName'] as String?) ?? '',
        image: (json['image'] as String?) ?? '',
        displayImage: (json['displayImage'] as String?),
        sizeMl: (json['sizeMl'] as num?)?.toInt() ?? 0,
        regularPrice: (json['regularPrice'] as num?)?.toDouble(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        discountPercentage:
            (json['discountPercentage'] as num?)?.toDouble() ?? 0,
        displayPrice: (json['displayPrice'] as num?)?.toDouble(),
        displayRegularPrice: (json['displayRegularPrice'] as num?)?.toDouble(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );

  // ── Remote (Supabase joined query) ────────────────────────────────────────
  //
  // Expected query:
  // cart.select('id, itemID, quantity, item_properties!propertyID(id, itemID, size, image, price, discountPercentage), items(itemName, itemNameEN, item_properties(id, image, price, discountPercentage, isDefault, inStock))')

  factory CartItemModel.fromSupabaseJson(Map<String, dynamic> json) {
    final selectedProp = json['item_properties'] as Map<String, dynamic>? ?? {};
    final item = json['items'] as Map<String, dynamic>? ?? {};
    final itemProperties =
        (item['item_properties'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final defaultProp = itemProperties.firstWhere(
      (p) => (p['size'] as num?)?.toInt() == 50,
      orElse: () => itemProperties.firstWhere(
        (p) => (p['isDefault'] as bool?) ?? false,
        orElse: () => selectedProp,
      ),
    );

    final selectedImage = (selectedProp['image'] as String?) ?? '';
    final defaultImage = (defaultProp['image'] as String?) ?? '';
    final selectedRegularPrice =
        (selectedProp['price'] as num?)?.toDouble() ?? 0;
    final selectedDiscount =
        (selectedProp['discountPercentage'] as num?)?.toDouble() ?? 0;
    final selectedPrice = _salePrice(selectedRegularPrice, selectedDiscount);
    final defaultRegularPrice = (defaultProp['price'] as num?)?.toDouble() ?? 0;
    final defaultDiscount =
        (defaultProp['discountPercentage'] as num?)?.toDouble() ?? 0;
    final defaultPrice = _salePrice(defaultRegularPrice, defaultDiscount);

    return CartItemModel(
      cartId: (json['id'] as num?)?.toInt() ?? 0,
      itemPropertyId: (selectedProp['id'] as num?)?.toInt() ?? 0,
      itemId:
          (json['itemID'] as num?)?.toInt() ??
          (selectedProp['itemID'] as num?)?.toInt() ??
          0,
      itemName: firstNonEmptyString(item, const ['itemName']),
      itemNameEn: firstNonEmptyString(item, const ['itemNameEN']),
      image: selectedImage,
      displayImage: defaultImage.isNotEmpty ? defaultImage : selectedImage,
      sizeMl: (selectedProp['size'] as num?)?.toInt() ?? 0,
      regularPrice: selectedRegularPrice,
      price: selectedPrice,
      discountPercentage: selectedDiscount,
      displayPrice: defaultPrice > 0 ? defaultPrice : selectedPrice,
      displayRegularPrice: defaultRegularPrice > 0
          ? defaultRegularPrice
          : selectedRegularPrice,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  CartItemModel copyWith({int? quantity}) => CartItemModel(
    cartId: cartId,
    itemPropertyId: itemPropertyId,
    itemId: itemId,
    itemName: itemName,
    image: image,
    displayImage: displayImage,
    sizeMl: sizeMl,
    regularPrice: regularPrice,
    price: price,
    discountPercentage: discountPercentage,
    displayPrice: displayPrice,
    displayRegularPrice: displayRegularPrice,
    quantity: quantity ?? this.quantity,
  );

  static double _salePrice(double price, double discount) {
    if (discount <= 0) return price;
    final percentage = discount.clamp(0, 100).toDouble();
    return double.parse((price * (1 - percentage / 100)).toStringAsFixed(2));
  }
}
