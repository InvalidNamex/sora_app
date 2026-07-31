import '../utils/locale_utils.dart';

class PerfumeAccord {
  const PerfumeAccord({required this.name, required this.percentage});

  final String name;
  final int percentage;
}

class ItemModel {
  final int id;
  final int categoryId;
  final int subCategoryId;

  /// 0 = Unisex, 1 = Men, 2 = Women
  final int gender;
  final String _itemName;
  final String _itemNameEn;
  final String brandName;
  final String _itemDescription;
  final String _itemDescriptionEn;
  final List<String> _notes;
  final List<String> _notesEn;
  final List<String> _topNotes;
  final List<String> _topNotesEn;
  final List<String> _middleNotes;
  final List<String> _middleNotesEn;
  final List<String> _baseNotes;
  final List<String> _baseNotesEn;
  final List<String> _accords;
  final List<String> _accordsEn;
  final List<int> _accordPercentages;
  final bool isFeatured;

  String get itemName => isEnglishLocale() && _itemNameEn.trim().isNotEmpty
      ? _itemNameEn.trim()
      : _itemName;

  String get itemDescription =>
      isEnglishLocale() && _itemDescriptionEn.trim().isNotEmpty
      ? _itemDescriptionEn.trim()
      : _itemDescription;

  String get nameAr => _itemName;
  String get nameEn => _itemNameEn;
  String get descAr => _itemDescription;
  String get descEn => _itemDescriptionEn;
  List<String> get notes =>
      isEnglishLocale() && _notesEn.isNotEmpty ? _notesEn : _notes;
  List<String> get topNotes =>
      isEnglishLocale() && _topNotesEn.isNotEmpty ? _topNotesEn : _topNotes;
  List<String> get middleNotes => isEnglishLocale() && _middleNotesEn.isNotEmpty
      ? _middleNotesEn
      : _middleNotes;
  List<String> get baseNotes =>
      isEnglishLocale() && _baseNotesEn.isNotEmpty ? _baseNotesEn : _baseNotes;
  List<String> get accords =>
      isEnglishLocale() && _accordsEn.isNotEmpty ? _accordsEn : _accords;
  List<String> get notesAr => _notes;
  List<String> get notesEn => _notesEn;
  List<String> get topNotesAr => _topNotes;
  List<String> get topNotesEn => _topNotesEn;
  List<String> get middleNotesAr => _middleNotes;
  List<String> get middleNotesEn => _middleNotesEn;
  List<String> get baseNotesAr => _baseNotes;
  List<String> get baseNotesEn => _baseNotesEn;
  List<String> get accordsAr => _accords;
  List<String> get accordsEn => _accordsEn;
  List<int> get accordPercentages => _accordPercentages;

  bool get hasGroupedNotes =>
      topNotes.isNotEmpty || middleNotes.isNotEmpty || baseNotes.isNotEmpty;

  List<PerfumeAccord> get accordProfile {
    final localizedAccords = accords;
    final count = localizedAccords.length < _accordPercentages.length
        ? localizedAccords.length
        : _accordPercentages.length;

    return List<PerfumeAccord>.generate(
      count,
      (index) => PerfumeAccord(
        name: localizedAccords[index],
        percentage: _accordPercentages[index],
      ),
      growable: false,
    );
  }

  const ItemModel({
    required this.id,
    required this.categoryId,
    required this.subCategoryId,
    this.gender = 0,
    required String itemName,
    String itemNameEn = '',
    this.brandName = '',
    required String itemDescription,
    String itemDescriptionEn = '',
    List<String> notes = const [],
    List<String> notesEn = const [],
    List<String> topNotes = const [],
    List<String> topNotesEn = const [],
    List<String> middleNotes = const [],
    List<String> middleNotesEn = const [],
    List<String> baseNotes = const [],
    List<String> baseNotesEn = const [],
    List<String> accords = const [],
    List<String> accordsEn = const [],
    List<int> accordPercentages = const [],
    this.isFeatured = false,
  }) : _itemName = itemName,
       _itemNameEn = itemNameEn,
       _itemDescription = itemDescription,
       _itemDescriptionEn = itemDescriptionEn,
       _notes = notes,
       _notesEn = notesEn,
       _topNotes = topNotes,
       _topNotesEn = topNotesEn,
       _middleNotes = middleNotes,
       _middleNotesEn = middleNotesEn,
       _baseNotes = baseNotes,
       _baseNotesEn = baseNotesEn,
       _accords = accords,
       _accordsEn = accordsEn,
       _accordPercentages = accordPercentages;

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

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static List<int> _parsePercentageList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map(
          (entry) => entry is num
              ? entry.toInt()
              : int.tryParse(entry?.toString().trim() ?? ''),
        )
        .whereType<int>()
        .where((percentage) => percentage >= 0 && percentage <= 100)
        .toList(growable: false);
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    categoryId: (json['categoryID'] as num?)?.toInt() ?? 0,
    subCategoryId: (json['subCategoryID'] as num?)?.toInt() ?? 0,
    gender: _parseGender(json['gender']),
    itemName: firstNonEmptyString(json, const ['itemName', 'name']),
    itemNameEn: firstNonEmptyString(json, const ['itemNameEN']),
    brandName: firstNonEmptyString(json, const ['brandName', 'brand']),
    itemDescription: firstNonEmptyString(json, const [
      'itemDescription',
      'description',
    ]),
    itemDescriptionEn: firstNonEmptyString(json, const ['itemDescriptionEN']),
    notes: _parseStringList(json['notes']),
    notesEn: _parseStringList(json['notesEN']),
    topNotes: _parseStringList(json['topNotes']),
    topNotesEn: _parseStringList(json['topNotesEN']),
    middleNotes: _parseStringList(json['middleNotes']),
    middleNotesEn: _parseStringList(json['middleNotesEN']),
    baseNotes: _parseStringList(json['baseNotes']),
    baseNotesEn: _parseStringList(json['baseNotesEN']),
    accords: _parseStringList(json['accords']),
    accordsEn: _parseStringList(json['accordsEN']),
    accordPercentages: _parsePercentageList(json['accordPercentages']),
    isFeatured: (json['isFeatured'] as bool?) ?? false,
  );
}
