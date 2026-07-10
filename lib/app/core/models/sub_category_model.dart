class SubCategoryModel {
  final int id;
  final int categoryId;
  final String subCategoryName;
  final String subCategoryImage;

  const SubCategoryModel({
    required this.id,
    required this.categoryId,
    required this.subCategoryName,
    required this.subCategoryImage,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) =>
      SubCategoryModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        categoryId: (json['categoryID'] as num?)?.toInt() ?? 0,
        subCategoryName: (json['subCategoryName'] as String?) ??
            (json['name'] as String?) ??
            '',
        subCategoryImage: (json['subCategoryImage'] as String?) ??
            (json['image'] as String?) ??
            '',
      );
}
