/// 미팅 기록을 입력하고 Firestore에 저장하는 화면이다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jg_business/features/meeting/presentation/controllers/meeting_record_controller.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';
import 'package:jg_business/shared/widgets/custom_text_form_field.dart';

class MeetingRecordScreen extends GetView<MeetingRecordController> {
  const MeetingRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = controller.event;
    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4E7C9), Color(0xFFF8F5EE), Color(0xFFD9ECE5)],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back<void>(),
                        icon: const Icon(Icons.arrow_back_ios_new),
                      ),
                      Expanded(
                        child: Obx(
                          () => Text(
                            controller.isEditMode
                                ? 'ミーティング記録を修正'
                                : 'ミーティング記録を作成',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ),
                      Obx(
                        () => TextButton(
                          onPressed: controller.isSaving.value ? null : controller.save,
                          child: Text(
                            controller.isSaving.value
                                ? '保存中...'
                                : controller.isEditMode
                                ? '更新'
                                : '保存',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(
                          title: event.summary ?? 'タイトル未設定',
                          subtitle: _formatSchedule(start, end, event.location),
                        ),
                        const SizedBox(height: 18),
                        _FormPanel(
                          title: '基本情報',
                          child: Column(
                            children: [
                              Obx(
                                () => DropdownButtonFormField<String?>(
                                  value: controller.selectedClientId.value,
                                  decoration: const InputDecoration(
                                    labelText: '既存顧客',
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('新しい顧客として保存'),
                                    ),
                                    ...controller.clients.map(
                                      (client) => DropdownMenuItem<String?>(
                                        value: client.id,
                                        child: Text(client.displayName),
                                      ),
                                    ),
                                  ],
                                  onChanged: controller.onClientSelected,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CustomTextFormField(
                                label: '会社名',
                                hintText: '会社名を入力してください。',
                                controller: controller.companyNameCtrl,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              CustomTextFormField(
                                label: '担当者名',
                                hintText: '担当者名を入力してください。',
                                controller: controller.contactNameCtrl,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FormPanel(
                          title: '記録内容',
                          child: Column(
                            children: [
                              CustomTextFormField(
                                label: '要約',
                                hintText: '面談の要点を入力してください。',
                                controller: controller.summaryCtrl,
                                textInputAction: TextInputAction.next,
                                maxLines: 3,
                                minLines: 3,
                              ),
                              const SizedBox(height: 16),
                              CustomTextFormField(
                                label: '詳細メモ',
                                hintText: '話した内容、決定事項、懸念点などを記録します。',
                                controller: controller.notesCtrl,
                                textInputAction: TextInputAction.next,
                                maxLines: 6,
                                minLines: 6,
                              ),
                              const SizedBox(height: 16),
                              CustomTextFormField(
                                label: '次のアクション',
                                hintText: '次に取るべき行動を入力してください。',
                                controller: controller.nextActionCtrl,
                                textInputAction: TextInputAction.done,
                                maxLines: 3,
                                minLines: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Obx(
                          () => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            child: Text(
                              '保存先: Firestore / ${controller.recordDocumentPath}\n'
                              '顧客連携: ${controller.selectedClientId.value ?? '新規作成'}\n'
                              '記録状態: completed として保存\n'
                              'Sheets同期状態: ${controller.sheetsSyncStatusLabel}\n'
                              'Sheets同期は予定詳細画面から実行できます。',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Obx(() {
                          if (!controller.isEditMode) {
                            return const SizedBox.shrink();
                          }

                          return SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  controller.isDeleting.value
                                      ? null
                                      : controller.deleteRecord,
                              icon:
                                  controller.isDeleting.value
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.delete_outline),
                              label: Text(
                                controller.isDeleting.value
                                    ? '削除中...'
                                    : '記録を削除',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173C3A), Color(0xFF0F766E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

String _formatSchedule(DateTime? start, DateTime? end, String? location) {
  if (start == null) return '日時未設定';
  final dateFormatter = DateFormat('M月d日(E)', 'ja_JP');
  final timeFormatter = DateFormat('HH:mm');
  final dateText = dateFormatter.format(start);
  final startText = timeFormatter.format(start);
  final endText = end != null ? timeFormatter.format(end) : '--:--';
  final locationText =
      location?.trim().isNotEmpty == true ? '  ${location!.trim()}' : '';
  return '$dateText  $startText - $endText$locationText';
}
