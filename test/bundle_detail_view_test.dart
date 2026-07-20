import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/core/models/bundle_deal_model.dart';
import 'package:sora/app/core/models/item_property_model.dart';
import 'package:sora/app/modules/bundle_detail/bundle_detail_controller.dart';
import 'package:sora/app/modules/bundle_detail/bundle_detail_view.dart';
import 'package:sora/app/modules/cart/cart_controller.dart';
import 'package:sora/app/routes/app_pages.dart';
import 'package:sora/app/translations/app_translations.dart';

class _FakeCartController extends CartController {
  @override
  // The real lifecycle requires Firebase auth; this fake only stores bundles.
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> addBundle(BundleDealModel bundle, int quantity) async {
    bundleItems.add(
      BundleCartItemModel(cartId: 0, bundle: bundle, quantity: quantity),
    );
  }
}

class _TestBundleDetailController extends BundleDetailController {
  @override
  Future<void> loadBundle() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('bundle page shows fixed recipe and deal pricing', (
    tester,
  ) async {
    final bundle = BundleDealModel(
      id: 1,
      title: 'باقة العناية',
      titleEn: 'Care Bundle',
      bannerImage: '',
      dealPrice: 250,
      items: const [
        BundleDealItemModel(
          id: 1,
          bundleId: 1,
          property: ItemPropertyModel(
            id: 2,
            itemId: 3,
            sizeMl: 100,
            image: '',
            price: 150,
          ),
          quantity: 2,
          itemName: 'منتج',
          itemNameEn: 'Product',
        ),
      ],
    );
    Get.put<CartController>(_FakeCartController());
    final controller = Get.put<BundleDetailController>(
      _TestBundleDetailController(),
    );
    controller.bundle.value = bundle;
    controller.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const BundleDetailView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Care Bundle'), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('× 2'), findsOneWidget);
    expect(find.text('EGP 300.00'), findsOneWidget);
    expect(find.text('EGP 250.00'), findsWidgets);
    expect(find.text('Save EGP 50.00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('bundle cart action changes to checkout without a snackbar', (
    tester,
  ) async {
    Get.testMode = false;
    const bundle = BundleDealModel(
      id: 9,
      title: 'باقة',
      titleEn: 'Bundle',
      bannerImage: '',
      dealPrice: 100,
      items: [
        BundleDealItemModel(
          id: 1,
          bundleId: 9,
          property: ItemPropertyModel(
            id: 2,
            itemId: 3,
            sizeMl: 100,
            image: '',
            price: 120,
          ),
          quantity: 1,
          itemName: 'منتج',
          itemNameEn: 'Product',
        ),
      ],
    );
    Get.put<CartController>(_FakeCartController());
    final controller = Get.put<BundleDetailController>(
      _TestBundleDetailController(),
    );
    controller.bundle.value = bundle;
    controller.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const BundleDetailView()),
          GetPage(
            name: Routes.checkout,
            page: () => const Scaffold(body: Text('Checkout destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add bundle to cart'), findsOneWidget);
    await tester.tap(find.text('Add bundle to cart'));
    await tester.pumpAndSettle();

    expect(find.text('Bundle added to cart'), findsNothing);
    expect(find.text('Proceed to Checkout'), findsOneWidget);

    await tester.tap(find.text('Proceed to Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Checkout destination'), findsOneWidget);
  });
}
