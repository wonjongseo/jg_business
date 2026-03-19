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

  Future<void> signOut() async {
    await initialize();
    await _signIn.disconnect();
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<void> reauthenticate({List<String> scopes = defaultScopes}) async {
    await initialize();
    await signOut();
    await _ensureSignedIn(scopes, interactive: true);
    final user = _currentUser;
    if (user == null) return;
    await user.authorizationClient.authorizeScopes(scopes);
  }

  Future<void> _ensureSignedIn(
    List<String> scopes, {
    required bool interactive,
  }) async {
    if (_currentUser != null) return;
    if (!interactive) return;
    _currentUser = await _signIn.authenticate(scopeHint: scopes);
  }
}
