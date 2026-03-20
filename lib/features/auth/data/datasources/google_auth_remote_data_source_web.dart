/// Google 로그인과 Calendar scope 인증 상태를 다루는 웹용 데이터 소스다.
import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:jg_business/shared/config/app_env.dart';

class GoogleAuthRemoteDataSource {
  static const calendarScope = 'https://www.googleapis.com/auth/calendar';
  static const sheetsScope = 'https://www.googleapis.com/auth/spreadsheets';
  static const defaultScopes = [calendarScope, sheetsScope];

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  final _authStateController = StreamController<Object?>.broadcast();

  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;
  Future<void>? _initializing;

  bool get isSignedIn => _currentUser != null;
  Stream<Object?> get authStateChanges => _authStateController.stream;
  String? get currentUserEmail => _currentUser?.email;
  String? get currentUserDisplayName => _currentUser?.displayName;
  String get currentUserId {
    final email = _currentUser?.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }
    return 'local-user';
  }

  String get greetingName {
    final displayName = currentUserDisplayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = currentUserEmail?.trim();
    if (email != null && email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }

    return '営業担当者';
  }

  /// 웹에서는 GIS 초기화를 한 번만 수행한다.
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializing != null) {
      await _initializing;
      return;
    }

    _initializing = _initializeInternal();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  /// clientId 기반 GIS 초기화 후 기존 세션 복구를 시도한다.
  Future<void> _initializeInternal() async {
    await _signIn.initialize(clientId: AppEnv.googleWebClientId);

    _signIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _currentUser = event.user;
          _authStateController.add(_currentUser);
          break;
        case GoogleSignInAuthenticationEventSignOut():
          _currentUser = null;
          _authStateController.add(null);
          break;
      }
    });

    _currentUser = await _signIn.attemptLightweightAuthentication();
    _authStateController.add(_currentUser);
    _isInitialized = true;
  }

  /// 웹에서는 현재 세션에 대해 필요한 scope 승격을 거쳐 헤더를 만든다.
  Future<Map<String, String>?> getAuthorizationHeaders({
    List<String> scopes = defaultScopes,
    bool interactive = true,
  }) async {
    await initialize();

    final user = _currentUser;
    if (user == null) return <String, String>{};

    if (interactive) {
      await user.authorizationClient.authorizeScopes(scopes);
    }

    return await user.authorizationClient.authorizationHeaders(
      scopes,
      promptIfNecessary: interactive,
    );
  }

  /// 웹 로그아웃은 GIS 연결을 끊고 메모리 세션을 비운다.
  Future<void> signOut() async {
    await initialize();
    await _signIn.disconnect();
    _currentUser = null;
    _authStateController.add(null);
  }

  /// 웹은 GIS 버튼 로그인 후 추가 scope만 다시 요청한다.
  Future<void> reauthenticate({List<String> scopes = defaultScopes}) async {
    await initialize();
    final user = _currentUser;
    if (user == null) {
      return;
    }
    await user.authorizationClient.authorizeScopes(scopes);
  }
}
