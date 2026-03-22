/// Google 로그인과 Calendar scope 인증 상태를 다루는 앱용 데이터 소스다.
import 'dart:async';

import 'package:jg_business/features/auth/data/datasources/google_auth_app_client.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_session_store.dart';

class GoogleAuthRemoteDataSource {
  static const calendarScope = 'https://www.googleapis.com/auth/calendar';
  static const sheetsScope = 'https://www.googleapis.com/auth/spreadsheets';
  static const defaultScopes = [calendarScope, sheetsScope];
  static const _serverClientId =
      '820390242930-k2ciki8i7divtsebcrisl172fer62t0o.apps.googleusercontent.com';

  factory GoogleAuthRemoteDataSource() {
    final sessionStore = GoogleAuthSessionStore();
    return GoogleAuthRemoteDataSource._(
      sessionStore,
      GoogleAuthAppClient(
        sessionStore: sessionStore,
        serverClientId: _serverClientId,
      ),
    );
  }

  GoogleAuthRemoteDataSource._(this._sessionStore, this._client);

  final GoogleAuthSessionStore _sessionStore;
  final GoogleAuthAppClient _client;

  bool get isSignedIn => _sessionStore.isSignedIn;
  Stream<Object?> get authStateChanges => _sessionStore.authStateChanges;
  String? get currentUserEmail => _sessionStore.currentUserEmail;
  String? get currentUserDisplayName => _sessionStore.currentUserDisplayName;
  String get currentUserId => _sessionStore.currentUserId;
  String get greetingName => _sessionStore.greetingName;

  /// 앱 실행 후 Google Sign-In SDK를 한 번만 초기화한다.
  Future<void> initialize() async {
    await _client.initialize();
  }

  /// 필요한 scope를 포함한 access token 헤더를 만든다.
  /// interactive=true 이면 부족한 권한이 있을 때 팝업을 허용한다.
  Future<Map<String, String>?> getAuthorizationHeaders({
    List<String> scopes = defaultScopes,
    bool interactive = true,
  }) async {
    return await _client.getAuthorizationHeaders(
      scopes: scopes,
      interactive: interactive,
    );
  }

  /// 현재 계정의 승인과 세션을 모두 정리한다.
  Future<void> signOut() async {
    await _client.signOut();
  }

  /// 연결 버튼 등에서 기존 계정을 끊고 필요한 scope까지 다시 승인받는다.
  Future<void> reauthenticate({List<String> scopes = defaultScopes}) async {
    await _client.reauthenticate(scopes: scopes);
  }
}
