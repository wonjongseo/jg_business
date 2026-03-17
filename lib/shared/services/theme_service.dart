/// 앱의 라이트/다크 테마 선택 상태를 로컬에 저장한다.
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static const _themeModeKey = 'theme_mode';

  final _isDarkMode = false.obs;

  bool get isDarkMode => _isDarkMode.value;

  Future<ThemeService> init() async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode.value = preferences.getBool(_themeModeKey) ?? false;
    return this;
  }

  Future<void> setDarkMode(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode.value = value;
    await preferences.setBool(_themeModeKey, value);
  }
}
