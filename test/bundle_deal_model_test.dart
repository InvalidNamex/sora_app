import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/core/models/bundle_deal_model.dart';
import 'package:sora/app/core/services/bundle_deal_service.dart';

void main() {
  test('bundle query uses the database column casing', () {
    expect(
      BundleDealService.bundleSelect,
      contains('PropertyDescription, propertyDescriptionEN'),
    );
    expect(
      BundleDealService.bundleSelect,
      isNot(contains('image, propertyDescription')),
    );
  });

  group('BundleDealModel', () {
    final json = <String, dynamic>{
      'id': 12,
      'title': 'باقة',
      'titleEN': 'Bundle',
      'description': 'وصف',
      'descriptionEN': 'Description',
      'bannerImage': 'https://example.com/banner.webp',
      'dealPrice': 250,
      'isActive': true,
      'sortOrder': 3,
      'bundle_deal_items': [
        {
          'id': 1,
          'bundleID': 12,
          'quantity': 2,
          'item_properties': {
            'id': 20,
            'itemID': 7,
            'size': 100,
            'image': 'https://example.com/item.webp',
            'price': 100,
            'inStock': true,
            'isDefault': true,
            'items': {'itemName': 'منتج', 'itemNameEN': 'Item'},
          },
        },
        {
          'id': 2,
          'bundleID': 12,
          'quantity': 1,
          'item_properties': {
            'id': 21,
            'itemID': 8,
            'size': 50,
            'image': '',
            'price': 80,
            'inStock': true,
            'isDefault': true,
            'items': {'itemName': 'منتج ٢', 'itemNameEN': 'Item 2'},
          },
        },
      ],
    };

    test('calculates regular price and savings from fixed quantities', () {
      final bundle = BundleDealModel.fromJson(json);

      expect(bundle.regularPrice, 280);
      expect(bundle.dealPrice, 250);
      expect(bundle.savings, 30);
      expect(bundle.isAvailable, isTrue);
    });

    test('bundle cart quantity multiplies deal and regular totals', () {
      final cartItem = BundleCartItemModel(
        cartId: 0,
        bundle: BundleDealModel.fromJson(json),
        quantity: 3,
      );

      expect(cartItem.subtotal, 750);
      expect(cartItem.regularSubtotal, 840);
      expect(cartItem.savings, 90);
    });

    test('guest cart serialization preserves the bundle recipe', () {
      final original = BundleCartItemModel(
        cartId: 0,
        bundle: BundleDealModel.fromJson(json),
        quantity: 2,
      );
      final restored = BundleCartItemModel.fromLocalJson(
        original.toLocalJson(),
      );

      expect(restored.bundle.id, 12);
      expect(restored.quantity, 2);
      expect(restored.bundle.items, hasLength(2));
      expect(restored.bundle.items.first.quantity, 2);
      expect(restored.subtotal, 500);
    });
  });
}
