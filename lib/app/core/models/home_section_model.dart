import '../utils/locale_utils.dart';

/// A configurable product collection shown on the home page.
class HomeSectionModel {
  const HomeSectionModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.type,
    required this.itemLimit,
    required this.displayOrder,
    required this.isActive,
    this.itemIds = const [],
  });

  final int id;
  final String titleAr;
  final String titleEn;
  final String type;
  final int itemLimit;
  final int displayOrder;
  final bool isActive;
  final List<int> itemIds;

  bool get isRecentlyAdded => type == 'recently_added';
  bool get isDiscounted => type == 'discounted';

  String get title =>
      isEnglishLocale() && titleEn.isNotEmpty ? titleEn : titleAr;

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    final rows = (json['home_section_items'] as List?) ?? const [];
    final itemIds =
        rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList()
          ..sort(
            (left, right) => ((left['display_order'] as num?)?.toInt() ?? 0)
                .compareTo((right['display_order'] as num?)?.toInt() ?? 0),
          );

    return HomeSectionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      titleAr: (json['title'] as String?)?.trim() ?? '',
      titleEn: (json['titleEN'] as String?)?.trim() ?? '',
      type: (json['section_type'] as String?)?.trim() ?? 'manual',
      itemLimit: (json['item_limit'] as num?)?.toInt() ?? 10,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] != false,
      itemIds: itemIds
          .map((row) => (row['itemID'] as num?)?.toInt())
          .whereType<int>()
          .toList(growable: false),
    );
  }
}
