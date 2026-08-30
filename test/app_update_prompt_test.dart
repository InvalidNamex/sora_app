import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/core/widgets/app_update_prompt.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  group('SoraUpgraderMessages', () {
    test('uses Egyptian Arabic update copy', () {
      final messages = SoraUpgraderMessages('ar');

      expect(messages.message(UpgraderMessage.title), 'تحديث جديد متاح');
      expect(
        messages.message(UpgraderMessage.buttonTitleUpdate),
        'حدّث دلوقتي',
      );
      expect(messages.message(UpgraderMessage.buttonTitleLater), 'بعدين');
    });

    test('falls back to package translations for English', () {
      final messages = SoraUpgraderMessages('en');

      expect(messages.message(UpgraderMessage.title), 'Update App?');
      expect(messages.message(UpgraderMessage.buttonTitleUpdate), 'UPDATE NOW');
    });
  });
}
