import '../utils/locale_utils.dart';
import 'item_property_model.dart';

class VeraSessionContext {
  const VeraSessionContext({
    this.turnCount = 0,
    this.perfumeName = '',
    this.brand = '',
    this.concentration = '',
  });

  final int turnCount;
  final String perfumeName;
  final String brand;
  final String concentration;

  factory VeraSessionContext.fromJson(Map<String, dynamic> json) =>
      VeraSessionContext(
        turnCount: (json['turn_count'] as num?)?.toInt() ?? 0,
        perfumeName: (json['perfume_name'] as String?)?.trim() ?? '',
        brand: (json['brand'] as String?)?.trim() ?? '',
        concentration: (json['concentration'] as String?)?.trim() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'turn_count': turnCount,
    'perfume_name': perfumeName,
    'brand': brand,
    'concentration': concentration,
  };
}

class VeraRecommendationModel {
  const VeraRecommendationModel({
    required this.itemId,
    required this.nameAr,
    required this.nameEn,
    required this.brand,
    required this.score,
    required this.band,
    required this.sharedAccordsAr,
    required this.sharedAccordsEn,
    required this.sharedNotesAr,
    required this.sharedNotesEn,
    required this.inStock,
    this.property,
  });

  final int itemId;
  final String nameAr;
  final String nameEn;
  final String brand;
  final int score;
  final String band;
  final List<String> sharedAccordsAr;
  final List<String> sharedAccordsEn;
  final List<String> sharedNotesAr;
  final List<String> sharedNotesEn;
  final bool inStock;
  final ItemPropertyModel? property;

  String get name => isEnglishLocale() && nameEn.isNotEmpty ? nameEn : nameAr;
  List<String> get sharedAccords =>
      isEnglishLocale() && sharedAccordsEn.isNotEmpty
      ? sharedAccordsEn
      : sharedAccordsAr;
  List<String> get sharedNotes => isEnglishLocale() && sharedNotesEn.isNotEmpty
      ? sharedNotesEn
      : sharedNotesAr;

  factory VeraRecommendationModel.fromJson(Map<String, dynamic> json) {
    final propertyJson = json['property'];
    return VeraRecommendationModel(
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      nameAr: (json['nameAr'] as String?)?.trim() ?? '',
      nameEn: (json['nameEn'] as String?)?.trim() ?? '',
      brand: (json['brand'] as String?)?.trim() ?? '',
      score: ((json['score'] as num?)?.toInt() ?? 0).clamp(0, 100),
      band: (json['band'] as String?)?.trim() ?? 'different_direction',
      sharedAccordsAr: _strings(json['sharedAccordsAr']),
      sharedAccordsEn: _strings(json['sharedAccordsEn']),
      sharedNotesAr: _strings(json['sharedNotesAr']),
      sharedNotesEn: _strings(json['sharedNotesEn']),
      inStock: json['inStock'] == true,
      property: propertyJson is Map
          ? ItemPropertyModel.fromJson({
              'id': propertyJson['id'],
              'itemID': propertyJson['itemId'],
              'size': propertyJson['sizeMl'],
              'image': propertyJson['image'],
              'price': propertyJson['price'],
              'inStock': propertyJson['inStock'],
              'isDefault': propertyJson['isDefault'],
              'propertyDescription': propertyJson['descriptionAr'],
              'propertyDescriptionEN': propertyJson['descriptionEn'],
            })
          : null,
    );
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
}

class VeraResponseModel {
  const VeraResponseModel({
    required this.code,
    required this.assistantText,
    required this.recommendations,
    required this.context,
  });

  final String code;
  final String assistantText;
  final List<VeraRecommendationModel> recommendations;
  final VeraSessionContext context;

  factory VeraResponseModel.fromJson(Map<String, dynamic> json) =>
      VeraResponseModel(
        code: (json['code'] as String?)?.trim() ?? 'service_error',
        assistantText:
            ((json['assistant_text'] ?? json['message']) as String?)?.trim() ??
            '',
        recommendations: ((json['recommendations'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (entry) => VeraRecommendationModel.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList(growable: false),
        context: json['context'] is Map
            ? VeraSessionContext.fromJson(
                Map<String, dynamic>.from(json['context'] as Map),
              )
            : const VeraSessionContext(),
      );
}
