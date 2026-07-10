import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import 'affiliate_controller.dart';

/// Affiliate dashboard — earnings summary, share link, payout request.
class AffiliateView extends GetView<AffiliateController> {
  const AffiliateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('affiliate_dashboard'.tr)),
      body: DesktopConstraint(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppConstants.darkBeige));
          }
          return RefreshIndicator(
            color: AppConstants.darkBeige,
            onRefresh: controller.fetchData,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _EarningsCard(controller: controller),
                const SizedBox(height: 20),
                _ShareLinkCard(controller: controller),
                const SizedBox(height: 20),
                _OrdersList(controller: controller),
                const SizedBox(height: 32),
                _PayoutButton(controller: controller),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Earnings summary card ─────────────────────────────────────────────────────

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.controller});
  final AffiliateController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.darkBeige, AppConstants.mediumBeige],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('total_earnings'.tr,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '${AppConstants.currency} ${controller.totalEarnings.value.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                  label: 'referred_orders'.tr,
                  value:
                      '${controller.referredOrders.length}'),
              const SizedBox(width: 24),
              _MiniStat(
                  label: 'pending_earnings'.tr,
                  value:
                      '${AppConstants.currency} ${controller.pendingEarnings.value.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }
}

// ── Share link card ───────────────────────────────────────────────────────────

class _ShareLinkCard extends StatelessWidget {
  const _ShareLinkCard({required this.controller});
  final AffiliateController controller;

  @override
  Widget build(BuildContext context) {
    final link = controller.affiliateLink;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('your_link'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(link,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                      backgroundColor: AppConstants.darkBeige),
                  icon: const Icon(Icons.copy, color: Colors.white),
                  tooltip: 'copy'.tr,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    Get.snackbar('copied'.tr, link,
                        snackPosition: SnackPosition.bottom,
                        duration: const Duration(seconds: 2));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orders list ───────────────────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.controller});
  final AffiliateController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.referredOrders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('referred_orders'.tr,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...controller.referredOrders.map((order) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long,
                    color: AppConstants.darkBeige),
                title: Text('#${order.id}'),
                subtitle: Text(DateFormat.yMMMd().format(order.createdAt)),
                trailing: Text(
                  '${AppConstants.currency} ${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppConstants.darkBeige,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )),
      ],
    );
  }
}

// ── Request payout button ─────────────────────────────────────────────────────

class _PayoutButton extends StatelessWidget {
  const _PayoutButton({required this.controller});
  final AffiliateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: controller.isSubmitting.value ||
                    controller.pendingEarnings.value <= 0
                ? null
                : () => _showPayoutDialog(context),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text('request_payout'.tr),
          ),
        ));
  }

  void _showPayoutDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'request_payout'.tr,
      middleText:
          '${'payout_amount'.tr}: ${AppConstants.currency} ${controller.pendingEarnings.value.toStringAsFixed(2)}',
      confirm: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          controller.requestPayout();
        },
        child: Text('confirm'.tr),
      ),
      cancel: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('cancel'.tr),
      ),
    );
  }
}
