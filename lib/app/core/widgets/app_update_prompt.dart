import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// Checks the public App Store / Play Store listing and prompts when a newer
/// Sora version is available.
///
/// The prompt is delayed briefly so it never competes with the launch screen.
/// It is intentionally disabled on web and desktop, where store lookup is not
/// applicable.
class AppUpdatePrompt extends StatefulWidget {
  const AppUpdatePrompt({
    super.key,
    required this.languageCode,
    required this.child,
  });

  final String languageCode;
  final Widget child;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt> {
  static const _startupDelay = Duration(seconds: 2);
  static const _reminderInterval = Duration(days: 1);
  static const _forcePromptForTesting = bool.fromEnvironment(
    'FORCE_UPDATE_PROMPT',
  );

  Timer? _startupTimer;
  Upgrader? _upgrader;
  bool _ready = false;

  bool get _supportsStoreLookup {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    if (!_supportsStoreLookup) return;

    _createUpgrader();
    _startupTimer = Timer(_startupDelay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void didUpdateWidget(covariant AppUpdatePrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_supportsStoreLookup ||
        oldWidget.languageCode == widget.languageCode) {
      return;
    }

    _upgrader?.dispose();
    _createUpgrader();
  }

  void _createUpgrader() {
    _upgrader = Upgrader(
      // Apple's lookup API otherwise defaults to the US storefront. Sora's
      // production listing is intended for the Egyptian storefront.
      countryCode: 'EG',
      languageCode: widget.languageCode,
      messages: SoraUpgraderMessages(widget.languageCode),
      checkOnResume: true,
      durationUntilAlertAgain: _reminderInterval,
      // Run with --dart-define=FORCE_UPDATE_PROMPT=true to exercise the UI.
      // kDebugMode guarantees the flag can never force a production prompt.
      debugDisplayAlways: kDebugMode && _forcePromptForTesting,
      debugLogging: kDebugMode,
    );
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    _upgrader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upgrader = _upgrader;
    if (!_ready || upgrader == null) return widget.child;

    return UpgradeAlert(
      key: ValueKey(widget.languageCode),
      upgrader: upgrader,
      barrierDismissible: false,
      showIgnore: false,
      showLater: true,
      showReleaseNotes: true,
      child: widget.child,
    );
  }
}

/// Product-specific copy. Arabic deliberately uses natural Egyptian wording
/// rather than the package's generic Arabic translation.
class SoraUpgraderMessages extends UpgraderMessages {
  SoraUpgraderMessages(this.appLanguageCode) : super(code: appLanguageCode);

  final String appLanguageCode;

  @override
  String? message(UpgraderMessage messageKey) {
    if (appLanguageCode == 'ar') {
      switch (messageKey) {
        case UpgraderMessage.title:
          return 'تحديث جديد متاح';
        case UpgraderMessage.body:
          return 'في نسخة جديدة من {{appName}} متاحة دلوقتي.';
        case UpgraderMessage.prompt:
          return 'حدّث التطبيق عشان تاخد آخر التحسينات والإصلاحات.';
        case UpgraderMessage.buttonTitleUpdate:
          return 'حدّث دلوقتي';
        case UpgraderMessage.buttonTitleLater:
          return 'بعدين';
        case UpgraderMessage.buttonTitleIgnore:
          return 'تجاهل';
        case UpgraderMessage.releaseNotes:
          return 'الجديد في النسخة';
      }
    }

    return super.message(messageKey);
  }
}
