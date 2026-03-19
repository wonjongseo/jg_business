import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/client/data/models/client_entity.dart';
import 'package:jg_business/features/client/data/repositories/client_repository.dart';
import 'package:jg_business/features/auth/presentation/controllers/auth_controller.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_status_repository.dart';
import 'package:jg_business/features/spreadsheet_sync/data/repositories/spreadsheet_sync_repository.dart';
import 'package:jg_business/shared/utils/app_feedback.dart';

class MeetingRecordController extends GetxController {
  MeetingRecordController({
    required MeetingRecordRepository repository,
    required MeetingStatusRepository meetingStatusRepository,
    required ClientRepository clientRepository,
    required SpreadsheetSyncRepository spreadsheetSyncRepository,
    required AuthController authController,
    required CalendarEvent event,
  }) : _repository = repository,
       _meetingStatusRepository = meetingStatusRepository,
       _clientRepository = clientRepository,
       _spreadsheetSyncRepository = spreadsheetSyncRepository,
       _authController = authController,
       event = event;

  final MeetingRecordRepository _repository;
  final MeetingStatusRepository _meetingStatusRepository;
  final ClientRepository _clientRepository;
  final SpreadsheetSyncRepository _spreadsheetSyncRepository;
  final AuthController _authController;
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
  List<ClientEntity> get clients => _uniqueClients(_clients);
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
    /// 일정 제목은 고객명과 같은 의미가 아니므로 회사명 필드를 자동으로 채우지 않는다.
    /// 회사명은 등록된 고객 선택 또는 사용자의 직접 입력으로만 정한다.
    companyNameCtrl.text = '';
    /// 참석자는 참고 정보일 뿐 실제 고객 담당자로 단정할 수 없으므로 자동 입력하지 않는다.
    contactNameCtrl.text = '';
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
      companyNameCtrl.text = record.companyName ?? '';
      contactNameCtrl.text = record.contactName ?? '';
      summaryCtrl.text = record.summary;
      notesCtrl.text = record.notes ?? '';
      nextActionCtrl.text = record.nextAction ?? '';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadClients() async {
    final clients = await _clientRepository.fetchByUser(_currentUserId);
    _clients.assignAll(_uniqueClients(clients));
    _normalizeSelectedClientId();
    _trySelectMatchedClient();
  }

  List<ClientEntity> _uniqueClients(Iterable<ClientEntity> clients) {
    /// 드롭다운의 value 는 반드시 하나의 항목에만 매칭되어야 하므로
    /// 같은 id 를 가진 고객이 섞여 있으면 여기서 먼저 정리한다.
    final uniqueById = <String, ClientEntity>{};
    for (final client in clients) {
      uniqueById[client.id] = client;
    }
    return uniqueById.values.toList();
  }

  void _normalizeSelectedClientId() {
    final currentId = selectedClientId.value;
    if (currentId == null) return;

    final exists = _clients.any((client) => client.id == currentId);
    if (!exists) {
      selectedClientId.value = null;
    }
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
    return _authController.currentUserId;
  }

  String? get currentUserEmail => _authController.currentUserEmail;

  Future<void> save() async {
    /// 기록과 상태를 함께 저장한 뒤 캘린더/홈 상태를 다시 읽는다.
    if (summaryCtrl.text.trim().isEmpty) return;

    final googleEventId = event.id;
    if (googleEventId == null || googleEventId.isEmpty) return;

    try {
      isSaving.value = true;
      final recordId =
          existingRecordId.value ?? '${_currentUserId}_$googleEventId';
      final client = await _clientRepository.upsertFromMeeting(
        userId: _currentUserId,
        selectedClientId: selectedClientId.value,
        companyName: companyNameCtrl.text.trim(),
        contactName: contactNameCtrl.text.trim(),
        googleEventId: googleEventId,
        meetingAt:
            event.end?.dateTime ?? event.start?.dateTime ?? event.start?.date,
      );

      final record = MeetingRecordEntity(
        id: recordId,
        userId: _currentUserId,
        clientId: client.id,
        googleEventId: googleEventId,
        calendarId: 'primary',
        title: event.summary ?? 'タイトル未設定',
        companyName:
            companyNameCtrl.text.trim().isEmpty
                ? null
                : companyNameCtrl.text.trim(),
        contactName:
            contactNameCtrl.text.trim().isEmpty
                ? null
                : contactNameCtrl.text.trim(),
        scheduledStartAt: event.start?.dateTime ?? event.start?.date,
        scheduledEndAt: event.end?.dateTime ?? event.end?.date,
        locationName: event.location,
        summary: summaryCtrl.text.trim(),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        nextAction:
            nextActionCtrl.text.trim().isEmpty
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
      );

      await _repository.save(record);
      await _syncToSheets(record);
      await _meetingStatusRepository.markRecordCompleted(
        userId: _currentUserId,
        event: event,
      );

      existingRecordId.value = recordId;
      selectedClientId.value = client.id;
      await _refreshSheetsSyncStatus(recordId);
      await _loadClients();
      if (Get.isRegistered<CalendarController>()) {
        await Get.find<CalendarController>().fetchCalendar(interactive: false);
      }
      if (sheetsSyncStatus.value == 'synced') {
        AppFeedback.success(
          '保存完了',
          'ミーティング記録を保存し、Google Sheets に同期しました。',
        );
      } else {
        AppFeedback.info(
          '保存完了',
          'ミーティング記録は保存しましたが、Sheets 同期は失敗しました。',
        );
      }
      Get.back<void>();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _syncToSheets(MeetingRecordEntity record) async {
    final attemptedAt = DateTime.now();

    try {
      await _repository.updateSheetsSyncState(
        recordId: record.id,
        status: 'syncing',
        attemptedAt: attemptedAt,
        errorCode: null,
      );
      sheetsSyncStatus.value = 'syncing';

      await _spreadsheetSyncRepository.syncMeetingRecord(record);

      await _repository.updateSheetsSyncState(
        recordId: record.id,
        status: 'synced',
        attemptedAt: attemptedAt,
        syncedAt: DateTime.now(),
        errorCode: null,
      );
      sheetsSyncStatus.value = 'synced';
    } catch (error) {
      await _repository.updateSheetsSyncState(
        recordId: record.id,
        status: 'failed',
        attemptedAt: attemptedAt,
        errorCode: _mapSyncError(error),
      );
      sheetsSyncStatus.value = 'failed';
    }
  }

  Future<void> _refreshSheetsSyncStatus(String recordId) async {
    final googleEventId = event.id;
    if (googleEventId == null || googleEventId.isEmpty) return;

    final savedRecord = await _repository.findByGoogleEventId(
      userId: _currentUserId,
      googleEventId: googleEventId,
    );
    if (savedRecord == null || savedRecord.id != recordId) return;
    sheetsSyncStatus.value = savedRecord.sheetsSyncStatus;
  }

  String _mapSyncError(Object error) {
    final text = error.toString();
    if (text.contains('missing_sheets_config')) {
      return 'missing_sheets_config';
    }
    if (text.contains('missing_google_auth')) {
      return 'missing_google_auth';
    }
    return 'sync_failed';
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
      AppFeedback.success('削除完了', 'ミーティング記録を削除しました。');
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
