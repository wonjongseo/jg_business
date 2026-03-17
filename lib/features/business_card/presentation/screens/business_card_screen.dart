/// 명함 OCR 결과를 확인하고 고객으로 저장하는 화면이다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/business_card/presentation/controllers/business_card_controller.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';
import 'package:jg_business/shared/widgets/app_panel.dart';
import 'package:jg_business/shared/widgets/custom_text_form_field.dart';

class BusinessCardScreen extends GetView<BusinessCardController> {
  const BusinessCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('名刺 OCR 登録')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OCR 원문', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '현재 단계ではカメラ OCR の代わりに、認識テキストを貼り付けて確認フローを先に実装しています。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      label: '認識テキスト',
                      hintText: '名刺 OCR 結果を貼り付けてください。',
                      controller: controller.rawTextCtrl,
                      maxLines: 8,
                      minLines: 8,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: controller.applyOcrDraft,
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        label: const Text('OCR 結果を適用'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CustomTextFormField(
                      label: '会社名',
                      hintText: '会社名を確認してください。',
                      controller: controller.companyNameCtrl,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      label: '担当者名',
                      hintText: '担当者名を確認してください。',
                      controller: controller.contactNameCtrl,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      label: '電話番号',
                      hintText: '電話番号を確認してください。',
                      controller: controller.phoneCtrl,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      label: 'メール',
                      hintText: 'メールアドレスを確認してください。',
                      controller: controller.emailCtrl,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      label: 'メモ',
                      hintText: '補足メモを残せます。',
                      controller: controller.notesCtrl,
                      maxLines: 4,
                      minLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => FilledButton.icon(
                    onPressed: controller.isSaving.value ? null : controller.save,
                    icon: controller.isSaving.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.badge_outlined),
                    label: Text(
                      controller.isSaving.value ? '保存中...' : '顧客として保存',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
