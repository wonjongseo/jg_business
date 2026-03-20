/// Google 로그인과 Calendar scope 인증 상태를 다루는 앱용 데이터 소스다.
import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthRemoteDataSource {
  static const calendarScope = 'https://www.googleapis.com/auth/calendar';
  static const sheetsScope = 'https://www.googleapis.com/auth/spreadsheets';
  static const defaultScopes = [calendarScope, sheetsScope];
  static const _serverClientId =
      '820390242930-k2ciki8i7divtsebcrisl172fer62t0o.apps.googleusercontent.com';

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

  /// 앱 실행 후 Google Sign-In SDK를 한 번만 초기화한다.
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

  /// 실제 앱용 GoogleSignIn 인스턴스를 초기화하고 auth 이벤트를 구독한다.
  Future<void> _initializeInternal() async {
    await _signIn.initialize(serverClientId: _serverClientId);

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

  /// 필요한 scope를 포함한 access token 헤더를 만든다.
  /// interactive=true 이면 부족한 권한이 있을 때 팝업을 허용한다.
  Future<Map<String, String>?> getAuthorizationHeaders({
    List<String> scopes = defaultScopes,
    bool interactive = true,
  }) async {
    await initialize();
    await _ensureSignedIn(scopes, interactive: interactive);

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

  /// 현재 계정의 승인과 세션을 모두 정리한다.
  Future<void> signOut() async {
    await initialize();
    await _signIn.disconnect();
    _currentUser = null;
    _authStateController.add(null);
  }

  /// 연결 버튼 등에서 기존 계정을 끊고 필요한 scope까지 다시 승인받는다.
  Future<void> reauthenticate({List<String> scopes = defaultScopes}) async {
    await initialize();
    await signOut();
    await _ensureSignedIn(scopes, interactive: true);
    final user = _currentUser;
    if (user == null) return;
    await user.authorizationClient.authorizeScopes(scopes);
  }

  /// 헤더 요청 전에 로그인된 사용자가 있는지 보장한다.
  Future<void> _ensureSignedIn(
    List<String> scopes, {
    required bool interactive,
  }) async {
    if (_currentUser != null) return;
    if (!interactive) return;
    _currentUser = await _signIn.authenticate(scopeHint: scopes);
  }
}
