/// 고객 탭의 목록/선택 상태를 관리한다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/client/data/models/client_entity.dart';
import 'package:jg_business/features/client/data/repositories/client_repository.dart';

class ClientController extends GetxController {
  ClientController({
    required ClientRepository repository,
    required GoogleAuthRemoteDataSource authRemoteDataSource,
  }) : _repository = repository,
       _authRemoteDataSource = authRemoteDataSource;

  final ClientRepository _repository;
  final GoogleAuthRemoteDataSource _authRemoteDataSource;

  final searchCtrl = TextEditingController();
  final _clients = <ClientEntity>[].obs;
  final _selectedClientId = RxnString();
  final _isLoading = false.obs;

  List<ClientEntity> get clients => _clients;
  bool get isLoading => _isLoading.value;
  String? get selectedClientId => _selectedClientId.value;

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
      final items = await _repository.fetchByUser(_authRemoteDataSource.currentUserId);
      _clients.assignAll(items);
      if (_selectedClientId.value == null && items.isNotEmpty) {
        _selectedClientId.value = items.first.id;
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void selectClient(String clientId) {
    _selectedClientId.value = clientId;
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
