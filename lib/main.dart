import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:jg_business/app/routes/app_pages.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  runApp(const JgBusinessApp());
}

class JgBusinessApp extends StatelessWidget {
  const JgBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Jg Business',
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      getPages: AppPages.pages,
      initialRoute: AppRoutes.splash,
    );
  }
}

/*
영업부를 위한 앱.
구현하고싶은 기능.
1. 구글 캘린더 CRUD
2. 구글 캘린더의 미팅을 저장해 시간별 / 미팅 위치별로 알림 보내기
3. 미팅이 끝나고 5분 뒤 or 미팅 장소에서 300미터 정도 떨어지면 미팅 내용을 기록하라는 알림 보내기
4. 미팅 내용을 기록하고, google spread sheet에 동기 가능하게
5. 고객 관리. 명함을 찍으면 명함 내용을 자동으로 등록해주는 기능
6. voip를 이용해 통화 / 녹음 / AI 요약 기능 
7. okta sso 인증
이정도를 생각하는데 더 좋은 아이디어 있어?
*/
