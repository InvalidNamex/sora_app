import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/core/models/vera_response_model.dart';

void main() {
  test('parses Vera recommendations and cart property safely', () {
    final response = VeraResponseModel.fromJson({
      'code': 'ok',
      'assistant_text': 'Five matches found',
      'context': {
        'turn_count': 1,
        'perfume_name': 'Sauvage',
        'brand': 'Dior',
        'concentration': 'EDT',
      },
      'recommendations': [
        {
          'itemId': 42,
          'nameAr': 'بلو دي شانيل',
          'nameEn': 'Bleu de Chanel',
          'brand': 'Chanel',
          'score': 81,
          'band': 'similar',
          'sharedAccordsAr': ['حمضي', 'خشبي'],
          'sharedAccordsEn': ['Citrus', 'Woody'],
          'sharedNotesAr': ['خشب الأرز'],
          'sharedNotesEn': ['Cedar'],
          'inStock': true,
          'property': {
            'id': 7,
            'itemId': 42,
            'sizeMl': 100,
            'image': 'https://example.com/image.jpg',
            'price': 950,
            'inStock': true,
            'isDefault': true,
            'descriptionAr': '١٠٠ مل',
            'descriptionEn': '100 ml',
          },
        },
      ],
    });

    expect(response.code, 'ok');
    expect(response.context.turnCount, 1);
    expect(response.context.perfumeName, 'Sauvage');
    expect(response.recommendations, hasLength(1));
    expect(response.recommendations.single.itemId, 42);
    expect(response.recommendations.single.score, 81);
    expect(response.recommendations.single.property?.itemId, 42);
    expect(response.recommendations.single.property?.inStock, isTrue);
  });

  test('handles a response without recommendations or persisted context', () {
    final response = VeraResponseModel.fromJson({
      'code': 'unsupported',
      'assistant_text': 'Perfume requests only',
      'recommendations': <Object>[],
    });

    expect(response.recommendations, isEmpty);
    expect(response.context.turnCount, 0);
    expect(response.context.perfumeName, isEmpty);
  });
}
