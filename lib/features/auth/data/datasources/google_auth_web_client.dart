import 'package:google_sign_in/google_sign_in.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_session_store.dart';
import 'package:jg_business/shared/config/app_env.dart';

/// 웹 플랫폼에서 Google Identity Services 호출을 담당한다.
class GoogleAuthWebClient {
  GoogleAuthWebClient({
    required GoogleAuthSessionStore sessionStore,
    GoogleSignIn? signIn,
  }) : _sessionStore = sessionStore,
       _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleAuthSessionStore _sessionStore;
  final GoogleSignIn _signIn;

  bool _isInitialized = false;
  bool _isAuthEventsBound = false;
  Future<void>? _initializing;

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

  Future<Map<String, String>?> getAuthorizationHeaders({
    required List<String> scopes,
    required bool interactive,
  }) async {
    await initialize();

    final user = _sessionStore.currentUser;
    if (user == null) return <String, String>{};

    try {
      if (interactive) {
        await user.authorizationClient.authorizeScopes(scopes);
      }

      return await user.authorizationClient.authorizationHeaders(
        scopes,
        promptIfNecessary: interactive,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return <String, String>{};
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await initialize();
    await _signIn.disconnect();
    _sessionStore.clear();
  }

  Future<void> reauthenticate({required List<String> scopes}) async {
    await initialize();
    final user = _sessionStore.currentUser;
    if (user == null) return;
    await user.authorizationClient.authorizeScopes(scopes);
  }

  Future<void> _initializeInternal() async {
    await _signIn.initialize(clientId: AppEnv.googleWebClientId);

    if (!_isAuthEventsBound) {
      _sessionStore.bindAuthenticationEvents(_signIn.authenticationEvents);
      _isAuthEventsBound = true;
    }

    _sessionStore.setCurrentUser(
      await _signIn.attemptLightweightAuthentication(),
    );
    _isInitialized = true;
  }
}
