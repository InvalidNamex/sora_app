import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/core/services/affiliate_program_service.dart';

void main() {
  group('AffiliateProgramService.promoCodeFromInput', () {
    test('normalizes a plain promo code', () {
      expect(AffiliateProgramService.promoCodeFromInput(' test26 '), 'TEST26');
    });

    test('extracts a code from a shared item URL', () {
      expect(
        AffiliateProgramService.promoCodeFromInput(
          'https://www.sora-eg.store/item/42?ref=test26',
        ),
        'TEST26',
      );
    });

    test('extracts a code from a referral URL', () {
      expect(
        AffiliateProgramService.promoCodeFromInput(
          'https://www.sora-eg.store/ref/test26',
        ),
        'TEST26',
      );
    });

    test('extracts a code when the full share message is pasted', () {
      expect(
        AffiliateProgramService.promoCodeFromInput(
          'See this item\n'
          'https://www.sora-eg.store/item/42?ref=TEST26',
        ),
        'TEST26',
      );
    });
  });
}
