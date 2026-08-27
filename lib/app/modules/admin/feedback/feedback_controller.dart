import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/models/order_feedback_model.dart';
import '../../../core/services/order_feedback_service.dart';

class FeedbackController extends GetxController {
  final feedback = <OrderFeedbackModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final ratingFilter = 0.obs;

  List<OrderFeedbackModel> get filteredFeedback => ratingFilter.value == 0
      ? feedback
      : feedback
            .where((entry) => entry.deliveryRating == ratingFilter.value)
            .toList(growable: false);

  double get averageDeliveryRating {
    if (feedback.isEmpty) return 0;
    return feedback.fold<int>(0, (sum, item) => sum + item.deliveryRating) /
        feedback.length;
  }

  double get averageProductRating {
    final reviews = feedback.expand((entry) => entry.productReviews).toList();
    if (reviews.isEmpty) return 0;
    return reviews.fold<int>(0, (sum, item) => sum + item.productRating) /
        reviews.length;
  }

  @override
  void onReady() {
    super.onReady();
    fetchFeedback();
  }

  Future<void> fetchFeedback() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      feedback.value = await OrderFeedbackService.fetchForAdmin();
    } catch (error, stackTrace) {
      debugPrint('[FeedbackController] fetchFeedback error: $error');
      debugPrint('$stackTrace');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
