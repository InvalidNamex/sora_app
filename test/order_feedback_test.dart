import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/core/models/order_detail_model.dart';
import 'package:sora/app/core/models/order_feedback_model.dart';
import 'package:sora/app/core/models/order_master_model.dart';
import 'package:sora/app/modules/admin/feedback/feedback_controller.dart';
import 'package:sora/app/modules/admin/feedback/feedback_view.dart';
import 'package:sora/app/modules/history/order_review_controller.dart';
import 'package:sora/app/modules/history/order_review_view.dart';
import 'package:sora/app/translations/app_translations.dart';

class _ReviewTestController extends OrderReviewController {
  @override
  void onInit() {
    super.onInit();
    orderId = 42;
    order.value = OrderMasterModel(
      id: 42,
      userId: 7,
      addressId: 3,
      totalPrice: 250,
      totalDiscount: 0,
      orderStatus: 'Delivered',
      createdAt: DateTime(2026, 8, 14),
    );
    details.assignAll([
      const OrderDetailModel(
        id: 10,
        orderMasterId: 42,
        itemPropertyId: 100,
        itemName: 'Amber perfume',
        quantity: 1,
        price: 250,
      ),
    ]);
    reviewControllers[10] = TextEditingController();
    isLoading.value = false;
  }

  @override
  void onReady() {}
}

class _FeedbackTestController extends FeedbackController {
  @override
  void onReady() {}
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('feedback models parse ratings and optional review text safely', () {
    final review = ProductReviewModel.fromJson({
      'id': 4,
      'order_id': 42,
      'order_detail_id': 10,
      'item_property_id': 100,
      'product_rating': 5,
      'review_text': 'Excellent',
      'created_at': '2026-08-14T12:00:00Z',
    }, itemName: 'Amber perfume');
    final feedback = OrderFeedbackModel.fromJson(
      {
        'id': 2,
        'order_id': 42,
        'user_id': 7,
        'delivery_rating': 4,
        'delivery_comment': 'On time',
        'created_at': '2026-08-14T12:00:00Z',
      },
      productReviews: [review],
    );

    expect(feedback.deliveryRating, 4);
    expect(feedback.productReviews.single.productRating, 5);
    expect(feedback.productReviews.single.itemName, 'Amber perfume');
  });

  testWidgets('delivered order presents delivery and product rating controls', (
    tester,
  ) async {
    final controller = Get.put<OrderReviewController>(_ReviewTestController());
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const OrderReviewView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery Experience'), findsOneWidget);
    expect(find.text('Amber perfume'), findsOneWidget);

    await tester.tap(find.byTooltip('1 / 5').first);
    await tester.pump();
    expect(controller.deliveryRating.value, 1);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Submit Review'), findsOneWidget);
  });

  testWidgets('admin feedback section shows collected comments and averages', (
    tester,
  ) async {
    final controller = Get.put<FeedbackController>(_FeedbackTestController());
    controller.feedback.assign(
      OrderFeedbackModel(
        id: 2,
        orderId: 42,
        userId: 7,
        deliveryRating: 4,
        deliveryComment: 'On time',
        customerName: 'Customer',
        createdAt: DateTime(2026, 8, 14),
        productReviews: [
          ProductReviewModel(
            id: 4,
            orderId: 42,
            orderDetailId: 10,
            itemPropertyId: 100,
            productRating: 5,
            reviewText: 'Excellent',
            itemName: 'Amber perfume',
            createdAt: DateTime(2026, 8, 14),
          ),
        ],
      ),
    );
    controller.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const FeedbackView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4.0'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('Order #42'), findsOneWidget);

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.text('On time'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
  });
}
