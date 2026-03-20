/// 앱의 라이트/다크 테마 선택 상태를 로컬에 저장한다.
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  static const _themeModeKey = 'theme_mode';

  final _isDarkMode = false.obs;

  bool get isDarkMode => _isDarkMode.value;

  /// 앱 시작 시 저장된 다크모드 상태를 읽어 메모리에 올린다.
  Future<ThemeService> init() async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode.value = preferences.getBool(_themeModeKey) ?? false;
    return this;
  }

  /// 다크모드 값을 저장하고 현재 메모리 상태도 함께 바꾼다.
  Future<void> setDarkMode(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode.value = value;
    await preferences.setBool(_themeModeKey, value);
  }
}
