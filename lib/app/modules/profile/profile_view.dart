import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/controllers/settings_controller.dart';
import '../../core/models/affiliate_program_models.dart';
import '../../core/services/affiliate_program_service.dart';
import '../../core/utils/app_snackbar.dart';
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
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name.isEmpty ? 'Add your name' : user.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: user.name.isEmpty ? Colors.grey : null,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          padding: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  _EditNameDialog(initialName: user.name),
                            );
                          },
                        ),
                      ],
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
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
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
                        leading: const Icon(
                          Icons.admin_panel_settings_outlined,
                        ),
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
                    ] else ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      const _AffiliateApplicationTile(),
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
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(
                    'sign_out'.tr,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => _SignOutDialog(),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _AffiliateApplicationTile extends StatefulWidget {
  const _AffiliateApplicationTile();

  @override
  State<_AffiliateApplicationTile> createState() =>
      _AffiliateApplicationTileState();
}

class _AffiliateApplicationTileState extends State<_AffiliateApplicationTile> {
  AffiliateApplicationModel? _application;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AffiliateProgramService.getApplicationStatus();
      if (data['is_affiliate'] == true) {
        await AuthController.to.refreshCurrentUser();
        return;
      }
      final raw = data['application'];
      if (mounted) {
        setState(() {
          _application = raw is Map
              ? AffiliateApplicationModel.fromJson(
                  Map<String, dynamic>.from(raw),
                )
              : null;
        });
      }
    } catch (_) {
      // Keep the application entry usable for a retry.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = _application;
    final isPending = application?.isPending == true;
    final wasRejected = application?.status == 'Rejected';

    return ListTile(
      leading: const Icon(Icons.campaign_outlined),
      title: Text(
        isPending ? 'affiliate_application_pending'.tr : 'become_affiliate'.tr,
      ),
      subtitle: isPending
          ? Text('${'preferred_code'.tr}: ${application!.preferredCode}')
          : wasRejected
          ? Text(
              application?.adminNote?.isNotEmpty == true
                  ? application!.adminNote!
                  : 'affiliate_application_rejected'.tr,
            )
          : null,
      trailing: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isPending
          ? const Icon(Icons.schedule_outlined)
          : const Icon(Icons.chevron_right),
      onTap: _loading || isPending
          ? null
          : () async {
              final submitted = await showDialog<bool>(
                context: context,
                builder: (_) => const _AffiliateApplicationDialog(),
              );
              if (submitted == true) await _load();
            },
    );
  }
}

class _AffiliateApplicationDialog extends StatefulWidget {
  const _AffiliateApplicationDialog();

  @override
  State<_AffiliateApplicationDialog> createState() =>
      _AffiliateApplicationDialogState();
}

class _AffiliateApplicationDialogState
    extends State<_AffiliateApplicationDialog> {
  final _codeCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = AffiliateProgramService.normalizeCode(_codeCtrl.text);
    final message = _messageCtrl.text.trim();
    if (!RegExp(r'^[A-Z0-9]{4,20}$').hasMatch(code)) {
      AppSnackbar.show(
        'error'.tr,
        'affiliate_code_hint'.tr,
        type: AppSnackbarType.error,
      );
      return;
    }
    if (message.length < 10) {
      AppSnackbar.show(
        'error'.tr,
        'affiliate_application_message_required'.tr,
        type: AppSnackbarType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await AffiliateProgramService.submitApplication(
        preferredCode: code,
        message: message,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppSnackbar.show(
        'success'.tr,
        'affiliate_application_submitted'.tr,
        type: AppSnackbarType.success,
      );
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('become_affiliate'.tr),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: InputDecoration(
                labelText: 'preferred_code'.tr,
                helperText: 'affiliate_code_hint'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _messageCtrl,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'affiliate_application_message'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('submit_application'.tr),
        ),
      ],
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
            const Icon(
              Icons.person_outline,
              size: 72,
              color: AppConstants.mediumBeige,
            ),
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
  bool _isValidOptionalPhone(String value) =>
      value.isEmpty || _isValidPhone(value);

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
    _secondaryCtrl = TextEditingController(
      text: (widget.user.phoneTwo as String?) ?? '',
    );
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
      setState(
        () =>
            _primaryError = 'Phone must start with 0 and be exactly 11 digits',
      );
      hasError = true;
    }
    if (!_isValidOptionalPhone(secondary)) {
      setState(
        () => _secondaryError =
            'Phone must start with 0 and be exactly 11 digits',
      );
      hasError = true;
    }
    if (hasError) return;

    setState(() {
      _saving = true;
      _primaryError = null;
      _secondaryError = null;
    });

    try {
      await AuthController.to.updatePhoneNumbers(
        phone: primary,
        phoneTwo: secondary,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('phones_saved'.tr)));
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
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
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
                          if (_primaryError != null) {
                            setState(() => _primaryError = null);
                          }
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
                          if (_secondaryError != null) {
                            setState(() => _secondaryError = null);
                          }
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: Text('sign_out'.tr),
        ),
      ],
    );
  }
}

// ── Edit Name Dialog ─────────────────────────────────────────────────────────

class _EditNameDialog extends StatefulWidget {
  final String initialName;
  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    setState(() => _saving = true);
    try {
      await AuthController.to.updateName(newName);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Name'),
      content: TextField(
        controller: _nameCtrl,
        decoration: const InputDecoration(
          labelText: 'Your Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.darkBeige,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('save'.tr),
        ),
      ],
    );
  }
}
