import 'package:intl/intl.dart';

abstract final class DateTimeFormatter {
  static final DateFormat _japaneseDateFormat = DateFormat('M月d日 (E)', 'ja_JP');
  static final DateFormat _meridiemTimeFormat = DateFormat('a h:mm', 'en_US');
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  static String japaneseDate(DateTime date) {
    return _japaneseDateFormat.format(date);
  }

  static String meridiemTime(DateTime date) {
    return _meridiemTimeFormat.format(date);
  }

  static String apiDate(DateTime date) {
    return _apiDateFormat.format(date);
  }
}
