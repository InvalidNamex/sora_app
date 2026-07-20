import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';
import 'account_deletion_controller.dart';

class AccountDeletionView extends GetView<AccountDeletionController> {
  const AccountDeletionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('delete_account'.tr)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
            children: [
              Icon(
                Icons.delete_forever_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'delete_account_title'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'delete_account_intro'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 28),
              _InformationCard(
                icon: Icons.delete_sweep_outlined,
                title: 'deleted_immediately'.tr,
                body: 'deleted_immediately_body'.tr,
              ),
              const SizedBox(height: 12),
              _InformationCard(
                icon: Icons.receipt_long_outlined,
                title: 'retained_order_records'.tr,
                body: 'retained_order_records_body'.tr,
              ),
              const SizedBox(height: 12),
              _InformationCard(
                icon: Icons.lock_reset_outlined,
                title: 'cannot_be_undone'.tr,
                body: 'cannot_be_undone_body'.tr,
              ),
              const SizedBox(height: 28),
              if (AuthController.to.currentUser.value == null)
                FilledButton.icon(
                  onPressed: () => Get.toNamed(Routes.auth),
                  icon: const Icon(Icons.login),
                  label: Text('sign_in_to_delete'.tr),
                )
              else ...[
                TextField(
                  controller: controller.confirmationController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'type_delete_to_confirm'.tr,
                    hintText: 'DELETE',
                    prefixIcon: const Icon(Icons.keyboard_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppConstants.darkBeige,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: controller.understandsConsequences.value,
                    onChanged: controller.isDeleting.value
                        ? null
                        : (value) {
                            controller.understandsConsequences.value =
                                value ?? false;
                          },
                    title: Text('delete_account_acknowledgement'.tr),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: controller.canDelete
                        ? controller.deleteAccount
                        : null,
                    icon: controller.isDeleting.value
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_forever_outlined),
                    label: Text(
                      controller.isDeleting.value
                          ? 'deleting_account'.tr
                          : 'delete_my_account'.tr,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.toNamed(Routes.privacyPolicy),
                child: Text('read_privacy_policy'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppConstants.darkBeige),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
