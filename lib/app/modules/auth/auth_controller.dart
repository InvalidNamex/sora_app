import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/deep_link_service.dart';
import '../../core/services/affiliate_program_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../navigation/nav_controller.dart';
import '../../routes/app_pages.dart';

/// Handles Firebase Authentication (Google + Phone) and Supabase user sync.
///
/// Google Sign-In: Firebase and Supabase are both authenticated with the same
/// Google ID token, which enables per-user RLS via [auth.jwt()].
///
/// Phone Sign-In: Firebase authenticates the user. Supabase receives the
/// Firebase JWT once a custom OIDC provider (Firebase) is configured in the
/// Supabase dashboard under Authentication → Third-party Auth Providers.
class AuthController extends GetxController with WidgetsBindingObserver {
  static AuthController get to => Get.find();

  final _auth = fb.FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  final _storage = GetStorage();

  final currentUser = Rxn<UserModel>();
  final isLoading = false.obs;
  final verificationId = ''.obs;
  final otpStatusMessage = ''.obs;
  final otpTimedOut = false.obs;
  final resendSecondsLeft = 0.obs;
  fb.ConfirmationResult? _webPhoneConfirmationResult;
  String? _pendingPhone;
  int? _resendToken;
  Timer? _resendTimer;
  StreamSubscription<String>? _fcmTokenRefreshSub;
  bool _isRegisteringFcm = false;
  bool _hasScheduledFcmRetry = false;
  bool _phoneOtpRequestActive = false;
  int _fcmRetryAttempts = 0;
  static const int _maxFcmRetryAttempts = 5;

  /// Controllers and focus nodes shared with [PhoneOtpSheet].
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  void resetOtpState() {
    for (final c in otpControllers) {
      c.clear();
    }
  }

  bool get canResendOtp =>
      resendSecondsLeft.value == 0 && _pendingPhone != null;

  void _startResendCountdown([int seconds = 30]) {
    _resendTimer?.cancel();
    resendSecondsLeft.value = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = resendSecondsLeft.value - 1;
      if (next <= 0) {
        resendSecondsLeft.value = 0;
        timer.cancel();
      } else {
        resendSecondsLeft.value = next;
      }
    });
  }

  bool get isLoggedIn => currentUser.value != null;
  bool get isAppleSignInAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  GoogleSignIn get _nativeGoogleSignIn => _googleSignIn ??= GoogleSignIn(
    serverClientId: AppConstants.googleWebClientId,
  );

  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final result = await SupabaseService.client
          .from('users')
          .select()
          .eq('uid', user.uid)
          .maybeSingle();
      if (result != null) {
        currentUser.value = UserModel.fromJson(result);
      }
    } catch (e) {
      debugPrint('[AuthController] refreshCurrentUser error: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _fcmTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      unawaited(_saveRefreshedFcmToken(token));
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendTimer?.cancel();
    _fcmTokenRefreshSub?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    _auth.authStateChanges().listen(_onFirebaseAuthState);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_registerFcmForCurrentUser());
    }
  }

  Future<void> _onFirebaseAuthState(fb.User? user) async {
    if (user == null) {
      currentUser.value = null;
      return;
    }
    unawaited(_registerFcmForCurrentUser());
    // Restore Supabase user on cold start (returning user already signed in).
    if (currentUser.value == null) {
      try {
        final result = await SupabaseService.client
            .from('users')
            .select()
            .eq('uid', user.uid)
            .maybeSingle();
        if (result != null && result['isDeleted'] != true) {
          currentUser.value = UserModel.fromJson(result);
          unawaited(AffiliateProgramService.syncPendingAttribution());
        } else if (result?['isDeleted'] == true) {
          currentUser.value = null;
          await _auth.signOut();
        }
      } catch (e) {
        debugPrint('[AuthController] Failed to restore user from Supabase: $e');
      }
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      fb.UserCredential result;

      if (kIsWeb) {
        result = await _auth.signInWithPopup(fb.GoogleAuthProvider());
      } else {
        final googleUser = await _nativeGoogleSignIn.signIn();
        if (googleUser == null) return; // user cancelled

        final auth = await googleUser.authentication;
        final idToken = auth.idToken;
        if (idToken == null) {
          throw Exception('Google did not return an ID token.');
        }
        final credential = fb.GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: auth.accessToken,
        );
        result = await _auth.signInWithCredential(credential);
      }

      final user = result.user;
      if (user == null) {
        throw Exception('Google sign-in completed without a Firebase user.');
      }
      await _postAuthSetup(user);
    } on fb.FirebaseAuthException catch (e, stack) {
      _logFirebaseAuthException('Google sign-in', e, stack);
      AppSnackbar.show(
        'error'.tr,
        _googleErrorMessage(e),
        type: AppSnackbarType.error,
      );
    } catch (e) {
      debugPrint('[AuthController] Google sign-in error: $e');
      AppSnackbar.show('error'.tr, e.toString(), type: AppSnackbarType.error);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Sign in with Apple (iOS only) ────────────────────────────────────────

  Future<void> signInWithApple() async {
    if (!isAppleSignInAvailable) return;

    try {
      isLoading.value = true;
      final provider = fb.AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final result = await _auth.signInWithProvider(provider);
      final user = result.user;
      if (user == null) {
        throw Exception(
          'Sign in with Apple completed without a Firebase user.',
        );
      }
      await _postAuthSetup(user);
    } on fb.FirebaseAuthException catch (error, stack) {
      _logFirebaseAuthException('Sign in with Apple', error, stack);
      if (error.code != 'web-context-cancelled' &&
          error.code != 'canceled' &&
          error.code != 'cancelled') {
        AppSnackbar.show(
          'error'.tr,
          error.message ?? 'Sign in with Apple failed. Please try again.',
          type: AppSnackbarType.error,
        );
      }
    } catch (error) {
      debugPrint('[AuthController] Sign in with Apple error: $error');
      AppSnackbar.show(
        'error'.tr,
        error.toString(),
        type: AppSnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Phone Sign-In (2-step OTP) ────────────────────────────────────────────

  Future<void> sendPhoneOtp(
    String phoneNumber, {
    VoidCallback? onCodeSent,
    bool isResend = false,
  }) async {
    if (_phoneOtpRequestActive) return;

    try {
      FocusManager.instance.primaryFocus?.unfocus();
      _phoneOtpRequestActive = true;
      isLoading.value = true;
      _pendingPhone = phoneNumber;
      _webPhoneConfirmationResult = null;
      otpTimedOut.value = false;
      otpStatusMessage.value = '';

      if (kIsWeb) {
        final confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
        );
        _webPhoneConfirmationResult = confirmationResult;
        verificationId.value = confirmationResult.verificationId;
        _phoneOtpRequestActive = false;
        otpStatusMessage.value = 'Code sent. Please enter the 6-digit code.';
        resetOtpState();
        _startResendCountdown();
        onCodeSent?.call();
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (credential) async {
          // Auto-retrieved on Android — no OTP sheet interaction needed.
          if (!_phoneOtpRequestActive) return;
          try {
            final result = await _auth.signInWithCredential(credential);
            await _postAuthSetup(result.user!);
          } catch (e) {
            debugPrint('[AuthController] Auto-verification error: $e');
          } finally {
            _phoneOtpRequestActive = false;
          }
        },
        verificationFailed: (e) {
          if (!_phoneOtpRequestActive) return;
          _phoneOtpRequestActive = false;
          _logFirebaseAuthException('Phone OTP send callback', e);
          otpStatusMessage.value = _phoneErrorMessage(e);
          AppSnackbar.show(
            'error'.tr,
            _phoneErrorMessage(e),
            type: AppSnackbarType.error,
            duration: const Duration(seconds: 6),
          );
        },
        codeSent: (id, token) {
          if (!_phoneOtpRequestActive) return;
          _phoneOtpRequestActive = false;
          verificationId.value = id;
          _resendToken = token;
          otpTimedOut.value = false;
          otpStatusMessage.value = 'Code sent. Please enter the 6-digit code.';
          resetOtpState();
          _startResendCountdown();
          onCodeSent?.call();
        },
        codeAutoRetrievalTimeout: (_) {
          _phoneOtpRequestActive = false;
          otpTimedOut.value = true;
          otpStatusMessage.value =
              'Auto-detection timed out. Please enter the code manually or resend.';
          AppSnackbar.show(
            'Verification'.tr,
            otpStatusMessage.value,
            type: AppSnackbarType.warning,
            duration: const Duration(seconds: 5),
          );
        },
      );
    } on fb.FirebaseAuthException catch (e, stack) {
      _phoneOtpRequestActive = false;
      _logFirebaseAuthException('Phone OTP send', e, stack);
      otpStatusMessage.value = _phoneErrorMessage(e);
      AppSnackbar.show(
        'error'.tr,
        _phoneErrorMessage(e),
        type: AppSnackbarType.error,
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      _phoneOtpRequestActive = false;
      debugPrint('[AuthController] Phone OTP send error: $e');
      otpStatusMessage.value = 'Verification failed. Please try again.';
      AppSnackbar.show(
        'error'.tr,
        otpStatusMessage.value,
        type: AppSnackbarType.error,
      );
    } finally {
      if (kIsWeb) {
        _phoneOtpRequestActive = false;
      }
      isLoading.value = false;
    }
  }

  Future<void> resendPhoneOtp({VoidCallback? onCodeSent}) async {
    final phone = _pendingPhone;
    if (phone == null || isLoading.value || !canResendOtp) return;
    await sendPhoneOtp(phone, onCodeSent: onCodeSent, isResend: true);
  }

  String _phoneErrorMessage(fb.FirebaseAuthException e) {
    final msg = e.message ?? '';
    switch (e.code) {
      case 'billing-not-enabled':
        return 'SMS service is currently unavailable. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Your device is temporarily blocked. Try again in a few hours.';
      case 'invalid-phone-number':
        return 'The phone number is invalid. Please check and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'captcha-check-failed':
        return 'Security verification failed. Please try again.';
      case 'app-not-authorized':
        return 'This app is not authorized for phone sign-in.';
      case 'internal-error':
        return 'SMS verification is unavailable. Please check Firebase billing and SMS region settings.';
      case 'missing-phone-number':
        return 'Please enter a valid phone number.';
      default:
        if (msg.contains('BILLING_NOT_ENABLED')) {
          return 'SMS service is currently unavailable. Please contact support.';
        }
        if (msg.contains('blocked') || msg.contains('TOO_MANY')) {
          return 'Too many attempts. Please try again in a few hours.';
        }
        return msg.isNotEmpty ? msg : 'Verification failed. Please try again.';
    }
  }

  Future<void> verifyPhoneOtp(String smsCode) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      late final fb.UserCredential result;

      if (kIsWeb) {
        final confirmationResult = _webPhoneConfirmationResult;
        if (confirmationResult == null) {
          throw fb.FirebaseAuthException(
            code: 'session-expired',
            message: 'The session has expired. Please request a new code.',
          );
        }
        result = await confirmationResult.confirm(smsCode);
      } else {
        final credential = fb.PhoneAuthProvider.credential(
          verificationId: verificationId.value,
          smsCode: smsCode,
        );
        result = await _auth.signInWithCredential(credential);
      }

      await _postAuthSetup(result.user!);
      _webPhoneConfirmationResult = null;
    } on fb.FirebaseAuthException catch (e, stack) {
      _logFirebaseAuthException('Phone OTP verify', e, stack);
      resetOtpState();
      AppSnackbar.show(
        'error'.tr,
        _otpErrorMessage(e),
        type: AppSnackbarType.error,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('[AuthController] Phone OTP verify error: $e');
      resetOtpState();
      AppSnackbar.show(
        'error'.tr,
        'Verification failed. Please try again.',
        type: AppSnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _logFirebaseAuthException(
    String operation,
    fb.FirebaseAuthException e, [
    StackTrace? stack,
  ]) {
    debugPrint(
      '[AuthController] $operation FirebaseAuthException '
      'code=${e.code}, message=${e.message}, email=${e.email}, '
      'credential=${e.credential?.providerId}',
    );
    if (stack != null) {
      debugPrintStack(stackTrace: stack, label: '[AuthController] $operation');
    }
  }

  String _googleErrorMessage(fb.FirebaseAuthException e) {
    final msg = e.message ?? '';
    if (e.code == 'unauthorized-domain' || msg.contains('origin_mismatch')) {
      return 'This web origin is not authorized for Google sign-in.';
    }
    if (e.code == 'popup-closed-by-user') {
      return 'Google sign-in was cancelled.';
    }
    if (e.code == 'popup-blocked') {
      return 'The browser blocked the Google sign-in popup.';
    }
    return msg.isNotEmpty ? msg : 'Google sign-in failed. Please try again.';
  }

  String _otpErrorMessage(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'The code you entered is incorrect. Please try again.';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'The session has expired. Please request a new code.';
      default:
        return e.message ?? 'Verification failed. Please try again.';
    }
  }

  // ── Post-auth setup ───────────────────────────────────────────────────────

  /// Order matters: upsert user → sync cart → expose user.
  /// Setting [currentUser] last ensures CartController re-loads from Supabase
  /// only after the guest cart has already been synced. Notification token
  /// registration runs in the background so login never waits on OS prompts,
  /// APNs, or FCM token availability.
  Future<void> _postAuthSetup(fb.User firebaseUser) async {
    final model = await _upsertSupabaseUser(firebaseUser);
    await _syncGuestCart(model.id);
    currentUser.value = model;
    unawaited(AffiliateProgramService.syncPendingAttribution());
    unawaited(_registerFcmForCurrentUser());
    final openedPendingRoute = await DeepLinkService.to.openPendingAuthRoute();
    if (!openedPendingRoute && Get.currentRoute != Routes.home) {
      Get.offAllNamed(Routes.home);
    }
  }

  Future<UserModel> _upsertSupabaseUser(fb.User user) async {
    final existingData = await SupabaseService.client
        .from('users')
        .select()
        .eq('uid', user.uid)
        .maybeSingle();

    if (existingData != null) {
      if (existingData['isDeleted'] == true) {
        throw StateError(
          'This account has been deleted and cannot be restored.',
        );
      }
      final payload = <String, dynamic>{};

      final currentName = existingData['name'] as String?;
      if (user.displayName != null &&
          user.displayName!.isNotEmpty &&
          (currentName == null || currentName.isEmpty)) {
        payload['name'] = user.displayName;
      }

      final currentPhone = existingData['phone'] as String?;
      final newPhone = user.phoneNumber ?? _pendingPhone;
      if (newPhone != null &&
          newPhone.isNotEmpty &&
          (currentPhone == null || currentPhone.isEmpty)) {
        payload['phone'] = newPhone;
      }

      final currentEmail = existingData['email'] as String?;
      if (user.email != null &&
          user.email!.isNotEmpty &&
          (currentEmail == null || currentEmail.isEmpty)) {
        payload['email'] = user.email;
      }

      if (payload.isNotEmpty) {
        final result = await SupabaseService.client
            .from('users')
            .update(payload)
            .eq('uid', user.uid)
            .select()
            .single();
        return UserModel.fromJson(result);
      }

      return UserModel.fromJson(existingData);
    } else {
      final result = await SupabaseService.client
          .from('users')
          .insert({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'phone': user.phoneNumber ?? _pendingPhone ?? '',
            if (user.email != null) 'email': user.email,
          })
          .select()
          .single();
      return UserModel.fromJson(result);
    }
  }

  Future<void> _registerFcmToken(fb.User user) async {
    try {
      final messaging = FirebaseMessaging.instance;
      // Request notification permissions for iOS
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        unawaited(_requestNotificationDisplayPermissions());
        final hasApnsToken = await _waitForApnsTokenIfNeeded(
          messaging,
        ).timeout(const Duration(seconds: 11));
        if (!hasApnsToken) {
          _scheduleFcmRetry('APNs token not ready yet');
          return;
        }
        final token = await _getFcmTokenWithRetry(
          messaging,
        ).timeout(const Duration(seconds: 5));
        if (token == null) return;
        await _upsertDeviceToken(
          user.uid,
          token,
        ).timeout(const Duration(seconds: 8));
        _fcmRetryAttempts = 0;
        _hasScheduledFcmRetry = false;
        debugPrint('[AuthController] FCM token registered successfully');
      } else {
        debugPrint('[AuthController] Notification permissions not granted');
      }
    } catch (e) {
      final isApnsTokenPending = '$e'.contains('apns-token-not-set');
      if (isApnsTokenPending) {
        _scheduleFcmRetry('APNs token not ready yet');
        return;
      }
      debugPrint('[AuthController] Failed to register FCM token: $e');
    }
  }

  void _scheduleFcmRetry(String reason) {
    if (_hasScheduledFcmRetry) return;

    if (_fcmRetryAttempts >= _maxFcmRetryAttempts) {
      debugPrint(
        '[AuthController] $reason; stopped retrying. Check iOS APNs/Firebase setup.',
      );
      return;
    }

    _hasScheduledFcmRetry = true;
    _fcmRetryAttempts += 1;
    debugPrint(
      '[AuthController] $reason; retrying in 3 seconds '
      '($_fcmRetryAttempts/$_maxFcmRetryAttempts)',
    );
    Future<void>.delayed(const Duration(seconds: 3), () {
      _hasScheduledFcmRetry = false;
      if (_auth.currentUser != null && !_isRegisteringFcm) {
        unawaited(_registerFcmForCurrentUser());
      }
    });
  }

  Future<void> _requestNotificationDisplayPermissions() async {
    if (!Get.isRegistered<NotificationService>()) return;

    try {
      await NotificationService.to.requestDisplayPermissions();
    } catch (e) {
      debugPrint(
        '[AuthController] Notification display permission skipped: $e',
      );
    }
  }

  Future<void> _registerFcmForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null || _isRegisteringFcm) return;
    _isRegisteringFcm = true;
    try {
      await _registerFcmToken(user);
    } finally {
      _isRegisteringFcm = false;
    }
  }

  Future<void> _saveRefreshedFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;
    try {
      await _upsertDeviceToken(user.uid, token);
    } catch (e) {
      debugPrint('[AuthController] Failed to persist refreshed FCM token: $e');
    }
  }

  Future<void> _upsertDeviceToken(String uid, String token) async {
    final isArabic = Get.locale?.languageCode == 'ar';
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    await SupabaseService.client.from('device_tokens').upsert({
      'userID': uid,
      'fcmToken': token,
      'isAndroid': isAndroid,
      'isArabic': isArabic,
      'isActive': true,
      'lastSeen': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'fcmToken');
  }

  Future<void> _deactivateCurrentDeviceToken() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint(
            '[AuthController] Skipping device-token deactivation; APNs token is not available yet.',
          );
          return;
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await SupabaseService.client
          .from('device_tokens')
          .update({
            'isActive': false,
            'lastSeen': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('fcmToken', token);
    } catch (e) {
      debugPrint('[AuthController] Failed to deactivate device token: $e');
    }
  }

  Future<bool> _waitForApnsTokenIfNeeded(FirebaseMessaging messaging) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return true;

    const attempts = 20; // Wait up to 10 seconds (20 × 500ms)
    for (var i = 0; i < attempts; i++) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  Future<String?> _getFcmTokenWithRetry(FirebaseMessaging messaging) async {
    const attempts = 3;
    for (var i = 0; i < attempts; i++) {
      try {
        return await messaging.getToken();
      } catch (e) {
        final isApnsTokenPending =
            !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.iOS &&
            '$e'.contains('apns-token-not-set');

        if (!isApnsTokenPending || i == attempts - 1) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }
    return null;
  }

  /// Reads the local guest cart, upserts each item into the authenticated
  /// user's Supabase cart, then clears local storage.
  Future<void> _syncGuestCart(int userId) async {
    final rawList = _storage.read<List>(AppConstants.kGuestCart);
    final rawBundles = _storage.read<List>(AppConstants.kGuestBundleCart);
    if ((rawList == null || rawList.isEmpty) &&
        (rawBundles == null || rawBundles.isEmpty)) {
      return;
    }

    final client = SupabaseService.client;
    for (final raw in rawList ?? const []) {
      final item = Map<String, dynamic>.from(raw as Map);
      final itemPropertyId = item['itemPropertyId'] as int;
      final itemId = (item['itemId'] as num?)?.toInt() ?? itemPropertyId;
      final quantity = item['quantity'] as int;

      final existing = await client
          .from('cart')
          .select()
          .eq('userID', userId)
          .eq('propertyID', itemPropertyId)
          .maybeSingle();

      if (existing != null) {
        final currentQty = existing['quantity'] as int;
        await client
            .from('cart')
            .update({'quantity': currentQty + quantity})
            .eq('id', existing['id'] as Object);
      } else {
        await client.from('cart').insert({
          'userID': userId,
          'propertyID': itemPropertyId,
          'itemID': itemId,
          'quantity': quantity,
        });
      }
    }

    for (final raw in rawBundles ?? const []) {
      final entry = Map<String, dynamic>.from(raw as Map);
      final bundle = Map<String, dynamic>.from(entry['bundle'] as Map);
      final bundleId = (bundle['id'] as num?)?.toInt() ?? 0;
      final quantity = (entry['quantity'] as num?)?.toInt() ?? 0;
      if (bundleId <= 0 || quantity <= 0) continue;

      final existing = await client
          .from('cart')
          .select('id, quantity')
          .eq('userID', userId)
          .eq('bundleID', bundleId)
          .maybeSingle();
      if (existing == null) {
        await client.from('cart').insert({
          'userID': userId,
          'bundleID': bundleId,
          'quantity': quantity,
        });
      } else {
        final current = (existing['quantity'] as num?)?.toInt() ?? 0;
        await client
            .from('cart')
            .update({'quantity': current + quantity})
            .eq('id', existing['id'] as Object);
      }
    }
    await _storage.remove(AppConstants.kGuestCart);
    await _storage.remove(AppConstants.kGuestBundleCart);
  }

  // ── User Data management ──────────────────────────────────────────────────

  Future<void> updateName(String newName) async {
    final user = currentUser.value;
    if (user == null) return;
    try {
      final result = await SupabaseService.client
          .from('users')
          .update({'name': newName.trim()})
          .eq('id', user.id)
          .select()
          .single();
      currentUser.value = UserModel.fromJson(result);
    } catch (e) {
      debugPrint('[AuthController] updateName error: $e');
      AppSnackbar.show('error'.tr, e.toString(), type: AppSnackbarType.error);
    }
  }

  // ── Phone number management ───────────────────────────────────────────────

  /// Updates [phone] and/or [phoneTwo] in Supabase and refreshes [currentUser].
  Future<void> updatePhoneNumbers({String? phone, String? phoneTwo}) async {
    final user = currentUser.value;
    if (user == null) return;
    try {
      final payload = <String, dynamic>{};
      if (phone != null) payload['phone'] = phone;
      // Allow explicit empty string to clear phoneTwo
      payload['phoneTwo'] = (phoneTwo?.isEmpty ?? true) ? null : phoneTwo;

      final result = await SupabaseService.client
          .from('users')
          .update(payload)
          .eq('id', user.id)
          .select()
          .single();
      currentUser.value = UserModel.fromJson(result);
    } catch (e) {
      debugPrint('[AuthController] updatePhoneNumbers error: $e');
      AppSnackbar.show('error'.tr, e.toString(), type: AppSnackbarType.error);
    }
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _deactivateCurrentDeviceToken();
      if (!kIsWeb) {
        await _nativeGoogleSignIn.signOut();
      }
      await _auth.signOut();
      await SupabaseService.client.auth.signOut();
      currentUser.value = null;
      AffiliateProgramService.clearSessionCache();

      // Return to a safe default tab after logout.
      if (Get.isRegistered<NavController>()) {
        NavController.to.setIndex(0);
      }

      Get.offAllNamed(Routes.home);
    } catch (e) {
      debugPrint('[AuthController] Sign-out error: $e');
      AppSnackbar.show('error'.tr, e.toString(), type: AppSnackbarType.error);
    } finally {
      isLoading.value = false;
    }
  }

  /// Revokes Apple's authorization before deleting an Apple-backed account.
  ///
  /// Apple only returns a fresh authorization code after the native
  /// confirmation sheet, so this intentionally reauthenticates at deletion
  /// time. Other providers require no extra client-side revocation step.
  Future<void> revokeAppleTokenForAccountDeletion() async {
    if (!isAppleSignInAvailable) return;
    final user = _auth.currentUser;
    if (user == null ||
        !user.providerData.any((info) => info.providerId == 'apple.com')) {
      return;
    }

    final provider = fb.AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final credential = await _auth.signInWithProvider(provider);
    final authorizationCode = credential.additionalUserInfo?.authorizationCode;
    if (authorizationCode == null || authorizationCode.isEmpty) {
      throw StateError(
        'Apple could not verify this deletion request. Please try again.',
      );
    }
    await _auth.revokeTokenWithAuthorizationCode(authorizationCode);
  }

  /// Clears the device session after the server has irreversibly deleted it.
  Future<void> finishAccountDeletion() async {
    try {
      if (!kIsWeb) {
        await _nativeGoogleSignIn.signOut();
      }
    } catch (error) {
      debugPrint('[AuthController] Provider cleanup skipped: $error');
    }

    try {
      await _auth.signOut();
      await SupabaseService.client.auth.signOut();
    } finally {
      await _storage.remove(AppConstants.kGuestCart);
      await _storage.remove(AppConstants.kGuestBundleCart);
      currentUser.value = null;
      AffiliateProgramService.clearSessionCache();
      if (Get.isRegistered<NavController>()) {
        NavController.to.setIndex(0);
      }
      Get.offAllNamed(Routes.home);
    }
  }
}
