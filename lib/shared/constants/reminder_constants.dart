/// 미팅 리마인더 기준 시간을 한 곳에서 관리한다.
class ReminderConstants {
  const ReminderConstants._();

  /// 현재는 테스트를 위해 1분 전 알림으로 두고 있다.
  /// 운영 시에는 1시간 전으로 바꾸면 된다.
  static const beforeMeetingMinutes = 1;

  /// 미팅 종료 후 기록 리마인더 기준들이다.
  static const afterMeetingReminderMinutes = [5, 10];

  /// 상태값 계산은 첫 번째 사후 리마인더를 기준으로 한다.
  static const primaryAfterMeetingReminderMinute = 5;
}
