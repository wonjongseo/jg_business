class CalendarEventEntity {
  const CalendarEventEntity({
    required this.id,
    required this.summary,
    required this.description,
    required this.location,
    required this.status,
    required this.startDateTime,
    required this.startDate,
    required this.endDateTime,
    required this.endDate,
    required this.updated,
  });

  final String id;
  final String? summary;
  final String? description;
  final String? location;
  final String? status;
  final String? startDateTime;
  final String? startDate;
  final String? endDateTime;
  final String? endDate;
  final String? updated;

  bool get isAllDay => startDate != null && startDateTime == null;

  factory CalendarEventEntity.fromApi(Map<String, dynamic> json) {
    final start = json['start'] as Map<String, dynamic>?;
    final end = json['end'] as Map<String, dynamic>?;

    return CalendarEventEntity(
      id: json['id'] as String,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String?,
      startDateTime: start?['dateTime'] as String?,
      startDate: start?['date'] as String?,
      endDateTime: end?['dateTime'] as String?,
      endDate: end?['date'] as String?,
      updated: json['updated'] as String?,
    );
  }

  factory CalendarEventEntity.fromDb(Map<String, Object?> map) {
    return CalendarEventEntity(
      id: map['id'] as String,
      summary: map['summary'] as String?,
      description: map['description'] as String?,
      location: map['location'] as String?,
      status: map['status'] as String?,
      startDateTime: map['start_date_time'] as String?,
      startDate: map['start_date'] as String?,
      endDateTime: map['end_date_time'] as String?,
      endDate: map['end_date'] as String?,
      updated: map['updated'] as String?,
    );
  }

  Map<String, Object?> toDb() {
    return {
      'id': id,
      'summary': summary,
      'description': description,
      'location': location,
      'status': status,
      'start_date_time': startDateTime,
      'start_date': startDate,
      'end_date_time': endDateTime,
      'end_date': endDate,
      'updated': updated,
    };
  }
}
