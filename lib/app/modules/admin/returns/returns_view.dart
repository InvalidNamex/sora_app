import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/return_request_model.dart';
import '../../../core/utils/responsive.dart';
import 'returns_controller.dart';

class ReturnsView extends GetView<ReturnsController> {
  const ReturnsView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('return_requests'.tr),
      actions: [
        IconButton(
          onPressed: controller.fetch,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Obx(() {
      if (controller.isLoading.value)
        return const Center(
          child: CircularProgressIndicator(color: AppConstants.darkBeige),
        );
      if (controller.requests.isEmpty)
        return Center(child: Text('no_return_requests'.tr));
      return DesktopConstraint(
        child: RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.requests.length,
            itemBuilder: (_, index) =>
                _ReturnCard(request: controller.requests[index]),
          ),
        ),
      );
    }),
  );
}

class _ReturnCard extends GetView<ReturnsController> {
  const _ReturnCard({required this.request});
  final ReturnRequestModel request;
  @override
  Widget build(BuildContext context) {
    final age = request.deliveryAge;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${'order'.tr} #${request.orderId} · ${request.itemName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Obx(
                  () => DropdownButton<String>(
                    value: request.status,
                    items: ReturnsController.statuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: controller.updatingId.value == request.id
                        ? null
                        : (status) {
                            if (status != null && status != request.status)
                              controller.updateStatus(request, status);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${request.customerName} · ${request.customerPhone} · ${request.hasWhatsapp ? 'WhatsApp' : 'No WhatsApp'}',
            ),
            if (age != null)
              Text('${'delivered_for'.tr}: ${age.inDays} ${'days'.tr}'),
            const SizedBox(height: 6),
            Text('${'return_reason'.tr}: ${request.reason}'),
            if (request.adminNote?.isNotEmpty == true)
              Text('${'admin_note'.tr}: ${request.adminNote}'),
          ],
        ),
      ),
    );
  }
}
