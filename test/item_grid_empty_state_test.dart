import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/modules/home/home_controller.dart';
import 'package:sora/app/modules/home/widgets/item_grid.dart';
import 'package:sora/app/translations/app_translations.dart';

class _EmptyHomeController extends HomeController {
  @override
  void onReady() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  Future<void> pumpEmptyGrid(WidgetTester tester, Locale locale) async {
    final controller = Get.put<HomeController>(_EmptyHomeController());
    controller.isLoadingItems.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: locale,
        home: const Scaffold(body: ItemGrid()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows translated English coming soon state', (tester) async {
    await pumpEmptyGrid(tester, const Locale('en'));
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('shows translated Arabic coming soon state', (tester) async {
    await pumpEmptyGrid(tester, const Locale('ar'));
    expect(find.text('قريباً'), findsOneWidget);
  });
}
