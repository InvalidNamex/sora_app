import '../utils/locale_utils.dart';

class CategoryModel {
  final int id;
  final String _categoryName;
  final String _categoryNameEn;
  final String categoryImage;

  String get categoryName =>
      isEnglishLocale() && _categoryNameEn.trim().isNotEmpty
          ? _categoryNameEn.trim()
          : _categoryName;

  const CategoryModel({
    required this.id,
    required String categoryName,
    String categoryNameEn = '',
    required this.categoryImage,
  })  : _categoryName = categoryName,
        _categoryNameEn = categoryNameEn;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        categoryName: firstNonEmptyString(json, const ['categoryName', 'name']),
        categoryNameEn: firstNonEmptyString(json, const ['categoryEN']),
        categoryImage: (json['categoryImage'] as String?) ??
            (json['image'] as String?) ??
            '',
      );
}
