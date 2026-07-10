import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/address_model.dart';
import 'address_controller.dart';

/// Address book — CRUD list of saved delivery addresses.
class AddressView extends GetView<AddressController> {
  const AddressView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('my_addresses'.tr)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.darkBeige,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('add_address'.tr),
        onPressed: () => _showForm(context),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppConstants.darkBeige));
        }
        if (controller.addresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_outlined,
                    size: 64, color: AppConstants.mediumBeige),
                const SizedBox(height: 12),
                Text('no_addresses'.tr),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppConstants.darkBeige,
          onRefresh: controller.fetchAddresses,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: controller.addresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _AddressTile(addr: controller.addresses[i]),
          ),
        );
      }),
    );
  }

  void _showForm(BuildContext context, {AddressModel? existing}) {
    Get.bottomSheet(
      _AddressFormSheet(existing: existing),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ── Address tile ─────────────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.addr});
  final AddressModel addr;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              addr.isDefault ? Icons.home : Icons.location_on_outlined,
              color: AppConstants.darkBeige,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(addr.address,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      if (addr.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.darkBeige
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'default'.tr,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppConstants.darkBeige,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
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
            PopupMenuButton<_AddrAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: _AddrAction.edit,
                    child: Text('edit'.tr)),
                if (!addr.isDefault)
                  PopupMenuItem(
                      value: _AddrAction.setDefault,
                      child: Text('set_default'.tr)),
                PopupMenuItem(
                    value: _AddrAction.delete,
                    child: Text('delete'.tr,
                        style:
                            const TextStyle(color: Colors.redAccent))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, _AddrAction action) {
    final ctrl = AddressController.to;
    switch (action) {
      case _AddrAction.edit:
        Get.bottomSheet(
          _AddressFormSheet(existing: addr),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        );
      case _AddrAction.setDefault:
        ctrl.setDefault(addr.id);
      case _AddrAction.delete:
        Get.defaultDialog(
          title: 'delete'.tr,
          middleText: 'delete_address_confirm'.tr,
          confirm: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () {
              ctrl.deleteAddress(addr.id);
              Navigator.of(context).pop(); // Close the dialog after deletion
            },
            child: Text('delete'.tr),
          ),
          cancel: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr),
          ),
        );
    }
  }
}

enum _AddrAction { edit, setDefault, delete }

// ── Address form bottom sheet ─────────────────────────────────────────────────

class _AddressFormSheet extends StatelessWidget {
  _AddressFormSheet({this.existing});

  final AddressModel? existing;
  final _addrCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _saving = false.obs;

  @override
  Widget build(BuildContext context) {
    if (existing != null) {
      _addrCtrl.text = existing!.address;
      _landmarkCtrl.text = existing!.landmark;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            existing == null ? 'add_address'.tr : 'edit_address'.tr,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _addrCtrl,
            decoration: InputDecoration(
              labelText: 'address'.tr,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _landmarkCtrl,
            decoration: InputDecoration(
              labelText: 'landmark'.tr,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving.value ? null : () => _save(),
                  child: _saving.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('save'.tr),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final addr = _addrCtrl.text.trim();
    if (addr.isEmpty) return;
    _saving.value = true;
    try {
      if (existing == null) {
        await AddressController.to
            .addAddress(addr, _landmarkCtrl.text.trim());
      } else {
        await AddressController.to.updateAddress(
            existing!.id, addr, _landmarkCtrl.text.trim());
      }
      Navigator.of(Get.context!).pop(); // Close the dialog first
    } finally {
      _saving.value = false;
    }
  }
}
