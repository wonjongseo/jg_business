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
    _authStateSubscription = _authRemoteDataSource.authStateChanges.listen((_) {
      _sessionVersion.value++;
      update();
    });
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized.value) return;
    await _authRemoteDataSource.initialize();
    _isInitialized.value = true;
    update();
  }

  Future<void> refreshSession() async {
    await _authRemoteDataSource.initialize();
    update();
  }

  Future<void> signOut() async {
    await _authRemoteDataSource.signOut();
    update();
  }

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
