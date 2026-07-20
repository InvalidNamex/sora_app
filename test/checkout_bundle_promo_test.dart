import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/core/models/bundle_deal_model.dart';
import 'package:sora/app/core/models/item_property_model.dart';
import 'package:sora/app/modules/cart/cart_controller.dart';
import 'package:sora/app/modules/checkout/checkout_controller.dart';

class _FakeCartController extends CartController {
  @override
  // This fake avoids the production auth/storage lifecycle.
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  test(
    'promo codes are rejected and cleared when a bundle is in the cart',
    () async {
      final cart = Get.put<CartController>(_FakeCartController());
      cart.bundleItems.add(
        BundleCartItemModel(
          cartId: 0,
          quantity: 1,
          bundle: const BundleDealModel(
            id: 4,
            title: 'باقة',
            bannerImage: '',
            dealPrice: 100,
            items: [
              BundleDealItemModel(
                id: 8,
                bundleId: 4,
                property: ItemPropertyModel(
                  id: 3,
                  itemId: 2,
                  sizeMl: 50,
                  image: '',
                  price: 120,
                ),
                quantity: 1,
                itemName: 'منتج',
              ),
            ],
          ),
        ),
      );
      final checkout = CheckoutController();
      checkout.promoCtrl.text = 'SAVE20';
      checkout.discount.value = 20;

      final applied = await checkout.applyPromo(showFeedback: false);

      expect(applied, isFalse);
      expect(checkout.hasBundleDeal, isTrue);
      expect(checkout.promoCtrl.text, isEmpty);
      expect(checkout.appliedPromo.value, isNull);
      expect(checkout.discount.value, 0);

      checkout.onClose();
    },
  );
}
