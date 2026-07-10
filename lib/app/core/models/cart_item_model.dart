/// Represents one line in the shopping cart.
///
/// Used for both guest (local storage) and authenticated (Supabase) carts.
/// [cartId] is 0 for guest entries.
class CartItemModel {
  final int cartId;
  final int itemPropertyId;
  final String itemName;
  final String image;
  final int sizeMl;
  final double price;
  int quantity;

  CartItemModel({
    required this.cartId,
    required this.itemPropertyId,
    required this.itemName,
    required this.image,
    required this.sizeMl,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  // ── Local (guest) ──────────────────────────────────────────────────────────

  Map<String, dynamic> toLocalJson() => {
        'itemPropertyId': itemPropertyId,
        'itemName': itemName,
        'image': image,
        'sizeMl': sizeMl,
        'price': price,
        'quantity': quantity,
      };

  factory CartItemModel.fromLocalJson(Map<String, dynamic> json) =>
      CartItemModel(
        cartId: 0,
        itemPropertyId: (json['itemPropertyId'] as num?)?.toInt() ?? 0,
        itemName: (json['itemName'] as String?) ?? '',
        image: (json['image'] as String?) ?? '',
        sizeMl: (json['sizeMl'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );

  // ── Remote (Supabase joined query) ────────────────────────────────────────
  //
  // Expected query: cart.select('id, quantity, item_properties(id, size, image, price, items(itemName))')

  factory CartItemModel.fromSupabaseJson(Map<String, dynamic> json) {
    final prop = json['item_properties'] as Map<String, dynamic>;
    final item = prop['items'] as Map<String, dynamic>;
    return CartItemModel(
      cartId: (json['id'] as num?)?.toInt() ?? 0,
      itemPropertyId: (prop['id'] as num?)?.toInt() ?? 0,
      itemName: (item['itemName'] as String?) ?? '',
      image: (prop['image'] as String?) ?? '',
      sizeMl: (prop['size'] as num?)?.toInt() ?? 0,
      price: (prop['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  CartItemModel copyWith({int? quantity}) => CartItemModel(
        cartId: cartId,
        itemPropertyId: itemPropertyId,
        itemName: itemName,
        image: image,
        sizeMl: sizeMl,
        price: price,
        quantity: quantity ?? this.quantity,
      );
}
