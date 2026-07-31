import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../auth_controller.dart';

/// Bottom sheet with a professional 6-box OTP input.
///
/// Platform behaviour:
/// - **Android**: [AuthController.sendPhoneOtp]'s `verificationCompleted`
///   callback fires automatically when Play Services reads the SMS — the sheet
///   is never touched.
/// - **iOS**: box 0 carries [AutofillHints.oneTimeCode] so the system offers
///   the code via QuickType. Tapping it fills box 0 with the full 6-digit
///   string; [_onDigitChanged] distributes it and auto-submits.
/// - **Web / paste**: same full-code distribution path as iOS.
/// - **Manual entry**: each digit advances focus; backspace retreats; all 6
///   filled → auto-submits.
class PhoneOtpSheet extends StatefulWidget {
  const PhoneOtpSheet({super.key, required this.controller});

  final AuthController controller;

  @override
  State<PhoneOtpSheet> createState() => _PhoneOtpSheetState();
}

class _PhoneOtpSheetState extends State<PhoneOtpSheet> {
  AuthController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_listenForAndroidSms());
    }
  }

  Future<void> _listenForAndroidSms() async {
    final result = await SmartAuth.instance.getSmsWithUserConsentApi();
    if (!mounted || !result.hasData) return;
    final code = result.requireData.code?.replaceAll(RegExp(r'\D'), '');
    if (code == null || code.length < 6) return;
    _applyFullCode(code.substring(0, 6));
  }

  Future<void> _resendCode() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await SmartAuth.instance.removeUserConsentApiListener();
      unawaited(_listenForAndroidSms());
    }
    await controller.resendPhoneOtp();
  }

  void _applyFullCode(String code) {
    for (int i = 0; i < 6; i++) {
      controller.otpControllers[i].text = code[i];
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (!controller.isLoading.value) {
      controller.verifyPhoneOtp(code);
    }
  }

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // ── Full code pasted / iOS autofill / web OTP API ─────────────────────
    if (digits.length >= 6) {
      _applyFullCode(digits.substring(0, 6));
      return;
    }

    // ── More than 1 digit typed quickly — keep only the last ─────────────
    if (digits.length > 1) {
      controller.otpControllers[index].text = digits[digits.length - 1];
    }

    // ── Advance focus ─────────────────────────────────────────────────────
    if (digits.isNotEmpty && index < 5) {
      controller.otpFocusNodes[index + 1].requestFocus();
    }

    // ── Auto-submit when all 6 boxes filled ───────────────────────────────
    final code = controller.otpControllers.map((c) => c.text).join();
    if (code.length == 6 && !controller.isLoading.value) {
      controller.verifyPhoneOtp(code);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(SmartAuth.instance.removeUserConsentApiListener());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wire backspace-to-previous-box on each focus node.
    // Safe to reassign each build — onKeyEvent is a simple property, not a stream.
    for (int i = 1; i < 6; i++) {
      final idx = i; // capture loop variable for the closure
      controller.otpFocusNodes[idx].onKeyEvent = (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            controller.otpControllers[idx].text.isEmpty) {
          controller.otpFocusNodes[idx - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
            ),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppConstants.mediumBeige.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'enter_otp'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'otp_sent_hint'.tr,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppConstants.mediumBeige),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Obx(() {
          final msg = controller.otpStatusMessage.value;
          if (msg.isEmpty) return const SizedBox.shrink();
          return Text(
            msg,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: controller.otpTimedOut.value
                  ? Colors.orange.shade800
                  : AppConstants.mediumBeige,
            ),
            textAlign: TextAlign.center,
          );
        }),
        const SizedBox(height: 28),
        // ── 6-box OTP grid ───────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 6.0;
            final boxWidth = ((constraints.maxWidth - (gap * 5)) / 6).clamp(
              36.0,
              44.0,
            );
            return AutofillGroup(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Padding(
                    padding: EdgeInsetsDirectional.only(end: i == 5 ? 0 : gap),
                    child: _OtpBox(
                      index: i,
                      width: boxWidth,
                      ctrl: controller.otpControllers[i],
                      focusNode: controller.otpFocusNodes[i],
                      onChanged: (v) => _onDigitChanged(i, v),
                    ),
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Obx(
          () => Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: controller.canResendOtp && !controller.isLoading.value
                  ? _resendCode
                  : null,
              child: Text(
                controller.resendSecondsLeft.value > 0
                    ? 'otp_resend_in'.trParams({
                        'seconds': '${controller.resendSecondsLeft.value}',
                      })
                    : 'otp_resend'.tr,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      final code = controller.otpControllers
                          .map((c) => c.text)
                          .join();
                      if (code.length == 6) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        controller.verifyPhoneOtp(code);
                      }
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
                  : Text('verify'.tr),
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.index,
    required this.width,
    required this.ctrl,
    required this.focusNode,
    required this.onChanged,
  });

  final int index;
  final double width;
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 56,
      child: TextField(
        controller: ctrl,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        // Box 0 has no maxLength so iOS/paste autofill of the full code lands
        // here and gets distributed by _onDigitChanged. Boxes 1–5 cap at 1.
        maxLength: index == 0 ? null : 1,
        autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppConstants.mediumBeige.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppConstants.darkBeige,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
