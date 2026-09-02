import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/core/models/cart_item_model.dart';
import 'package:sora/app/core/models/item_property_model.dart';

void main() {
  test('item property calculates a rounded sale price', () {
    final property = ItemPropertyModel.fromJson({
      'id': 1,
      'itemID': 10,
      'size': 50,
      'price': 999,
      'discountPercentage': 15,
    });

    expect(property.hasDiscount, isTrue);
    expect(property.salePrice, 849.15);
  });

  test(
    'preferred property remains 50 ml even when another size is default',
    () {
      final properties = [
        ItemPropertyModel.fromJson({
          'id': 1,
          'itemID': 10,
          'size': 100,
          'price': 1500,
          'isDefault': true,
        }),
        ItemPropertyModel.fromJson({
          'id': 2,
          'itemID': 10,
          'size': 50,
          'price': 900,
        }),
      ];

      expect(ItemPropertyModel.preferred(properties)?.sizeMl, 50);
    },
  );

  test('remote cart lines retain regular and sale prices', () {
    final item = CartItemModel.fromSupabaseJson({
      'id': 7,
      'itemID': 10,
      'quantity': 2,
      'item_properties': {
        'id': 20,
        'itemID': 10,
        'size': 50,
        'price': 1000,
        'discountPercentage': 20,
        'image': '',
      },
      'items': {
        'itemName': 'عطر',
        'itemNameEN': 'Perfume',
        'item_properties': [
          {
            'id': 20,
            'image': '',
            'price': 1000,
            'discountPercentage': 20,
            'isDefault': true,
          },
        ],
      },
    });

    expect(item.regularPrice, 1000);
    expect(item.price, 800);
    expect(item.subtotal, 1600);
    expect(item.hasDiscount, isTrue);
  });
}
