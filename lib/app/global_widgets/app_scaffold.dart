import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/responsive.dart';
import '../modules/cart/cart_controller.dart';
import '../modules/cart/cart_view.dart';
import '../modules/contact/contact_view.dart';
import '../modules/history/history_view.dart';
import '../modules/home/home_view.dart';
import '../modules/navigation/nav_controller.dart';
import '../modules/profile/profile_view.dart';
import 'app_drawer.dart';

/// Adaptive navigation shell.
///
/// Mobile / Tablet  →  [BottomNavigationBar] with 5 tabs.
/// Desktop (≥ 1200) →  [AppBar] with inline [TextButton] nav links, body
///                      width-constrained to 1 400 dp.
///
/// All five tab widgets live in an [IndexedStack] so state is preserved
/// while switching tabs.
class AppScaffold extends GetView<NavController> {
  const AppScaffold({super.key});

  static final _tabs = <Widget>[
    const HomeView(),
    const CartView(),
    const HistoryView(),
    const ProfileView(),
    const ContactView(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (controller.currentIndex.value != 0) {
          controller.setIndex(0);
          return;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('exit_app'.tr),
            content: Text('exit_app_confirm'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text('exit'.tr),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Obx(() {
        final index = controller.currentIndex.value;
        final cartCount = CartController.to.totalItems;

        if (Responsive.isDesktop(context)) {
          return Scaffold(
            appBar: _DesktopAppBar(currentIndex: index, cartCount: cartCount),
            body: Row(
              children: [
                const AppDrawer(isDesktop: true),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(index: index, children: _tabs),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          key: controller.scaffoldKey,
          drawer: const AppDrawer(),
          body: IndexedStack(index: index, children: _tabs),
          bottomNavigationBar: _MobileBottomNav(
            currentIndex: index,
            cartCount: cartCount,
            onTap: controller.setIndex,
          ),
        );
      }),
    );
  }
}

// ── Desktop top nav ──────────────────────────────────────────────────────────

class _DesktopAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _DesktopAppBar({
    required this.currentIndex,
    required this.cartCount,
  });

  final int currentIndex;
  final int cartCount;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final labels = [
      'home'.tr,
      'cart'.tr,
      'history'.tr,
      'profile'.tr,
      'contact'.tr,
    ];

    return AppBar(
      titleSpacing: 16,
      title: Image.asset(AppConstants.logoPath, height: 38),
      actions: [
        for (int i = 0; i < labels.length; i++)
          _DesktopNavButton(
            label: i == 1 && cartCount > 0
                ? '${labels[i]} ($cartCount)'
                : labels[i],
            index: i,
            isSelected: i == currentIndex,
          ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _DesktopNavButton extends StatelessWidget {
  const _DesktopNavButton({
    required this.label,
    required this.index,
    required this.isSelected,
  });

  final String label;
  final int index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => NavController.to.setIndex(index),
      style: TextButton.styleFrom(
        foregroundColor: isSelected
            ? AppConstants.darkBeige
            : Theme.of(context).colorScheme.onSurface,
        textStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 24,
              decoration: BoxDecoration(
                color: AppConstants.darkBeige,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Mobile bottom nav ────────────────────────────────────────────────────────

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final isSelected = index == currentIndex;
            final iconData = _getIcon(index, isSelected);
            final label = _getLabel(index);

            Widget iconWidget = Icon(
              iconData,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
              size: 22,
            );

            if (index == 1 && cartCount > 0) {
              iconWidget = Badge.count(
                count: cartCount,
                isLabelVisible: true,
                child: iconWidget,
              );
            }

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap(index);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.darkBeige : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconWidget,
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  IconData _getIcon(int index, bool isSelected) {
    switch (index) {
      case 0:
        return isSelected ? Icons.home : Icons.home_outlined;
      case 1:
        return isSelected ? Icons.shopping_bag : Icons.shopping_bag_outlined;
      case 2:
        return isSelected ? Icons.receipt_long : Icons.receipt_long_outlined;
      case 3:
        return isSelected ? Icons.person : Icons.person_outline;
      case 4:
      default:
        return isSelected ? Icons.headset_mic : Icons.headset_mic_outlined;
    }
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'home'.tr;
      case 1:
        return 'cart'.tr;
      case 2:
        return 'history'.tr;
      case 3:
        return 'profile'.tr;
      case 4:
      default:
        return 'contact'.tr;
    }
  }
}
