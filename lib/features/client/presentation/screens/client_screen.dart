/// 고객 목록과 기본 상세 정보를 보여주는 화면이다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/client/data/models/client_entity.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/features/client/presentation/controllers/client_controller.dart';
import 'package:jg_business/shared/layout/app_responsive.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';
import 'package:jg_business/shared/widgets/app_panel.dart';
import 'package:jg_business/shared/widgets/custom_text_form_field.dart';

class ClientScreen extends GetView<ClientController> {
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final useSplitLayout = AppResponsive.useSplitClientLayout(context);

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child:
                useSplitLayout
                    ? Row(
                      children: [
                        SizedBox(
                          width: AppResponsive.clientListPaneWidth,
                          child: _ClientListPane(),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(child: _ClientDetailPane()),
                      ],
                    )
                    : Column(
                      children: [
                        const _ClientListHeader(),
                        const SizedBox(height: 16),
                        const Expanded(child: _ClientListPane()),
                      ],
                    ),
          );
        }),
      ),
    );
  }
}

class _ClientListHeader extends GetView<ClientController> {
  const _ClientListHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('顧客', style: theme.textTheme.headlineSmall)),
            FilledButton.tonalIcon(
              onPressed: () => Get.toNamed(AppRoutes.businessCard),
              icon: const Icon(Icons.badge_outlined),
              label: const Text('名刺登録'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.searchCtrl,
          decoration: const InputDecoration(
            hintText: '会社名または担当者名で検索',
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ],
    );
  }
}

class _ClientListPane extends GetView<ClientController> {
  const _ClientListPane();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = controller.filteredClients;

    return AppPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (AppResponsive.useSplitClientLayout(context))
            const _ClientListHeader(),
          if (AppResponsive.useSplitClientLayout(context))
            const SizedBox(height: 16),
          Text('登録済み顧客 ${items.length}件', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'まだ登録された顧客がありません。\n面談記録または名刺登録から顧客が作成されます。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final client = items[index];
                  final selected = controller.selectedClientId == client.id;
                  final useSplitLayout = AppResponsive.useSplitClientLayout(
                    context,
                  );
                  return InkWell(
                    onTap: () async {
                      await controller.selectClient(client.id);
                      if (!useSplitLayout && context.mounted) {
                        Get.to(() => _ClientDetailMobileScreen());
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? AppColors.accentSoft
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.companyName,
                            style: theme.textTheme.titleMedium,
                          ),
                          if (client.contactName?.trim().isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 6),
                            Text(
                              client.contactName!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '連携面談 ${client.linkedGoogleEventIds.length}件',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          if (!useSplitLayout) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '詳細を見る',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, size: 18),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientDetailPane extends GetView<ClientController> {
  const _ClientDetailPane();

  @override
  Widget build(BuildContext context) {
    return const _ClientDetailContent();
  }
}

class _ClientDetailMobileScreen extends StatelessWidget {
  const _ClientDetailMobileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('顧客詳細')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: _ClientDetailContent(),
        ),
      ),
    );
  }
}

class _ClientDetailContent extends GetView<ClientController> {
  const _ClientDetailContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final client = controller.selectedClient;
      final records = controller.selectedClientRecords;

      return AppPanel(
        padding: const EdgeInsets.all(24),
        child:
            client == null
                ? Center(
                  child: Text(
                    '顧客を選択してください。',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              client.companyName,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                controller.isSaving
                                    ? null
                                    : () => _showClientEditSheet(
                                      context: context,
                                      controller: controller,
                                      client: client,
                                    ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('編集'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoChip(
                            label: '連携面談',
                            value: '${client.linkedGoogleEventIds.length}件',
                          ),
                          _InfoChip(label: '記録数', value: '${records.length}件'),
                          _InfoChip(
                            label: '最終面談',
                            value:
                                client.lastMeetingAt == null
                                    ? '未設定'
                                    : DateFormat(
                                      'MM/dd HH:mm',
                                    ).format(client.lastMeetingAt!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailSection(
                        title: '基本情報',
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'ご担当者',
                              value: client.contactName ?? '未設定',
                            ),
                            _DetailRow(
                              label: '電話番号',
                              value: client.phoneNumber ?? '未設定',
                            ),
                            _DetailRow(
                              label: 'メール',
                              value: client.email ?? '未設定',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailSection(
                        title: 'メモ',
                        child: Text(
                          client.notes?.trim().isNotEmpty == true
                              ? client.notes!
                              : 'まだ登録されたメモはありません。',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailSection(
                        title: '最近の面談記録',
                        child:
                            controller.isLoadingDetail
                                ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  ),
                                )
                                : records.isEmpty
                                ? Text(
                                  'この顧客に紐づく面談記録はまだありません。',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                )
                                : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final record in records.take(5)) ...[
                                      _RecordPreviewTile(record: record),
                                      if (record != records.take(5).last)
                                        const Divider(height: 20),
                                    ],
                                  ],
                                ),
                      ),
                    ],
                  ),
                ),
      );
    });
  }
}

Future<void> _showClientEditSheet({
  required BuildContext context,
  required ClientController controller,
  required ClientEntity client,
}) async {
  final companyCtrl = TextEditingController(text: client.companyName);
  final contactCtrl = TextEditingController(text: client.contactName ?? '');
  final phoneCtrl = TextEditingController(text: client.phoneNumber ?? '');
  final emailCtrl = TextEditingController(text: client.email ?? '');
  final notesCtrl = TextEditingController(text: client.notes ?? '');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Obx(
          () => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('顧客情報を編集', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                CustomTextFormField(
                  label: '会社名',
                  hintText: '会社名を入力してください。',
                  controller: companyCtrl,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                CustomTextFormField(
                  label: 'ご担当者名',
                  hintText: 'ご担当者名を入力してください。',
                  controller: contactCtrl,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                CustomTextFormField(
                  label: '電話番号',
                  hintText: '電話番号を入力してください。',
                  controller: phoneCtrl,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                CustomTextFormField(
                  label: 'メール',
                  hintText: 'メールアドレスを入力してください。',
                  controller: emailCtrl,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                CustomTextFormField(
                  label: 'メモ',
                  hintText: '顧客メモを入力してください。',
                  controller: notesCtrl,
                  textInputAction: TextInputAction.done,
                  maxLines: 4,
                  minLines: 4,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        controller.isSaving
                            ? null
                            : () async {
                              await controller.updateSelectedClient(
                                companyName: companyCtrl.text,
                                contactName: contactCtrl.text,
                                phoneNumber: phoneCtrl.text,
                                email: emailCtrl.text,
                                notes: notesCtrl.text,
                              );
                              if (context.mounted) {
                                Get.back();
                              }
                            },
                    child: Text(controller.isSaving ? '保存中...' : '保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label  $value',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecordPreviewTile extends StatelessWidget {
  const _RecordPreviewTile({required this.record});

  final MeetingRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = record.scheduledStartAt;
    final (syncLabel, syncColor) = switch (record.sheetsSyncStatus) {
      'synced' => ('同期完了', AppColors.accentSoft),
      'failed' => ('同期失敗', AppColors.warningSoft),
      'syncing' => ('同期中', AppColors.secondarySoft),
      _ => ('未同期', AppColors.outlineSoft),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                record.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: syncColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                syncLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),
        Text(record.summary, style: theme.textTheme.bodyMedium),
        if (record.notes?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            record.notes!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
        if (record.nextAction?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            '次のアクション: ${record.nextAction!}',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
        if (schedule != null) ...[
          const SizedBox(height: 6),
          Text(
            DateFormat('yyyy/MM/dd HH:mm').format(schedule),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openMeetingRecordEditor(record),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('記録を編集'),
            ),
          ],
        ),
      ],
    );
  }
}

void _openMeetingRecordEditor(MeetingRecordEntity record) {
  if (!Get.isRegistered<CalendarController>()) {
    return;
  }

  final calendarController = Get.find<CalendarController>();
  for (final event in calendarController.events) {
    if (event.id == record.googleEventId) {
      Get.toNamed(AppRoutes.meetingRecord, arguments: event);
      return;
    }
  }
}

Future<void> _showAllClientRecordsSheet(
  BuildContext context,
  List<MeetingRecordEntity> records,
) async {
  final theme = Theme.of(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('全ての面談記録', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    return _RecordPreviewTile(record: records[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
