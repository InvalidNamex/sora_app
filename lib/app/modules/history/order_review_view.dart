import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/order_detail_model.dart';
import '../../core/utils/responsive.dart';
import 'order_review_controller.dart';

class OrderReviewView extends GetView<OrderReviewController> {
  const OrderReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('rate_order'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }
        if (controller.hasError.value) {
          return _LoadError(onRetry: controller.load);
        }
        if (!controller.canReview) {
          return _MessageState(
            icon: Icons.local_shipping_outlined,
            message: 'review_after_delivery'.tr,
          );
        }
        if (controller.details.isEmpty) {
          return _MessageState(
            icon: Icons.inventory_2_outlined,
            message: 'no_order_items'.tr,
          );
        }

        return DesktopConstraint(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${'order'.tr} #${controller.orderId}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                controller.isEditing.value
                    ? 'edit_review_hint'.tr
                    : 'review_intro'.tr,
              ),
              const SizedBox(height: 20),
              _ReviewCard(
                title: 'delivery_experience'.tr,
                icon: Icons.local_shipping_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('delivery_rating_question'.tr),
                    const SizedBox(height: 8),
                    _RatingSelector(
                      rating: controller.deliveryRating.value,
                      onChanged: controller.setDeliveryRating,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.deliveryCommentController,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: 'delivery_comment'.tr,
                        hintText: 'review_optional'.tr,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'rate_products'.tr,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...controller.details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProductReviewCard(
                    detail: detail,
                    rating: controller.productRatings[detail.id] ?? 0,
                    reviewController: controller.reviewControllers[detail.id]!,
                    onRatingChanged: (rating) =>
                        controller.setProductRating(detail.id, rating),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: controller.isSubmitting.value
                    ? null
                    : controller.submit,
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  controller.isEditing.value
                      ? 'update_review'.tr
                      : 'submit_review'.tr,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}

class _ProductReviewCard extends StatelessWidget {
  const _ProductReviewCard({
    required this.detail,
    required this.rating,
    required this.reviewController,
    required this.onRatingChanged,
  });

  final OrderDetailModel detail;
  final int rating;
  final TextEditingController reviewController;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      title: detail.itemName,
      icon: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RatingSelector(rating: rating, onChanged: onRatingChanged),
          const SizedBox(height: 12),
          TextField(
            controller: reviewController,
            minLines: 3,
            maxLines: 5,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: 'write_product_review'.tr,
              hintText: 'review_optional'.tr,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppConstants.darkBeige),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'rating_out_of_five'.trParams({'rating': '$rating'}),
      child: Wrap(
        spacing: 2,
        children: List.generate(5, (index) {
          final value = index + 1;
          return IconButton(
            tooltip: '$value / 5',
            onPressed: () => onChanged(value),
            color: AppConstants.darkBeige,
            iconSize: 34,
            icon: Icon(value <= rating ? Icons.star : Icons.star_border),
          );
        }),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => _MessageState(
    icon: Icons.error_outline,
    message: 'error_loading'.tr,
    action: ElevatedButton(onPressed: onRetry, child: Text('retry'.tr)),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppConstants.mediumBeige),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
