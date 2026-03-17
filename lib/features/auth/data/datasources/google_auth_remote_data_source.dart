import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthRemoteDataSource {
  static const calendarScope = 'https://www.googleapis.com/auth/calendar';

  final GoogleSignIn _signIn = GoogleSignIn.instance;

  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;

  bool get isSignedIn => _currentUser != null;
  String? get currentUserEmail => _currentUser?.email;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _signIn.initialize(
      serverClientId:
          '820390242930-k2ciki8i7divtsebcrisl172fer62t0o.apps.googleusercontent.com',
    );

    _signIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _currentUser = event.user;
          break;
        case GoogleSignInAuthenticationEventSignOut():
          _currentUser = null;
          break;
      }
    });

    _currentUser = await _signIn.attemptLightweightAuthentication();
    _isInitialized = true;
  }

  Future<Map<String, String>?> getAuthorizationHeaders({
    List<String> scopes = const [calendarScope],
    bool interactive = true,
  }) async {
    await initialize();
    await _signInIfNeeded(scopes, interactive: interactive);

    final user = _currentUser;
    if (user == null) return <String, String>{};

    return await user.authorizationClient.authorizationHeaders(scopes);
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    _currentUser = null;
  }

  Future<void> reauthenticate({
    List<String> scopes = const [calendarScope],
  }) async {
    await signOut();
    await _signInIfNeeded(scopes, interactive: true);
  }

  Future<void> _signInIfNeeded(
    List<String> scopes, {
    required bool interactive,
  }) async {
    if (_currentUser != null) return;
    if (!interactive) return;
    _currentUser = await _signIn.authenticate(scopeHint: scopes);
  }
}
