/// 홈 화면에서 최근 저장한 미팅 기록을 요약해서 보여주는 카드다.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_panel.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';

class HomeRecentRecordsCard extends StatelessWidget {
  const HomeRecentRecordsCard({super.key});

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
      final records = controller.recentMeetingRecords;
      if (records.isEmpty) {
        return HomePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'まだ保存したミーティング記録はありません。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '予定詳細から「ミーティング記録を作成」を押すと、ここに最近保存した内容が表示されます。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF556070),
                ),
              ),
            ],
          ),
        );
      }

      return HomePanel(
        child: Column(
          children: [
            for (var i = 0; i < records.length; i++) ...[
              _RecentRecordTile(record: records[i], controller: controller),
              if (i != records.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      );
    });
  }
}

class _RecentRecordTile extends StatelessWidget {
  const _RecentRecordTile({
    required this.record,
    required this.controller,
  });

  final MeetingRecordEntity record;
  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final matchedEvents = controller.events
        .where((item) => item.id == record.googleEventId)
        .toList();
    final event = matchedEvents.isNotEmpty ? matchedEvents.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        if (record.companyName?.trim().isNotEmpty == true)
          Text(
            record.companyName!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF556070),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          record.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (record.nextAction?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            '次のアクション: ${record.nextAction!}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF556070),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: event == null ? null : () => controller.openEventDetail(event),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('予定詳細を見る'),
          ),
        ),
      ],
    );
  }
}
