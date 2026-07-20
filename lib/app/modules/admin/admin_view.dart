import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../routes/app_pages.dart';
import 'admin_controller.dart';

/// Admin Dashboard — overview metrics, navigation to sub-screens.
class AdminView extends GetView<AdminController> {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin_dashboard'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchMetrics,
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
            onRefresh: controller.fetchMetrics,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'overview'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Metrics row — wraps to column on narrow screens
                LayoutBuilder(
                  builder: (_, constraints) {
                    final isWide = constraints.maxWidth > 520;
                    final tiles = [
                      _MetricTile(
                        icon: Icons.receipt_long,
                        label: 'total_orders'.tr,
                        value: controller.totalOrders.value,
                      ),
                      _MetricTile(
                        icon: Icons.pending_actions,
                        label: 'pending_orders'.tr,
                        value: controller.pendingOrders.value,
                        highlight: controller.pendingOrders.value > 0,
                      ),
                      _MetricTile(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'pending_payouts'.tr,
                        value: controller.pendingPayouts.value,
                        highlight: controller.pendingPayouts.value > 0,
                      ),
                    ];
                    if (isWide) {
                      return Row(
                        children: tiles
                            .map(
                              (t) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: t,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Row(
                      children: tiles
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.all(3),
                              child: t,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'management'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _NavTile(
                  icon: Icons.list_alt,
                  title: 'order_management'.tr,
                  onTap: () => Get.toNamed(Routes.adminOrders),
                ),
                const SizedBox(height: 10),
                _NavTile(
                  icon: Icons.people_alt_outlined,
                  title: 'affiliate_management'.tr,
                  onTap: () => Get.toNamed(Routes.adminAffiliates),
                ),
                const SizedBox(height: 10),
                _NavTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'catalog_management'.tr,
                  onTap: () => Get.toNamed(Routes.adminCatalog),
                ),
                const SizedBox(height: 10),
                _NavTile(
                  icon: Icons.all_inbox_outlined,
                  title: 'bundle_management'.tr,
                  onTap: () => Get.toNamed(Routes.adminBundles),
                ),
                const SizedBox(height: 10),
                _NavTile(
                  icon: Icons.bar_chart,
                  title: 'reports'.tr,
                  onTap: () => Get.toNamed(Routes.adminReports),
                ),
                const SizedBox(height: 10),
                _NavTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications Center',
                  onTap: () => Get.toNamed(Routes.adminNotifications),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.orange.shade700 : AppConstants.darkBeige;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: AppConstants.darkBeige),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppConstants.mediumBeige,
      ),
      onTap: onTap,
    );
  }
}
