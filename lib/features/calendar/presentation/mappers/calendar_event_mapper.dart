/// Google Calendar 이벤트를 calendar_view 위젯 모델로 변환한다.
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';

class CalendarEventMapper {
  static List<CalendarEventData<CalendarEvent>> toCalendarViewEvents(
    List<CalendarEvent> source,
  ) {
    return source.map((event) {
      final isAllDay = event.start?.isAllDay ?? false;
      final start =
          event.start?.dateTime ?? event.start?.date ?? DateTime.now();

      return CalendarEventData<CalendarEvent>(
        date: start,
        title: event.summary ?? '(제목 없음)',
        description: event.description,
        startTime: isAllDay ? null : event.start?.dateTime,
        endTime: isAllDay ? null : event.end?.dateTime,
        color: isAllDay ? Colors.orange : Colors.blue,
        event: event,
      );
    }).toList();
  }
}
