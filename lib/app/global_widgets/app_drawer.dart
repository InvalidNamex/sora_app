import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../core/controllers/settings_controller.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/home/home_controller.dart';
import '../modules/navigation/nav_controller.dart';
import '../routes/app_pages.dart';

/// Slide-in drawer (mobile) or always-visible sidebar (desktop/web).
///
/// Pass [isDesktop: true] to hide nav tiles and the close/logo header
/// (desktop AppBar already has those).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.isDesktop = false});

  final bool isDesktop;

  static const double width = 260;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header (mobile only — desktop has AppBar) ─────────────
            if (!isDesktop) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 16),
                child: Row(
                  children: [
                    Image.asset(AppConstants.logoPath, height: 36),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ] else ...[
              const SizedBox(height: 8),
            ],
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  // Navigation (mobile only — desktop uses AppBar)
                  if (!isDesktop) ...[
                    _SectionLabel(label: 'navigation'.tr),
                    const _NavTiles(),
                    const Divider(),
                  ],
                  // Filters
                  _SectionLabel(label: 'filters'.tr),
                  const _FiltersSection(),
                  const Divider(),
                  // Settings
                  _SectionLabel(label: 'settings'.tr),
                  _SettingsSection(isDesktop: isDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppConstants.mediumBeige,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ── Navigation tiles (mobile drawer only) ────────────────────────────────────

class _NavTiles extends StatelessWidget {
  const _NavTiles();

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'home'),
    (Icons.shopping_cart_outlined, Icons.shopping_cart, 'cart'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'history'),
    (Icons.person_outline, Icons.person, 'profile'),
    (Icons.headset_mic_outlined, Icons.headset_mic, 'contact'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = NavController.to.currentIndex.value;
      return Column(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            ListTile(
              dense: true,
              leading: Icon(
                current == i ? _tabs[i].$2 : _tabs[i].$1,
                color: current == i ? AppConstants.darkBeige : null,
              ),
              title: Text(
                _tabs[i].$3.tr,
                style: TextStyle(
                  color: current == i ? AppConstants.darkBeige : null,
                  fontWeight: current == i
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              selected: current == i,
              onTap: () {
                NavController.to.setIndex(i);
                Navigator.of(context).pop();
              },
            ),
        ],
      );
    });
  }
}

// ── Filters section ───────────────────────────────────────────────────────────

class _FiltersSection extends StatelessWidget {
  const _FiltersSection();

  static const _genderOptions = [
    (null, 'all_genders'),
    (1, 'men'),
    (2, 'women'),
    (0, 'unisex'),
  ];

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HomeController>()) return const SizedBox.shrink();
    final ctrl = HomeController.to;

    return Obx(() {
      final selected = ctrl.genderFilter.value;
      return RadioGroup<int?>(
        groupValue: selected,
        onChanged: ctrl.setGenderFilter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'gender_filter'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final opt in _genderOptions)
              ListTile(
                dense: true,
                leading: Radio<int?>(
                  value: opt.$1,
                  activeColor: AppConstants.darkBeige,
                ),
                title: Text(opt.$2.tr, style: const TextStyle(fontSize: 13)),
                onTap: () => ctrl.setGenderFilter(opt.$1),
              ),
            CheckboxListTile(
              dense: true,
              value: ctrl.inStockOnly.value,
              activeColor: AppConstants.darkBeige,
              title: Text(
                'in_stock_only'.tr,
                style: const TextStyle(fontSize: 13),
              ),
              onChanged: (v) => ctrl.setInStockOnly(v ?? false),
            ),
          ],
        ),
      );
    });
  }
}

// ── Settings section ──────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dark mode toggle
        Obx(() {
          final ctrl = Get.find<SettingsController>();
          return SwitchListTile(
            dense: true,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text('dark_mode'.tr, style: const TextStyle(fontSize: 13)),
            value: ctrl.isDark.value,
            activeThumbColor: AppConstants.darkBeige,
            onChanged: (_) => ctrl.toggleTheme(),
          );
        }),
        // Language toggle
        Obx(() {
          final isAr = Get.find<SettingsController>().localeCode.value == 'ar';
          return ListTile(
            dense: true,
            leading: const Icon(Icons.language),
            title: Text('language'.tr, style: const TextStyle(fontSize: 13)),
            trailing: _LangToggle(isArabic: isAr),
          );
        }),
        ListTile(
          dense: true,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(
            'privacy_policy'.tr,
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () {
            if (!isDesktop) Navigator.of(context).pop();
            Get.toNamed(Routes.privacyPolicy);
          },
        ),
        Obx(() {
          final user = AuthController.to.currentUser.value;
          if (user == null) return const SizedBox.shrink();
          return ListTile(
            dense: true,
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
            ),
            title: Text(
              'delete_account'.tr,
              style: const TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
            onTap: () {
              if (!isDesktop) Navigator.of(context).pop();
              Get.toNamed(Routes.accountDeletion);
            },
          );
        }),

        // Login / Logout
        Obx(() {
          final user = AuthController.to.currentUser.value;
          return ListTile(
            dense: true,
            leading: Icon(
              user != null ? Icons.logout : Icons.login,
              color: user != null ? Colors.redAccent : null,
            ),
            title: Text(
              user != null ? 'sign_out'.tr : 'sign_in'.tr,
              style: TextStyle(
                fontSize: 13,
                color: user != null ? Colors.redAccent : null,
              ),
            ),
            onTap: user != null
                ? () => _confirmSignOut(context)
                : () {
                    if (!isDesktop) Navigator.of(context).pop();
                    Get.toNamed(Routes.auth);
                  },
          );
        }),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    Get.defaultDialog(
      title: 'sign_out'.tr,
      middleText: 'sign_out_confirm'.tr,
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        onPressed: () async {
          Navigator.of(context).pop(); // Close the dialog first
          await AuthController.to.signOut();
        },
        child: Text('sign_out'.tr),
      ),
      cancel: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('cancel'.tr),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppConstants.mediumBeige),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangBtn(
            label: 'ع',
            selected: isArabic,
            onTap: () => Get.find<SettingsController>().changeLocale('ar'),
          ),
          _LangBtn(
            label: 'EN',
            selected: !isArabic,
            onTap: () => Get.find<SettingsController>().changeLocale('en'),
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  const _LangBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppConstants.darkBeige : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}
