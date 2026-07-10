import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import 'affiliate_management_controller.dart';

/// Affiliate management — two tabs: Payouts and Users.
class AffiliateManagementView extends GetView<AffiliateManagementController> {
  const AffiliateManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('affiliate_management'.tr),
          bottom: TabBar(
            labelColor: AppConstants.darkBeige,
            indicatorColor: AppConstants.darkBeige,
            tabs: [
              Tab(text: 'payouts'.tr),
              Tab(text: 'users'.tr),
            ],
          ),
        ),
        body: DesktopConstraint(
          child: TabBarView(
            children: [
              _PayoutsTab(controller: controller),
              _UsersTab(controller: controller),
            ],
          ),
        ),
      ),
    );
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
            child:
                CircularProgressIndicator(color: AppConstants.darkBeige));
      }
      if (controller.pendingPayouts.isEmpty) {
        return Center(child: Text('no_pending_payouts'.tr));
      }
      return RefreshIndicator(
        color: AppConstants.darkBeige,
        onRefresh: controller.fetchPendingPayouts,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pendingPayouts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final req = controller.pendingPayouts[i];
            return Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(req.affiliateName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(
                          '${AppConstants.currency} ${req.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: AppConstants.darkBeige,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(req.affiliatePhone,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6))),
                    Text(
                        DateFormat.yMMMd().format(req.createdAt),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                controller.rejectRequest(req.id),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent),
                            child: Text('reject'.tr),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                controller.approveRequest(req.id),
                            child: Text('approve'.tr),
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
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'search_by_phone'.tr,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.loadingUsers.value) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: AppConstants.darkBeige));
            }
            if (controller.searchResults.isEmpty) {
              return Center(
                child: Text(
                  _searchCtrl.text.isEmpty
                      ? 'search_hint'.tr
                      : 'no_results'.tr,
                  style:
                      TextStyle(color: AppConstants.mediumBeige),
                ),
              );
            }
            return ListView.separated(
              itemCount: controller.searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final user = controller.searchResults[i];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.phone),
                  trailing: Switch(
                    value: user.isAffiliate,
                    activeThumbColor: AppConstants.darkBeige,
                    onChanged: (_) => controller.toggleAffiliateStatus(
                        user.id, user.isAffiliate),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
