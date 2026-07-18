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
  });
}
