# Authentication Implementation Guide

Use this file as a compact implementation brief for Firebase Authentication in a Flutter app with:

- Google sign-in on iOS, Android, and web.
- Phone OTP on iOS, Android, and web.
- Firebase user state synced into an app database such as Supabase.
- Optional Supabase Edge Functions that trust Firebase ID tokens for admin actions.

This guide is based on the Sora setup and includes the fixes that solved real issues:

- iOS phone auth returned `internal-error` after CAPTCHA until APNs, background remote notifications, and Firebase Auth notification handling were correctly wired.
- Web Google auth failed with `origin_mismatch` until exact web origins were added in Google Cloud and Firebase Auth.
- Web Google auth then failed with People API disabled because `google_sign_in` was still initialized/touched on web. Fix: use `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` on web and keep `google_sign_in` native-only/lazy.
- Web phone auth failed because native `verifyPhoneNumber` flow was used on web. Fix: use `FirebaseAuth.signInWithPhoneNumber()` and store `ConfirmationResult`.

## Packages

Add:

```yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  firebase_messaging: ^latest # needed for iOS APNs plumbing and notification token sync
  google_sign_in: ^latest
  get: ^latest # or your state/router package
  get_storage_wasm: ^latest # optional local storage
  supabase_flutter: ^latest # optional app database/backend
```

Generate Firebase options:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Expected generated/platform files:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist` if macOS is supported

## App Startup

Initialize Firebase before creating auth controllers or services.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await SupabaseService.init(); // optional
  AppBinding.init(); // register AuthController permanently
  runApp(const App());
}
```

Keep `AuthController` permanent/long-lived so it can listen to Firebase auth state and token refreshes:

```dart
Get.put(AuthController(), permanent: true);
```

## Constants

Keep OAuth client IDs and domains in one place.

```dart
class AppConstants {
  static const String baseDomain = 'https://www.example.com/';
  static const String googleWebClientId =
      '<WEB_CLIENT_ID>.apps.googleusercontent.com';
}
```

The web client ID is the OAuth client of type "Web application", not the iOS or Android client.

## Auth Controller Pattern

Core state:

```dart
final _auth = FirebaseAuth.instance;
GoogleSignIn? _googleSignIn; // lazy and native-only
ConfirmationResult? _webPhoneConfirmationResult;
String? _pendingPhone;
int? _resendToken;
bool _phoneOtpRequestActive = false;

GoogleSignIn get _nativeGoogleSignIn =>
    _googleSignIn ??= GoogleSignIn(
      serverClientId: AppConstants.googleWebClientId,
    );
```

Important fix: do not create or use `GoogleSignIn` on web. In Sora, web sign-in reached `content-people.googleapis.com` and failed with `People API has not been used...` because `google_sign_in` was still in the web path. Firebase Auth popup does not need that extra People API call.

### Google Sign-In

Use Firebase Auth popup on web. Use `google_sign_in` only on native platforms.

```dart
Future<void> signInWithGoogle() async {
  try {
    isLoading.value = true;
    late final UserCredential result;

    if (kIsWeb) {
      result = await FirebaseAuth.instance.signInWithPopup(
        GoogleAuthProvider(),
      );
    } else {
      final googleUser = await _nativeGoogleSignIn.signIn();
      if (googleUser == null) return;

      final auth = await googleUser.authentication;
      if (auth.idToken == null) {
        throw Exception('Google did not return an ID token.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      result = await FirebaseAuth.instance.signInWithCredential(credential);
    }

    final user = result.user;
    if (user == null) {
      throw Exception('Google sign-in completed without a Firebase user.');
    }
    await _postAuthSetup(user);
  } on FirebaseAuthException catch (e, stack) {
    _logFirebaseAuthException('Google sign-in', e, stack);
    showError(_googleErrorMessage(e));
  } finally {
    isLoading.value = false;
  }
}
```

Error messages:

```dart
String _googleErrorMessage(FirebaseAuthException e) {
  final msg = e.message ?? '';
  if (e.code == 'unauthorized-domain' || msg.contains('origin_mismatch')) {
    return 'This web origin is not authorized for Google sign-in.';
  }
  if (e.code == 'popup-closed-by-user') return 'Google sign-in was cancelled.';
  if (e.code == 'popup-blocked') {
    return 'The browser blocked the Google sign-in popup.';
  }
  return msg.isNotEmpty ? msg : 'Google sign-in failed. Please try again.';
}
```

Sign out:

```dart
if (!kIsWeb) {
  await _nativeGoogleSignIn.signOut();
}
await FirebaseAuth.instance.signOut();
await SupabaseService.client.auth.signOut(); // optional
```

## Phone OTP

Use different APIs for web and native.

### Send OTP

```dart
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

    if (kIsWeb) {
      final confirmationResult =
          await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
      _webPhoneConfirmationResult = confirmationResult;
      verificationId.value = confirmationResult.verificationId;
      _phoneOtpRequestActive = false;
      startResendCountdown();
      onCodeSent?.call();
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: isResend ? _resendToken : null,
      verificationCompleted: (credential) async {
        if (!_phoneOtpRequestActive) return;
        try {
          final result =
              await FirebaseAuth.instance.signInWithCredential(credential);
          await _postAuthSetup(result.user!);
        } finally {
          _phoneOtpRequestActive = false;
        }
      },
      verificationFailed: (e) {
        if (!_phoneOtpRequestActive) return;
        _phoneOtpRequestActive = false;
        _logFirebaseAuthException('Phone OTP send callback', e);
        showError(_phoneErrorMessage(e));
      },
      codeSent: (id, token) {
        if (!_phoneOtpRequestActive) return;
        _phoneOtpRequestActive = false;
        verificationId.value = id;
        _resendToken = token;
        startResendCountdown();
        onCodeSent?.call();
      },
      codeAutoRetrievalTimeout: (_) {
        _phoneOtpRequestActive = false;
        showWarning('Auto-detection timed out. Enter the code manually.');
      },
    );
  } on FirebaseAuthException catch (e, stack) {
    _phoneOtpRequestActive = false;
    _logFirebaseAuthException('Phone OTP send', e, stack);
    showError(_phoneErrorMessage(e));
  } finally {
    if (kIsWeb) _phoneOtpRequestActive = false;
    isLoading.value = false;
  }
}
```

Why this matters:

- Native uses `verifyPhoneNumber` with callbacks.
- Web uses `signInWithPhoneNumber`, shows Firebase reCAPTCHA/app verifier, and returns a `ConfirmationResult`.
- Guard with `_phoneOtpRequestActive` to avoid repeated callbacks and multiple snackbar spam.
- Unfocus the phone field before iOS CAPTCHA/OTP flow. This avoids keyboard/session glitches such as `RTIInputSystemClient ... requires a valid sessionID`.

### Verify OTP

```dart
Future<void> verifyPhoneOtp(String smsCode) async {
  try {
    isLoading.value = true;
    late final UserCredential result;

    if (kIsWeb) {
      final confirmationResult = _webPhoneConfirmationResult;
      if (confirmationResult == null) {
        throw FirebaseAuthException(
          code: 'session-expired',
          message: 'The session has expired. Please request a new code.',
        );
      }
      result = await confirmationResult.confirm(smsCode);
    } else {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );
      result = await FirebaseAuth.instance.signInWithCredential(credential);
    }

    await _postAuthSetup(result.user!);
    _webPhoneConfirmationResult = null;
  } on FirebaseAuthException catch (e, stack) {
    _logFirebaseAuthException('Phone OTP verify', e, stack);
    showError(_otpErrorMessage(e));
  } finally {
    isLoading.value = false;
  }
}
```

Phone error mapping:

```dart
String _phoneErrorMessage(FirebaseAuthException e) {
  final msg = e.message ?? '';
  switch (e.code) {
    case 'billing-not-enabled':
      return 'SMS service is currently unavailable. Please contact support.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    case 'invalid-phone-number':
      return 'The phone number is invalid.';
    case 'quota-exceeded':
      return 'SMS quota exceeded. Try again later.';
    case 'captcha-check-failed':
      return 'Security verification failed. Please try again.';
    case 'app-not-authorized':
      return 'This app is not authorized for phone sign-in.';
    case 'internal-error':
      return 'SMS verification is unavailable. Check Firebase billing and SMS region settings.';
    case 'missing-phone-number':
      return 'Please enter a valid phone number.';
    default:
      if (msg.contains('BILLING_NOT_ENABLED')) {
        return 'SMS service is currently unavailable. Please contact support.';
      }
      return msg.isNotEmpty ? msg : 'Verification failed. Please try again.';
  }
}
```

## OTP UI

Recommended behavior:

- Use a 6-box OTP UI.
- First box has `AutofillHints.oneTimeCode`.
- First box allows more than one digit so iOS QuickType/paste can drop the full code there.
- Distribute pasted/autofilled code across all six boxes and auto-submit.
- Backspace moves to previous box.
- Add resend cooldown.

Phone normalization example for Egypt:

```dart
// UI accepts 01xxxxxxxxx, sends +2 + local number.
controller.sendPhoneOtp('+2$phone');
```

Adjust country formatting per project.

## iOS Setup for Google and Phone Auth

### Info.plist

Add Google reversed client ID scheme and app custom scheme.

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.<IOS_REVERSED_CLIENT_ID></string>
    </array>
  </dict>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string><BUNDLE_ID></string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string><CUSTOM_SCHEME></string>
    </array>
  </dict>
</array>
```

Add background modes if you implement `didReceiveRemoteNotification:fetchCompletionHandler` and for Firebase Auth silent APNs verification:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

Without `remote-notification`, iOS logs:

```text
You've implemented application:didReceiveRemoteNotification:fetchCompletionHandler:,
but you still need to add "remote-notification" to UIBackgroundModes.
```

### AppDelegate.swift

Pass APNs token to both Firebase Messaging and Firebase Auth, let Firebase Auth consume its silent notification, and let Firebase Auth consume URL callbacks.

```swift
import Flutter
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
#if DEBUG
    FirebaseConfiguration.shared.setLoggerLevel(.debug)
#endif
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    NSLog("[Auth] APNs token registered and passed to Firebase Auth.")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[Auth] Failed to register APNs token: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification notification: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(notification) {
      NSLog("[Auth] Firebase Auth handled remote notification.")
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: notification,
      fetchCompletionHandler: completionHandler
    )
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      NSLog("[Auth] Firebase Auth handled URL callback: \(url.scheme ?? "no-scheme")")
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
```

### SceneDelegate.swift

If the app uses scenes, also pass scene URL callbacks to Firebase Auth.

```swift
import Flutter
import FirebaseAuth
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      if Auth.auth().canHandle(context.url) {
        NSLog("[Auth] Firebase Auth handled scene URL callback.")
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
```

Expected successful iOS phone-auth diagnostic:

```text
[Auth] Firebase Auth handled remote notification.
```

If this log appears and Firebase still returns `internal-error`, the app/APNs plumbing is probably correct and the remaining cause is server-side SMS configuration: billing, SMS region policy, quota, or abuse prevention.

## Android Setup

Use the Android package name registered in Firebase.

Checklist:

- Add `android/app/google-services.json`.
- Add SHA-1 and SHA-256 fingerprints in Firebase project settings.
- Enable Google provider and Phone provider in Firebase Auth.
- Use `google-services` Gradle plugin per FlutterFire setup.
- Android automatic SMS retrieval depends on Play Services and SMS format; always support manual OTP entry too.

## Web Setup

Required:

- `lib/firebase_options.dart` web entry with `apiKey`, `appId`, `projectId`, `authDomain`.
- Web OAuth client ID in constants or `web/index.html` meta if any package needs it.
- Use `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` for Google.
- Use `FirebaseAuth.signInWithPhoneNumber(phone)` and `ConfirmationResult.confirm(code)` for Phone.
- Do not initialize/use `google_sign_in` on web unless you intentionally enable the People API and accept that dependency.

Origin rules:

- Google Cloud OAuth "Authorized JavaScript origins" require exact origins.
- Include scheme and host, no path, no trailing slash.
- Add every origin you test from:
  - `http://localhost:<port>`
  - `https://www.example.com`
  - `https://example.com`
  - Vercel preview/production aliases if you test them
- Firebase Auth "Authorized domains" use domains only, without `https://`.

Deployment trap from Sora:

- We deployed a fixed build to Vercel project `web`, but the real domain `www.sora-eg.store` pointed to Vercel project `sora`.
- Always inspect the custom domain after deploy:

```bash
vercel inspect www.example.com
```

Confirm the custom domain aliases the new deployment, not an old project.

## Supabase Sync

Common model:

- Firebase is the identity provider.
- `users.uid` stores `FirebaseAuth.currentUser.uid`.
- App-specific roles live in Supabase `users` table, for example `isAdmin`, `isAffiliate`.
- On auth state restore, load Supabase row by Firebase UID.
- On first login, insert the Supabase user row.
- On repeated login, fill missing name, phone, or email without overwriting user-edited values.

Example post-auth sequence:

```dart
Future<void> _postAuthSetup(User firebaseUser) async {
  final model = await _upsertSupabaseUser(firebaseUser);
  await _syncGuestCart(model.id);
  currentUser.value = model;
  unawaited(_registerFcmForCurrentUser());
  final openedPendingRoute = await DeepLinkService.to.openPendingAuthRoute();
  if (!openedPendingRoute) {
    Get.offAllNamed(Routes.home);
  }
}
```

For Supabase RLS with Firebase JWTs:

- Configure Supabase Third-Party Auth Provider for Firebase.
- Ensure RLS policies trust the Firebase JWT claims you expect.
- In future apps, strongly consider initializing Supabase with an `accessToken` callback that returns `FirebaseAuth.instance.currentUser?.getIdToken()`, if using Supabase RLS directly from the client.
- For Edge Functions, pass Firebase ID token manually:

```dart
final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
await SupabaseService.client.functions.invoke(
  'function-name',
  headers: {'Authorization': 'Bearer $idToken'},
  body: payload,
);
```

Then verify the Firebase token with Firebase Admin SDK inside the function and check `users.isAdmin`.

## Developer Console Work That Code Cannot Do

Firebase project:

- Create/register Android, iOS, web apps.
- Download and add `google-services.json` and `GoogleService-Info.plist`.
- Enable Authentication providers:
  - Google
  - Phone
- Configure OAuth consent screen and authorized domains.
- Add SHA-1/SHA-256 for Android.
- Add iOS bundle ID exactly matching Xcode.
- Upload APNs auth key `.p8` for iOS phone auth/FCM:
  - Apple Team ID
  - Key ID
  - `.p8` file from Apple Developer
- Link Cloud Billing / Blaze if using real SMS.
- Configure SMS region policy and allow target countries.
- Add fictional test phone numbers for development.

Google Cloud OAuth:

- Edit the web OAuth client.
- Add exact Authorized JavaScript origins.
- If using native `google_sign_in` on web or any People API profile call, enable People API. Prefer avoiding this by using Firebase Auth popup on web.

Supabase:

- Configure Third-Party Auth Provider for Firebase if RLS/functions trust Firebase JWTs.
- Add RLS policies and tables.
- Add Edge Function secrets if using Firebase Admin:
  - `FIREBASE_PROJECT_ID`
  - `FIREBASE_CLIENT_EMAIL`
  - `FIREBASE_PRIVATE_KEY` with newlines escaped as `\n`
  - service role key is provided by Supabase but must be available to functions

Apple Developer:

- Create APNs Auth Key `.p8`.
- Enable Push Notifications capability.
- Enable Associated Domains if using universal links.
- Ensure provisioning profiles contain those capabilities.

## Debugging Matrix

`origin_mismatch` on web Google:

- Add exact origin in Google Cloud OAuth client.
- Add domain in Firebase Auth authorized domains.
- Confirm the deployed custom domain points to the new Vercel project.

`People API has not been used...` after Google account selection:

- Web path is still touching `google_sign_in` or a profile API.
- Fix by using `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` on web and making `GoogleSignIn` lazy/native-only.
- Alternative: enable People API in Google Cloud, but this is unnecessary for Firebase web popup.

iOS phone `internal-error` after CAPTCHA:

- Check native logs.
- If Firebase Auth did not handle remote notification:
  - APNs key/cert missing in Firebase.
  - Push Notifications capability missing.
  - `UIBackgroundModes` missing `remote-notification`.
  - APNs token not passed to `Auth.auth().setAPNSToken`.
  - `Auth.auth().canHandleNotification(notification)` not called.
- If Firebase Auth did handle remote notification:
  - Check Firebase billing/Blaze.
  - Check SMS region policy.
  - Check Phone provider enabled.
  - Check quotas and abuse prevention.
  - Test with a Firebase fictional phone number.

Phone web reCAPTCHA problems:

- Ensure domain is in Firebase Auth authorized domains.
- Use supported browsers.
- Do not call native `verifyPhoneNumber` path on web.

APNs token not set / FCM token fails after login:

- Request notification permissions.
- Wait for APNs token before calling `FirebaseMessaging.getToken()` on iOS.
- Retry briefly after app resume.

## Verification Checklist

Code:

```bash
dart format lib/app/modules/auth/auth_controller.dart
flutter analyze lib/app/modules/auth/auth_controller.dart
flutter build web --release
flutter build ios --debug --no-codesign
```

Manual:

- iOS Google sign-in returns to app.
- iOS phone OTP reaches `codeSent` or fictional number works.
- Web Google sign-in works on exact production domain.
- Web phone OTP opens reCAPTCHA/security check and verifies with `ConfirmationResult`.
- Sign-out works on web and native.
- Auth state restores after app restart.
- Supabase user row is created/restored.
- Protected route visited before login opens after successful auth.

## Official References

- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- Firebase Auth Flutter: https://firebase.google.com/docs/auth/flutter/start
- Firebase Auth web phone: https://firebase.google.com/docs/auth/web/phone-auth
- Firebase Auth iOS phone: https://firebase.google.com/docs/auth/ios/phone-auth
- Firebase Auth limits: https://firebase.google.com/docs/auth/limits
- Firebase FAQ for SMS billing changes: https://firebase.google.com/support/faq
- Google OAuth origin mismatch: https://developers.google.com/identity/protocols/oauth2/javascript-implicit-flow#authorization-errors-origin-mismatch
- Supabase Firebase third-party auth: https://supabase.com/docs/guides/auth/third-party/firebase-auth
