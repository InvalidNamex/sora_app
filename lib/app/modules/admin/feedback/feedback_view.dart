import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/order_feedback_model.dart';
import '../../../core/utils/responsive.dart';
import 'feedback_controller.dart';

class FeedbackView extends GetView<FeedbackController> {
  const FeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('customer_feedback'.tr),
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            onPressed: controller.fetchFeedback,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: DesktopConstraint(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppConstants.darkBeige),
            );
          }
          if (controller.hasError.value) {
            return _FeedbackState(
              icon: Icons.error_outline,
              message: 'feedback_load_failed'.tr,
              onRefresh: controller.fetchFeedback,
            );
          }
          if (controller.feedback.isEmpty) {
            return _FeedbackState(
              icon: Icons.rate_review_outlined,
              message: 'no_feedback'.tr,
              onRefresh: controller.fetchFeedback,
            );
          }

          final entries = controller.filteredFeedback;
          return RefreshIndicator(
            color: AppConstants.darkBeige,
            onRefresh: controller.fetchFeedback,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'delivery_rating'.tr,
                        value: controller.averageDeliveryRating,
                        icon: Icons.local_shipping_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'product_rating'.tr,
                        value: controller.averageProductRating,
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: controller.ratingFilter.value,
                  decoration: InputDecoration(
                    labelText: 'filter_delivery_rating'.tr,
                    prefixIcon: const Icon(Icons.filter_list),
                  ),
                  items: [
                    DropdownMenuItem(value: 0, child: Text('all'.tr)),
                    ...List.generate(
                      5,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1} / 5'),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      controller.ratingFilter.value = value ?? 0,
                ),
                const SizedBox(height: 14),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('no_matching_feedback'.tr)),
                  )
                else
                  ...entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FeedbackCard(feedback: entry),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: AppConstants.darkBeige),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.darkBeige,
            ),
          ),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});
  final OrderFeedbackModel feedback;

  @override
  Widget build(BuildContext context) {
    final contact = [
      feedback.customerName,
      feedback.customerPhone,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.lightBeige,
          child: Text(
            '${feedback.deliveryRating}',
            style: const TextStyle(
              color: AppConstants.darkBeige,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${'order'.tr} #${feedback.orderId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            if (contact.isNotEmpty) contact,
            DateFormat.yMMMd().add_jm().format(feedback.createdAt.toLocal()),
          ].join('\n'),
        ),
        trailing: _Stars(rating: feedback.deliveryRating),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            'delivery_experience'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _Stars(rating: feedback.deliveryRating),
          if (feedback.deliveryComment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(feedback.deliveryComment),
          ],
          const SizedBox(height: 16),
          Text(
            'product_reviews'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (feedback.productReviews.isEmpty)
            Text('no_product_reviews'.tr)
          else
            ...feedback.productReviews.map(
              (review) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(review.itemName),
                subtitle: review.reviewText.isEmpty
                    ? null
                    : Text(review.reviewText),
                trailing: _Stars(rating: review.productRating),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (index) => Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: AppConstants.darkBeige,
        size: 17,
      ),
    ),
  );
}

class _FeedbackState extends StatelessWidget {
  const _FeedbackState({
    required this.icon,
    required this.message,
    required this.onRefresh,
  });
  final IconData icon;
  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: AppConstants.mediumBeige),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
      ],
    ),
  );
}
