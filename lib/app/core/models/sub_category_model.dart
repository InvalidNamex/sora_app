import '../utils/locale_utils.dart';

class SubCategoryModel {
  final int id;
  final int categoryId;
  final String _subCategoryName;
  final String _subCategoryNameEn;
  final String subCategoryImage;

  String get subCategoryName =>
      isEnglishLocale() && _subCategoryNameEn.trim().isNotEmpty
          ? _subCategoryNameEn.trim()
          : _subCategoryName;

  const SubCategoryModel({
    required this.id,
    required this.categoryId,
    required String subCategoryName,
    String subCategoryNameEn = '',
    required this.subCategoryImage,
  })  : _subCategoryName = subCategoryName,
        _subCategoryNameEn = subCategoryNameEn;

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) =>
      SubCategoryModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        categoryId: (json['categoryID'] as num?)?.toInt() ?? 0,
        subCategoryName:
            firstNonEmptyString(json, const ['subCategoryName', 'name']),
        subCategoryNameEn: firstNonEmptyString(json, const ['subCategoryEN']),
        subCategoryImage: (json['subCategoryImage'] as String?) ??
            (json['image'] as String?) ??
            '',
      );
}
