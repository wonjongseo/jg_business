/// 외부 연동에 필요한 런타임 환경값을 모아둔다.
abstract final class AppEnv {
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '820390242930-k2ciki8i7divtsebcrisl172fer62t0o.apps.googleusercontent.com',
  );

  static const googleSheetsSpreadsheetId = String.fromEnvironment(
    'GOOGLE_SHEETS_SPREADSHEET_ID',
    defaultValue: '1RLWqZ44UUsvoyww035zcPupAN1pgtlSubHE8e06WcQ4',
  );

  static const googleSheetsSheetName = String.fromEnvironment(
    'GOOGLE_SHEETS_SHEET_NAME',
    defaultValue: 'name1',
  );

  static bool get hasGoogleSheetsConfig =>
      googleSheetsSpreadsheetId.trim().isNotEmpty;
}
