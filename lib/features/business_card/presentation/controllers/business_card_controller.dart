/// 명함 OCR 초안 입력과 고객 저장을 관리한다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/business_card/data/models/business_card_entity.dart';
import 'package:jg_business/features/business_card/data/repositories/business_card_repository.dart';
import 'package:jg_business/features/client/data/repositories/client_repository.dart';
import 'package:jg_business/features/client/presentation/controllers/client_controller.dart';
import 'package:jg_business/shared/utils/app_feedback.dart';

class BusinessCardController extends GetxController {
  BusinessCardController({
    required BusinessCardRepository businessCardRepository,
    required ClientRepository clientRepository,
    required GoogleAuthRemoteDataSource authRemoteDataSource,
  }) : _businessCardRepository = businessCardRepository,
       _clientRepository = clientRepository,
       _authRemoteDataSource = authRemoteDataSource;

  final BusinessCardRepository _businessCardRepository;
  final ClientRepository _clientRepository;
  final GoogleAuthRemoteDataSource _authRemoteDataSource;

  final rawTextCtrl = TextEditingController();
  final companyNameCtrl = TextEditingController();
  final contactNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final isSaving = false.obs;

  void applyOcrDraft() {
    final lines = rawTextCtrl.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    companyNameCtrl.text = _pickCompany(lines);
    contactNameCtrl.text = _pickContact(lines);
    phoneCtrl.text = _extractPhone(rawTextCtrl.text) ?? '';
    emailCtrl.text = _extractEmail(rawTextCtrl.text) ?? '';
    notesCtrl.text = rawTextCtrl.text.trim();
  }

  Future<void> save() async {
    final companyName = companyNameCtrl.text.trim();
    if (companyName.isEmpty) {
      AppFeedback.error(
        '保存不可',
        '会社名を入力してください。',
      );
      return;
    }

    try {
      isSaving.value = true;
      final userId = _authRemoteDataSource.currentUserId;
      final now = DateTime.now();
      final client = await _clientRepository.upsertFromBusinessCard(
        userId: userId,
        companyName: companyName,
        contactName: contactNameCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
      );

      await _businessCardRepository.save(
        BusinessCardEntity(
          id: '${userId}_${now.millisecondsSinceEpoch}',
          userId: userId,
          sourceType: 'manual_ocr_draft',
          imagePath: null,
          rawText: rawTextCtrl.text.trim(),
          companyName: companyName,
          contactName: contactNameCtrl.text.trim().isEmpty
              ? null
              : contactNameCtrl.text.trim(),
          phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          ocrStatus: 'confirmed',
          linkedClientId: client.id,
          createdAt: null,
          updatedAt: null,
        ),
      );

      if (Get.isRegistered<ClientController>()) {
        await Get.find<ClientController>().fetchClients();
      }

      AppFeedback.success(
        '保存完了',
        '名刺情報を顧客に登録しました。',
      );
      Get.back<void>();
    } finally {
      isSaving.value = false;
    }
  }

  String _pickCompany(List<String> lines) {
    for (final line in lines) {
      if (line.contains('株式会社') ||
          line.contains('有限会社') ||
          line.toLowerCase().contains('corp') ||
          line.toLowerCase().contains('inc') ||
          line.toLowerCase().contains('company')) {
        return line;
      }
    }
    return lines.isNotEmpty ? lines.first : '';
  }

  String _pickContact(List<String> lines) {
    final company = _pickCompany(lines);
    for (final line in lines) {
      final hasEmail = line.contains('@');
      final hasPhone = RegExp(r'\d{2,4}[- ]?\d{3,4}[- ]?\d{4}').hasMatch(line);
      if (hasEmail || hasPhone) continue;
      if (line == company) continue;
      if (line.length <= 20) {
        return line;
      }
    }
    return lines.length >= 2 ? lines[1] : '';
  }

  String? _extractEmail(String value) {
    final match = RegExp(
      r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ).firstMatch(value);
    return match?.group(0);
  }

  String? _extractPhone(String value) {
    final match =
        RegExp(r'(\+?\d[\d -]{8,}\d)').firstMatch(value.replaceAll('\n', ' '));
    return match?.group(0)?.trim();
  }

  @override
  void onClose() {
    rawTextCtrl.dispose();
    companyNameCtrl.dispose();
    contactNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}
