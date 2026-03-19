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
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller.searchCtrl,
          builder: (context, value, _) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outlineSoft),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.searchCtrl,
                decoration: InputDecoration(
                  hintText: '会社名または担当者名で検索',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      value.text.isEmpty
                          ? null
                          : IconButton(
                            onPressed: controller.searchCtrl.clear,
                            icon: const Icon(Icons.close),
                          ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            );
          },
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

    return Obx(() {
      final items = controller.filteredClients;
      final selectedClientId = controller.selectedClientId;

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
                    '該当する顧客がありません。\n検索条件を変えるか、新しい顧客を登録してください。',
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
                    final selected = selectedClientId == client.id;
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
                          border: Border.all(
                            color:
                                selected
                                    ? AppColors.accent
                                    : AppColors.outlineSoft,
                          ),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _ListInfoPill(
                                  label: '連携面談',
                                  value:
                                      '${client.linkedGoogleEventIds.length}件',
                                ),
                                _ListInfoPill(
                                  label: '最近接点',
                                  value:
                                      client.lastMeetingAt == null
                                          ? '未設定'
                                          : DateFormat(
                                            'MM/dd',
                                          ).format(client.lastMeetingAt!),
                                ),
                              ],
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
    });
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
                          PopupMenuButton<_ClientAction>(
                            onSelected: (action) {
                              switch (action) {
                                case _ClientAction.edit:
                                  _showClientEditSheet(
                                    context: context,
                                    controller: controller,
                                    client: client,
                                  );
                                case _ClientAction.createRecord:
                                  _openLatestLinkedMeetingRecord(client);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: _ClientAction.edit,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('顧客編集'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: _ClientAction.createRecord,
                                    enabled: _hasLinkedCalendarEvent(client),
                                    child: const ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.note_add_outlined),
                                      title: Text('記録作成'),
                                    ),
                                  ),
                                ],
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.more_horiz),
                            ),
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
                        title: '次のアクション',
                        child:
                            controller.nextActionRecords.isEmpty
                                ? Text(
                                  '設定された次のアクションはありません。',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                )
                                : Column(
                                  children: [
                                    for (final record
                                        in controller.nextActionRecords) ...[
                                      _NextActionTile(record: record),
                                      if (record !=
                                          controller.nextActionRecords.last)
                                        const Divider(height: 20),
                                    ],
                                  ],
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
  const _DetailSection({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

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
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ListInfoPill extends StatelessWidget {
  const _ListInfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.outlineSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (schedule != null)
                      Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(schedule),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (schedule != null) const SizedBox(height: 6),
                    Text(
                      record.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
          const SizedBox(height: 10),
          Text(
            record.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          if (record.nextAction?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.outlineSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '次のアクション',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(record.nextAction!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _openMeetingRecordEditor(record),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('記録を編集'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextActionTile extends StatelessWidget {
  const _NextActionTile({required this.record});

  final MeetingRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.warning,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.nextAction ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              if (record.scheduledStartAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'yyyy/MM/dd HH:mm',
                  ).format(record.scheduledStartAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: () => _openMeetingRecordEditor(record),
          child: const Text('編集'),
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

void _openLatestLinkedMeetingRecord(ClientEntity client) {
  if (!Get.isRegistered<CalendarController>()) {
    return;
  }

  final calendarController = Get.find<CalendarController>();
  final linkedEvents =
      calendarController.events
          .where(
            (event) =>
                event.id != null &&
                client.linkedGoogleEventIds.contains(event.id),
          )
          .toList()
        ..sort((a, b) {
          final left = a.start?.dateTime ?? a.start?.date ?? DateTime(1970);
          final right = b.start?.dateTime ?? b.start?.date ?? DateTime(1970);
          return right.compareTo(left);
        });

  if (linkedEvents.isEmpty) {
    return;
  }

  Get.toNamed(AppRoutes.meetingRecord, arguments: linkedEvents.first);
}

bool _hasLinkedCalendarEvent(ClientEntity client) {
  if (!Get.isRegistered<CalendarController>()) {
    return false;
  }

  final calendarController = Get.find<CalendarController>();
  return calendarController.events.any(
    (event) =>
        event.id != null && client.linkedGoogleEventIds.contains(event.id),
  );
}

enum _ClientAction { edit, createRecord }

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
