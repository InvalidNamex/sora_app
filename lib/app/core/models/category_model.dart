class CategoryModel {
  final int id;
  final String categoryName;
  final String categoryImage;

  const CategoryModel({
    required this.id,
    required this.categoryName,
    required this.categoryImage,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        categoryName: (json['categoryName'] as String?) ??
            (json['name'] as String?) ??
            '',
        categoryImage: (json['categoryImage'] as String?) ??
            (json['image'] as String?) ??
            '',
      );
}
