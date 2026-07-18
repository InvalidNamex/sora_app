# Deep Linking Implementation Guide

Use this file as a compact implementation brief for deep linking in a Flutter app with:

- App Links / Universal Links using `https://www.example.com/...`.
- A custom URL scheme such as `myapp://item/123`.
- Web SPA route rewrites for Flutter web.
- Notification payloads that route through the same link handler.
- Pending protected routes that reopen after authentication.

This guide includes Sora fixes and patterns:

- Capture the initial app link early, but delay route navigation until the splash/router is ready.
- Store a pending protected route when auth guard redirects to login, then reopen it after auth.
- Use one `LinkNavigationService` for notification taps, in-app action URLs, and external fallback URLs.
- Serve `assetlinks.json` and `apple-app-site-association` with `application/json` content type.
- Add Vercel rewrites for every Flutter web route so direct links and refreshes load `index.html`.

## Packages

```yaml
dependencies:
  app_links: ^latest
  get: ^latest # or your router/state package
  get_storage_wasm: ^latest # optional for referral/affiliate persistence
  url_launcher: ^latest # external URL fallback
```

## Supported Link Shapes

Recommended contract:

```text
https://www.example.com/home
https://www.example.com/item/123
https://www.example.com/orders/456
https://www.example.com/ref/<firebase_uid_or_ref_code>

myapp://home
myapp://item/123
myapp://orders/456
myapp://ref/<firebase_uid_or_ref_code>

/home
/item/123
/orders/456
/ref/<firebase_uid_or_ref_code>
```

Notes:

- Relative paths are useful for notification payloads and in-app messages.
- `https` links are used for App Links, Universal Links, and web.
- Custom scheme is a fallback and is useful for internal actions.
- Use one parser for all variants.

## App Startup Order

Register the deep-link service before UI navigation begins.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebUrlStrategy(); // optional: remove # from Flutter web URLs
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppBinding.init(); // registers DeepLinkService
  runApp(const App());
}
```

Binding:

```dart
Get.put(DeepLinkService(), permanent: true);
Get.put(NotificationService(), permanent: true);
Get.put(AuthController(), permanent: true);
```

The order can vary, but all three must exist before notification taps/auth redirects rely on deep links.

## DeepLinkService Pattern

Responsibilities:

- Subscribe to `AppLinks().uriLinkStream`.
- Capture `getInitialLink()`.
- Keep `_pendingUri` until navigation is ready.
- Parse supported links and route to app pages.
- Persist referral links if needed.
- Expose `handleDeepLink(String?)` for notification/in-app-message payloads.
- Expose `openPendingAuthRoute()` for post-login route restoration.

Implementation skeleton:

```dart
class DeepLinkService extends GetxService {
  final _appLinks = AppLinks();
  final _storage = GetStorage();

  StreamSubscription<Uri>? _linkSubscription;
  Future<void>? _initialLinkCapture;
  Uri? _pendingUri;
  String? _pendingAuthRoute;
  bool _navigationReady = false;

  @override
  void onInit() {
    super.onInit();
    _initialLinkCapture = _captureInitialLink();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (Object e) => debugPrint('[DeepLinkService] stream error: $e'),
    );
  }

  Future<bool> openPendingLink() async {
    await _initialLinkCapture?.timeout(
      const Duration(milliseconds: 700),
      onTimeout: () => debugPrint('[DeepLinkService] initial link timeout'),
    );

    _navigationReady = true;
    final uri = _pendingUri;
    if (uri == null) return false;
    _pendingUri = null;
    return _routeUri(uri);
  }

  Future<bool> handleDeepLink(String? value) async {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    return handleUri(uri);
  }

  Future<bool> handleUri(Uri uri) async {
    if (!_navigationReady) {
      _pendingUri = uri;
      return true;
    }
    return _routeUri(uri);
  }
}
```

Call `openPendingLink()` from splash or the first controller that knows `GetMaterialApp` is ready:

```dart
final openedDeepLink = await DeepLinkService.to.openPendingLink();
if (!openedDeepLink) {
  Get.offAllNamed(Routes.home);
}
```

## URI Parsing

Support all three forms:

- Relative path: `/item/123`
- HTTPS app link: `https://www.example.com/item/123`
- Custom scheme: `myapp://item/123`

Parser:

```dart
bool _isSupportedUri(Uri uri) {
  if (!uri.hasScheme) return true;
  if (uri.scheme == 'myapp') return true;
  if (uri.scheme != 'https') return false;
  return uri.host == 'www.example.com';
}

List<String> _pathSegmentsFor(Uri uri) {
  if (uri.scheme == 'myapp' && uri.host.isNotEmpty) {
    return [uri.host, ...uri.pathSegments];
  }
  return uri.pathSegments;
}

int? _idFrom(List<String> segments, Uri uri) {
  final rawId = segments.length > 1 ? segments[1] : uri.queryParameters['id'];
  if (rawId == null) return null;
  final id = int.tryParse(rawId);
  return id != null && id > 0 ? id : null;
}
```

Route handling:

```dart
Future<bool> _routeUri(Uri uri) async {
  if (!_isSupportedUri(uri)) return false;

  final segments = _pathSegmentsFor(uri);
  if (segments.isEmpty) return false;

  switch (segments.first) {
    case 'home':
      await _openHome();
      return true;
    case 'item':
      final itemId = _idFrom(segments, uri);
      if (itemId == null) return false;
      await _openRoute(Routes.itemPath(itemId));
      return true;
    case 'orders':
      final orderId = _idFrom(segments, uri);
      if (orderId == null) return false;
      await _openRoute(Routes.orderDetailPath(orderId));
      return true;
    case 'ref':
      final uid = segments.length > 1 ? segments[1].trim() : '';
      if (uid.isEmpty) return false;
      await _storage.write(AppConstants.kActiveAffiliateId, uid);
      await _openHome();
      return true;
    default:
      return false;
  }
}
```

Navigation:

```dart
Future<void> _openHome() async {
  if (Get.isRegistered<NavController>()) {
    NavController.to.setIndex(0);
  }
  if (Get.currentRoute != Routes.home) {
    Get.offAllNamed(Routes.home);
  }
}

Future<void> _openRoute(String route) async {
  if (Get.currentRoute != Routes.home) {
    Get.offAllNamed(Routes.home);
    await Future<void>.delayed(Duration.zero);
  }
  await Get.toNamed(route);
}
```

Why Sora opens home first:

- The app shell/tab scaffold lives at `/home`.
- Detail pages are pushed above that shell.
- This avoids detail pages opening without the expected navigation scaffold.

## Auth Guard Integration

Protected route redirect:

```dart
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!AuthController.to.isLoggedIn) {
      if (route != null && route.isNotEmpty) {
        DeepLinkService.to.setPendingAuthRoute(route);
      }
      return const RouteSettings(name: Routes.auth);
    }
    return null;
  }
}
```

After login:

```dart
final openedPendingRoute = await DeepLinkService.to.openPendingAuthRoute();
if (!openedPendingRoute && Get.currentRoute != Routes.home) {
  Get.offAllNamed(Routes.home);
}
```

This preserves flows such as:

1. User taps `https://www.example.com/orders/456`.
2. App opens, route is protected.
3. App sends user to `/auth`.
4. After login, app opens `/orders/456`.

## LinkNavigationService

Use this as one entry point for notification taps and in-app action URLs.

```dart
class LinkNavigationService {
  static Future<bool> open(String? target) async {
    if (target == null || target.trim().isEmpty) return false;

    final value = target.trim();
    if (Get.isRegistered<DeepLinkService>() &&
        await DeepLinkService.to.handleDeepLink(value)) {
      return true;
    }

    final uri = Uri.tryParse(value);
    final isExternalWebUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isExternalWebUrl) {
      debugPrint('[LinkNavigationService] ignored target: $value');
      return false;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      debugPrint('[LinkNavigationService] could not open URL: $value');
    }
    return opened;
  }
}
```

Use it for:

- FCM `message.data['deep_link']`.
- Local notification payloads.
- In-app message action URLs.
- Admin-created campaign URLs.

## Android App Links

`android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop">

    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data
            android:scheme="https"
            android:host="www.example.com"/>
    </intent-filter>

    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="myapp"/>
    </intent-filter>
</activity>
```

`singleTop` helps route a new link into the existing Flutter activity instead of creating a duplicate stack.

Serve Digital Asset Links at:

```text
https://www.example.com/.well-known/assetlinks.json
```

Example:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.app",
      "sha256_cert_fingerprints": [
        "AA:BB:CC:..."
      ]
    }
  }
]
```

Developer must supply:

- Final Android package name.
- SHA-256 certificate fingerprint for the signing key used in the build being tested.
- Separate fingerprints for debug, upload, and Play App Signing if needed.

Test:

```bash
adb shell am start -a android.intent.action.VIEW \
  -c android.intent.category.BROWSABLE \
  -d "https://www.example.com/item/123"
```

## iOS Universal Links

Entitlements:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:www.example.com</string>
</array>
```

Serve Apple App Site Association at:

```text
https://www.example.com/.well-known/apple-app-site-association
```

No `.json` extension.

Example:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["<APPLE_TEAM_ID>.<BUNDLE_ID>"],
        "components": [
          { "/": "/item/*" },
          { "/": "/orders/*" },
          { "/": "/ref/*" },
          { "/": "/home" }
        ]
      }
    ]
  }
}
```

Developer must supply:

- Apple Team ID.
- Final iOS bundle ID.
- Associated Domains capability in Apple Developer and Xcode.
- Provisioning profile regenerated after enabling the capability.

Custom scheme in `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.example.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

If Firebase Auth/Google sign-in also uses URL schemes, include both the Google reversed client ID scheme and the app custom scheme. Make sure Firebase Auth gets a chance to handle its callback in `AppDelegate`/`SceneDelegate` before generic deep-link handling.

Test:

```bash
xcrun simctl openurl booted "myapp://item/123"
```

Universal links must be tested from a real tap context such as Notes, Messages, Safari, or an email. Pasting into Safari can open the website instead of the app.

## Flutter Deep Linking Handler Note

When using a plugin such as `app_links`, check the current Flutter and plugin docs. In some setups, you may need to disable Flutter's built-in deep link handling to avoid duplicate delivery:

```xml
<key>FlutterDeepLinkingEnabled</key>
<false/>
```

Add this only if your plugin/framework recommends it or you observe duplicate initial links.

## Web SPA Setup

Use path URL strategy if you want clean URLs:

```dart
void configureWebUrlStrategy() {
  if (kIsWeb) {
    usePathUrlStrategy();
  }
}
```

Then configure hosting rewrites so direct links and refreshes load Flutter `index.html`.

Vercel example:

```json
{
  "framework": null,
  "buildCommand": null,
  "installCommand": null,
  "outputDirectory": ".",
  "headers": [
    {
      "source": "/.well-known/assetlinks.json",
      "headers": [
        {
          "key": "Content-Type",
          "value": "application/json; charset=utf-8"
        }
      ]
    },
    {
      "source": "/.well-known/apple-app-site-association",
      "headers": [
        {
          "key": "Content-Type",
          "value": "application/json; charset=utf-8"
        }
      ]
    }
  ],
  "rewrites": [
    { "source": "/home", "destination": "/index.html" },
    { "source": "/item", "destination": "/index.html" },
    { "source": "/item/:path*", "destination": "/index.html" },
    { "source": "/orders/:path*", "destination": "/index.html" },
    { "source": "/ref/:path*", "destination": "/index.html" },
    { "source": "/auth", "destination": "/index.html" }
  ]
}
```

Deployment trap from Sora:

- Check that the real custom domain points to the deployment/project you just updated:

```bash
vercel inspect www.example.com
```

If the custom domain points to another Vercel project, your fixed build will not be visible on production.

## Notification Integration

Send links as data payload:

```json
{
  "deep_link": "/item/123",
  "item_id": "123"
}
```

On tap:

```dart
await LinkNavigationService.open(message.data['deep_link'] as String?);
```

This is better than directly calling `Get.toNamed` inside notification code because:

- The same parser handles relative, custom-scheme, and HTTPS links.
- Unsupported HTTP URLs can fall back to external browser.
- Auth-protected routes can preserve pending destination.

## Referral/Affiliate Links

Sora pattern:

- Affiliate share URL is `https://www.example.com/ref/<affiliate_code>`.
- Product share URL is
  `https://www.example.com/item/<item_id>?ref=<affiliate_code>`.
- DeepLinkService stores the public code locally:

```dart
await AffiliateProgramService.captureLinkCode(code, itemId: itemId);
await _openHome();
```

- A Firebase-verified backend resolves the code to an active affiliate, persists
  cross-device attribution, and snapshots the affiliate on the order.

Important:

- Treat referral codes as public.
- Validate/resolve server-side before applying rewards.
- Do not trust client-provided user roles or payout information.

## Developer Setup That Code Cannot Do

Domain/hosting:

- Buy/configure domain.
- Point DNS to hosting provider.
- Serve HTTPS.
- Serve `.well-known/assetlinks.json`.
- Serve `.well-known/apple-app-site-association` with no extension and JSON content type.
- Configure SPA rewrites.

Android:

- Decide final package name.
- Generate signing key.
- Get SHA-256 fingerprints for debug/release/upload/Play signing.
- Put correct fingerprints in `assetlinks.json`.
- Publish/update app build that uses the same package and signing key.

iOS:

- Decide final bundle ID.
- Get Apple Team ID.
- Enable Associated Domains in Apple Developer.
- Add Associated Domains capability in Xcode.
- Regenerate provisioning profiles.
- Put `<TEAM_ID>.<BUNDLE_ID>` in AASA.

Firebase/Google auth interaction:

- If custom schemes overlap with Firebase Auth callback schemes, ensure `Auth.auth().canHandle(url)` gets first chance.
- Add Google reversed client ID scheme for native Google sign-in.

## Debugging Matrix

Universal link opens website instead of app:

- App not installed, or entitlement/provisioning missing.
- AASA not reachable over HTTPS.
- AASA has wrong Team ID/bundle ID.
- AASA content type wrong.
- Path not included in AASA components.
- iOS cache is stale. Reinstall app or wait; sometimes toggling Associated Domains/build helps.

Android app link opens browser:

- `assetlinks.json` unreachable or invalid.
- SHA-256 fingerprint mismatch.
- Package name mismatch.
- `android:autoVerify="true"` missing.
- User changed default opening behavior in Android settings.

Custom scheme not opening:

- Scheme missing from Android intent filter or iOS `CFBundleURLTypes`.
- Testing URL shape wrong: `myapp://item/123` means `host=item`, path segment `123`.
- Parser must treat custom scheme host as first route segment.

Web direct URL 404:

- Missing hosting rewrite to `index.html`.
- Build deployed to wrong Vercel/Firebase Hosting project.
- Path URL strategy enabled but hosting not configured.

Notification tap ignored:

- Payload key mismatch. Use `deep_link`.
- Link parser does not support the route.
- DeepLinkService not registered before NotificationService handles initial message.
- App tried to navigate before router/splash ready. Use pending URI.

Protected route loses destination after login:

- Auth guard must call `setPendingAuthRoute(route)`.
- Post-auth setup must call `openPendingAuthRoute()` before default home redirect.

## Verification Checklist

Local parser tests:

- `/item/123` -> item 123
- `https://www.example.com/item/123` -> item 123
- `myapp://item/123` -> item 123
- `/orders/456` -> order 456, auth-protected if needed
- `/ref/abc` -> stores referral and opens home
- unsupported host returns false

Platform tests:

```bash
adb shell am start -a android.intent.action.VIEW \
  -c android.intent.category.BROWSABLE \
  -d "https://www.example.com/item/123"

xcrun simctl openurl booted "myapp://item/123"
```

Production tests:

- Visit `https://www.example.com/.well-known/assetlinks.json`.
- Visit `https://www.example.com/.well-known/apple-app-site-association`.
- Refresh `https://www.example.com/item/123` in browser.
- Tap universal link from Notes/Messages on iOS.
- Tap Android app link from browser/search/message.
- Send notification with `deep_link: /item/123` and tap it.
- Tap protected `/orders/456` while logged out, then verify post-login route restoration.

## Official References

- app_links package: https://pub.dev/packages/app_links
- Android App Links: https://developer.android.com/training/app-links
- Digital Asset Links: https://developers.google.com/digital-asset-links
- Apple Universal Links: https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app
- Flutter web URL strategies: https://docs.flutter.dev/ui/navigation/url-strategies
- Vercel rewrites: https://vercel.com/docs/rewrites
