/// 기록이 아직 작성되지 않은 면담을 홈에서 빠르게 보여주는 카드다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_panel.dart';

class HomePendingRecordsCard extends StatelessWidget {
  const HomePendingRecordsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<CalendarController>()
            ? Get.find<CalendarController>()
            : null;

    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final events = controller.pendingRecordEvents;
      if (events.isEmpty) {
        return HomePanel(
          child: Text(
            '今すぐ記録が必要な面談はありません。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      return HomePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < events.length; i++) ...[
              _PendingRecordTile(event: events[i], controller: controller),
              if (i != events.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      );
    });
  }
}

class _PendingRecordTile extends StatelessWidget {
  const _PendingRecordTile({required this.event, required this.controller});

  final CalendarEvent event;
  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date;
    final formatter = DateFormat('M/d HH:mm', 'ja_JP');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.summary ?? 'タイトル未設定',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          [
            if (start != null) formatter.format(start),
            if (end != null) '~ ${DateFormat('HH:mm').format(end)}',
            if (event.location?.trim().isNotEmpty == true)
              event.location!.trim(),
          ].join(' '),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF556070)),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () => controller.openEventDetail(event),
          icon: const Icon(Icons.edit_note),
          label: const Text('記録する'),
        ),
      ],
    );
  }
}
