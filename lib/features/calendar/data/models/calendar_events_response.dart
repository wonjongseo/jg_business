/// Google Calendar events 응답 모델 모음이다.
class CalendarEventsResponse {
  const CalendarEventsResponse({
    required this.kind,
    required this.etag,
    required this.summary,
    required this.updated,
    required this.timeZone,
    required this.items,
  });

  final String? kind;
  final String? etag;
  final String? summary;
  final DateTime? updated;
  final String? timeZone;
  final List<CalendarEvent> items;

  factory CalendarEventsResponse.fromJson(Map<String, dynamic> json) {
    return CalendarEventsResponse(
      kind: json['kind'] as String?,
      etag: json['etag'] as String?,
      summary: json['summary'] as String?,
      updated:
          json['updated'] != null
              ? DateTime.tryParse(json['updated'] as String)
              : null,
      timeZone: json['timeZone'] as String?,
      items:
          (json['items'] as List<dynamic>? ?? [])
              .map(
                (item) => CalendarEvent.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.status,
    required this.htmlLink,
    required this.created,
    required this.updated,
    required this.summary,
    required this.description,
    required this.location,
    required this.creatorEmail,
    required this.organizerEmail,
    required this.attendees,
    required this.start,
    required this.end,
  });

  final String? id;
  final String? status;
  final String? htmlLink;
  final DateTime? created;
  final DateTime? updated;
  final String? summary;
  final String? description;
  final String? location;
  final String? creatorEmail;
  final String? organizerEmail;
  final List<CalendarAttendee> attendees;
  final EventDateTime? start;
  final EventDateTime? end;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String?,
      status: json['status'] as String?,
      htmlLink: json['htmlLink'] as String?,
      created:
          json['created'] != null
              ? DateTime.tryParse(json['created'] as String)
              : null,
      updated:
          json['updated'] != null
              ? DateTime.tryParse(json['updated'] as String)
              : null,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      creatorEmail:
          (json['creator'] as Map<String, dynamic>?)?['email'] as String?,
      organizerEmail:
          (json['organizer'] as Map<String, dynamic>?)?['email'] as String?,
      attendees:
          (json['attendees'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    CalendarAttendee.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      start:
          json['start'] != null
              ? EventDateTime.fromJson(json['start'] as Map<String, dynamic>)
              : null,
      end:
          json['end'] != null
              ? EventDateTime.fromJson(json['end'] as Map<String, dynamic>)
              : null,
    );
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, status: $status, htmlLink: $htmlLink, created: $created, updated: $updated, summary: $summary, description: $description, location: $location, creatorEmail: $creatorEmail, organizerEmail: $organizerEmail, start: $start, end: $end)';
  }
}

class CalendarAttendee {
  const CalendarAttendee({
    required this.email,
    required this.displayName,
    required this.responseStatus,
  });

  final String? email;
  final String? displayName;
  final String? responseStatus;

  String get label => displayName?.trim().isNotEmpty == true
      ? displayName!
      : (email ?? '');

  factory CalendarAttendee.fromJson(Map<String, dynamic> json) {
    return CalendarAttendee(
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      responseStatus: json['responseStatus'] as String?,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      if (email != null) 'email': email,
    };
  }
}

class EventDateTime {
  const EventDateTime({
    required this.dateTime,
    required this.date,
    required this.timeZone,
  });

  final DateTime? dateTime;
  final DateTime? date;
  final String? timeZone;

  bool get isAllDay => date != null && dateTime == null;

  factory EventDateTime.fromJson(Map<String, dynamic> json) {
    DateTime? parseToLocal(String key) {
      final value = json[key] as String?;
      if (value == null) return null;

      final parsed = DateTime.tryParse(value);
      if (parsed == null) return null;

      return parsed.toLocal();
    }

    return EventDateTime(
      dateTime: parseToLocal('dateTime'),
      date: parseToLocal('date'),
      timeZone: json['timeZone'] as String?,
    );
  }
}
