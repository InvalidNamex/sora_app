import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../firebase_options.dart';
import 'link_navigation_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

@pragma('vm:entry-point')
void localNotificationBackgroundHandler(NotificationResponse response) {}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  static const _androidChannel = AndroidNotificationChannel(
    'sora_high_importance',
    'Sora notifications',
    description: 'Order updates, promotions, and featured items.',
    importance: Importance.high,
  );

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  Future<void>? _initializeFuture;
  var _initialized = false;

  @override
  void onInit() {
    super.onInit();
    _initializeFuture = _initialize();
  }

  @override
  void onClose() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    super.onClose();
  }

  Future<void> requestDisplayPermissions() async {
    if (kIsWeb) return;
    await (_initializeFuture ??= _initialize());

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          localNotificationBackgroundHandler,
    );

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse != null) {
      _handleLocalNotificationTap(launchResponse);
    }

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    final usesNativeForegroundPresentation =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: usesNativeForegroundPresentation,
      badge: usesNativeForegroundPresentation,
      sound: usesNativeForegroundPresentation,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleRemoteMessageTap(initialMessage);
    }

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(_handleRemoteMessageTap(message)),
    );
    _foregroundSub = FirebaseMessaging.onMessage.listen(
      (message) => unawaited(_showForegroundNotification(message)),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    debugPrint(
      '[NotificationService] Foreground message received: '
      '${message.messageId ?? 'no-message-id'}',
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
      id: _notificationId(message),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sora_high_importance',
          'Sora notifications',
          channelDescription: 'Order updates, promotions, and featured items.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
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

  Future<void> _handleRemoteMessageTap(RemoteMessage message) async {
    await LinkNavigationService.open(message.data['deep_link'] as String?);
  }

  String? _stringData(RemoteMessage message, String key) {
    final value = message.data[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int _notificationId(RemoteMessage message) {
    final id =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    return id & 0x7fffffff;
  }
}
