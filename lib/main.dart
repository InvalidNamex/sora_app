import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/core/bindings/app_binding.dart';
import 'app/core/controllers/settings_controller.dart';
import 'app/core/services/notification_service.dart';
import 'app/core/services/supabase_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/utils/web_url_strategy.dart';
import 'app/core/widgets/app_update_prompt.dart';
import 'app/routes/app_pages.dart';
import 'app/translations/app_translations.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init((options) {
    options.dsn =
        'https://08d59abc0502c735d5261aeb13abce6b@o4510415561687040.ingest.de.sentry.io/4511768490541136';
    options.sendDefaultPii = false;
    options.environment = kReleaseMode
        ? 'production'
        : kProfileMode
        ? 'staging'
        : 'development';
    options.attachStacktrace = true;
    options.enableAutoSessionTracking = true;
  }, appRunner: _runBootstrap);
}

Future<void> _runBootstrap() async {
  try {
    await _bootstrap();
  } catch (error, stackTrace) {
    await Sentry.captureException(error, stackTrace: stackTrace);
    rethrow;
  }
}

Future<void> _bootstrap() async {
  configureWebUrlStrategy();

  await dotenv.load(fileName: '.env');
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final supportsNativeAppCheck =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (supportsNativeAppCheck) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
  }
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await SupabaseService.init();

  final settings = Get.put(await SettingsController.load(), permanent: true);
  AppBinding.init(); // registers AuthController, CartController, NavController, lazy tab controllers

  runApp(SentryWidget(child: SoraApp(settings: settings)));
}

class SoraApp extends StatefulWidget {
  const SoraApp({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<SoraApp> createState() => _SoraAppState();
}

class _SoraAppState extends State<SoraApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      widget.settings.localeCode.value;
      widget.settings.isDark.value;

      return GetMaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Sora',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: widget.settings.themeMode,
        translations: AppTranslations(),
        locale: widget.settings.locale,
        fallbackLocale: const Locale('en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        builder: (context, child) => AppUpdatePrompt(
          languageCode: widget.settings.localeCode.value,
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      );
    });
  }
}
