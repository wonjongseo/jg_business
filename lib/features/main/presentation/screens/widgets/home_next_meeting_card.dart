/// 다음 미팅 또는 진행 중인 미팅을 강조해서 보여주는 카드다.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jg_business/features/auth/presentation/controllers/auth_controller.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/features/main/presentation/controllers/main_controller.dart';
import 'package:jg_business/features/main/presentation/screens/widgets/home_panel.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';
import 'package:jg_business/shared/widgets/google_sign_in_web_button.dart';

class HomeNextMeetingCard extends StatelessWidget {
  const HomeNextMeetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<CalendarController>()
            ? Get.find<CalendarController>()
            : null;

    if (controller == null) {
      return const _PreviewCard();
    }

    return Obx(() {
      if (controller.isLoading) {
        return const HomePanel(
          child: Center(child: CircularProgressIndicator.adaptive()),
        );
      }

      if (!controller.isConnected) {
        return _CalendarDisconnectedCard(controller: controller);
      }

      final event = controller.currentOrNextEvent;
      if (event == null) {
        return const _EmptyScheduleCard();
      }

      return _CalendarEventCard(event: event);
    });
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Google Calendar 連携待ち', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '連携すると、次の予定がここに表示されます。',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CalendarDisconnectedCard extends StatelessWidget {
  const _CalendarDisconnectedCard({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Google Calendar が未連携です', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '予定を見たくなったタイミングで連携できます。連携しないままホームを見ることもできます。',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (kIsWeb)
                const GoogleSignInWebButton()
              else
                FilledButton.icon(
                  onPressed: controller.connectCalendar,
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Google Calendar を連携'),
                ),
              OutlinedButton.icon(
                onPressed:
                    () => Get.find<MainController>().onDestinationSelected(1),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('カレンダーへ'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('次の予定はありません', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Google Calendar に今後の予定が見つかりませんでした。',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date;
    final timeLabel = _formatTimeRange(start, end, event.location);
    final attendeeCount = event.attendees.length;
    final isOngoing = Get.find<CalendarController>().isOngoing(event);
    final currentUserEmail =
        Get.find<AuthController>().currentUserEmail?.trim().toLowerCase();
    final meta = _buildMetaLine(
      event,
      attendeeCount,
      currentUserEmail: currentUserEmail,
    );
    return HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            decoration: BoxDecoration(
              color: isOngoing ? AppColors.warningSoft : AppColors.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isOngoing ? '進行中  $timeLabel' : timeLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text(event.summary ?? 'タイトル未設定', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (meta.isNotEmpty)
            Text(
              meta,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed:
                    () => Get.find<CalendarController>().openEventDetail(event),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('詳細を見る'),
              ),
              FilledButton.tonalIcon(
                onPressed:
                    () => Get.find<CalendarController>().openEventEditor(event),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('編集する'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTimeRange(DateTime? start, DateTime? end, String? location) {
  final formatter = DateFormat('HH:mm');
  final startText = start != null ? formatter.format(start) : '時刻未設定';
  final endText = end != null ? formatter.format(end) : '--:--';
  final place =
      (location?.trim().isNotEmpty ?? false) ? '  ${location!.trim()}' : '';
  return '$startText - $endText$place';
}

String _buildMetaLine(
  CalendarEvent event,
  int attendeeCount, {
  String? currentUserEmail,
}) {
  final organizerEmail = event.organizerEmail?.trim();
  final normalizedOrganizerEmail = organizerEmail?.toLowerCase();
  final parts = <String>[
    if (organizerEmail?.isNotEmpty ?? false)
      if (normalizedOrganizerEmail != currentUserEmail) organizerEmail!,
    if (attendeeCount > 0) '参加者 $attendeeCount 名',
  ];
  if (parts.isEmpty) return '';
  return parts.join(' ・ ');
}
