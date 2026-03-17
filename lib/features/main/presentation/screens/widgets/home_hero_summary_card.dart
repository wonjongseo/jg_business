import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';

class HomeHeroSummaryCard extends StatelessWidget {
  const HomeHeroSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CalendarController>()
        ? Get.find<CalendarController>()
        : null;

    if (controller == null) {
      return const _HeroContent(
        todayMeetings: '0',
        pendingRecords: '0',
        syncAlerts: '0',
        description: '営業の1日は、予定・記録・同期・フォローでつながります。今はまず Google Calendar 連携から段階的に進めます。',
      );
    }

    return Obx(
      () => _HeroContent(
        todayMeetings: '${controller.todayEvents.length}',
        pendingRecords: '0',
        syncAlerts: '0',
        description: controller.isConnected
            ? '営業の流れはこのまま広げます。今の段階では Google Calendar の予定取得を先に固めています。'
            : '営業の流れは、予定取得から始まります。最初に Google ログインは強制せず、必要なタイミングで連携します。',
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.todayMeetings,
    required this.pendingRecords,
    required this.syncAlerts,
    required this.description,
  });

  final String todayMeetings;
  final String pendingRecords;
  final String syncAlerts;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF173C3A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F766E),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'おはようございます、\nAlex',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.04,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.84),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(label: '今日の面談', value: todayMeetings),
              _MetricPill(label: '記録待ち', value: pendingRecords),
              _MetricPill(label: '同期アラート', value: syncAlerts),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.84),
          ),
          children: [
            TextSpan(
              text: '$value ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}
