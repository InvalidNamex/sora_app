import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/controllers/settings_controller.dart';
import '../../core/utils/responsive.dart';
import '../../modules/navigation/nav_controller.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';

/// Profile tab — displays user info and navigation tiles.
/// Uses permanently-registered [AuthController] and [SettingsController];
/// no separate controller needed.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr),
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
        final user = AuthController.to.currentUser.value;

        if (user == null) {
          return _GuestProfile();
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Avatar & name ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppConstants.darkBeige,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.phone,
                    style: TextStyle(color: AppConstants.mediumBeige),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Divider(),

            // ── Navigation tiles ───────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text('my_addresses'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(Routes.addressBook),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text('wishlist'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(Routes.wishlist),
            ),

            const Divider(),

            // ── Theme toggle ───────────────────────────────────────────
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text('dark_mode'.tr),
              value: Get.isDarkMode,
              activeThumbColor: AppConstants.darkBeige,
              onChanged: (_) =>
                  Get.find<SettingsController>().toggleTheme(),
            ),

            const Divider(),

            // ── Admin tile (conditional) ───────────────────────────────
            if (user.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: Text('admin_dashboard'.tr),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(Routes.adminDashboard),
              ),

            // ── Affiliate tile (conditional) ───────────────────────────
            if (user.isAffiliate)
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text('affiliate_dashboard'.tr),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(Routes.affiliateDashboard),
              ),
            const Divider(),

            // ── Sign out ───────────────────────────────────────────────
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Colors.redAccent),
              title: Text('sign_out'.tr,
                  style: const TextStyle(color: Colors.redAccent)),
              onTap: () => Get.dialog(_SignOutDialog()),
            ),
          ],
        );
      }),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline,
                size: 72, color: AppConstants.mediumBeige),
            const SizedBox(height: 16),
            Text(
              'sign_in_to_access_profile'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.auth),
              child: Text('sign_in'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('sign_out'.tr),
      content: Text('sign_out_confirm'.tr),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop(); // Close the dialog first
            await AuthController.to.signOut();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent),
          child: Text('sign_out'.tr),
        ),
      ],
    );
  }
}
