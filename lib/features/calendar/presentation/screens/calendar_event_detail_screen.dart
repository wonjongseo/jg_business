/// 일정 상세와 미팅 기록 진입 버튼을 보여주는 화면이다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';

class CalendarEventDetailScreen extends GetView<CalendarController> {
  const CalendarEventDetailScreen({super.key, required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date;

    return Scaffold(
      appBar: AppBar(
        title: const Text('予定詳細'),
        actions: [
          IconButton(
            onPressed: () => controller.openEventEditor(event),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.summary ?? 'タイトル未設定',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Obx(() {
                final meetingStatus = controller.statusForEvent(event);
                final recordStatus = meetingStatus?.recordStatus ?? 'idle';
                final recordStatusLabel = switch (recordStatus) {
                  'completed' => '記録済み',
                  'pending' => '記録待ち',
                  _ => '進行前',
                };
                final recordStatusColor = switch (recordStatus) {
                  'completed' => const Color(0xFFD7EFE6),
                  'pending' => const Color(0xFFFFE7BF),
                  _ => const Color(0xFFF1EFE8),
                };

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: recordStatusColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    recordStatusLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              }),
              const SizedBox(height: 16),
              _InfoTile(
                icon: Icons.schedule_outlined,
                title: '日時',
                value: _formatDateRange(start, end),
              ),
              _InfoTile(
                icon: Icons.place_outlined,
                title: '場所',
                value: event.location?.trim().isNotEmpty == true
                    ? event.location!
                    : '未設定',
              ),
              _InfoTile(
                icon: Icons.group_outlined,
                title: '参加者',
                value: event.attendees.isEmpty
                    ? '参加者なし'
                    : event.attendees
                        .map((attendee) => attendee.label)
                        .where((label) => label.trim().isNotEmpty)
                        .join(', '),
              ),
              _InfoTile(
                icon: Icons.description_outlined,
                title: '説明',
                value: event.description?.trim().isNotEmpty == true
                    ? event.description!
                    : '説明なし',
              ),
              const SizedBox(height: 8),
              Obx(() {
                final record = controller.recordForEvent(event);
                if (record == null) {
                  return const SizedBox.shrink();
                }

                return _MeetingRecordPreviewCard(
                  record: record,
                  controller: controller,
                  event: event,
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final recordStatus =
                      controller.statusForEvent(event)?.recordStatus ?? 'idle';
                  return FilledButton.icon(
                    onPressed: () => Get.toNamed(
                      AppRoutes.meetingRecord,
                      arguments: event,
                    ),
                    icon: const Icon(Icons.note_add_outlined),
                    label: Text(
                      recordStatus == 'completed'
                          ? 'ミーティング記録を修正'
                          : 'ミーティング記録を作成',
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => controller.openEventEditor(event),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('この予定を編集'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingRecordPreviewCard extends StatelessWidget {
  const _MeetingRecordPreviewCard({
    required this.record,
    required this.controller,
    required this.event,
  });

  final MeetingRecordEntity record;
  final CalendarController controller;
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '保存済みミーティング記録',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              _SyncStatusChip(record: record),
            ],
          ),
          const SizedBox(height: 10),
          _RecordLine(label: '要約', value: record.summary),
          if (record.notes != null && record.notes!.trim().isNotEmpty)
            _RecordLine(label: '詳細メモ', value: record.notes!),
          if (record.nextAction != null &&
              record.nextAction!.trim().isNotEmpty)
            _RecordLine(label: '次のアクション', value: record.nextAction!),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Obx(() {
              final isSyncing = controller.isSyncingRecord(record.id);
              return FilledButton.tonalIcon(
                onPressed: isSyncing
                    ? null
                    : () => controller.syncRecordToSheets(event),
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.table_view_outlined),
                label: Text(isSyncing ? '同期中...' : 'Sheets に同期'),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip({required this.record});

  final MeetingRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (record.sheetsSyncStatus) {
      'synced' => ('同期完了', AppColors.accentSoft),
      'failed' => ('同期失敗', AppColors.warningSoft),
      'syncing' => ('同期中', AppColors.secondarySoft),
      _ => ('未同期', AppColors.outlineSoft),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RecordLine extends StatelessWidget {
  const _RecordLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF556070),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

String _formatDateRange(DateTime? start, DateTime? end) {
  if (start == null) return '日時未設定';
  final dateFormatter = DateFormat('M月d日(E)', 'ja_JP');
  final timeFormatter = DateFormat('HH:mm');
  final startDate = dateFormatter.format(start);
  final startTime = timeFormatter.format(start);
  final endTime = end != null ? timeFormatter.format(end) : '--:--';
  return '$startDate  $startTime - $endTime';
}
