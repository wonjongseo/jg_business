/// Google 로그인과 Calendar scope 인증 상태를 다루는 웹용 데이터 소스다.
import 'dart:async';

import 'package:jg_business/features/auth/data/datasources/google_auth_session_store.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_web_client.dart';

class GoogleAuthRemoteDataSource {
  static const calendarScope = 'https://www.googleapis.com/auth/calendar';
  static const sheetsScope = 'https://www.googleapis.com/auth/spreadsheets';
  static const defaultScopes = [calendarScope, sheetsScope];

  factory GoogleAuthRemoteDataSource() {
    final sessionStore = GoogleAuthSessionStore();
    return GoogleAuthRemoteDataSource._(
      sessionStore,
      GoogleAuthWebClient(sessionStore: sessionStore),
    );
  }

  GoogleAuthRemoteDataSource._(this._sessionStore, this._client);

  final GoogleAuthSessionStore _sessionStore;
  final GoogleAuthWebClient _client;

  bool get isSignedIn => _sessionStore.isSignedIn;
  Stream<Object?> get authStateChanges => _sessionStore.authStateChanges;
  String? get currentUserEmail => _sessionStore.currentUserEmail;
  String? get currentUserDisplayName => _sessionStore.currentUserDisplayName;
  String get currentUserId => _sessionStore.currentUserId;
  String get greetingName => _sessionStore.greetingName;

  /// 웹에서는 GIS 초기화를 한 번만 수행한다.
  Future<void> initialize() async {
    await _client.initialize();
  }

  /// 웹에서는 현재 세션에 대해 필요한 scope 승격을 거쳐 헤더를 만든다.
  Future<Map<String, String>?> getAuthorizationHeaders({
    List<String> scopes = defaultScopes,
    bool interactive = true,
  }) async {
    return await _client.getAuthorizationHeaders(
      scopes: scopes,
      interactive: interactive,
    );
  }

  /// 웹 로그아웃은 GIS 연결을 끊고 메모리 세션을 비운다.
  Future<void> signOut() async {
    await _client.signOut();
  }

  /// 웹은 GIS 버튼 로그인 후 추가 scope만 다시 요청한다.
  Future<void> reauthenticate({List<String> scopes = defaultScopes}) async {
    await _client.reauthenticate(scopes: scopes);
  }
}
