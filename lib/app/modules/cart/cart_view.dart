import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../auth/auth_controller.dart';
import '../navigation/nav_controller.dart';
import 'cart_controller.dart';
import '../../routes/app_pages.dart';

/// Shopping cart screen.
/// Mobile: full-width list + sticky bottom summary.
/// Desktop: two-column layout — list on the left, summary card on the right.
class CartView extends GetView<CartController> {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('cart'.tr),
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
        if (controller.cartItems.isEmpty) {
          return _EmptyCart();
        }

        return ResponsiveLayout(
          mobile: _MobileCartLayout(controller: controller),
          desktop: _DesktopCartLayout(controller: controller),
        );
      }),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 72, color: AppConstants.mediumBeige),
          const SizedBox(height: 16),
          Text('cart_empty'.tr,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.offAllNamed(Routes.home),
            child: Text('keep_shopping'.tr),
          ),
        ],
      ),
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileCartLayout extends StatelessWidget {
  const _MobileCartLayout({required this.controller});
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _CartItemList(controller: controller)),
        _OrderSummary(controller: controller, compact: true),
      ],
    );
  }
}

// ── Desktop layout ────────────────────────────────────────────────────────────

class _DesktopCartLayout extends StatelessWidget {
  const _DesktopCartLayout({required this.controller});
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _CartItemList(controller: controller),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 340,
                child: _OrderSummary(controller: controller, compact: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cart item list ────────────────────────────────────────────────────────────

class _CartItemList extends StatelessWidget {
  const _CartItemList({required this.controller});
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.cartItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = controller.cartItems[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
                    child: item.image.isNotEmpty
                ? Image.network(item.image,
                    width: 64, height: 64, fit: BoxFit.cover)
                : Container(
                    width: 64,
                    height: 64,
                    color: AppConstants.lightBeige,
                    child: const Icon(Icons.image_outlined,
                        color: AppConstants.mediumBeige)),
          ),
          title: Text(item.itemName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.sizeMl} ml',
                  style: TextStyle(color: AppConstants.mediumBeige)),
              Text(
                '${AppConstants.currency} ${item.price.toStringAsFixed(2)}',
                style: TextStyle(
                    color: AppConstants.darkBeige,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          trailing: _QuantityControl(item: item, controller: controller),
        );
      },
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.item, required this.controller});
  final dynamic item;
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: AppConstants.darkBeige,
          onPressed: () => controller.decrement(item),
        ),
        Text(
          '${item.quantity}',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppConstants.darkBeige,
          onPressed: () => controller.increment(item),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: Colors.red.shade400,
          onPressed: () => controller.remove(item),
        ),
      ],
    );
  }
}

// ── Order summary ─────────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  const _OrderSummary(
      {required this.controller, required this.compact});
  final CartController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.totalPrice;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: compact
              ? const Border(
                  top: BorderSide(color: AppConstants.mediumBeige, width: 0.5))
              : Border.all(
                  color:
                      AppConstants.mediumBeige.withValues(alpha: 0.3)),
          borderRadius:
              compact ? null : BorderRadius.circular(16),
          boxShadow: compact
              ? const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2))
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('subtotal'.tr,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${AppConstants.currency} ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppConstants.darkBeige,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (!AuthController.to.isLoggedIn) {
                    Get.toNamed(Routes.auth);
                  } else {
                    Get.toNamed(Routes.checkout);
                  }
                },
                child: Text('checkout'.tr,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
