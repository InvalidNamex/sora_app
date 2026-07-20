import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/core/models/item_model.dart';
import 'package:sora/app/core/models/item_property_model.dart';
import 'package:sora/app/modules/admin/bundle_management/bundle_management_controller.dart';
import 'package:sora/app/modules/admin/bundle_management/bundle_management_view.dart';
import 'package:sora/app/translations/app_translations.dart';

class _TestBundleManagementController extends BundleManagementController {
  @override
  void onReady() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('admin can open and select a bundle item property', (
    tester,
  ) async {
    final controller = Get.put<BundleManagementController>(
      _TestBundleManagementController(),
    );
    controller.isLoading.value = false;
    controller.items.assignAll([
      const ItemModel(
        id: 1,
        categoryId: 1,
        subCategoryId: 1,
        itemName: 'خمره قهوة',
        itemNameEn: 'Khamrah Qahwa',
        itemDescription: '',
      ),
    ]);
    controller.properties.assignAll([
      const ItemPropertyModel(
        id: 5,
        itemId: 1,
        sizeMl: 10,
        image: '',
        price: 60,
      ),
    ]);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const BundleManagementView(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Bundle').last);
    await tester.pumpAndSettle();

    final dropdown = find.byType(DropdownButtonFormField<int>);
    expect(dropdown, findsOneWidget);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    expect(find.textContaining('Khamrah Qahwa'), findsWidgets);
    await tester.tap(find.textContaining('Khamrah Qahwa').last);
    await tester.pumpAndSettle();

    expect(controller.selectedPropertyId.value, 5);
    await tester.tap(find.byTooltip('Add item to bundle'));
    await tester.pumpAndSettle();

    expect(controller.draftQuantities, {5: 1});
    expect(controller.selectedPropertyId.value, isNull);
  });
}
