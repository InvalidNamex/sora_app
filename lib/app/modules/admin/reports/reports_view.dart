import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import 'reports_controller.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('reports'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchReports,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }
        return DesktopConstraint(
          child: RefreshIndicator(
            color: AppConstants.darkBeige,
            onRefresh: controller.fetchReports,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _RevenueCard(controller: controller),
                const SizedBox(height: 24),
                _OrderStatusBreakdown(controller: controller),
                const SizedBox(height: 24),
                _RecentPayouts(controller: controller),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.controller});
  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.darkBeige.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.darkBeige.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('total_revenue'.tr,
              style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.darkBeige.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${AppConstants.currency} ${controller.totalRevenue.value.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkBeige),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusBreakdown extends StatelessWidget {
  const _OrderStatusBreakdown({required this.controller});
  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> statuses = controller.ordersByStatus;
    if (statuses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('order_status_breakdown'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: AppConstants.darkBeige)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: statuses.entries.map((e) {
            return Container(
              width: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('${e.value}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RecentPayouts extends StatelessWidget {
  const _RecentPayouts({required this.controller});
  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.recentPayouts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('recent_payouts'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: AppConstants.darkBeige)),
        const SizedBox(height: 12),
        ...controller.recentPayouts.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet,
                    color: AppConstants.darkBeige),
                title: Text(p.affiliateName.isNotEmpty ? p.affiliateName : 'Affiliate #${p.affiliateId}'),
                subtitle: Text(
                    '${DateFormat.yMMMd().format(p.createdAt)} - ${p.status}'),
                trailing: Text(
                  '${AppConstants.currency} ${p.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )),
      ],
    );
  }
}
