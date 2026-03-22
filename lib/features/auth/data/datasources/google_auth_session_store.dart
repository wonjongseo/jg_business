import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

/// Google 인증의 메모리 세션 상태와 auth 변경 스트림만 관리한다.
class GoogleAuthSessionStore {
  final _authStateController = StreamController<Object?>.broadcast();

  GoogleSignInAccount? _currentUser;

  bool get isSignedIn => _currentUser != null;
  Stream<Object?> get authStateChanges => _authStateController.stream;
  GoogleSignInAccount? get currentUser => _currentUser;
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

  void bindAuthenticationEvents(
    Stream<GoogleSignInAuthenticationEvent> events,
  ) {
    events.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          setCurrentUser(event.user);
          break;
        case GoogleSignInAuthenticationEventSignOut():
          clear();
          break;
      }
    });
  }

  void setCurrentUser(GoogleSignInAccount? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  void clear() {
    setCurrentUser(null);
  }
}
