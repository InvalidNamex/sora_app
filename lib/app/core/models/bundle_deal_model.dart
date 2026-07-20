import '../utils/locale_utils.dart';
import 'item_property_model.dart';

class BundleDealItemModel {
  const BundleDealItemModel({
    required this.id,
    required this.bundleId,
    required this.property,
    required this.quantity,
    required String itemName,
    String itemNameEn = '',
  }) : _itemName = itemName,
       _itemNameEn = itemNameEn;

  final int id;
  final int bundleId;
  final ItemPropertyModel property;
  final int quantity;
  final String _itemName;
  final String _itemNameEn;

  String get itemName => isEnglishLocale() && _itemNameEn.trim().isNotEmpty
      ? _itemNameEn.trim()
      : _itemName;
  String get itemNameAr => _itemName;
  String get itemNameEn => _itemNameEn;

  double get regularTotal => property.price * quantity;

  factory BundleDealItemModel.fromJson(Map<String, dynamic> json) {
    final propertyJson =
        json['item_properties'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final itemJson =
        propertyJson['items'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return BundleDealItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bundleId: (json['bundleID'] as num?)?.toInt() ?? 0,
      property: ItemPropertyModel.fromJson(propertyJson),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      itemName: (itemJson['itemName'] as String?) ?? '',
      itemNameEn: (itemJson['itemNameEN'] as String?) ?? '',
    );
  }
}

class BundleDealModel {
  const BundleDealModel({
    required this.id,
    required String title,
    String titleEn = '',
    String description = '',
    String descriptionEn = '',
    required this.bannerImage,
    required this.dealPrice,
    this.isActive = true,
    this.sortOrder = 0,
    this.items = const [],
  }) : _title = title,
       _titleEn = titleEn,
       _description = description,
       _descriptionEn = descriptionEn;

  final int id;
  final String _title;
  final String _titleEn;
  final String _description;
  final String _descriptionEn;
  final String bannerImage;
  final double dealPrice;
  final bool isActive;
  final int sortOrder;
  final List<BundleDealItemModel> items;

  String get title => isEnglishLocale() && _titleEn.trim().isNotEmpty
      ? _titleEn.trim()
      : _title;

  String get description =>
      isEnglishLocale() && _descriptionEn.trim().isNotEmpty
      ? _descriptionEn.trim()
      : _description;

  String get titleAr => _title;
  String get titleEn => _titleEn;
  String get descriptionAr => _description;
  String get descriptionEn => _descriptionEn;

  double get regularPrice =>
      items.fold(0, (sum, item) => sum + item.regularTotal);
  double get savings => (regularPrice - dealPrice).clamp(0, double.infinity);
  bool get isAvailable =>
      isActive &&
      items.isNotEmpty &&
      items.every((item) => item.property.inStock);

  factory BundleDealModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['bundle_deal_items'] as List?) ?? const [];
    return BundleDealModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      titleEn: (json['titleEN'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      descriptionEn: (json['descriptionEN'] as String?) ?? '',
      bannerImage: (json['bannerImage'] as String?) ?? '',
      dealPrice: (json['dealPrice'] as num?)?.toDouble() ?? 0,
      isActive: (json['isActive'] as bool?) ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                BundleDealItemModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class BundleCartItemModel {
  BundleCartItemModel({
    required this.cartId,
    required this.bundle,
    required this.quantity,
  });

  final int cartId;
  final BundleDealModel bundle;
  int quantity;

  double get subtotal => bundle.dealPrice * quantity;
  double get regularSubtotal => bundle.regularPrice * quantity;
  double get savings => (regularSubtotal - subtotal).clamp(0, double.infinity);

  Map<String, dynamic> toLocalJson() => {
    'bundle': {
      'id': bundle.id,
      'title': bundle.titleAr,
      'titleEN': bundle.titleEn,
      'description': bundle.descriptionAr,
      'descriptionEN': bundle.descriptionEn,
      'bannerImage': bundle.bannerImage,
      'dealPrice': bundle.dealPrice,
      'isActive': bundle.isActive,
      'sortOrder': bundle.sortOrder,
      'bundle_deal_items': bundle.items
          .map(
            (item) => {
              'id': item.id,
              'bundleID': item.bundleId,
              'quantity': item.quantity,
              'item_properties': {
                'id': item.property.id,
                'itemID': item.property.itemId,
                'size': item.property.sizeMl,
                'image': item.property.image,
                'propertyDescription': item.property.descAr,
                'propertyDescriptionEN': item.property.descEn,
                'price': item.property.price,
                'inStock': item.property.inStock,
                'isDefault': item.property.isDefault,
                'items': {
                  'itemName': item.itemNameAr,
                  'itemNameEN': item.itemNameEn,
                },
              },
            },
          )
          .toList(),
    },
    'quantity': quantity,
  };

  factory BundleCartItemModel.fromLocalJson(Map<String, dynamic> json) {
    final rawBundle =
        json['bundle'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return BundleCartItemModel(
      cartId: 0,
      bundle: BundleDealModel.fromJson(rawBundle),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  factory BundleCartItemModel.fromSupabaseJson(Map<String, dynamic> json) {
    final rawBundle =
        json['bundle_deals'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return BundleCartItemModel(
      cartId: (json['id'] as num?)?.toInt() ?? 0,
      bundle: BundleDealModel.fromJson(rawBundle),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
