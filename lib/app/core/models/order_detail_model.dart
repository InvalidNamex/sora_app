import '../utils/locale_utils.dart';

class OrderDetailModel {
  final int id;
  final int orderMasterId;
  final int itemPropertyId;
  final String _itemName;
  final String _itemNameEn;
  final int quantity;
  final double price;

  String get itemName {
    if (isEnglishLocale() && _itemNameEn.trim().isNotEmpty) {
      return _itemNameEn.trim();
    }
    return _itemName;
  }

  String get nameAr => _itemName;
  String get nameEn => _itemNameEn;

  const OrderDetailModel({
    required this.id,
    required this.orderMasterId,
    required this.itemPropertyId,
    required String itemName,
    String itemNameEn = '',
    required this.quantity,
    required this.price,
  }) : _itemName = itemName,
       _itemNameEn = itemNameEn;

  double get subtotal => price * quantity;

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) =>
      OrderDetailModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        orderMasterId: (json['orderMasterID'] as num?)?.toInt() ?? 0,
        itemPropertyId: (json['itemPropertyID'] as num?)?.toInt() ?? 0,
        itemName: firstNonEmptyString(json, const ['itemName']),
        itemNameEn: firstNonEmptyString(json, const ['itemNameEN']),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}
