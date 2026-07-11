import '../utils/locale_utils.dart';

class ItemModel {
  final int id;
  final int categoryId;
  final int subCategoryId;

  /// 0 = Unisex, 1 = Men, 2 = Women
  final int gender;
  final String _itemName;
  final String _itemNameEn;
  final String _itemDescription;
  final String _itemDescriptionEn;
  final bool isFeatured;

  String get itemName =>
      isEnglishLocale() && _itemNameEn.trim().isNotEmpty
          ? _itemNameEn.trim()
          : _itemName;

  String get itemDescription =>
      isEnglishLocale() && _itemDescriptionEn.trim().isNotEmpty
          ? _itemDescriptionEn.trim()
          : _itemDescription;

  const ItemModel({
    required this.id,
    required this.categoryId,
    required this.subCategoryId,
    this.gender = 0,
    required String itemName,
    String itemNameEn = '',
    required String itemDescription,
    String itemDescriptionEn = '',
    this.isFeatured = false,
  })  : _itemName = itemName,
        _itemNameEn = itemNameEn,
        _itemDescription = itemDescription,
        _itemDescriptionEn = itemDescriptionEn;

  static int _parseGender(dynamic rawGender) {
    if (rawGender is num) return rawGender.toInt();

    final normalized = rawGender?.toString().trim().toLowerCase();
    return switch (normalized) {
      '0' || 'unisex' || 'all' => 0,
      '1' || 'men' || 'male' => 1,
      '2' || 'women' || 'woman' || 'female' => 2,
      _ => 0,
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoryId: (json['categoryID'] as num?)?.toInt() ?? 0,
      subCategoryId: (json['subCategoryID'] as num?)?.toInt() ?? 0,
      gender: _parseGender(json['gender']),
      itemName: firstNonEmptyString(json, const ['itemName', 'name']),
      itemNameEn: firstNonEmptyString(json, const ['itemNameEN']),
      itemDescription:
          firstNonEmptyString(json, const ['itemDescription', 'description']),
      itemDescriptionEn: firstNonEmptyString(json, const ['itemDescriptionEN']),
      isFeatured: (json['isFeatured'] as bool?) ?? false,
    );
}
