import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_session_store.dart';
import 'package:jg_business/shared/utils/snackbar_helper.dart';

/// 앱 플랫폼에서 Google Sign-In SDK와 실제 통신을 담당한다.
class GoogleAuthAppClient {
  GoogleAuthAppClient({
    required GoogleAuthSessionStore sessionStore,
    required String serverClientId,
    GoogleSignIn? signIn,
  }) : _sessionStore = sessionStore,
       _serverClientId = serverClientId,
       _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleAuthSessionStore _sessionStore;
  final String _serverClientId;
  final GoogleSignIn _signIn;

  bool _isInitialized = false;
  bool _isAuthEventsBound = false;
  Future<void>? _initializing;
  Future<void>? _interactiveAuthInFlight;

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
    await _ensureSignedIn(scopes, interactive: interactive);

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
      if (_isCanceledSignIn(error)) return <String, String>{};
      rethrow;
    }
  }

  Future<void> signOut() async {
    await initialize();
    try {
      // disconnect 는 승인까지 끊어 다음 권한 요청을 깨끗하게 만드는 데 유리하지만,
      // 실기기에서는 계정 상태에 따라 실패할 수 있어 signOut 으로 한 번 더 안전하게 정리한다.
      await _signIn.disconnect();
    } catch (e) {
      SnackbarHelper.error('LogoiutERROR', '$e');
      await _signIn.signOut();
    }
    _sessionStore.clear();
  }

  Future<void> reauthenticate({required List<String> scopes}) async {
    await initialize();
    if (_interactiveAuthInFlight != null) {
      await _interactiveAuthInFlight;
      return;
    }

    final future = _reauthenticateInternal(scopes);
    _interactiveAuthInFlight = future;
    try {
      await future;
    } finally {
      _interactiveAuthInFlight = null;
    }
  }

  Future<void> _initializeInternal() async {
    await _signIn.initialize(serverClientId: _serverClientId);

    if (!_isAuthEventsBound) {
      _sessionStore.bindAuthenticationEvents(_signIn.authenticationEvents);
      _isAuthEventsBound = true;
    }

    _sessionStore.setCurrentUser(await _restorePreviousSessionSafely());
    _isInitialized = true;
  }

  Future<GoogleSignInAccount?> _restorePreviousSessionSafely() async {
    try {
      return await _signIn.attemptLightweightAuthentication();
    } on PlatformException catch (error) {
      if (!_isRevokedCredentialError(error)) rethrow;
      await _clearStaleSession();
      return null;
    }
  }

  Future<void> _reauthenticateInternal(List<String> scopes) async {
    await _ensureSignedIn(scopes, interactive: true);
    final user = _sessionStore.currentUser;
    if (user == null) return;

    try {
      await user.authorizationClient.authorizeScopes(scopes);
    } on GoogleSignInException catch (error) {
      if (!_isCanceledSignIn(error)) rethrow;
    }
  }

  Future<void> _ensureSignedIn(
    List<String> scopes, {
    required bool interactive,
  }) async {
    try {
      if (_sessionStore.currentUser != null) return;
      if (!interactive) return;
      _sessionStore.setCurrentUser(
        await _signIn.authenticate(scopeHint: scopes),
      );
    } on GoogleSignInException catch (error) {
      if (_isCanceledSignIn(error)) return;
      SnackbarHelper.error('LoginERROR', '$error');
    } catch (e) {
      SnackbarHelper.error('LoginERROR', '$e');
    }
  }

  bool _isRevokedCredentialError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    final details = error.details?.toString().toLowerCase() ?? '';

    return code.contains('oauth_token') &&
        (message.contains('invalid_grant') ||
            message.contains('expired or revoked') ||
            details.contains('invalid_grant') ||
            details.contains('expired or revoked'));
  }

  bool _isCanceledSignIn(GoogleSignInException error) {
    return error.code == GoogleSignInExceptionCode.canceled;
  }

  Future<void> _clearStaleSession() async {
    try {
      await _signIn.signOut();
    } catch (_) {}
    _sessionStore.clear();
  }
}
