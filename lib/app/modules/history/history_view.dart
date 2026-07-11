import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/order_master_model.dart';
import '../../core/utils/responsive.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';
import '../navigation/nav_controller.dart';
import 'history_controller.dart';

/// Order history tab.
class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('history'.tr),
        leading: Responsive.isDesktop(context)
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    NavController.to.scaffoldKey.currentState?.openDrawer(),
              ),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        Widget child;

        if (!AuthController.to.isLoggedIn) {
          child = const _HistoryEmptyState(
            icon: Icons.lock_outline,
            message: 'login_to_see_orders',
          );
        } else if (controller.isLoading.value) {
          child = const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        } else if (controller.orders.isEmpty) {
          child = controller.hasError.value
              ? _HistoryErrorState(onRetry: controller.fetchOrders)
              : const _HistoryEmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'no_orders',
                );
        } else {
          child = ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: controller.orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _OrderCard(order: controller.orders[i]),
          );
        }

        return RefreshIndicator(
          color: AppConstants.darkBeige,
          onRefresh: controller.fetchOrders,
          child: child,
        );
      }),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: AppConstants.mediumBeige),
                const SizedBox(height: 16),
                Text(message.tr),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_outlined,
                    size: 56, color: AppConstants.mediumBeige),
                const SizedBox(height: 12),
                Text('error_loading'.tr),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderMasterModel order;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMd().format(order.createdAt);
    final statusColor = OrderMasterModel.statusColor(order.orderStatus);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed(Routes.orderDetail, arguments: order.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Order icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.lightBeige,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long,
                    color: AppConstants.darkBeige),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'order'.tr} #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${AppConstants.currency} ${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppConstants.darkBeige,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  order.orderStatus,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
