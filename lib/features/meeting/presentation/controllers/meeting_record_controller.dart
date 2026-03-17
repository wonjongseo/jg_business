/// 미팅 기록 입력 화면의 로딩/저장 상태를 관리한다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/client/data/models/client_entity.dart';
import 'package:jg_business/features/client/data/repositories/client_repository.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_status_repository.dart';
import 'package:jg_business/shared/utils/app_feedback.dart';

class MeetingRecordController extends GetxController {
  MeetingRecordController({
    required MeetingRecordRepository repository,
    required MeetingStatusRepository meetingStatusRepository,
    required ClientRepository clientRepository,
    required GoogleAuthRemoteDataSource authRemoteDataSource,
    required CalendarEvent event,
  }) : _repository = repository,
       _meetingStatusRepository = meetingStatusRepository,
       _clientRepository = clientRepository,
       _authRemoteDataSource = authRemoteDataSource,
       event = event;

  final MeetingRecordRepository _repository;
  final MeetingStatusRepository _meetingStatusRepository;
  final ClientRepository _clientRepository;
  final GoogleAuthRemoteDataSource _authRemoteDataSource;
  final CalendarEvent event;

  final companyNameCtrl = TextEditingController();
  final contactNameCtrl = TextEditingController();
  final summaryCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final nextActionCtrl = TextEditingController();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isDeleting = false.obs;
  final existingRecordId = RxnString();
  final sheetsSyncStatus = 'pending'.obs;
  final _clients = <ClientEntity>[].obs;
  final selectedClientId = RxnString();

  bool get isEditMode => existingRecordId.value != null;
  List<ClientEntity> get clients => _clients;
  String get recordDocumentId =>
      existingRecordId.value ??
      (event.id == null || event.id!.isEmpty
          ? '未生成'
          : '${_currentUserId}_${event.id!}');
  String get recordDocumentPath => 'meeting_records/$recordDocumentId';

  @override
  void onInit() {
    super.onInit();
    _prefillFromCalendar();
    _loadClients();
    _loadExistingRecord();
  }

  void _prefillFromCalendar() {
    companyNameCtrl.text = event.summary ?? '';
    final firstAttendee = event.attendees.isNotEmpty ? event.attendees.first : null;
    contactNameCtrl.text = firstAttendee?.label ?? '';
  }

  Future<void> _loadExistingRecord() async {
    /// 같은 일정에 대한 기존 기록이 있으면 수정 모드로 불러온다.
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
      sheetsSyncStatus.value = record.sheetsSyncStatus;
      selectedClientId.value = record.clientId;
      companyNameCtrl.text = record.companyName ?? companyNameCtrl.text;
      contactNameCtrl.text = record.contactName ?? contactNameCtrl.text;
      summaryCtrl.text = record.summary;
      notesCtrl.text = record.notes ?? '';
      nextActionCtrl.text = record.nextAction ?? '';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadClients() async {
    final clients = await _clientRepository.fetchByUser(_currentUserId);
    _clients.assignAll(clients);
    _trySelectMatchedClient();
  }

  void _trySelectMatchedClient() {
    if (selectedClientId.value != null) return;
    final company = companyNameCtrl.text.trim().toLowerCase();
    final contact = contactNameCtrl.text.trim().toLowerCase();
    if (company.isEmpty) return;

    for (final client in _clients) {
      final companyMatches = client.companyName.trim().toLowerCase() == company;
      final contactMatches =
          contact.isEmpty ||
          (client.contactName ?? '').trim().toLowerCase() == contact;
      if (companyMatches && contactMatches) {
        selectedClientId.value = client.id;
        return;
      }
    }
  }

  void onClientSelected(String? clientId) {
    selectedClientId.value = clientId;
    if (clientId == null || clientId.isEmpty) return;

    for (final client in _clients) {
      if (client.id != clientId) continue;
      companyNameCtrl.text = client.companyName;
      contactNameCtrl.text = client.contactName ?? '';
      break;
    }
  }

  String get _currentUserId {
    return _authRemoteDataSource.currentUserId;
  }

  Future<void> save() async {
    /// 기록과 상태를 함께 저장한 뒤 캘린더/홈 상태를 다시 읽는다.
    if (summaryCtrl.text.trim().isEmpty) return;

    final googleEventId = event.id;
    if (googleEventId == null || googleEventId.isEmpty) return;

    try {
      isSaving.value = true;
      final recordId = existingRecordId.value ?? '${_currentUserId}_$googleEventId';
      final client = await _clientRepository.upsertFromMeeting(
        userId: _currentUserId,
        selectedClientId: selectedClientId.value,
        companyName: companyNameCtrl.text.trim(),
        contactName: contactNameCtrl.text.trim(),
        googleEventId: googleEventId,
        meetingAt: event.end?.dateTime ?? event.start?.dateTime ?? event.start?.date,
      );

      await _repository.save(
        MeetingRecordEntity(
          id: recordId,
          userId: _currentUserId,
          clientId: client.id,
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
          status: 'completed',
          createdAt: null,
          updatedAt: null,
          sheetsSyncStatus: 'pending',
          sheetsLastAttemptAt: null,
          sheetsLastSyncedAt: null,
          sheetsErrorCode: null,
        ),
      );
      await _meetingStatusRepository.markRecordCompleted(
        userId: _currentUserId,
        event: event,
      );

      existingRecordId.value = recordId;
      selectedClientId.value = client.id;
      sheetsSyncStatus.value = 'pending';
      await _loadClients();
      if (Get.isRegistered<CalendarController>()) {
        await Get.find<CalendarController>().fetchCalendar(interactive: false);
      }
      AppFeedback.success(
        '保存完了',
        'ミーティング記録を Firestore に保存しました。',
      );
      Get.back<void>();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteRecord() async {
    final recordId = existingRecordId.value;
    if (recordId == null || recordId.isEmpty) {
      return;
    }

    try {
      isDeleting.value = true;
      await _repository.delete(recordId);
      await _meetingStatusRepository.markRecordDeleted(
        userId: _currentUserId,
        event: event,
      );
      existingRecordId.value = null;
      sheetsSyncStatus.value = 'pending';
      if (Get.isRegistered<CalendarController>()) {
        await Get.find<CalendarController>().fetchCalendar(interactive: false);
      }
      AppFeedback.success(
        '削除完了',
        'ミーティング記録を削除しました。',
      );
      Get.back<void>();
    } finally {
      isDeleting.value = false;
    }
  }

  String get sheetsSyncStatusLabel {
    switch (sheetsSyncStatus.value) {
      case 'synced':
        return '同期完了';
      case 'failed':
        return '同期失敗';
      case 'syncing':
        return '同期中';
      default:
        return '未同期';
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
