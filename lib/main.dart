import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await SupabaseService.init();

  final settings = Get.put(await SettingsController.load(), permanent: true);
  AppBinding.init(); // registers AuthController, CartController, NavController, lazy tab controllers

  runApp(SentryWidget(child: SoraApp(settings: settings)));
}

class SoraApp extends StatelessWidget {
  const SoraApp({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      settings.localeCode.value;
      settings.isDark.value;

      return GetMaterialApp(
        title: 'Sora',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        translations: AppTranslations(),
        locale: settings.locale,
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
          languageCode: settings.localeCode.value,
          child: child ?? const SizedBox.shrink(),
        ),
      );
    });
  }
}
