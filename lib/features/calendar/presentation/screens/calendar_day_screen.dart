import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';

class CalendarDayScreen extends GetView<CalendarController> {
  static String name = '/calendar_day';

  const CalendarDayScreen({super.key, required this.date});
  final DateTime date;

  double _initialScrollOffset() {
    const heightPerMinute = 1.15;
    final now = DateTime.now();
    final minutes = (now.hour * 60) + now.minute;
    final offset = (minutes * heightPerMinute) - 180;
    return offset < 0 ? 0 : offset;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${date.year}-${date.month}-${date.day}')),
      body: DayView<CalendarEvent>(
        dayTitleBuilder: (date) => SizedBox.shrink(),
        controller: controller.calendarEventController,
        initialDay: date,
        heightPerMinute: 1.15,
        scrollOffset: _initialScrollOffset(),

        showLiveTimeLineInAllDays: true,
        onEventTap:
            (events, date) =>
                controller.goToEventScreen(events: events, date: date),
        onDateTap: (date) => controller.goToEventScreen(date: date),
        liveTimeIndicatorSettings: const LiveTimeIndicatorSettings(
          color: Color(0xFFEA4335),
          // showTime: true,
        ),
        hourIndicatorSettings: const HourIndicatorSettings(
          color: Color(0xFFE5E7EB),
          offset: 0,
          lineStyle: LineStyle.dashed,
        ),
        keepScrollOffset: true,
        onPageChange: (date, pageIndex) {
          controller.syncFocusedDay(date);
        },
        eventTileBuilder: (date, events, boundary, start, end) {
          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  events.first.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (events.first.description != null)
                  Text(
                    events.first.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
