# Notifications Implementation Guide

Use this file as a compact implementation brief for Firebase Cloud Messaging in a Flutter app with:

- FCM registration on iOS and Android.
- Local foreground notification display.
- Notification tap routing through app deep links.
- Device token persistence in Supabase.
- Admin-created notification jobs processed by a Supabase Edge Function using Firebase Admin SDK.

This guide includes Sora fixes:

- Avoid duplicate foreground notifications on iOS/macOS by letting native FCM foreground presentation handle iOS/macOS and showing local notifications only on Android.
- On iOS, wait for APNs token before calling `FirebaseMessaging.getToken()`.
- Pass APNs token to both Firebase Messaging and Firebase Auth when phone auth and notifications coexist.
- Add `remote-notification` background mode because `didReceiveRemoteNotification:fetchCompletionHandler` is implemented.
- Log foreground `dataKeys` to debug payload/deep-link issues.
- For in-app top banners, do not rely only on Supabase Realtime. Add a foreground polling fallback and refresh immediately after publishing.
- Deploy the in-app message admin Edge Function whenever new message types such as `banner` are added, because the backend validator can reject types that the UI already shows.

## Packages

```yaml
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest
  flutter_local_notifications: ^latest
  get: ^latest
  supabase_flutter: ^latest # optional backend/token table
  url_launcher: ^latest # optional external fallback
```

## Startup

Register the background handler before `runApp` and only on non-web unless web push is implemented separately.

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  AppBinding.init(); // includes NotificationService
  runApp(const App());
}
```

Register the notification service as a permanent app service:

```dart
Get.put(NotificationService(), permanent: true);
```

## Notification Service Responsibilities

The client service should:

- Initialize `flutter_local_notifications`.
- Create an Android notification channel.
- Configure iOS/macOS foreground presentation.
- Handle app launched from notification.
- Handle taps while app is backgrounded.
- Handle foreground messages.
- Route `message.data['deep_link']` through the deep-link router.
- Avoid doing token registration here if AuthController needs to associate token with the signed-in user.

## Foreground Display

Use local notifications for Android foreground messages. Skip local notification display on iOS/macOS to avoid duplicates when `setForegroundNotificationPresentationOptions(alert: true, ...)` is active.

```dart
Future<void> _showForegroundNotification(RemoteMessage message) async {
  debugPrint(
    '[NotificationService] Foreground message received: '
    '${message.messageId ?? 'no-message-id'} '
    'dataKeys=${message.data.keys.join(',')}',
  );

  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return;
  }

  final title = message.notification?.title ?? _stringData(message, 'title');
  final body = message.notification?.body ?? _stringData(message, 'body');
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

  await _localNotifications.show(
    _notificationId(message),
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance',
        'App notifications',
        channelDescription: 'Important app updates.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: jsonEncode(message.data),
  );
}
```

Why:

- Android does not show notification UI for foreground FCM messages by default.
- iOS can show foreground notifications natively when presentation options are set.
- Showing a local iOS notification on top of native presentation can produce duplicates.

## Tap Handling

Payload contract:

```json
{
  "deep_link": "/item/123",
  "item_id": "123"
}
```

Implementation:

```dart
final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  await _handleRemoteMessageTap(initialMessage);
}

_openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
  (message) => unawaited(_handleRemoteMessageTap(message)),
);

Future<void> _handleRemoteMessageTap(RemoteMessage message) async {
  await LinkNavigationService.open(message.data['deep_link'] as String?);
}

void _handleLocalNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    unawaited(LinkNavigationService.open(data['deep_link'] as String?));
  } catch (e) {
    debugPrint('[NotificationService] local payload parse error: $e');
  }
}
```

## Permissions

Do not force notification permissions on app startup unless the product requires it. Sora requests display permissions after auth when registering the token.

```dart
final settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

final allowed =
    settings.authorizationStatus == AuthorizationStatus.authorized ||
    settings.authorizationStatus == AuthorizationStatus.provisional;
```

Android 13 and later requires:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Then call:

```dart
await _localNotifications
    .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >()
    ?.requestNotificationsPermission();
```

iOS local notification permission:

```dart
await _localNotifications
    .resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin
    >()
    ?.requestPermissions(alert: true, badge: true, sound: true);
```

## iOS APNs and AppDelegate

If the app uses iOS phone auth and FCM, pass the APNs token to both systems.

```swift
override func application(
  _ application: UIApplication,
  didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
  Messaging.messaging().apnsToken = deviceToken
  Auth.auth().setAPNSToken(deviceToken, type: .unknown)
  NSLog("[Notifications] APNs token registered.")
  super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
}
```

Call `application.registerForRemoteNotifications()` in `didFinishLaunchingWithOptions`.

If you implement `didReceiveRemoteNotification:fetchCompletionHandler`, include:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

If Firebase Auth phone verification is also used, let Firebase Auth consume its hidden verification push:

```swift
override func application(
  _ application: UIApplication,
  didReceiveRemoteNotification notification: [AnyHashable: Any],
  fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
) {
  if Auth.auth().canHandleNotification(notification) {
    completionHandler(.noData)
    return
  }
  super.application(
    application,
    didReceiveRemoteNotification: notification,
    fetchCompletionHandler: completionHandler
  )
}
```

Expected useful logs:

```text
[Notifications] APNs token registered.
[Auth] Firebase Auth handled remote notification.
[NotificationService] Foreground message received: <id> dataKeys=deep_link,item_id
```

## Token Registration

Register tokens after login so the token can be linked to the Firebase UID.

Recommended fields for `device_tokens`:

```sql
-- names shown match Sora's existing code
fcmToken text primary key,
userID text not null, -- Firebase UID
isAndroid boolean not null default false,
isArabic boolean not null default false,
isActive boolean not null default true,
lastSeen timestamptz not null default now()
```

Client upsert:

```dart
await SupabaseService.client.from('device_tokens').upsert({
  'userID': user.uid,
  'fcmToken': token,
  'isAndroid': !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  'isArabic': Get.locale?.languageCode == 'ar',
  'isActive': true,
  'lastSeen': DateTime.now().toUtc().toIso8601String(),
}, onConflict: 'fcmToken');
```

Listen for token refresh:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((token) {
  unawaited(_saveRefreshedFcmToken(token));
});
```

Deactivate on sign-out:

```dart
final token = await FirebaseMessaging.instance.getToken();
if (token != null && token.isNotEmpty) {
  await SupabaseService.client
      .from('device_tokens')
      .update({
        'isActive': false,
        'lastSeen': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('fcmToken', token);
}
```

## iOS Token Race Fix

On iOS, `FirebaseMessaging.getToken()` can fail with `apns-token-not-set` if called too early. Wait for APNs first.

```dart
Future<bool> _waitForApnsTokenIfNeeded(FirebaseMessaging messaging) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return true;

  const attempts = 20; // 10 seconds total
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
```

If APNs is not ready, schedule a short retry and retry again when the app resumes.

## Android Setup

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Create a high-importance notification channel before showing local notifications:

```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance',
  'App notifications',
  description: 'Important app updates.',
  importance: Importance.high,
);

await flutterLocalNotifications
    .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >()
    ?.createNotificationChannel(channel);
```

## iOS Developer Setup That Code Cannot Do

Apple Developer:

- Enable Push Notifications capability for the app ID.
- Enable Background Modes with Remote notifications.
- Create APNs Auth Key `.p8`.
- Note Apple Team ID and Key ID.
- Regenerate/download provisioning profiles after capability changes.

Firebase Console:

- Project Settings -> Cloud Messaging -> Apple app configuration.
- Upload `.p8` APNs auth key.
- Enter Key ID and Team ID.
- Confirm iOS bundle ID matches exactly.

Xcode:

- Add Push Notifications capability.
- Add Background Modes capability.
- Check Remote notifications.
- Ensure entitlements include `aps-environment`.

Example entitlements:

```xml
<key>aps-environment</key>
<string>$(APS_ENVIRONMENT)</string>
```

## In-App Messaging and Top Banners

Sora has a separate in-app messaging feature alongside FCM push:

- Admin publishes rows to `in_app_messages`.
- Client subscribes to Supabase Realtime inserts/updates.
- Client also refreshes active rows from Supabase while foregrounded.
- Messages can display as `card`, `modal`, `image`, or `banner`.
- `banner` renders as a temporary top overlay.

Important delivery fix:

- Realtime alone is not enough. If Supabase Realtime is not enabled for `in_app_messages`, if a client misses the websocket event, or if the app is already open on a stale tab, a newly published top banner may not appear.
- Add a polling fallback while foregrounded, for example every 45 seconds.
- After the admin publishes a message, call the local in-app service `refreshNow()` so the publisher can immediately verify the banner.

Service pattern:

```dart
class InAppMessagingService extends GetxService with WidgetsBindingObserver {
  static InAppMessagingService get to => Get.find();

  Timer? _refreshTimer;
  bool _isForeground = true;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
    _scheduleRefresh(const Duration(seconds: 2));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      _scheduleRefresh(const Duration(milliseconds: 500));
      unawaited(_presentNext());
    }
  }

  Future<void> refreshNow() => _refresh();

  void _scheduleRefresh(Duration delay) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    if (!_isForeground) return;

    try {
      final now = DateTime.now().toUtc();
      final rows = await SupabaseService.client
          .from('in_app_messages')
          .select()
          .eq('is_active', true)
          .lte('starts_at', now.toIso8601String())
          .order('priority', ascending: false)
          .order('created_at', ascending: false)
          .limit(25);

      for (final row in rows) {
        final message = InAppMessageModel.fromJson(row);
        _enqueue(message, now: now);
      }
    } catch (e) {
      debugPrint('[InAppMessagingService] refresh skipped: $e');
    } finally {
      if (_isForeground) {
        _scheduleRefresh(const Duration(seconds: 45));
      }
    }
  }
}
```

Admin publish should trigger an immediate local refresh:

```dart
await _invokeInAppAdmin({
  'action': 'publish',
  'message': messagePayload,
});

if (Get.isRegistered<InAppMessagingService>()) {
  unawaited(InAppMessagingService.to.refreshNow());
}
```

Top banner presenter:

```dart
static Future<void> show({
  required BuildContext context,
  required InAppMessageModel message,
  required InAppMessageAction onAction,
}) {
  if (message.type == InAppMessageType.banner) {
    return _showBanner(context, message, onAction);
  }

  return showDialog<void>(
    context: context,
    builder: (_) => MessageDialog(message: message, onAction: onAction),
  );
}
```

Recommended `in_app_messages` fields:

```sql
id bigint primary key generated always as identity,
type text not null check (type in ('card', 'modal', 'image', 'banner')),
title text not null default '',
body text not null default '',
image_url text not null default '',
background_color text not null default '#FFFFFF',
text_color text not null default '#171717',
button_color text not null default '#B09263',
button_text_color text not null default '#FFFFFF',
primary_button_text text not null default '',
primary_action_url text not null default '',
secondary_button_text text not null default '',
secondary_action_url text not null default '',
target_platform text not null default 'all',
target_language text not null default 'all',
display_once boolean not null default true,
is_active boolean not null default true,
priority integer not null default 0,
starts_at timestamptz not null default now(),
ends_at timestamptz,
created_by text,
created_at timestamptz not null default now()
```

Backend validator must include the same message types as the app:

```ts
const messageTypes = new Set(['card', 'modal', 'image', 'banner']);
```

Deploy after changing the validator or adding a type:

```bash
supabase functions deploy manage-in-app-messages --no-verify-jwt
```

Use `--no-verify-jwt` when the Flutter admin panel sends Firebase ID tokens and the function verifies them with Firebase Admin SDK internally.

Testing gotcha:

- If `display_once` is true, a message that already appeared on a device is stored in local storage and will not show again.
- While testing top banners, turn off "Show once per device" or clear local storage.
- A banner auto-closes after its timer. Make sure you are looking at an active app tab/device when publishing.

## Backend Notification Queue

Sora uses Supabase:

- Admin Flutter panel inserts rows into `notification_jobs`.
- Admin can call `process-notification-jobs` Edge Function immediately.
- Scheduler can call the same function every minute with a secret.
- Edge Function uses Firebase Admin SDK to send FCM.

Server-generated business events also insert queue rows:

```text
admin_order_placed
affiliate_application_submitted
affiliate_application_reviewed
affiliate_payout_requested
affiliate_payout_reviewed
order_status_changed
```

Use `payload.target_audience = "admins"` for admin-only events. The worker
resolves current admin Firebase UIDs from `users.isAdmin` and then selects only
their active device tokens. Use `payload.target_user_uid` for one user's
application or payout result. Without one of these targets, a job may become a
broadcast, so target server-generated events explicitly.

Order placement is server-authoritative. An `AFTER INSERT` trigger on
`order_master` queues the admin alert in the same transaction. After the Edge
Function RPC succeeds, it invokes `process-notification-jobs` with
`x-process-queue-secret`, making delivery immediate without trusting the
customer client.

`notification_jobs` expected fields:

```sql
id bigint primary key generated always as identity,
eventType text not null,
title text not null,
body text not null,
payload jsonb not null default '{}',
isAndroidOnly boolean not null default false,
isArabicOnly boolean not null default false,
status text not null default 'pending',
attempts integer not null default 0,
lastError text,
createdAt timestamptz not null default now()
```

Also create RPCs/functions:

- `claim_notification_jobs(p_limit int)` to atomically claim pending rows.
- `complete_notification_job(p_job_id bigint, p_status text, p_last_error text)` to mark sent/failed.

Edge Function required secrets:

```text
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
PROCESS_QUEUE_SECRET
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
```

`FIREBASE_PRIVATE_KEY` must preserve newlines. In Supabase secrets, commonly store escaped newlines as `\n`, then convert:

```ts
privateKey: Deno.env.get('FIREBASE_PRIVATE_KEY')!.replace(/\\n/g, '\n')
```

Deploy:

```bash
supabase functions deploy process-notification-jobs --no-verify-jwt
```

Why `--no-verify-jwt`:

- The Flutter admin panel sends a Firebase ID token.
- Supabase gateway does not validate Firebase ID tokens by default.
- The Edge Function verifies the Firebase token with Firebase Admin SDK, then checks `users.isAdmin`.

Firebase Admin send pattern:

```ts
await getMessaging().sendEachForMulticast({
  tokens: chunkOfUpTo500,
  notification: { title, body },
  data: payloadToStringMap(payload),
  android: { priority: 'high' },
  apns: {
    headers: { 'apns-priority': '10' },
    payload: { aps: { sound: 'default', badge: 1 } },
  },
});
```

Deactivate invalid tokens for errors:

- `messaging/invalid-argument`
- `messaging/invalid-registration-token`
- `messaging/registration-token-not-registered`

## Notification Payloads

Use only string values in FCM `data`; convert objects/numbers to strings before sending.

Recommended app data:

```json
{
  "deep_link": "/item/123",
  "item_id": "123",
  "event_type": "featured_item_published"
}
```

Supported deep links should be accepted by `DeepLinkService`:

- `/home`
- `/item/<id>`
- `/orders/<id>`
- `/ref/<uid>`
- `myapp://item/<id>`
- `https://www.example.com/item/<id>`

## Web Push

Sora does not fully implement web FCM. If a future app needs web push, add:

- Firebase web app config.
- Web Push certificate/VAPID key in Firebase Cloud Messaging settings.
- `firebase-messaging-sw.js` in `web/`.
- Browser permission flow.
- `FirebaseMessaging.getToken(vapidKey: '<VAPID_KEY>')`.
- Domain must be HTTPS and authorized.

Keep this separate from web auth. Do not assume mobile FCM setup covers web push.

## Debugging Matrix

No iOS token / `apns-token-not-set`:

- Check Push Notifications capability.
- Check APNs `.p8` uploaded in Firebase.
- Check bundle ID.
- Check physical device. Push does not fully work in all simulator cases.
- Wait for APNs token before `getToken()`.

iOS phone auth broke after adding notifications:

- Ensure `Auth.auth().setAPNSToken(deviceToken, type: .unknown)` is still called.
- Ensure `Auth.auth().canHandleNotification(notification)` gets first chance.
- Ensure `UIBackgroundModes` includes `remote-notification`.

Foreground messages duplicate on iOS:

- Do not show local notification on iOS/macOS if native foreground presentation is enabled.

Notification tap does nothing:

- Log `message.data.keys`.
- Confirm payload has `deep_link`, not `deepLink` or `url`.
- Confirm `DeepLinkService` is registered before notification service handles taps.
- Confirm initial message is handled after app init.
- Add internal routes used by payloads to `DeepLinkService`. Sora supports
  `/admin-orders`, `/admin-affiliates`, and `/affiliate`, with role checks.

Top banner publishes but does not show:

- Confirm a row exists in `in_app_messages` with `type = 'banner'`.
- Confirm `is_active = true`, `starts_at <= now`, and `ends_at` is null or in the future.
- Confirm `target_platform` matches the current platform or is `all`.
- Confirm `target_language` matches `Get.locale.languageCode` or is `all`.
- Confirm `display_once` did not hide an already-seen message. Turn off "Show once per device" while testing.
- Confirm Supabase Realtime is enabled for `in_app_messages`, or that the foreground polling fallback is running.
- Confirm `manage-in-app-messages` was redeployed after adding `banner` to the backend validator.
- Confirm the production web/native client was redeployed after adding `refreshNow()` or polling fallback.
- Check logs for `[InAppMessagingService] refresh skipped:` or `[InAppMessagingService] display failed:`.

Backend sends no messages:

- Check `device_tokens.isActive`.
- Check FCM token strings are valid and current.
- Check Edge Function secrets.
- Check Firebase Admin service account belongs to the same Firebase project as the app.
- Check `notification_jobs` RPCs.
- Check function deployed with `--no-verify-jwt` if it receives Firebase ID tokens.

## Verification Checklist

Client:

```bash
flutter analyze lib/app/core/services/notification_service.dart
flutter build ios --debug --no-codesign
flutter build apk --debug
```

Manual:

- Fresh install on iOS physical device.
- Accept notifications.
- Confirm APNs token log.
- Confirm FCM token stored in `device_tokens`.
- Send foreground notification.
- Send background notification and tap it.
- Tap opens expected route.
- Sign out deactivates token.
- Sign back in reactivates/upserts token.
- Publish an in-app top banner with "Show once per device" off.
- Confirm the publishing device shows it immediately.
- Confirm an already-open second device shows it through Realtime or within the polling interval.
- Confirm a fresh app launch/resume shows any eligible active banner.

Backend:

- Queue one notification job.
- Invoke process function as admin with Firebase ID token.
- Invoke process function with `x-process-queue-secret`.
- Confirm invalid tokens are deactivated.
- Confirm job status changes to `sent` or `failed`.
- Place an order and confirm only admin tokens receive `admin_order_placed`.
- Submit/review an affiliate application and confirm admin/applicant targeting.
- Request/review a payout and confirm admin/affiliate targeting.
- Publish one `banner` in-app message through `manage-in-app-messages`.
- Confirm the function accepts `type: banner`.

## Official References

- Firebase Cloud Messaging Flutter: https://firebase.google.com/docs/cloud-messaging/flutter/client
- Firebase iOS APNs setup: https://firebase.google.com/docs/cloud-messaging/ios/client
- Firebase Admin send messages: https://firebase.google.com/docs/cloud-messaging/send/admin-sdk
- Flutter local notifications package: https://pub.dev/packages/flutter_local_notifications
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
