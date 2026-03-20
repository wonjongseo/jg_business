/// Google Calendar REST API를 호출해 일정 CRUD를 수행한다.
import 'package:dio/dio.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/shared/utils/date_time_formatter.dart';

class GoogleCalendarRemoteDataSource {
  GoogleCalendarRemoteDataSource({
    required GoogleAuthRemoteDataSource authRemoteDataSource,
  }) : _authRemoteDataSource = authRemoteDataSource;

  final GoogleAuthRemoteDataSource _authRemoteDataSource;
  final Dio _dio = Dio();

  bool get isConnected => _authRemoteDataSource.isSignedIn;

  Future<void> initialize() {
    return _authRemoteDataSource.initialize();
  }

  Future<List<CalendarEvent>> fetchEvents({bool interactive = true}) async {
    try {
      final now = DateTime.now();
      final timeMin = DateTime(now.year, now.month - 6, now.day);
      final timeMax = DateTime(now.year, now.month + 6, now.day, 23, 59, 59);

      final headers = await _authRemoteDataSource.getAuthorizationHeaders(
        interactive: interactive,
      );
      if (headers == null || headers.isEmpty) return [];

      final response = await _dio.get(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events',
        options: Options(headers: headers),
        queryParameters: {
          'singleEvents': true,
          'orderBy': 'startTime',
          'timeMin': timeMin.toUtc().toIso8601String(),
          'timeMax': timeMax.toUtc().toIso8601String(),
        },
      );

      final calendarResponse = CalendarEventsResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      return calendarResponse.items;
    } catch (_) {
      return [];
    }
  }

  Future<void> createEvent({
    required String summary,
    String? description,
    String? location,
    List<String> attendees = const [],
    required DateTime start,
    required DateTime end,
    bool isAllDay = false,
  }) async {
    final headers = await _authRemoteDataSource.getAuthorizationHeaders();
    if (headers == null || headers.isEmpty) return;

    final data = <String, dynamic>{
      'summary': summary,
      'description': description,
      'location': location,
      if (attendees.isNotEmpty)
        'attendees': attendees.map((email) => {'email': email}).toList(),
    };

    if (isAllDay) {
      data['start'] = {'date': DateTimeFormatter.apiDate(start)};
      data['end'] = {
        'date': DateTimeFormatter.apiDate(end.add(const Duration(days: 1))),
      };
    } else {
      data['start'] = {
        'dateTime': start.toUtc().toIso8601String(),
        'timeZone': 'Asia/Tokyo',
      };
      data['end'] = {
        'dateTime': end.toUtc().toIso8601String(),
        'timeZone': 'Asia/Tokyo',
      };
    }

    await _dio.post(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events',
      options: Options(headers: headers),
      queryParameters: {'sendUpdates': 'all'},
      data: data,
    );
  }

  Future<void> updateEvent({
    required String eventId,
    String? summary,
    String? description,
    String? location,
    List<String>? attendees,
    DateTime? start,
    DateTime? end,
    bool? isAllDay,
  }) async {
    final headers = await _authRemoteDataSource.getAuthorizationHeaders();
    if (headers == null || headers.isEmpty) return;

    final data = <String, dynamic>{};

    if (summary != null) data['summary'] = summary;
    if (description != null) data['description'] = description;
    if (location != null) data['location'] = location;
    if (attendees != null) {
      data['attendees'] = attendees.map((email) => {'email': email}).toList();
    }

    if (start != null && end != null) {
      if (isAllDay ?? false) {
        data['start'] = {'date': DateTimeFormatter.apiDate(start)};
        data['end'] = {
          'date': DateTimeFormatter.apiDate(end.add(const Duration(days: 1))),
        };
      } else {
        data['start'] = {
          'dateTime': start.toUtc().toIso8601String(),
          'timeZone': 'Asia/Tokyo',
        };
        data['end'] = {
          'dateTime': end.toUtc().toIso8601String(),
          'timeZone': 'Asia/Tokyo',
        };
      }
    }

    await _dio.patch(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events/$eventId',
      options: Options(headers: headers),
      queryParameters: {'sendUpdates': 'all'},
      data: data,
    );
  }

  Future<void> deleteEvent(String eventId) async {
    final headers = await _authRemoteDataSource.getAuthorizationHeaders();
    if (headers == null || headers.isEmpty) return;

    await _dio.delete(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events/$eventId',
      options: Options(headers: headers),
    );
  }

  Future<void> reauthenticate() {
    return _authRemoteDataSource.reauthenticate();
  }
}
