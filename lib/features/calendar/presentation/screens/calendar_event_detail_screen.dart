import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jg_business/app/routes/app_routes.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';

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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.meetingRecord,
                    arguments: event,
                  ),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('ミーティング記録を作成'),
                ),
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

String _formatDateRange(DateTime? start, DateTime? end) {
  if (start == null) return '日時未設定';
  final dateFormatter = DateFormat('M月d日(E)', 'ja_JP');
  final timeFormatter = DateFormat('HH:mm');
  final startDate = dateFormatter.format(start);
  final startTime = timeFormatter.format(start);
  final endTime = end != null ? timeFormatter.format(end) : '--:--';
  return '$startDate  $startTime - $endTime';
}
