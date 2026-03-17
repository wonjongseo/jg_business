/// 외부 연동에 필요한 런타임 환경값을 모아둔다.
abstract final class AppEnv {
  static const googleSheetsSpreadsheetId = String.fromEnvironment(
    'GOOGLE_SHEETS_SPREADSHEET_ID',
  );

  static const googleSheetsSheetName = String.fromEnvironment(
    'GOOGLE_SHEETS_SHEET_NAME',
    defaultValue: 'MeetingRecords',
  );

  static bool get hasGoogleSheetsConfig =>
      googleSheetsSpreadsheetId.trim().isNotEmpty;
}
