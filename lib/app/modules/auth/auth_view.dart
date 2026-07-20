import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import 'auth_controller.dart';
import 'widgets/phone_otp_sheet.dart';

/// Login screen: Google Sign-In and Phone OTP.
/// Layout is the same across all breakpoints — centered card max-width 480 dp.
class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                children: [
                  Image.asset(
                    AppConstants.logoPath,
                    height: 110,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox(height: 110),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'welcome'.tr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.darkBeige,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'app_name'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppConstants.mediumBeige,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (controller.isAppleSignInAvailable) ...[
                    _AppleButton(controller: controller),
                    const SizedBox(height: 12),
                  ],
                  _GoogleButton(controller: controller),
                  const SizedBox(height: 24),
                  _OrDivider(),
                  const SizedBox(height: 24),
                  _PhoneSection(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: controller.isLoading.value
              ? null
              : controller.signInWithApple,
          icon: const Icon(Icons.apple, size: 24),
          label: Text('sign_in_apple'.tr),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black.withValues(alpha: 0.45),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.controller});
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: controller.isLoading.value
              ? null
              : controller.signInWithGoogle,
          icon: const _GoogleLogo(),
          label: Text('sign_in_google'.tr),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppConstants.mediumBeige),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    // Simple "G" placeholder — replace with a real Google SVG if needed.
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppConstants.mediumBeige.withValues(alpha: 0.5),
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or'.tr,
            style: TextStyle(color: AppConstants.mediumBeige),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Forces input to start with '0' and caps at 11 digits.
class _EgyptianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip non-digits.
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // Force first digit to be '0'.
    if (digits.isNotEmpty && digits[0] != '0') {
      digits = '0$digits';
    }
    // Cap at 11 digits.
    if (digits.length > 11) digits = digits.substring(0, 11);
    return newValue.copyWith(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class _PhoneSection extends StatelessWidget {
  _PhoneSection({required this.controller});

  final AuthController controller;
  final _phoneCtrl = TextEditingController();

  bool _isValid(String v) => v.length == 11 && v.startsWith('0');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          maxLength: 11,
          inputFormatters: [_EgyptianPhoneFormatter()],
          decoration: InputDecoration(
            labelText: 'phone_number'.tr,
            hintText: '01xxxxxxxxx',
            counterText: '',
            prefixIcon: const Icon(Icons.phone_outlined),

            prefixStyle: const TextStyle(fontWeight: FontWeight.w600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Obx(
          () => SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      final phone = _phoneCtrl.text.trim();
                      if (!_isValid(phone)) return;
                      controller.sendPhoneOtp(
                        '+2$phone',
                        onCodeSent: () => Get.bottomSheet(
                          PhoneOtpSheet(controller: controller),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        ),
                      );
                    },
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('send_otp'.tr),
            ),
          ),
        ),
      ],
    );
  }
}
