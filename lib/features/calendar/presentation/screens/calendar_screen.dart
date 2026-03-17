import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/calendar/data/models/calendar_events_response.dart';
import 'package:jg_business/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:calendar_view/calendar_view.dart';

class CalendarScreen extends GetView<CalendarController> {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return MonthView<CalendarEvent>(
            controller: controller.calendarEventController,
            initialMonth: DateTime.now(),
            startDay: WeekDays.sunday,
            hideDaysNotInMonth: true,
            weekDayBuilder: (index) {
              const labels = ['日', '月', '火', '水', '木', '金', '土'];
              final label = labels[index];

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                color: Colors.white,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            headerBuilder: (date) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${date.year}.${date.month}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
            onCellTap: (events, date) => controller.openDayView(date),
            onEventTap: (events, date) => controller.openDayView(date),
          );
        }),
      ),
    );
  }
}
