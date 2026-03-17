/// 첫 실행 여부와 온보딩 완료 여부를 로컬 설정에 저장한다.
import 'package:shared_preferences/shared_preferences.dart';

class AppLaunchService {
  static const _onboardingCompletedKey = 'onboarding_completed';

  SharedPreferences? _preferences;

  Future<void> initialize() async {
    /// SharedPreferences 인스턴스를 지연 초기화해 재사용한다.
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<bool> isOnboardingCompleted() async {
    /// 온보딩 완료 여부를 읽는다.
    await initialize();
    return _preferences?.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    /// 온보딩 완료 플래그를 저장한다.
    await initialize();
    await _preferences?.setBool(_onboardingCompletedKey, true);
  }
}
