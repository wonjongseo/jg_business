import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jg_business/core/models/calendar_events_response.dart';

class GoogleCalendarService {
  final GoogleSignIn signIn = GoogleSignIn.instance;

  GoogleSignInAccount? _currentUser;

  final Dio dio = Dio();

  Future<void> initGoogle() async {
    try {
      await signIn.initialize(
        serverClientId:
            '820390242930-k2ciki8i7divtsebcrisl172fer62t0o.apps.googleusercontent.com', // WebClientID
      );

      signIn.authenticationEvents.listen((event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            _currentUser = event.user;
            break;
          case GoogleSignInAuthenticationEventSignOut():
            _currentUser = null;
            break;
        }
      });

      final restoreUser = await signIn.attemptLightweightAuthentication();

      _currentUser = restoreUser;
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> signInIfNeeded() async {
    if (_currentUser != null) return;
    _currentUser = await signIn.authenticate(
      scopeHint: const ['https://www.googleapis.com/auth/calendar.readonly'],
    );
  }

  Future<void> fetchCalendar() async {
    try {
      await signInIfNeeded();

      final user = _currentUser;
      if (user == null) return;

      final headers = await user.authorizationClient.authorizationHeaders(
        const ['https://www.googleapis.com/auth/calendar.readonly'],
      );

      final response = await dio.get(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events',
        options: Options(headers: headers),
        queryParameters: {
          'singleEvents': true,
          'orderBy': 'startTime',
          'timeMin': DateTime(2026, 3).toUtc().toIso8601String(),
          'maxResults': 2,
        },
      );
      final calendarResponse = CalendarEventsResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      for (final event in calendarResponse.items) {
        print('event : ${event}');
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
