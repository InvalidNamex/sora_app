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
  final double price;
  final double displayPrice;
  int quantity;

  String get itemName =>
      isEnglishLocale() && _itemNameEn.trim().isNotEmpty
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
    required this.price,
    double? displayPrice,
    required this.quantity,
  })  : displayImage = displayImage ?? image,
      displayPrice = displayPrice ?? price,
      _itemName = itemName,
      _itemNameEn = itemNameEn;

  double get subtotal => price * quantity;

  // ── Local (guest) ──────────────────────────────────────────────────────────

  Map<String, dynamic> toLocalJson() => {
        'itemPropertyId': itemPropertyId,
        'itemId': itemId,
        'itemName': itemName,
        'image': image,
        'displayImage': displayImage,
        'sizeMl': sizeMl,
        'price': price,
        'displayPrice': displayPrice,
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
        price: (json['price'] as num?)?.toDouble() ?? 0,
        displayPrice: (json['displayPrice'] as num?)?.toDouble(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );

  // ── Remote (Supabase joined query) ────────────────────────────────────────
  //
  // Expected query:
  // cart.select('id, itemID, quantity, item_properties!propertyID(id, itemID, size, image, price), items(itemName, itemNameEN, item_properties(id, image, price, isDefault, inStock))')

  factory CartItemModel.fromSupabaseJson(Map<String, dynamic> json) {
    final selectedProp = json['item_properties'] as Map<String, dynamic>? ?? {};
    final item = json['items'] as Map<String, dynamic>? ?? {};
    final itemProperties = (item['item_properties'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final defaultProp = itemProperties.firstWhere(
      (p) => (p['isDefault'] as bool?) ?? false,
      orElse: () => selectedProp,
    );

    final selectedImage = (selectedProp['image'] as String?) ?? '';
    final defaultImage = (defaultProp['image'] as String?) ?? '';
    final selectedPrice = (selectedProp['price'] as num?)?.toDouble() ?? 0;
    final defaultPrice = (defaultProp['price'] as num?)?.toDouble() ?? 0;

    return CartItemModel(
      cartId: (json['id'] as num?)?.toInt() ?? 0,
      itemPropertyId: (selectedProp['id'] as num?)?.toInt() ?? 0,
      itemId: (json['itemID'] as num?)?.toInt() ??
          (selectedProp['itemID'] as num?)?.toInt() ??
          0,
      itemName: firstNonEmptyString(item, const ['itemName']),
      itemNameEn: firstNonEmptyString(item, const ['itemNameEN']),
      image: selectedImage,
      displayImage: defaultImage.isNotEmpty ? defaultImage : selectedImage,
      sizeMl: (selectedProp['size'] as num?)?.toInt() ?? 0,
      price: selectedPrice,
      displayPrice: defaultPrice > 0 ? defaultPrice : selectedPrice,
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
        price: price,
        displayPrice: displayPrice,
        quantity: quantity ?? this.quantity,
      );
}
