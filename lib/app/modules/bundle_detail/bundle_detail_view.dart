import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/bundle_deal_model.dart';
import '../../core/utils/responsive.dart';
import '../../global_widgets/network_image_with_placeholder.dart';
import 'bundle_detail_controller.dart';

class BundleDetailView extends GetView<BundleDetailController> {
  const BundleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('bundle_deal'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }
        final bundle = controller.bundle.value;
        if (bundle == null) {
          return Center(child: Text('bundle_not_found'.tr));
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Responsive.maxContentWidth,
            ),
            child: Responsive.isDesktop(context)
                ? _DesktopBundle(bundle: bundle, controller: controller)
                : _MobileBundle(bundle: bundle, controller: controller),
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final bundle = controller.bundle.value;
        if (bundle == null) return const SizedBox.shrink();
        return _BundleBottomBar(bundle: bundle, controller: controller);
      }),
    );
  }
}

class _MobileBundle extends StatelessWidget {
  const _MobileBundle({required this.bundle, required this.controller});
  final BundleDealModel bundle;
  final BundleDetailController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _BundleBanner(bundle: bundle),
        Padding(
          padding: const EdgeInsets.all(20),
          child: _BundleInformation(bundle: bundle, controller: controller),
        ),
      ],
    );
  }
}

class _DesktopBundle extends StatelessWidget {
  const _DesktopBundle({required this.bundle, required this.controller});
  final BundleDealModel bundle;
  final BundleDetailController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _BundleBanner(bundle: bundle)),
          const SizedBox(width: 32),
          Expanded(
            child: _BundleInformation(bundle: bundle, controller: controller),
          ),
        ],
      ),
    );
  }
}

class _BundleBanner extends StatelessWidget {
  const _BundleBanner({required this.bundle});
  final BundleDealModel bundle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: NetworkImageWithPlaceholder(
        imageUrl: bundle.bannerImage,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _BundleInformation extends StatelessWidget {
  const _BundleInformation({required this.bundle, required this.controller});
  final BundleDealModel bundle;
  final BundleDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bundle.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (bundle.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(bundle.description),
        ],
        const SizedBox(height: 18),
        _BundlePrice(bundle: bundle),
        const SizedBox(height: 22),
        Text(
          'bundle_includes'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...bundle.items.map((item) => _BundleItemTile(item: item)),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'bundle_quantity'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Obx(
              () => _QuantitySelector(
                quantity: controller.quantity.value,
                onDecrement: controller.decrement,
                onIncrement: controller.increment,
              ),
            ),
          ],
        ),
        if (!bundle.isAvailable) ...[
          const SizedBox(height: 14),
          Text(
            'bundle_unavailable'.tr,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class _BundlePrice extends StatelessWidget {
  const _BundlePrice({required this.bundle});
  final BundleDealModel bundle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${AppConstants.currency} ${bundle.dealPrice.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppConstants.darkBeige,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${AppConstants.currency} ${bundle.regularPrice.toStringAsFixed(2)}',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.55),
            decoration: TextDecoration.lineThrough,
          ),
        ),
        if (bundle.savings > 0) ...[
          const SizedBox(width: 10),
          Chip(
            label: Text(
              '${'you_save'.tr} ${AppConstants.currency} '
              '${bundle.savings.toStringAsFixed(2)}',
            ),
          ),
        ],
      ],
    );
  }
}

class _BundleItemTile extends StatelessWidget {
  const _BundleItemTile({required this.item});
  final BundleDealItemModel item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 54,
          height: 54,
          child: NetworkImageWithPlaceholder(
            imageUrl: item.property.image,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(item.itemName),
      subtitle: Text(
        '${item.property.sizeMl} ml · ${AppConstants.currency} '
        '${item.property.price.toStringAsFixed(2)}',
      ),
      trailing: Chip(label: Text('× ${item.quantity}')),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppConstants.mediumBeige.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1 ? onDecrement : null,
            icon: const Icon(Icons.remove),
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: onIncrement, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class _BundleBottomBar extends StatelessWidget {
  const _BundleBottomBar({required this.bundle, required this.controller});
  final BundleDealModel bundle;
  final BundleDetailController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 10,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'bundle_deal_price'.tr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${AppConstants.currency} '
                        '${controller.dealTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppConstants.darkBeige,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 50,
                child: Obx(() {
                  final isInCart = controller.bundleInCart;
                  return FilledButton.icon(
                    onPressed: !bundle.isAvailable || controller.isAdding.value
                        ? null
                        : controller.handleCartAction,
                    icon: controller.isAdding.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isInCart
                                ? Icons.shopping_cart_checkout
                                : Icons.add_shopping_cart,
                          ),
                    label: Text(
                      isInCart
                          ? 'proceed_to_checkout'.tr
                          : 'add_bundle_to_cart'.tr,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
