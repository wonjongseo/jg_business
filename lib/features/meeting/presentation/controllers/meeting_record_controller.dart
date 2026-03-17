import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';

class MeetingRecordController extends GetxController {
  MeetingRecordController({
    required MeetingRecordRepository repository,
    required GoogleAuthRemoteDataSource authRemoteDataSource,
    required CalendarEvent event,
  }) : _repository = repository,
       _authRemoteDataSource = authRemoteDataSource,
       event = event;

  final MeetingRecordRepository _repository;
  final GoogleAuthRemoteDataSource _authRemoteDataSource;
  final CalendarEvent event;

  final companyNameCtrl = TextEditingController();
  final contactNameCtrl = TextEditingController();
  final summaryCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final nextActionCtrl = TextEditingController();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final existingRecordId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _prefillFromCalendar();
    _loadExistingRecord();
  }

  void _prefillFromCalendar() {
    companyNameCtrl.text = event.summary ?? '';
    final firstAttendee = event.attendees.isNotEmpty ? event.attendees.first : null;
    contactNameCtrl.text = firstAttendee?.label ?? '';
  }

  Future<void> _loadExistingRecord() async {
    final googleEventId = event.id;
    if (googleEventId == null || googleEventId.isEmpty) return;

    try {
      isLoading.value = true;
      final userId = _currentUserId;
      final record = await _repository.findByGoogleEventId(
        userId: userId,
        googleEventId: googleEventId,
      );
      if (record == null) return;

      existingRecordId.value = record.id;
      companyNameCtrl.text = record.companyName ?? companyNameCtrl.text;
      contactNameCtrl.text = record.contactName ?? contactNameCtrl.text;
      summaryCtrl.text = record.summary;
      notesCtrl.text = record.notes ?? '';
      nextActionCtrl.text = record.nextAction ?? '';
    } finally {
      isLoading.value = false;
    }
  }

  String get _currentUserId {
    final email = _authRemoteDataSource.currentUserEmail;
    if (email != null && email.trim().isNotEmpty) return email.trim();
    return 'local-user';
  }

  Future<void> save() async {
    if (summaryCtrl.text.trim().isEmpty) return;

    final googleEventId = event.id;
    if (googleEventId == null || googleEventId.isEmpty) return;

    try {
      isSaving.value = true;
      final recordId = existingRecordId.value ?? '${_currentUserId}_$googleEventId';

      await _repository.save(
        MeetingRecordEntity(
          id: recordId,
          userId: _currentUserId,
          googleEventId: googleEventId,
          calendarId: 'primary',
          title: event.summary ?? 'タイトル未設定',
          companyName: companyNameCtrl.text.trim().isEmpty
              ? null
              : companyNameCtrl.text.trim(),
          contactName: contactNameCtrl.text.trim().isEmpty
              ? null
              : contactNameCtrl.text.trim(),
          scheduledStartAt: event.start?.dateTime ?? event.start?.date,
          scheduledEndAt: event.end?.dateTime ?? event.end?.date,
          locationName: event.location,
          summary: summaryCtrl.text.trim(),
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          nextAction: nextActionCtrl.text.trim().isEmpty
              ? null
              : nextActionCtrl.text.trim(),
          nextActionDueAt: null,
          status: 'draft',
          createdAt: null,
          updatedAt: null,
          sheetsSyncStatus: 'pending',
          sheetsLastAttemptAt: null,
          sheetsLastSyncedAt: null,
          sheetsErrorCode: null,
        ),
      );

      existingRecordId.value = recordId;
      Get.snackbar(
        '保存完了',
        'ミーティング記録を Firestore に保存しました。',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back<void>();
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    companyNameCtrl.dispose();
    contactNameCtrl.dispose();
    summaryCtrl.dispose();
    notesCtrl.dispose();
    nextActionCtrl.dispose();
    super.onClose();
  }
}
