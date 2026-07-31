import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/item_suggestion_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/responsive.dart';
import '../auth/auth_controller.dart';
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
      body: RefreshIndicator(
        color: AppConstants.darkBeige,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.headset_mic_outlined,
                      size: 64,
                      color: AppConstants.darkBeige,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'contact_us'.tr,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    _ContactTile(
                      icon: Icons.email_outlined,
                      label: AppConstants.supportEmail,
                      onTap: () =>
                          _launch('mailto:${AppConstants.supportEmail}'),
                    ),
                    const SizedBox(height: 12),
                    _ContactTile(
                      icon: Icons.phone_outlined,
                      label: AppConstants.supportPhone,
                      onTap: () => _launch('tel:${AppConstants.supportPhone}'),
                    ),
                    Obx(
                      () => AuthController.to.isLoggedIn
                          ? const _ItemSuggestionForm()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {}

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      AppSnackbar.show(
        'error'.tr,
        'could_not_open'.tr,
        type: AppSnackbarType.error,
      );
    }
  }
}

class _ItemSuggestionForm extends StatefulWidget {
  const _ItemSuggestionForm();

  @override
  State<_ItemSuggestionForm> createState() => _ItemSuggestionFormState();
}

class _ItemSuggestionFormState extends State<_ItemSuggestionForm> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _brandController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ItemSuggestionService.submit(
        itemName: _itemNameController.text,
        brandName: _brandController.text,
        details: _detailsController.text,
      );
      _formKey.currentState?.reset();
      _itemNameController.clear();
      _brandController.clear();
      _detailsController.clear();
      AppSnackbar.show(
        'success'.tr,
        'suggestion_submitted'.tr,
        type: AppSnackbarType.success,
      );
    } catch (error) {
      debugPrint('[ContactView] item suggestion error: $error');
      AppSnackbar.show(
        'error'.tr,
        'suggestion_submit_failed'.tr,
        type: AppSnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(
                Icons.add_shopping_cart_outlined,
                color: AppConstants.darkBeige,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'suggest_item'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'suggest_item_hint'.tr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _itemNameController,
            textInputAction: TextInputAction.next,
            maxLength: 160,
            decoration: InputDecoration(
              labelText: 'suggestion_item_name'.tr,
              prefixIcon: const Icon(Icons.inventory_2_outlined),
            ),
            validator: (value) => (value ?? '').trim().length < 2
                ? 'suggestion_item_required'.tr
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _brandController,
            textInputAction: TextInputAction.next,
            maxLength: 160,
            decoration: InputDecoration(
              labelText: 'suggestion_brand_name'.tr,
              prefixIcon: const Icon(Icons.sell_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _detailsController,
            minLines: 3,
            maxLines: 5,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: 'suggestion_details'.tr,
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 64),
                child: Icon(Icons.notes_outlined),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text('submit_suggestion'.tr),
            ),
          ),
        ],
      ),
    );
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
            color: AppConstants.mediumBeige.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.darkBeige),
            const SizedBox(width: 16),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppConstants.mediumBeige,
            ),
          ],
        ),
      ),
    );
  }
}
