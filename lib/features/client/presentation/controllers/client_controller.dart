/// 고객 탭의 목록/선택 상태를 관리한다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/auth/presentation/controllers/auth_controller.dart';
import 'package:jg_business/features/client/data/models/client_entity.dart';
import 'package:jg_business/features/client/data/repositories/client_repository.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/features/meeting/data/repositories/meeting_record_repository.dart';
import 'package:jg_business/shared/utils/app_feedback.dart';

class ClientController extends GetxController {
  ClientController({
    required ClientRepository repository,
    required AuthController authController,
    required MeetingRecordRepository meetingRecordRepository,
  }) : _repository = repository,
       _authController = authController,
       _meetingRecordRepository = meetingRecordRepository;

  final ClientRepository _repository;
  final AuthController _authController;
  final MeetingRecordRepository _meetingRecordRepository;

  final searchCtrl = TextEditingController();
  final _clients = <ClientEntity>[].obs;
  final _selectedClientId = RxnString();
  final _selectedClientRecords = <MeetingRecordEntity>[].obs;
  final _isLoading = false.obs;
  final _isLoadingDetail = false.obs;
  final _isSaving = false.obs;

  List<ClientEntity> get clients => _clients;
  bool get isLoading => _isLoading.value;
  bool get isLoadingDetail => _isLoadingDetail.value;
  bool get isSaving => _isSaving.value;
  String? get selectedClientId => _selectedClientId.value;
  List<MeetingRecordEntity> get selectedClientRecords => _selectedClientRecords;
  List<MeetingRecordEntity> get nextActionRecords =>
      _selectedClientRecords
          .where((record) => (record.nextAction ?? '').trim().isNotEmpty)
          .take(3)
          .toList();

  List<ClientEntity> get filteredClients {
    final query = searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _clients;
    return _clients.where((client) {
      return client.companyName.toLowerCase().contains(query) ||
          (client.contactName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  ClientEntity? get selectedClient {
    final id = _selectedClientId.value;
    if (id == null) return null;
    for (final client in _clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    searchCtrl.addListener(() => _clients.refresh());
    fetchClients();
  }

  Future<void> fetchClients() async {
    try {
      _isLoading.value = true;
      final items = await _repository.fetchByUser(_authController.currentUserId);
      _clients.assignAll(items);
      if (_selectedClientId.value == null && items.isNotEmpty) {
        _selectedClientId.value = items.first.id;
      }
      await _loadSelectedClientRecords();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> selectClient(String clientId) async {
    _selectedClientId.value = clientId;
    await _loadSelectedClientRecords();
  }

  Future<void> _loadSelectedClientRecords() async {
    final clientId = _selectedClientId.value;
    if (clientId == null || clientId.isEmpty) {
      _selectedClientRecords.clear();
      return;
    }

    try {
      _isLoadingDetail.value = true;
      final records = await _meetingRecordRepository.byClientId(
        userId: _authController.currentUserId,
        clientId: clientId,
      );
      _selectedClientRecords.assignAll(records);
    } finally {
      _isLoadingDetail.value = false;
    }
  }

  Future<void> updateSelectedClient({
    required String companyName,
    required String contactName,
    required String phoneNumber,
    required String email,
    required String notes,
  }) async {
    final client = selectedClient;
    if (client == null) return;

    try {
      _isSaving.value = true;
      await _repository.updateClient(
        client: client,
        companyName: companyName,
        contactName: contactName,
        phoneNumber: phoneNumber,
        email: email,
        notes: notes,
      );
      await fetchClients();
      _selectedClientId.value = client.id;
      await _loadSelectedClientRecords();
      AppFeedback.success('保存完了', '顧客情報を更新しました。');
    } catch (_) {
      AppFeedback.error('保存失敗', '顧客情報の更新に失敗しました。');
    } finally {
      _isSaving.value = false;
    }
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
