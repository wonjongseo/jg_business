/// Google Sheets REST API에 미팅 기록을 한 줄씩 추가한다.
import 'package:dio/dio.dart';
import 'package:jg_business/features/auth/data/datasources/google_auth_remote_data_source.dart';
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/shared/config/app_env.dart';

class GoogleSheetsRemoteDataSource {
  GoogleSheetsRemoteDataSource({
    required GoogleAuthRemoteDataSource authRemoteDataSource,
    Dio? dio,
  }) : _authRemoteDataSource = authRemoteDataSource,
       _dio = dio ?? Dio();

  final GoogleAuthRemoteDataSource _authRemoteDataSource;
  final Dio _dio;

  /// 한 개의 미팅 기록을 지정한 시트 탭에 append 한다.
  Future<void> appendMeetingRecord(MeetingRecordEntity record) async {
    if (!AppEnv.hasGoogleSheetsConfig) {
      throw StateError('missing_sheets_config');
    }

    final headers = await _authRemoteDataSource.getAuthorizationHeaders(
      scopes: const [
        GoogleAuthRemoteDataSource.calendarScope,
        GoogleAuthRemoteDataSource.sheetsScope,
      ],
      interactive: true,
    );
    if (headers == null || headers.isEmpty) {
      throw StateError('missing_google_auth');
    }

    final encodedRange =
        '${AppEnv.googleSheetsSheetName}!A:K'.replaceAll(' ', '%20');

    await _dio.post(
      'https://sheets.googleapis.com/v4/spreadsheets/'
      '${AppEnv.googleSheetsSpreadsheetId}/values/$encodedRange:append',
      options: Options(headers: headers),
      queryParameters: const {
        'valueInputOption': 'USER_ENTERED',
        'insertDataOption': 'INSERT_ROWS',
      },
      data: {
        'majorDimension': 'ROWS',
        'values': [
          [
            record.title,
            record.companyName ?? '',
            record.contactName ?? '',
            record.scheduledStartAt?.toIso8601String() ?? '',
            record.scheduledEndAt?.toIso8601String() ?? '',
            record.locationName ?? '',
            record.summary,
            record.notes ?? '',
            record.nextAction ?? '',
            record.userId,
            record.googleEventId,
          ],
        ],
      },
    );
  }
}
