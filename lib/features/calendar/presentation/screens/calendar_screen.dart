/// 주간 기본 보기와 확장형 월간 캘린더를 함께 보여주는 메인 화면이다.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:jg_business/shared/layout/app_responsive.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';
import 'package:jg_business/shared/widgets/google_sign_in_web_button.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends GetView<CalendarController> {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Obx(
        () =>
            controller.isConnected
                ? FloatingActionButton.extended(
                  onPressed:
                      () => controller.goToEventScreen(
                        date: controller.focusedDay.value,
                      ),
                  icon: const Icon(Icons.add),
                  label: const Text('予定追加'),
                )
                : const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (!controller.isConnected) {
            return _CalendarDisconnectedState(controller: controller);
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchCalendar(interactive: false),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                const _CalendarHeader(),
                const SizedBox(height: 16),
                Obx(
                  () => _MonthCalendarPanel(
                    controller: controller,
                    isExpanded: controller.isMonthCalendarExpanded.value,
                  ),
                ),
                const SizedBox(height: 20),
                _EventSection(
                  title: '今日の予定',
                  subtitle: '今日の営業予定をすぐ確認できます。',
                  events: controller.todayEvents,
                  emptyMessage: '今日の予定はありません。',
                ),
                const SizedBox(height: 20),
                _EventSection(
                  title: '今後の予定',
                  subtitle: '進行中の予定と次に来る予定を優先して表示します。',
                  events: controller.upcomingEvents,
                  emptyMessage: '今後の予定はありません。',
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MonthCalendarPanel extends StatelessWidget {
  const _MonthCalendarPanel({
    required this.controller,
    required this.isExpanded,
  });

  final CalendarController controller;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final calendarFormat = isExpanded
        ? CalendarFormat.month
        : CalendarFormat.week;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: controller.toggleMonthCalendar,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '月カレンダー',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          isExpanded ? 'タップで閉じます' : '必要なときだけ月表示を開けます',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TableCalendar<CalendarEvent>(
              locale: 'ja_JP',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: controller.focusedDay.value,
              calendarFormat: calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              availableGestures:
                  kIsWeb
                      ? AvailableGestures.none
                      : AvailableGestures.horizontalSwipe,
              selectedDayPredicate:
                  (day) => isSameDay(day, controller.focusedDay.value),
              eventLoader: controller.eventsForDate,
              formatAnimationDuration: const Duration(milliseconds: 260),
              formatAnimationCurve: Curves.easeOutCubic,
              daysOfWeekHeight: 32,
              rowHeight: AppResponsive.isDesktopWidth(context) ? 56 : 48,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                leftChevronVisible: true,
                rightChevronVisible: true,
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekendStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                weekdayStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: isExpanded,
                markersMaxCount: 1,
                markerDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                defaultTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                weekendTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                controller.syncFocusedDay(selectedDay);
                Get.to(() => _SelectedDayEventsScreen(selectedDate: selectedDay));
              },
              onPageChanged: controller.syncFocusedDay,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends GetView<CalendarController> {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('カレンダー', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Google Calendar と連携した予定を、月表示と営業用リストの両方で確認できます。',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _CalendarDisconnectedState extends StatelessWidget {
  const _CalendarDisconnectedState({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppResponsive.compactContentMaxWidth,
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Calendar 連携が必要です',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'このタブでは、今日の予定、今後の予定、予定詳細、追加・編集・削除までをまとめて扱います。まずは Google Calendar を連携してください。',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child:
                      kIsWeb
                          ? const GoogleSignInWebButton()
                          : FilledButton.icon(
                            onPressed: controller.connectCalendar,
                            icon: const Icon(Icons.link_outlined),
                            label: const Text('Google Calendar を連携する'),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventSection extends GetView<CalendarController> {
  const _EventSection({
    required this.title,
    required this.subtitle,
    required this.events,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final List<CalendarEvent> events;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(emptyMessage),
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventListTile(event: event),
            ),
          ),
      ],
    );
  }
}

class _EventListTile extends GetView<CalendarController> {
  const _EventListTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = event.start?.dateTime ?? event.start?.date;
    final end = event.end?.dateTime ?? event.end?.date;
    final isOngoing = controller.isOngoing(event);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => controller.openEventDetail(event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isOngoing ? AppColors.warning : AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.summary ?? 'タイトル未設定',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatScheduleLine(start, end, event.location),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    if (event.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => controller.openEventEditor(event),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayEventsScreen extends GetView<CalendarController> {
  const _SelectedDayEventsScreen({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final events = controller.eventsForDate(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('M月d日(E)', 'ja_JP').format(selectedDate)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _EventSection(
              title: 'この日の予定',
              subtitle: '選択した日付に登録された予定一覧です。',
              events: events,
              emptyMessage: 'この日の予定はありません。',
            ),
          ],
        ),
      ),
    );
  }
}

String _formatScheduleLine(DateTime? start, DateTime? end, String? location) {
  final formatter = DateFormat('HH:mm');
  final startText = start != null ? formatter.format(start) : '時刻未設定';
  final endText = end != null ? formatter.format(end) : '--:--';
  if (location?.trim().isNotEmpty == true) {
    return '$startText - $endText  ${location!.trim()}';
  }
  return '$startText - $endText';
}
