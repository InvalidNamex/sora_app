import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/core/services/share_service.dart';

void main() {
  group('ShareService.itemLink', () {
    test('creates a canonical item link for a regular user', () {
      expect(
        ShareService.itemLink(42).toString(),
        'https://www.sora-eg.store/item/42',
      );
    });

    test('adds the affiliate code when present', () {
      expect(
        ShareService.itemLink(42, affiliateCode: ' rios10 ').toString(),
        'https://www.sora-eg.store/item/42?ref=RIOS10',
      );
    });

    test('adds the selected property when present', () {
      expect(
        ShareService.itemLink(42, propertyId: 456).toString(),
        'https://www.sora-eg.store/item/42?property=456',
      );
    });

    test('combines the selected property and affiliate code', () {
      expect(
        ShareService.itemLink(
          42,
          propertyId: 456,
          affiliateCode: ' rios10 ',
        ).toString(),
        'https://www.sora-eg.store/item/42?property=456&ref=RIOS10',
      );
    });

    test('ignores an invalid property id', () {
      expect(
        ShareService.itemLink(42, propertyId: 0).toString(),
        'https://www.sora-eg.store/item/42',
      );
    });
  });
}
