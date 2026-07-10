class OrderDetailModel {
  final int id;
  final int orderMasterId;
  final int itemPropertyId;
  final String itemName;
  final int quantity;
  final double price;

  const OrderDetailModel({
    required this.id,
    required this.orderMasterId,
    required this.itemPropertyId,
    required this.itemName,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) =>
      OrderDetailModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        orderMasterId: (json['orderMasterID'] as num?)?.toInt() ?? 0,
        itemPropertyId: (json['itemPropertyID'] as num?)?.toInt() ?? 0,
        itemName: (json['itemName'] as String?) ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}
