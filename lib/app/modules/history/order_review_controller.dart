import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/models/order_detail_model.dart';
import '../../core/models/order_feedback_model.dart';
import '../../core/models/order_master_model.dart';
import '../../core/services/order_feedback_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';

class OrderReviewController extends GetxController {
  int orderId = 0;
  final order = Rxn<OrderMasterModel>();
  final details = <OrderDetailModel>[].obs;
  final deliveryRating = 0.obs;
  final productRatings = <int, int>{}.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final hasError = false.obs;
  final isEditing = false.obs;
  final deliveryCommentController = TextEditingController();
  final Map<int, TextEditingController> reviewControllers = {};

  @override
  void onInit() {
    super.onInit();
    final rawOrderId = Get.arguments ?? Get.parameters['id'];
    orderId = rawOrderId is int ? rawOrderId : int.tryParse('$rawOrderId') ?? 0;
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  @override
  void onClose() {
    deliveryCommentController.dispose();
    for (final controller in reviewControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  bool get canReview => order.value?.orderStatus == 'Delivered';

  Future<void> load() async {
    if (orderId == 0) {
      isLoading.value = false;
      hasError.value = true;
      return;
    }
    isLoading.value = true;
    hasError.value = false;
    try {
      final responses = await Future.wait<Object?>([
        SupabaseService.client
            .from('order_master')
            .select()
            .eq('id', orderId)
            .single(),
        SupabaseService.client
            .from('order_detail')
            .select()
            .eq('orderMasterID', orderId)
            .order('id'),
        OrderFeedbackService.fetchForOrder(orderId),
      ]);
      order.value = OrderMasterModel.fromJson(
        Map<String, dynamic>.from(responses[0] as Map),
      );
      details.value = (responses[1] as List)
          .map(
            (row) => OrderDetailModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);

      for (final controller in reviewControllers.values) {
        controller.dispose();
      }
      reviewControllers.clear();
      productRatings.clear();
      deliveryRating.value = 0;
      deliveryCommentController.clear();
      isEditing.value = false;
      for (final detail in details) {
        reviewControllers[detail.id] = TextEditingController();
      }

      final existing = responses[2] as OrderFeedbackModel?;
      if (existing != null) {
        isEditing.value = true;
        deliveryRating.value = existing.deliveryRating;
        deliveryCommentController.text = existing.deliveryComment;
        for (final review in existing.productReviews) {
          productRatings[review.orderDetailId] = review.productRating;
          reviewControllers[review.orderDetailId]?.text = review.reviewText;
        }
      }
    } catch (error, stackTrace) {
      debugPrint('[OrderReviewController] load error: $error');
      debugPrint('$stackTrace');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void setDeliveryRating(int rating) => deliveryRating.value = rating;

  void setProductRating(int orderDetailId, int rating) {
    productRatings[orderDetailId] = rating;
  }

  Future<void> submit() async {
    if (deliveryRating.value == 0) {
      AppSnackbar.show(
        'rating_required'.tr,
        'delivery_rating_required'.tr,
        type: AppSnackbarType.warning,
      );
      return;
    }
    final missingProduct = details.any(
      (detail) => (productRatings[detail.id] ?? 0) == 0,
    );
    if (missingProduct) {
      AppSnackbar.show(
        'rating_required'.tr,
        'product_rating_required'.tr,
        type: AppSnackbarType.warning,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      await OrderFeedbackService.submit(
        orderId: orderId,
        deliveryRating: deliveryRating.value,
        deliveryComment: deliveryCommentController.text,
        productReviews: details
            .map(
              (detail) => ProductReviewSubmission(
                orderDetailId: detail.id,
                rating: productRatings[detail.id]!,
                review: reviewControllers[detail.id]?.text ?? '',
              ),
            )
            .toList(growable: false),
      );
      isEditing.value = true;
      AppSnackbar.show(
        'thank_you'.tr,
        'review_saved'.tr,
        type: AppSnackbarType.success,
      );
      Get.back(result: true);
    } catch (error, stackTrace) {
      debugPrint('[OrderReviewController] submit error: $error');
      debugPrint('$stackTrace');
      AppSnackbar.show(
        'error'.tr,
        'review_save_failed'.tr,
        type: AppSnackbarType.error,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
