import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/routes/app_pages.dart';

void main() {
  group('Routes.itemPath', () {
    test('creates the existing item route without a property', () {
      expect(Routes.itemPath(42), '/item/42');
    });

    test('includes a valid property id', () {
      expect(Routes.itemPath(42, propertyId: 456), '/item/42?property=456');
    });

    test('ignores an invalid property id', () {
      expect(Routes.itemPath(42, propertyId: 0), '/item/42');
    });
  });
}
