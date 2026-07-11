import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

        return RefreshIndicator(
          color: AppConstants.darkBeige,
          onRefresh: AuthController.to.refreshCurrentUser,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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

              // ── Phone numbers ──────────────────────────────────────────
              _PhonesSection(user: user),
              const SizedBox(height: 16),
              
              // ── Navigation & Settings Card ─────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text('my_addresses'.tr),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.toNamed(Routes.addressBook),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.favorite_outline),
                      title: Text('wishlist'.tr),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.toNamed(Routes.wishlist),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // ── Theme toggle ───────────────────────────────────────────
                    Obx(() {
                      final settings = Get.find<SettingsController>();
                      return SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: Text('dark_mode'.tr),
                        value: settings.isDark.value,
                        activeThumbColor: AppConstants.darkBeige,
                        onChanged: (_) => settings.toggleTheme(),
                      );
                    }),
                    // ── Admin tile (conditional) ───────────────────────────────
                    if (user.isAdmin) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_outlined),
                        title: Text('admin_dashboard'.tr),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(Routes.adminDashboard),
                      ),
                    ],
                    // ── Affiliate tile (conditional) ───────────────────────────
                    if (user.isAffiliate) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.people_outline),
                        title: Text('affiliate_dashboard'.tr),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Get.toNamed(Routes.affiliateDashboard),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Sign out Card ──────────────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('sign_out'.tr,
                      style: const TextStyle(color: Colors.redAccent)),
                  onTap: () => showDialog(context: context, builder: (_) => _SignOutDialog()),
                ),
              ),
            ],
          ),
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

class _PhonesSection extends StatefulWidget {
  const _PhonesSection({required this.user});
  final dynamic user; // UserModel

  @override
  State<_PhonesSection> createState() => _PhonesSectionState();
}

class _PhonesSectionState extends State<_PhonesSection> {
  late final TextEditingController _primaryCtrl;
  late final TextEditingController _secondaryCtrl;
  bool _saving = false;
  String? _primaryError;
  String? _secondaryError;

  bool _isValidPhone(String value) => RegExp(r'^0\d{10}$').hasMatch(value);
  bool _isValidOptionalPhone(String value) => value.isEmpty || _isValidPhone(value);

  List<TextInputFormatter> _phoneInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty) return newValue;
        if (text.length > 11) return oldValue;
        if (!text.startsWith('0')) return oldValue;
        return newValue;
      }),
    ];
  }

  @override
  void initState() {
    super.initState();
    _primaryCtrl = TextEditingController(text: widget.user.phone as String);
    _secondaryCtrl = TextEditingController(text: (widget.user.phoneTwo as String?) ?? '');
  }

  @override
  void didUpdateWidget(covariant _PhonesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newPrimary = widget.user.phone as String;
    final newSecondary = (widget.user.phoneTwo as String?) ?? '';
    if (_primaryCtrl.text != newPrimary) {
      _primaryCtrl.text = newPrimary;
    }
    if (_secondaryCtrl.text != newSecondary) {
      _secondaryCtrl.text = newSecondary;
    }
  }

  @override
  void dispose() {
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    final primary = _primaryCtrl.text.trim();
    final secondary = _secondaryCtrl.text.trim();

    bool hasError = false;
    if (!_isValidPhone(primary)) {
      setState(() => _primaryError = 'Phone must start with 0 and be exactly 11 digits');
      hasError = true;
    }
    if (!_isValidOptionalPhone(secondary)) {
      setState(() => _secondaryError = 'Phone must start with 0 and be exactly 11 digits');
      hasError = true;
    }
    if (hasError) return;

    setState(() {
      _saving = true;
      _primaryError = null;
      _secondaryError = null;
    });

    try {
      await AuthController.to.updatePhoneNumbers(phone: primary, phoneTwo: secondary);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('phones_saved'.tr)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Text(
            'phone_numbers'.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkBeige,
                ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _primaryCtrl,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        maxLength: 11,
                        inputFormatters: _phoneInputFormatters(),
                        onChanged: (_) {
                          if (_primaryError != null) setState(() => _primaryError = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'primary_phone'.tr,
                          prefixIcon: const Icon(Icons.phone_android),
                          border: const OutlineInputBorder(),
                          errorText: _primaryError,
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _secondaryCtrl,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        maxLength: 11,
                        inputFormatters: _phoneInputFormatters(),
                        onChanged: (_) {
                          if (_secondaryError != null) setState(() => _secondaryError = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'secondary_phone'.tr,
                          prefixIcon: const Icon(Icons.phone_android),
                          border: const OutlineInputBorder(),
                          errorText: _secondaryError,
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _saveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.darkBeige,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('save'.tr),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sign-out dialog ────────────────────────────────────────────────────────────

class _SignOutDialog extends StatelessWidget {  @override
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
