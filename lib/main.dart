import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:jg_business/app/routes/app_pages.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  runApp(const JgBusinessApp());
}

class JgBusinessApp extends StatelessWidget {
  const JgBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Jg Business',
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
      ],
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
