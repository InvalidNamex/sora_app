import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/address_model.dart';
import '../../core/utils/responsive.dart';
import '../../routes/app_pages.dart';
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
        return ResponsiveLayout(
          mobile: _MobileLayout(c: controller),
          desktop: _DesktopLayout(c: controller),
        );
      }),
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.c});
  final CheckoutController c;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AddressCard(c: c),
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AddressCard(c: c),
                    const SizedBox(height: 16),
                    _PromoCard(c: c),
                    const SizedBox(height: 16),
                    _NotesCard(c: c),
                  ],
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
        return Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppConstants.darkBeige),
            const SizedBox(width: 12),
            Expanded(
              child: addr == null
                  ? Text('no_addresses'.tr,
                      style: TextStyle(color: AppConstants.mediumBeige))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(addr.address,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (addr.landmark.isNotEmpty)
                          Text(addr.landmark,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 12)),
                      ],
                    ),
            ),
            TextButton(
              onPressed: () => _showAddressSheet(context),
              child: Text('change'.tr),
            ),
          ],
        );
      }),
    );
  }

  void _showAddressSheet(BuildContext context) {
    Get.bottomSheet(
      _AddressSelectSheet(addresses: c.addresses, onSelect: c.selectAddress),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _AddressSelectSheet extends StatelessWidget {
  const _AddressSelectSheet(
      {required this.addresses, required this.onSelect});
  final List<AddressModel> addresses;
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
          Text('select_address'.tr,
              style: Theme.of(context).textTheme.titleLarge),
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
                      addr.isDefault
                          ? Icons.home
                          : Icons.location_on_outlined,
                      color: AppConstants.darkBeige,
                    ),
                    title: Text(addr.address),
                    subtitle: addr.landmark.isNotEmpty
                        ? Text(addr.landmark)
                        : null,
                    onTap: () => onSelect(addr),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text('add_address'.tr),
            onPressed: () {
              Navigator.of(context).pop(); // Close the bottom sheet first
              Get.toNamed(Routes.addressBook);
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: c.promoCtrl,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: 'enter_promo'.tr,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(() => ElevatedButton(
                onPressed:
                    c.promoLoading.value ? null : c.applyPromo,
                child: c.promoLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('apply'.tr),
              )),
        ],
      ),
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
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
    return _SectionCard(
      title: 'order_summary'.tr,
      child: Obx(() => Column(
            children: [
              ...cart.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.itemName} (${item.sizeMl} ml) × ${item.quantity}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${AppConstants.currency} ${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              _SummaryRow(
                  label: 'subtotal'.tr,
                  value:
                      '${AppConstants.currency} ${c.cartTotal.toStringAsFixed(2)}'),
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
                  const Icon(Icons.payments_outlined,
                      size: 18, color: AppConstants.mediumBeige),
                  const SizedBox(width: 8),
                  Text('cash_on_delivery'.tr,
                      style: TextStyle(color: AppConstants.mediumBeige)),
                ],
              ),
            ],
          )),
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
          Text(value,
              style: (style ?? const TextStyle()).copyWith(
                  color: valueColor,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
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
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
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
            color: AppConstants.mediumBeige.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
