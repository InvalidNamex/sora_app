import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/order_master_model.dart';
import '../../routes/app_pages.dart';
import 'order_detail_controller.dart';
import '../auth/auth_controller.dart';

class OrderDetailView extends GetView<OrderDetailController> {
  const OrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${'order'.tr} #${controller.orderId}'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }

        if (controller.hasError.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text('error_loading'.tr),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchDetails,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        final master = controller.orderMaster.value;
        if (master == null) {
          return Center(child: Text('item_not_found'.tr));
        }

        final dateStr = DateFormat.yMMMd().add_Hm().format(master.createdAt);
        final statusColor = OrderMasterModel.statusColor(master.orderStatus);

        return RefreshIndicator(
          color: AppConstants.darkBeige,
          onRefresh: controller.fetchDetails,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Status & Date Header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'status'.tr,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            master.orderStatus,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'date'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Items list
              Text(
                'items'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.details.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final d = controller.details[index];
                    final existingReturn = controller.returnFor(d.id);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        d.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${d.quantity} × ${AppConstants.currency} ${d.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${AppConstants.currency} ${d.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppConstants.darkBeige,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (master.orderStatus == 'Delivered')
                            TextButton(
                              onPressed: existingReturn == null
                                  ? () => _showReturnDialog(
                                      context,
                                      d.id,
                                      d.itemName,
                                    )
                                  : null,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                existingReturn?.status ?? 'request_return'.tr,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Price Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('subtotal'.tr),
                        Text(
                          '${AppConstants.currency} ${(master.totalPrice + master.totalDiscount).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    if (master.totalDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'discount'.tr,
                            style: const TextStyle(color: Colors.green),
                          ),
                          Text(
                            '- ${AppConstants.currency} ${master.totalDiscount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'total'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${AppConstants.currency} ${master.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppConstants.darkBeige,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (master.orderStatus == 'Delivered') ...[
                FilledButton.icon(
                  onPressed: () async {
                    final saved = await Get.toNamed(
                      Routes.orderReviewPath(master.id),
                      arguments: master.id,
                    );
                    if (saved == true) {
                      await controller.fetchDetails();
                    }
                  },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(
                    controller.hasReview.value
                        ? 'edit_your_review'.tr
                        : 'rate_your_order'.tr,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Notes Section
              if (master.notes != null && master.notes!.isNotEmpty) ...[
                Text(
                  'notes'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    master.notes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showReturnDialog(
    BuildContext context,
    int detailId,
    String itemName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ReturnRequestDialog(
        controller: controller,
        detailId: detailId,
        itemName: itemName,
      ),
    );
    if (result == true && context.mounted) {
      Get.snackbar('return_submitted'.tr, 'return_submitted_message'.tr);
    }
  }
}

class _ReturnRequestDialog extends StatefulWidget {
  const _ReturnRequestDialog({
    required this.controller,
    required this.detailId,
    required this.itemName,
  });
  final OrderDetailController controller;
  final int detailId;
  final String itemName;
  @override
  State<_ReturnRequestDialog> createState() => _ReturnRequestDialogState();
}

class _ReturnRequestDialogState extends State<_ReturnRequestDialog> {
  late final TextEditingController name = TextEditingController(
    text: AuthController.to.currentUser.value?.name ?? '',
  );
  late final TextEditingController phone = TextEditingController(
    text: AuthController.to.currentUser.value?.phone ?? '',
  );
  final reason = TextEditingController();
  bool whatsapp = false;
  late bool confirmed =
      name.text.trim().isNotEmpty && phone.text.trim().isNotEmpty;
  late final bool hadExistingContact = confirmed;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('return_item'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${'return_for'.tr}: ${widget.itemName}'),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              readOnly: confirmed,
              decoration: InputDecoration(labelText: 'full_name'.tr),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phone,
              readOnly: confirmed,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'phone_number'.tr),
            ),
            if (hadExistingContact)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: confirmed,
                onChanged: (v) => setState(() => confirmed = v == true),
                title: Text('confirm_contact'.tr),
              ),
            const SizedBox(height: 4),
            Text('whatsapp_question'.tr),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              value: true,
              groupValue: whatsapp,
              onChanged: (v) => setState(() => whatsapp = v == true),
              title: Text('yes'.tr),
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              value: false,
              groupValue: whatsapp,
              onChanged: (v) => setState(() => whatsapp = v == true),
              title: Text('no'.tr),
            ),
            TextField(
              controller: reason,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'return_reason'.tr,
                hintText: 'return_reason_hint'.tr,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        FilledButton(onPressed: _submit, child: Text('submit_return'.tr)),
      ],
    );
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        (hadExistingContact && !confirmed) ||
        reason.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'return_required_fields'.tr);
      return;
    }
    await widget.controller.submitReturn(
      detailId: widget.detailId,
      name: name.text,
      phone: phone.text,
      whatsapp: whatsapp,
      reason: reason.text,
    );
    if (mounted) Navigator.pop(context, true);
  }
}
