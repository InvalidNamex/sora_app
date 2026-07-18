import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_snackbar.dart';
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
              child: CircularProgressIndicator(color: AppConstants.darkBeige),
            );
          }
          return RefreshIndicator(
            color: AppConstants.darkBeige,
            onRefresh: controller.fetchData,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _EarningsCard(controller: controller),
                const SizedBox(height: 20),
                _AffiliateCodeCard(controller: controller),
                const SizedBox(height: 20),
                _OrdersList(controller: controller),
                const SizedBox(height: 20),
                _PayoutHistory(controller: controller),
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
          Text(
            'total_earnings'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppConstants.currency} ${controller.totalEarnings.value.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _MiniStat(
                label: 'referred_orders'.tr,
                value: '${controller.referredOrders.length}',
              ),
              _MiniStat(
                label: 'pending_earnings'.tr,
                value:
                    '${AppConstants.currency} ${controller.pendingEarnings.value.toStringAsFixed(2)}',
              ),
              _MiniStat(
                label: 'available_balance'.tr,
                value:
                    '${AppConstants.currency} ${controller.availableBalance.value.toStringAsFixed(2)}',
              ),
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
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// ── Share link card ───────────────────────────────────────────────────────────

class _AffiliateCodeCard extends StatelessWidget {
  const _AffiliateCodeCard({required this.controller});
  final AffiliateController controller;

  @override
  Widget build(BuildContext context) {
    final link = controller.affiliateLink;
    final profile = controller.profile.value;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your_affiliate_code'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      helperText: 'affiliate_code_hint'.tr,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(
                  () => IconButton.filled(
                    tooltip: 'save'.tr,
                    onPressed: controller.isSavingCode.value
                        ? null
                        : controller.updateCode,
                    icon: controller.isSavingCode.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                  ),
                ),
              ],
            ),
            if (profile != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  Text(
                    '${'customer_discount'.tr}: '
                    '${profile.customerDiscountPercentage.toStringAsFixed(0)}%',
                  ),
                  Text(
                    '${'your_commission'.tr}: '
                    '${profile.affiliateCommissionPercentage.toStringAsFixed(0)}%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_outlined),
                    label: Text('copy_code'.tr),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.code));
                      AppSnackbar.show(
                        'copied'.tr,
                        profile.code,
                        type: AppSnackbarType.info,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: Text('share_code'.tr),
                    onPressed: () => controller.shareCode(context),
                  ),
                ],
              ),
            ],
            const Divider(height: 28),
            Text(
              'your_link'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      link,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppConstants.darkBeige,
                  ),
                  icon: const Icon(Icons.copy, color: Colors.white),
                  tooltip: 'copy'.tr,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    AppSnackbar.show(
                      'copied'.tr,
                      link,
                      type: AppSnackbarType.info,
                      duration: const Duration(seconds: 2),
                    );
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
        Text(
          'referred_orders'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...controller.referredOrders.map(
          (order) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long,
                color: AppConstants.darkBeige,
              ),
              title: Text('#${order.id}'),
              subtitle: Text(DateFormat.yMMMd().format(order.createdAt)),
              trailing: Text(
                '${AppConstants.currency} '
                '${order.affiliateCommissionAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppConstants.darkBeige,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Payout History ─────────────────────────────────────────────────────────────

class _PayoutHistory extends StatelessWidget {
  const _PayoutHistory({required this.controller});
  final AffiliateController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.payoutHistory.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payout_history'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...controller.payoutHistory.map(
          (req) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.history, color: AppConstants.darkBeige),
              title: Text(
                '${AppConstants.currency} ${req.amount.toStringAsFixed(2)}',
              ),
              subtitle: Text(DateFormat.yMMMd().format(req.createdAt)),
              trailing: Text(
                req.status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: req.status == 'Paid'
                      ? Colors.green
                      : req.status == 'Rejected'
                      ? Colors.redAccent
                      : Colors.orange,
                ),
              ),
            ),
          ),
        ),
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
    return Obx(
      () => SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed:
              controller.isSubmitting.value ||
                  controller.availableBalance.value <= 0
              ? null
              : () => showDialog<void>(
                  context: context,
                  builder: (_) => _PayoutDialog(controller: controller),
                ),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: Text('request_payout'.tr),
        ),
      ),
    );
  }
}

class _PayoutDialog extends StatelessWidget {
  const _PayoutDialog({required this.controller});

  final AffiliateController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('request_payout'.tr),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'payout_amount'.tr}: ${AppConstants.currency} '
              '${controller.availableBalance.value.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.payoutMethod.value,
                decoration: InputDecoration(
                  labelText: 'payout_method'.tr,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'mobile_wallet',
                    child: Text('mobile_wallet'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'instapay',
                    child: Text('instapay'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('bank_transfer'.tr),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) controller.payoutMethod.value = value;
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.payoutAccountCtrl,
              textDirection: ui.TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'payout_account'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () async {
            if (controller.payoutAccountCtrl.text.trim().length < 5) {
              AppSnackbar.show(
                'error'.tr,
                'payout_account_required'.tr,
                type: AppSnackbarType.error,
              );
              return;
            }
            Navigator.of(context).pop();
            await controller.requestPayout();
          },
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
