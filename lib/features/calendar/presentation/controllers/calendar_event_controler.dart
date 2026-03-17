import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/data/datasources/google_calendar_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/shared/extensions/string_x.dart';
import 'package:jg_business/shared/utils/date_time_formatter.dart';

class _TextEditingControllers {
  final summary = TextEditingController();
  final description = TextEditingController();
  final location = TextEditingController();
  final attendeeEmail = TextEditingController();
  final date = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();

  void dispose() {
    summary.dispose();
    description.dispose();
    location.dispose();
    attendeeEmail.dispose();
    date.dispose();
    start.dispose();
    end.dispose();
  }
}

class CalendarEventControler extends GetxController {
  CalendarEventControler({
    required GoogleCalendarRemoteDataSource remoteDataSource,
    CalendarEvent? event,
    required DateTime dateTime,
  }) : _remoteDataSource = remoteDataSource,
       selectedEvent = Rxn<CalendarEvent>(event),
       startDt = dateTime.obs,
       endDt = dateTime.add(const Duration(hours: 1)).obs,
       isAllDay = false.obs;

  final GoogleCalendarRemoteDataSource _remoteDataSource;

  final Rxn<CalendarEvent> selectedEvent;
  final Rx<DateTime> startDt;
  final Rx<DateTime> endDt;
  final RxBool isAllDay;
  final RxBool isSaving = false.obs;
  final attendees = <String>[].obs;
  final teCtrls = _TextEditingControllers();

  bool get isEditMode => selectedEvent.value != null;

  @override
  void onInit() {
    _hydrateInitialValues();
    _syncTextControllers();
    super.onInit();
  }

  void _hydrateInitialValues() {
    final event = selectedEvent.value;
    if (event == null) return;

    teCtrls.summary.text = event.summary ?? '';
    teCtrls.description.text = event.description ?? '';
    teCtrls.location.text = event.location ?? '';
    attendees.assignAll(
      event.attendees
          .map((attendee) => attendee.email)
          .whereType<String>()
          .where((email) => email.trim().isNotEmpty),
    );

    isAllDay.value = event.start?.isAllDay ?? false;

    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date;

    if (start != null) {
      startDt.value = start;
    }

    if (end != null) {
      endDt.value =
          isAllDay.value ? end.subtract(const Duration(days: 1)) : end;
    } else {
      endDt.value = startDt.value.add(const Duration(hours: 1));
    }
  }

  void _syncTextControllers() {
    if (isAllDay.value) {
      teCtrls.date.text = DateTimeFormatter.japaneseDate(startDt.value);
      teCtrls.start.text = DateTimeFormatter.japaneseDate(startDt.value);
      teCtrls.end.text = DateTimeFormatter.japaneseDate(endDt.value);
      return;
    }

    teCtrls.date.text = DateTimeFormatter.japaneseDate(startDt.value);
    teCtrls.start.text = DateTimeFormatter.meridiemTime(startDt.value);
    teCtrls.end.text = DateTimeFormatter.meridiemTime(endDt.value);
  }

  void updateDate(DateTime date) {
    final currentStart = startDt.value;
    final currentEnd = endDt.value;

    startDt.value = DateTime(
      date.year,
      date.month,
      date.day,
      currentStart.hour,
      currentStart.minute,
    );
    endDt.value = DateTime(
      date.year,
      date.month,
      date.day,
      currentEnd.hour,
      currentEnd.minute,
    );

    if (!isAllDay.value) {
      _ensureEndAfterStart();
    }
    _syncTextControllers();
  }

  void updateAllDayStartDate(DateTime date) {
    final currentStart = startDt.value;
    startDt.value = DateTime(date.year, date.month, date.day);

    if (endDt.value.isBefore(startDt.value)) {
      endDt.value = startDt.value;
    } else {
      endDt.value = DateTime(
        endDt.value.year,
        endDt.value.month,
        endDt.value.day,
      );
    }

    // Preserve prior duration only for timed events.
    if (!isAllDay.value) {
      startDt.value = DateTime(
        date.year,
        date.month,
        date.day,
        currentStart.hour,
        currentStart.minute,
      );
    }

    _syncTextControllers();
  }

  void updateAllDayEndDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isBefore(DateTime(startDt.value.year, startDt.value.month, startDt.value.day))) {
      return;
    }

    endDt.value = normalized;
    _syncTextControllers();
  }

  void updateStartTime(TimeOfDay time) {
    if (isAllDay.value) return;

    final currentStart = startDt.value;
    startDt.value = DateTime(
      currentStart.year,
      currentStart.month,
      currentStart.day,
      time.hour,
      time.minute,
    );

    _ensureEndAfterStart();
    _syncTextControllers();
  }

  void updateEndTime(TimeOfDay time) {
    if (isAllDay.value) return;

    final currentEnd = endDt.value;
    final nextEnd = DateTime(
      currentEnd.year,
      currentEnd.month,
      currentEnd.day,
      time.hour,
      time.minute,
    );

    if (!nextEnd.isAfter(startDt.value)) {
      return;
    }

    endDt.value = nextEnd;
    _syncTextControllers();
  }

  void toggleAllDay(bool value) {
    isAllDay.value = value;

    if (!value) {
      _ensureEndAfterStart();
    }

    _syncTextControllers();
  }

  void addAttendee() {
    final email = teCtrls.attendeeEmail.text.nullIfBlank;
    if (email == null) return;
    if (attendees.contains(email)) {
      teCtrls.attendeeEmail.clear();
      return;
    }

    attendees.add(email);
    teCtrls.attendeeEmail.clear();
  }

  void removeAttendee(String email) {
    attendees.remove(email);
  }

  Future<void> submit() async {
    final summary = teCtrls.summary.text.trim();
    if (summary.isEmpty) return;

    try {
      isSaving.value = true;

      if (isEditMode && selectedEvent.value?.id != null) {
        await _remoteDataSource.updateEvent(
          eventId: selectedEvent.value!.id!,
          summary: summary,
          description: teCtrls.description.text.nullIfBlank,
          location: teCtrls.location.text.nullIfBlank,
          attendees: attendees.toList(),
          start: startDt.value,
          end: endDt.value,
          isAllDay: isAllDay.value,
        );
      } else {
        await _remoteDataSource.createEvent(
          summary: summary,
          description: teCtrls.description.text.nullIfBlank,
          location: teCtrls.location.text.nullIfBlank,
          attendees: attendees.toList(),
          start: startDt.value,
          end: endDt.value,
          isAllDay: isAllDay.value,
        );
      }

      if (Get.isRegistered<CalendarController>()) {
        await Get.find<CalendarController>().fetchCalendar();
      }
      Get.back<void>();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteEvent() async {
    final eventId = selectedEvent.value?.id;
    if (eventId == null) return;

    try {
      isSaving.value = true;
      await _remoteDataSource.deleteEvent(eventId);
      if (Get.isRegistered<CalendarController>()) {
        await Get.find<CalendarController>().fetchCalendar();
      }
      Get.back<void>();
    } finally {
      isSaving.value = false;
    }
  }

  void _ensureEndAfterStart() {
    if (endDt.value.isAfter(startDt.value)) {
      return;
    }

    endDt.value = startDt.value.add(const Duration(hours: 1));
  }

  @override
  void onClose() {
    teCtrls.dispose();
    super.onClose();
  }
}
