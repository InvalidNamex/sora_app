import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/order_master_model.dart';
import '../../../core/utils/responsive.dart';
import 'order_management_controller.dart';

/// Order management screen — view all orders, update status.
class OrderManagementView extends GetView<OrderManagementController> {
  const OrderManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('order_management'.tr),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.fetchOrders),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppConstants.darkBeige));
              }
              if (controller.filteredOrders.isEmpty) {
                return Center(child: Text('no_orders'.tr));
              }
              return DesktopConstraint(
                child: RefreshIndicator(
                  color: AppConstants.darkBeige,
                  onRefresh: controller.fetchOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.filteredOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _OrderRow(
                        order: controller.filteredOrders[i],
                        controller: controller),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final OrderManagementController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Obx(() => ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: OrderManagementController.statuses
                .map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s == 'all' ? 'all'.tr : s),
                        selected: controller.selectedFilter.value == s,
                        onSelected: (_) =>
                            controller.selectedFilter.value = s,
                        selectedColor: AppConstants.darkBeige,
                        labelStyle: TextStyle(
                          color: controller.selectedFilter.value == s
                              ? Colors.white
                              : null,
                        ),
                        showCheckmark: false,
                      ),
                    ))
                .toList(),
          )),
    );
  }
}

// ── Order row ─────────────────────────────────────────────────────────────────

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.controller});
  final OrderWithUser order;
  final OrderManagementController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final updating = controller.updatingOrderId.value == order.id;
      final statusColor = OrderMasterModel.statusColor(order.orderStatus);

      return Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: updating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.receipt_long),
            ),
          ),
          title: Text(
            '#${order.id} – ${order.userName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${order.formattedDate}  •  ${order.userPhone}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: _StatusDropdown(order: order, controller: controller),
          children: [
            FutureBuilder(
              future: controller.fetchOrderDetails(order.id),
              builder: (context, snapshot) => Obx(() {
                final details = controller.details
                    .where((d) => d.orderMasterId == order.id)
                    .toList();
                if (details.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                        child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))),
                  );
                }
                return Column(
                  children: details
                      .map((d) => ListTile(
                            dense: true,
                            title: Text(d.itemName),
                            trailing: Text(
                              '${d.quantity} × ${AppConstants.currency} ${d.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppConstants.darkBeige),
                            ),
                          ))
                      .toList(),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.order, required this.controller});
  final OrderWithUser order;
  final OrderManagementController controller;

  static const _statuses = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => DropdownButton<String>(
          value: order.orderStatus,
          underline: const SizedBox.shrink(),
          items: _statuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: controller.updatingOrderId.value != null
              ? null
              : (newStatus) {
                  if (newStatus != null &&
                      newStatus != order.orderStatus) {
                    controller.updateStatus(order, newStatus);
                  }
                },
        ));
  }
}
