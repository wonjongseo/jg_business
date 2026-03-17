/// 날짜/시간 선택 다이얼로그 호출을 한곳에 모은 헬퍼다.
import 'package:flutter/material.dart';

abstract final class DateTimePickerHelper {
  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDatePicker(
      context: context,
      locale: const Locale('ja', 'JP'),
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2035),
    );
  }

  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
  }
}
