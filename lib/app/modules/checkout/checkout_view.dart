import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/cart_item_model.dart';
import '../../core/models/bundle_deal_model.dart';
import '../../core/models/address_model.dart';
import '../../core/utils/responsive.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import 'checkout_controller.dart';

/// Checkout screen — Cash on Delivery.
///
/// Mobile  : single-column scrollable form.
/// Desktop : two-column layout (form left, order summary right).
class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('checkout'.tr)),
      body: Obx(() {
        if (controller.placingOrder.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.darkBeige),
          );
        }
        if (!AuthController.to.isLoggedIn) {
          return _CheckoutLoginPrompt(c: controller);
        }
        return ResponsiveLayout(
          mobile: _MobileLayout(c: controller),
          desktop: _DesktopLayout(c: controller),
        );
      }),
    );
  }
}

class _CheckoutLoginPrompt extends StatelessWidget {
  const _CheckoutLoginPrompt({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppConstants.mediumBeige.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  size: 36,
                  color: AppConstants.darkBeige,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'checkout_login_title'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'checkout_login_message'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: c.startLoginForCheckout,
                  icon: const Icon(Icons.login_outlined),
                  label: Text('sign_in'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppConstants.darkBeige,
      onRefresh: c.refreshCheckout,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddressCard(c: c),
            const SizedBox(height: 16),
            _PhoneCard(c: c),
            const SizedBox(height: 16),
            _PromoCard(c: c),
            const SizedBox(height: 16),
            _NotesCard(c: c),
            const SizedBox(height: 16),
            _OrderSummaryCard(c: c),
            const SizedBox(height: 24),
            _PlaceOrderButton(c: c),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return DesktopConstraint(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: form
            Expanded(
              child: RefreshIndicator(
                color: AppConstants.darkBeige,
                onRefresh: c.refreshCheckout,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AddressCard(c: c),
                      const SizedBox(height: 16),
                      _PhoneCard(c: c),
                      const SizedBox(height: 16),
                      _PromoCard(c: c),
                      const SizedBox(height: 16),
                      _NotesCard(c: c),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Right: summary + CTA
            SizedBox(
              width: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OrderSummaryCard(c: c),
                  const SizedBox(height: 16),
                  _PlaceOrderButton(c: c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phone card ───────────────────────────────────────────────────────────────

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    final user = c.phoneCtrl; // TextEditingController
    final savedPhones = <String>[
      AuthController.to.currentUser.value?.phone ?? '',
      AuthController.to.currentUser.value?.phoneTwo ?? '',
    ].where((p) => p.isNotEmpty).toSet().toList();

    return _SectionCard(
      title: 'contact_phone'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick-pick chips when the user has more than one saved phone
          if (savedPhones.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final phone in savedPhones)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.phone_outlined, size: 14),
                        label: Text(
                          phone,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => c.phoneCtrl.text = phone,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: user,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\s()]')),
            ],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_outlined),
              hintText: 'phone_hint'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Address card ──────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'delivery_address'.tr,
      child: Obx(() {
        final addr = c.selectedAddress.value;
        final addresses = c.addresses.toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppConstants.darkBeige,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: addr == null
                      ? Text(
                          'no_addresses'.tr,
                          style: const TextStyle(
                            color: AppConstants.mediumBeige,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.address,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (addr.landmark.isNotEmpty)
                              Text(
                                addr.landmark,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                ),
                TextButton(
                  onPressed: () => _showAddressSheet(context),
                  child: Text('change'.tr),
                ),
              ],
            ),
            if (addresses.length > 1) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final a in addresses)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(
                            a.addressName.isEmpty ? a.address : a.addressName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: a.id == addr?.id,
                          onSelected: (_) => c.selectAddress(a),
                          selectedColor: AppConstants.mediumBeige.withValues(
                            alpha: 0.35,
                          ),
                          side: BorderSide(
                            color: AppConstants.mediumBeige.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  void _showAddressSheet(BuildContext context) {
    Get.bottomSheet(
      _AddressSelectSheet(
        addresses: c.addresses,
        selectedAddressId: c.selectedAddress.value?.id,
        onSelect: c.selectAddress,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _AddressSelectSheet extends StatelessWidget {
  const _AddressSelectSheet({
    required this.addresses,
    required this.selectedAddressId,
    required this.onSelect,
  });
  final List<AddressModel> addresses;
  final int? selectedAddressId;
  final ValueChanged<AddressModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'select_address'.tr,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('no_addresses'.tr, textAlign: TextAlign.center),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: addresses.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final addr = addresses[i];
                  return ListTile(
                    leading: Icon(
                      addr.isDefault ? Icons.home : Icons.location_on_outlined,
                      color: AppConstants.darkBeige,
                    ),
                    trailing: addr.id == selectedAddressId
                        ? const Icon(
                            Icons.check_circle,
                            color: AppConstants.darkBeige,
                          )
                        : null,
                    selected: addr.id == selectedAddressId,
                    selectedTileColor: AppConstants.mediumBeige.withValues(
                      alpha: 0.12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      addr.addressName.isEmpty
                          ? addr.address
                          : addr.addressName,
                    ),
                    subtitle: Text(
                      [
                        if (addr.addressName.isNotEmpty) addr.address,
                        if (addr.landmark.isNotEmpty) addr.landmark,
                      ].join('\n'),
                    ),
                    onTap: () {
                      onSelect(addr);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text('add_address'.tr),
            onPressed: () async {
              Navigator.of(context).pop(); // Close the bottom sheet first
              await Get.toNamed(Routes.addressBook);
              await CheckoutController.to.loadAddresses();
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'promo_code'.tr,
      child: Obx(() {
        if (c.hasBundleDeal) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.lightBeige.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppConstants.darkBeige),
                const SizedBox(width: 10),
                Expanded(child: Text('promo_unavailable_with_bundle'.tr)),
              ],
            ),
          );
        }
        final applied = c.appliedPromo.value;
        if (applied != null) {
          return Container(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applied.code,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${'discount'.tr}: ${AppConstants.currency} '
                        '${applied.discountAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'change'.tr,
                  onPressed: c.editPromo,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: c.promoCtrl,
                onChanged: c.onPromoChanged,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'enter_promo'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: c.promoLoading.value ? null : c.applyPromo,
              child: c.promoLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('apply'.tr),
            ),
          ],
        );
      }),
    );
  }
}

// ── Notes card ────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'order_notes'.tr,
      child: TextField(
        controller: c.notesCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'notes_hint'.tr,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ── Order summary card ────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    final cart = CartController.to.cartItems;
    final bundles = CartController.to.bundleItems;
    return _SectionCard(
      title: 'order_summary'.tr,
      child: Obx(
        () => Column(
          children: [
            ...cart.map((item) => _CheckoutCartItemRow(item: item, c: c)),
            ...bundles.map((item) => _CheckoutBundleRow(item: item)),
            const Divider(height: 24),
            _SummaryRow(
              label: 'subtotal'.tr,
              value:
                  '${AppConstants.currency} '
                  '${CartController.to.regularTotalPrice.toStringAsFixed(2)}',
            ),
            if (CartController.to.bundleSavings > 0)
              _SummaryRow(
                label: 'bundle_savings'.tr,
                value:
                    '- ${AppConstants.currency} '
                    '${CartController.to.bundleSavings.toStringAsFixed(2)}',
                valueColor: Colors.green.shade700,
              ),
            if (c.discount.value > 0)
              _SummaryRow(
                label: 'discount'.tr,
                value:
                    '- ${AppConstants.currency} ${c.discount.value.toStringAsFixed(2)}',
                valueColor: Colors.green.shade700,
              ),
            const Divider(height: 16),
            _SummaryRow(
              label: 'total'.tr,
              value:
                  '${AppConstants.currency} ${c.finalTotal.toStringAsFixed(2)}',
              bold: true,
              valueColor: AppConstants.darkBeige,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppConstants.mediumBeige,
                ),
                const SizedBox(width: 8),
                Text(
                  'cash_on_delivery'.tr,
                  style: TextStyle(color: AppConstants.mediumBeige),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBundleRow extends StatelessWidget {
  const _CheckoutBundleRow({required this.item});
  final BundleCartItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.mediumBeige.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.mediumBeige.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 18,
                color: AppConstants.darkBeige,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.bundle.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${item.quantity} × ${'bundle'.tr}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...item.bundle.items.map(
            (bundleItem) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${bundleItem.itemName} · '
                      '${bundleItem.property.sizeMl} ml',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    '× ${bundleItem.quantity * item.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppConstants.currency} '
                '${item.regularSubtotal.toStringAsFixed(2)}',
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
              Text(
                '${AppConstants.currency} ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppConstants.darkBeige,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'bundle_quantities_locked'.tr,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutCartItemRow extends StatelessWidget {
  const _CheckoutCartItemRow({required this.item, required this.c});
  final CartItemModel item;
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.sizeMl} ml · ${AppConstants.currency} '
                  '${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                _CheckoutQuantityControl(item: item, c: c),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${AppConstants.currency} ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                tooltip: 'delete'.tr,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red.shade400,
                onPressed: () => c.removeCartItem(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutQuantityControl extends StatelessWidget {
  const _CheckoutQuantityControl({required this.item, required this.c});
  final CartItemModel item;
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppConstants.mediumBeige.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: item.quantity <= 1 ? 'delete'.tr : 'decrease'.tr,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              item.quantity <= 1 ? Icons.delete_outline : Icons.remove_rounded,
              size: 18,
            ),
            color: AppConstants.darkBeige,
            onPressed: () => c.decrementCartItem(item),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'increase'.tr,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded, size: 18),
            color: AppConstants.darkBeige,
            onPressed: () => c.incrementCartItem(item),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: (style ?? const TextStyle()).copyWith(
              color: valueColor,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Place order button ────────────────────────────────────────────────────────

class _PlaceOrderButton extends StatelessWidget {
  const _PlaceOrderButton({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: c.placeOrder,
        child: Text(
          'place_order'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Shared section card ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.mediumBeige.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
