import 'package:shared_preferences/shared_preferences.dart';

class AppLaunchService {
  static const _onboardingCompletedKey = 'onboarding_completed';

  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<bool> isOnboardingCompleted() async {
    await initialize();
    return _preferences?.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    await initialize();
    await _preferences?.setBool(_onboardingCompletedKey, true);
  }
}
