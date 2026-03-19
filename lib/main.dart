/// 앱의 전역 초기화와 루트 위젯 구성을 담당한다.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_pages.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jg_business/shared/services/theme_service.dart';
import 'package:jg_business/shared/theme/app_theme.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> _initTimezone() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  await _initTimezone();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    // Firebase config is not generated for every desktop target yet.
  }
  await Get.putAsync(() => ThemeService().init(), permanent: true);

  runApp(const JgBusinessApp());
}

class JgBusinessApp extends StatelessWidget {
  const JgBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return Obx(
      () => GetMaterialApp(
        title: 'Jg Business',
        locale: const Locale('ja', 'JP'),
        supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        getPages: AppPages.pages,
        initialRoute: AppRoutes.splash,
      ),
    );
  }
}

// flutter run -d chrome --web-port 3000
//flutter run -d chrome \  --dart-define=GOOGLE_WEB_CLIENT_ID=820390242930-k2ciki8i7divtsebcrisl172fer62t0o.apps.googleusercontent.com
