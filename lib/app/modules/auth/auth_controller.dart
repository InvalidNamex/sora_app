import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/services/supabase_service.dart';
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
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final _auth = fb.FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(
    serverClientId: AppConstants.googleWebClientId,
  );
  final _storage = GetStorage();

  final currentUser = Rxn<UserModel>();
  final isLoading = false.obs;
  final verificationId = ''.obs;
  final otpStatusMessage = ''.obs;
  final otpTimedOut = false.obs;
  final resendSecondsLeft = 0.obs;
  String? _pendingPhone;
  int? _resendToken;
  Timer? _resendTimer;

  /// Controllers and focus nodes shared with [PhoneOtpSheet].
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  void resetOtpState() {
    for (final c in otpControllers) c.clear();
  }

  bool get canResendOtp => resendSecondsLeft.value == 0 && _pendingPhone != null;

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
  void onClose() {
    _resendTimer?.cancel();
    for (final c in otpControllers) c.dispose();
    for (final f in otpFocusNodes) f.dispose();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    _auth.authStateChanges().listen(_onFirebaseAuthState);
  }

  Future<void> _onFirebaseAuthState(fb.User? user) async {
    if (user == null) {
      currentUser.value = null;
      return;
    }
    // Restore Supabase user on cold start (returning user already signed in).
    if (currentUser.value == null) {
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
        debugPrint('[AuthController] Failed to restore user from Supabase: $e');
      }
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final googleUser = await _googleSignIn.signIn();
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
      final result = await _auth.signInWithCredential(credential);
      await _postAuthSetup(result.user!);
    } catch (e) {
      debugPrint('[AuthController] Google sign-in error: $e');
      AppSnackbar.show(
        'error'.tr,
        e.toString(),
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
    try {
      isLoading.value = true;
      _pendingPhone = phoneNumber;
      otpTimedOut.value = false;
      otpStatusMessage.value = '';
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (credential) async {
          // Auto-retrieved on Android — no OTP sheet interaction needed.
          try {
            final result = await _auth.signInWithCredential(credential);
            await _postAuthSetup(result.user!);
          } catch (e) {
            debugPrint('[AuthController] Auto-verification error: $e');
          }
        },
        verificationFailed: (e) {
          otpStatusMessage.value = _phoneErrorMessage(e);
          AppSnackbar.show(
            'error'.tr,
            _phoneErrorMessage(e),
            type: AppSnackbarType.error,
            duration: const Duration(seconds: 6),
          );
        },
        codeSent: (id, token) {
          verificationId.value = id;
          _resendToken = token;
          otpTimedOut.value = false;
          otpStatusMessage.value = 'Code sent. Please enter the 6-digit code.';
          resetOtpState();
          _startResendCountdown();
          onCodeSent?.call();
        },
        codeAutoRetrievalTimeout: (_) {
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
    } finally {
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
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      await _postAuthSetup(result.user!);
    } on fb.FirebaseAuthException catch (e) {
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

  /// Order matters: upsert user → register FCM → sync cart → expose user.
  /// Setting [currentUser] last ensures CartController re-loads from Supabase
  /// only after the guest cart has already been synced.
  Future<void> _postAuthSetup(fb.User firebaseUser) async {
    final model = await _upsertSupabaseUser(firebaseUser);
    await _registerFcmToken(firebaseUser);
    await _syncGuestCart(model.id);
    currentUser.value = model;
    if (Get.currentRoute != Routes.home) {
      Get.offAllNamed(Routes.home);
    }
  }

  Future<UserModel> _upsertSupabaseUser(fb.User user) async {
    final result = await SupabaseService.client
        .from('users')
        .upsert(
          {
            'uid': user.uid,
            'name': user.displayName ?? '',
            'phone': user.phoneNumber ?? _pendingPhone ?? '',
            if (user.email != null) 'email': user.email,
          },
          onConflict: 'uid',
          ignoreDuplicates: false,
        )
        .select()
        .single();
    return UserModel.fromJson(result);
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
        final token = await messaging.getToken();
        if (token == null) return;
        await SupabaseService.client
            .from('users')
            .update({'fcmTokens': token}).eq('uid', user.uid);
      } else {
        debugPrint('[AuthController] Notification permissions not granted');
      }
    } catch (e) {
      debugPrint('[AuthController] Failed to register FCM token: $e');
    }
  }

  /// Reads the local guest cart, upserts each item into the authenticated
  /// user's Supabase cart, then clears local storage.
  Future<void> _syncGuestCart(int userId) async {
    final rawList = _storage.read<List>(AppConstants.kGuestCart);
    if (rawList == null || rawList.isEmpty) return;

    final client = SupabaseService.client;
    for (final item in rawList.cast<Map<String, dynamic>>()) {
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
    await _storage.remove(AppConstants.kGuestCart);
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
      AppSnackbar.show(
        'error'.tr,
        e.toString(),
        type: AppSnackbarType.error,
      );
    }
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _googleSignIn.signOut();
      await _auth.signOut();
      await SupabaseService.client.auth.signOut();
      currentUser.value = null;

      // Return to a safe default tab after logout.
      if (Get.isRegistered<NavController>()) {
        NavController.to.setIndex(0);
      }

      Get.offAllNamed(Routes.home);
    } catch (e) {
      debugPrint('[AuthController] Sign-out error: $e');
      AppSnackbar.show(
        'error'.tr,
        e.toString(),
        type: AppSnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
