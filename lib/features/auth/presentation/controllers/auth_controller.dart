/// 앱 전역에서 사용하는 인증/세션 상태를 관리한다.
import 'dart:async';

import 'package:get/get.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';

class AuthController extends GetxController {
  AuthController({
    required GoogleAuthRemoteDataSource authRemoteDataSource,
  }) : _authRemoteDataSource = authRemoteDataSource;

  final GoogleAuthRemoteDataSource _authRemoteDataSource;
  final _isInitialized = false.obs;
  final _sessionVersion = 0.obs;
  StreamSubscription<Object?>? _authStateSubscription;

  bool get isInitialized => _isInitialized.value;
  bool get isSignedIn => _authRemoteDataSource.isSignedIn;
  RxInt get sessionVersionRx => _sessionVersion;
  String? get currentUserEmail => _authRemoteDataSource.currentUserEmail;
  String? get currentUserDisplayName => _authRemoteDataSource.currentUserDisplayName;
  String get currentUserId => _authRemoteDataSource.currentUserId;
  String get greetingName => _authRemoteDataSource.greetingName;

  @override
  void onInit() {
    super.onInit();
    // auth state가 바뀌면 sessionVersion을 올려 다른 컨트롤러가 재동기화할 수 있게 한다.
    _authStateSubscription = _authRemoteDataSource.authStateChanges.listen((_) {
      _sessionVersion.value++;
      update();
    });
    _initialize();
  }

  /// 앱 시작 시 인증 SDK 초기화를 보장한다.
  Future<void> _initialize() async {
    if (_isInitialized.value) return;
    await _authRemoteDataSource.initialize();
    _isInitialized.value = true;
    update();
  }

  /// 화면에서 세션 재확인이 필요할 때 초기화만 다시 보장한다.
  Future<void> refreshSession() async {
    await _authRemoteDataSource.initialize();
    update();
  }

  /// 로그아웃 후 GetX 상태를 갱신한다.
  Future<void> signOut() async {
    await _authRemoteDataSource.signOut();
    update();
  }

  /// 필요한 scope를 포함해 재인증을 요청한다.
  Future<void> reauthenticate({
    List<String> scopes = GoogleAuthRemoteDataSource.defaultScopes,
  }) async {
    await _authRemoteDataSource.reauthenticate(scopes: scopes);
    update();
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    super.onClose();
  }
}
