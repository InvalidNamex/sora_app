import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../navigation/nav_controller.dart';

/// Contact tab — shows support email and phone, both launchable via url_launcher.
class ContactView extends StatelessWidget {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('contact'.tr),
        leading: Responsive.isDesktop(context)
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    NavController.to.scaffoldKey.currentState?.openDrawer(),
              ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.headset_mic_outlined,
                    size: 64, color: AppConstants.darkBeige),
                const SizedBox(height: 16),
                Text(
                  'contact_us'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                _ContactTile(
                  icon: Icons.email_outlined,
                  label: AppConstants.supportEmail,
                  onTap: () => _launch(
                      'mailto:${AppConstants.supportEmail}'),
                ),
                const SizedBox(height: 12),
                _ContactTile(
                  icon: Icons.phone_outlined,
                  label: AppConstants.supportPhone,
                  onTap: () => _launch(
                      'tel:${AppConstants.supportPhone}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      Get.snackbar('error'.tr, 'could_not_open'.tr);
    }
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppConstants.mediumBeige.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.darkBeige),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppConstants.mediumBeige),
          ],
        ),
      ),
    );
  }
}
