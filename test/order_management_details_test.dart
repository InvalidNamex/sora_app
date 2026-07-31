import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/core/models/order_detail_model.dart';
import 'package:sora/app/modules/admin/order_management/order_management_controller.dart';
import 'package:sora/app/modules/admin/order_management/order_management_view.dart';
import 'package:sora/app/translations/app_translations.dart';

class _OrderDetailsTestController extends OrderManagementController {
  @override
  void onReady() {}

  @override
  Future<void> fetchOrderDetails(int orderId, {bool force = false}) async {
    if (loadingOrderIds.contains(orderId)) return;
    loadingOrderIds.add(orderId);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    orderDetails[orderId] = orderId == 1
        ? const [
            OrderDetailModel(
              id: 10,
              orderMasterId: 1,
              itemPropertyId: 100,
              itemName: 'Test perfume',
              quantity: 2,
              price: 125,
            ),
          ]
        : const [];
    loadingOrderIds.remove(orderId);
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('expanded orders replace the loader with their own details', (
    tester,
  ) async {
    final controller = Get.put<OrderManagementController>(
      _OrderDetailsTestController(),
    );
    controller.isLoading.value = false;
    controller.orders.assignAll([
      OrderWithUser(
        id: 1,
        userName: 'Customer',
        userPhone: '01000000000',
        totalPrice: 250,
        totalDiscount: 0,
        address: 'Cairo',
        checkoutPhone: '01000000000',
        orderStatus: 'Pending',
        createdAt: DateTime(2026, 7, 26),
      ),
    ]);
    controller.filteredOrders.assignAll(controller.orders);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const OrderManagementView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExpansionTile), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Test perfume'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an order with no details shows an empty state, not a spinner', (
    tester,
  ) async {
    final controller = Get.put<OrderManagementController>(
      _OrderDetailsTestController(),
    );
    controller.isLoading.value = false;
    controller.orders.assignAll([
      OrderWithUser(
        id: 2,
        userName: 'Customer',
        userPhone: '01000000000',
        totalPrice: 0,
        totalDiscount: 0,
        address: '',
        checkoutPhone: '',
        orderStatus: 'Pending',
        createdAt: DateTime(2026, 7, 26),
      ),
    ]);
    controller.filteredOrders.assignAll(controller.orders);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const OrderManagementView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExpansionTile), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.text('No items were found in this order'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
