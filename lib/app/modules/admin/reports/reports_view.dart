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
            tooltip: 'refresh'.tr,
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
                _ReportKpis(controller: controller),
                const SizedBox(height: 24),
                _DailyOrders(controller: controller),
                const SizedBox(height: 24),
                _OrderStatusBreakdown(controller: controller),
                const SizedBox(height: 24),
                _AffiliatePerformance(controller: controller),
                const SizedBox(height: 24),
                _CommissionBreakdown(controller: controller),
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

class _ReportKpis extends StatelessWidget {
  const _ReportKpis({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'net_revenue'.tr,
        _money(controller.totalRevenue.value),
        Icons.payments_outlined,
      ),
      (
        'gross_sales'.tr,
        _money(controller.grossSales.value),
        Icons.trending_up,
      ),
      (
        'total_orders'.tr,
        '${controller.totalOrders.value}',
        Icons.receipt_long_outlined,
      ),
      (
        'average_order_value'.tr,
        _money(controller.averageOrderValue.value),
        Icons.analytics_outlined,
      ),
      (
        'total_discounts'.tr,
        _money(controller.totalDiscounts.value),
        Icons.sell_outlined,
      ),
      (
        'affiliate_revenue'.tr,
        _money(controller.affiliateRevenue.value),
        Icons.groups_outlined,
      ),
      (
        'promo_orders'.tr,
        '${controller.promoOrders.value}',
        Icons.local_offer_outlined,
      ),
      (
        'paid_payouts'.tr,
        _money(controller.paidPayouts.value),
        Icons.account_balance_wallet_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _KpiCard(label: card.$1, value: card.$2, icon: card.$3),
              ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.darkBeige, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyOrders extends StatelessWidget {
  const _DailyOrders({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final days = controller.ordersByDay;
    if (days.isEmpty) return const SizedBox.shrink();
    final maxOrders = days.fold<int>(
      1,
      (maximum, day) => day.orders > maximum ? day.orders : maximum,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('orders_last_14_days'.tr),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in days)
                Expanded(
                  child: Tooltip(
                    message:
                        '${DateFormat.MMMd().format(day.date)}\n'
                        '${day.orders} ${'orders'.tr}\n${_money(day.revenue)}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${day.orders}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 130 * day.orders / maxOrders,
                            constraints: const BoxConstraints(minHeight: 3),
                            decoration: const BoxDecoration(
                              color: AppConstants.darkBeige,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('d').format(day.date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderStatusBreakdown extends StatelessWidget {
  const _OrderStatusBreakdown({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final statuses = controller.ordersByStatus;
    if (statuses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('order_status_breakdown'.tr),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in statuses.entries)
              _InlineStat(label: entry.key, value: '${entry.value}'),
          ],
        ),
      ],
    );
  }
}

class _AffiliatePerformance extends StatelessWidget {
  const _AffiliatePerformance({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    final sources = controller.affiliateSources;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('affiliate_performance'.tr),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InlineStat(
              label: 'affiliate_orders'.tr,
              value: '${controller.affiliateOrders.value}',
            ),
            _InlineStat(
              label: 'link_attributions'.tr,
              value: '${sources['link'] ?? 0}',
            ),
            _InlineStat(
              label: 'manual_codes'.tr,
              value: '${sources['manual'] ?? 0}',
            ),
            _InlineStat(
              label: 'promo_discounts'.tr,
              value: _money(controller.promoDiscounts.value),
            ),
          ],
        ),
        if (controller.topAffiliates.isNotEmpty) ...[
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (var i = 0; i < controller.topAffiliates.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _AffiliateRow(
                    rank: i + 1,
                    affiliate: controller.topAffiliates[i],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AffiliateRow extends StatelessWidget {
  const _AffiliateRow({required this.rank, required this.affiliate});

  final int rank;
  final TopAffiliateReport affiliate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppConstants.darkBeige.withValues(alpha: 0.15),
        foregroundColor: AppConstants.darkBeige,
        child: Text('$rank'),
      ),
      title: Text(affiliate.name.isEmpty ? affiliate.code : affiliate.name),
      subtitle: Text('${affiliate.code} · ${affiliate.orders} ${'orders'.tr}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _money(affiliate.revenue),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${'commission'.tr}: ${_money(affiliate.commission)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CommissionBreakdown extends StatelessWidget {
  const _CommissionBreakdown({required this.controller});

  final ReportsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('commission_liability'.tr),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InlineStat(
              label: 'total_commission'.tr,
              value: _money(controller.commissionTotal.value),
            ),
            _InlineStat(
              label: 'pending_earnings'.tr,
              value: _money(controller.commissionPending.value),
            ),
            _InlineStat(
              label: 'available_balance'.tr,
              value: _money(controller.commissionAvailable.value),
            ),
            _InlineStat(
              label: 'processing'.tr,
              value: _money(controller.commissionProcessing.value),
            ),
            _InlineStat(
              label: 'paid_commission'.tr,
              value: _money(controller.commissionPaid.value),
            ),
            _InlineStat(
              label: 'pending_payouts'.tr,
              value: '${controller.pendingPayoutCount.value}',
            ),
          ],
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
        _SectionTitle('recent_payouts'.tr),
        const SizedBox(height: 12),
        for (final payout in controller.recentPayouts)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: AppConstants.darkBeige,
              ),
              title: Text(
                payout.affiliateName.isNotEmpty
                    ? payout.affiliateName
                    : '${'affiliate'.tr} #${payout.affiliateId}',
              ),
              subtitle: Text(
                '${DateFormat.yMMMd().format(payout.createdAt)} · '
                '${payout.status}',
              ),
              trailing: Text(
                _money(payout.amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppConstants.darkBeige,
      ),
    );
  }
}

String _money(double value) =>
    '${AppConstants.currency} ${value.toStringAsFixed(2)}';
