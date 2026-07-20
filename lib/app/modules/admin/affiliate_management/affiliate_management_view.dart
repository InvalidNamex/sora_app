import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/affiliate_program_models.dart';
import '../../../core/models/payout_request_model.dart';
import '../../../core/utils/responsive.dart';
import 'affiliate_management_controller.dart';

/// Affiliate management: applications, payouts, and manual user controls.
class AffiliateManagementView extends GetView<AffiliateManagementController> {
  const AffiliateManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('affiliate_management'.tr),
          bottom: TabBar(
            labelColor: AppConstants.darkBeige,
            indicatorColor: AppConstants.darkBeige,
            tabs: [
              Tab(text: 'applications'.tr),
              Tab(text: 'payouts'.tr),
              Tab(text: 'users'.tr),
            ],
          ),
        ),
        body: DesktopConstraint(
          child: TabBarView(
            children: [
              _ApplicationsTab(controller: controller),
              _PayoutsTab(controller: controller),
              _UsersTab(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationsTab extends StatelessWidget {
  const _ApplicationsTab({required this.controller});

  final AffiliateManagementController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loadingApplications.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppConstants.darkBeige),
        );
      }
      if (controller.pendingApplications.isEmpty) {
        return Center(child: Text('no_pending_applications'.tr));
      }
      return RefreshIndicator(
        color: AppConstants.darkBeige,
        onRefresh: controller.fetchQueues,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pendingApplications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final application = controller.pendingApplications[index];
            final isReviewing = controller.reviewingId.value == application.id;
            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            application.userName.isEmpty
                                ? application.userPhone
                                : application.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          application.preferredCode,
                          textDirection: ui.TextDirection.ltr,
                          style: const TextStyle(
                            color: AppConstants.darkBeige,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (application.userPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(application.userPhone),
                    ],
                    const SizedBox(height: 10),
                    Text(application.message),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.yMMMd().add_Hm().format(application.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: Text('reject'.tr),
                            onPressed: isReviewing
                                ? null
                                : () => _showApplicationReview(
                                    context,
                                    controller,
                                    application,
                                    approve: false,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: Text('approve'.tr),
                            onPressed: isReviewing
                                ? null
                                : () => _showApplicationReview(
                                    context,
                                    controller,
                                    application,
                                    approve: true,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ── Payouts tab ───────────────────────────────────────────────────────────────

class _PayoutsTab extends StatelessWidget {
  const _PayoutsTab({required this.controller});
  final AffiliateManagementController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loadingPayouts.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppConstants.darkBeige),
        );
      }
      if (controller.pendingPayouts.isEmpty) {
        return Center(child: Text('no_pending_payouts'.tr));
      }
      return RefreshIndicator(
        color: AppConstants.darkBeige,
        onRefresh: controller.fetchQueues,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pendingPayouts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final req = controller.pendingPayouts[i];
            final isReviewing = controller.reviewingId.value == req.id;
            return Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          req.affiliateName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${AppConstants.currency} ${req.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppConstants.darkBeige,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      req.affiliatePhone,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (req.payoutMethod != null ||
                        req.payoutAccount != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_payoutMethodLabel(req.payoutMethod)}'
                        ' · ${req.payoutAccount ?? '-'}',
                        textDirection: ui.TextDirection.ltr,
                      ),
                    ],
                    Text(
                      DateFormat.yMMMd().format(req.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isReviewing
                                ? null
                                : () => _showPayoutReview(
                                    context,
                                    controller,
                                    req,
                                    paid: false,
                                  ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                            child: Text('reject'.tr),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isReviewing
                                ? null
                                : () => _showPayoutReview(
                                    context,
                                    controller,
                                    req,
                                    paid: true,
                                  ),
                            child: Text('mark_paid'.tr),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

String _payoutMethodLabel(String? method) {
  switch (method) {
    case 'mobile_wallet':
      return 'mobile_wallet'.tr;
    case 'instapay':
      return 'instapay'.tr;
    case 'bank_transfer':
      return 'bank_transfer'.tr;
    default:
      return 'payout_method'.tr;
  }
}

Future<void> _showApplicationReview(
  BuildContext context,
  AffiliateManagementController controller,
  AffiliateApplicationModel application, {
  required bool approve,
}) async {
  final noteCtrl = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(approve ? 'approve_application'.tr : 'reject_application'.tr),
      content: TextField(
        controller: noteCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'admin_note'.tr,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(approve ? 'approve'.tr : 'reject'.tr),
        ),
      ],
    ),
  );
  final note = noteCtrl.text;
  noteCtrl.dispose();
  if (confirmed != true) return;
  await controller.reviewApplication(
    application.id,
    approve: approve,
    adminNote: note,
  );
}

Future<void> _showPayoutReview(
  BuildContext context,
  AffiliateManagementController controller,
  PayoutRequestModel request, {
  required bool paid,
}) async {
  final referenceCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(paid ? 'mark_paid'.tr : 'reject_payout'.tr),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paid)
                TextFormField(
                  controller: referenceCtrl,
                  textDirection: ui.TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'payment_reference'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 3
                      ? 'payment_reference_required'.tr
                      : null,
                ),
              if (paid) const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'admin_note'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () {
            if (paid && formKey.currentState?.validate() != true) return;
            Navigator.of(context).pop(true);
          },
          child: Text(paid ? 'mark_paid'.tr : 'reject'.tr),
        ),
      ],
    ),
  );
  final reference = referenceCtrl.text;
  final note = noteCtrl.text;
  referenceCtrl.dispose();
  noteCtrl.dispose();
  if (confirmed != true) return;
  await controller.reviewPayout(
    request.id,
    paid: paid,
    paymentReference: paid ? reference : null,
    adminNote: note,
  );
}

// ── Users tab ─────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  _UsersTab({required this.controller});
  final AffiliateManagementController controller;
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'search_affiliate_users'.tr,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.loadingUsers.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppConstants.darkBeige),
              );
            }
            if (controller.searchResults.isEmpty) {
              return Center(
                child: Text(
                  _searchCtrl.text.isEmpty
                      ? 'no_affiliates'.tr
                      : 'no_results'.tr,
                  style: TextStyle(color: AppConstants.mediumBeige),
                ),
              );
            }
            return RefreshIndicator(
              color: AppConstants.darkBeige,
              onRefresh: () => controller.fetchUsers(query: _searchCtrl.text),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: controller.searchResults.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final user = controller.searchResults[i];
                  final title = user.name.isEmpty ? user.phone : user.name;
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (user.phone.isNotEmpty)
                                      Text(
                                        user.phone,
                                        textDirection: ui.TextDirection.ltr,
                                      ),
                                  ],
                                ),
                              ),
                              if (user.code.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.darkBeige.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.code,
                                    textDirection: ui.TextDirection.ltr,
                                    style: const TextStyle(
                                      color: AppConstants.darkBeige,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Switch(
                                value: user.isAffiliate,
                                activeThumbColor: AppConstants.darkBeige,
                                onChanged: (_) =>
                                    controller.toggleAffiliateStatus(
                                      user.id,
                                      user.isAffiliate,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 18,
                            runSpacing: 10,
                            children: [
                              _UserMetric(
                                label: 'referred_orders'.tr,
                                value: '${user.referredOrders}',
                              ),
                              _UserMetric(
                                label: 'affiliate_revenue'.tr,
                                value:
                                    '${AppConstants.currency} ${user.referredRevenue.toStringAsFixed(0)}',
                              ),
                              _UserMetric(
                                label: 'total_commission'.tr,
                                value:
                                    '${AppConstants.currency} ${user.totalCommission.toStringAsFixed(0)}',
                              ),
                              _UserMetric(
                                label: 'available_balance'.tr,
                                value:
                                    '${AppConstants.currency} ${user.availableCommission.toStringAsFixed(0)}',
                              ),
                              _UserMetric(
                                label: 'paid_commission'.tr,
                                value:
                                    '${AppConstants.currency} ${user.paidCommission.toStringAsFixed(0)}',
                              ),
                              if (user.code.isNotEmpty)
                                _UserMetric(
                                  label: 'rates'.tr,
                                  value:
                                      '${user.customerDiscountPercentage.toStringAsFixed(0)}% / '
                                      '${user.commissionPercentage.toStringAsFixed(0)}%',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _UserMetric extends StatelessWidget {
  const _UserMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
