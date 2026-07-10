class ItemModel {
  final int id;
  final int categoryId;
  final int subCategoryId;

  /// 0 = Unisex, 1 = Men, 2 = Women
  final int gender;
  final String itemName;
  final String itemDescription;
  final bool isFeatured;

  const ItemModel({
    required this.id,
    required this.categoryId,
    required this.subCategoryId,
    this.gender = 0,
    required this.itemName,
    required this.itemDescription,
    this.isFeatured = false,
  });

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
      itemName: (json['itemName'] as String?) ?? '',
        itemDescription: (json['itemDescription'] as String?) ?? '',
        isFeatured: (json['isFeatured'] as bool?) ?? false,
      );
}
