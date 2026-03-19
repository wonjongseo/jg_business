/// Google Sheets REST API에 미팅 기록을 한 줄씩 추가한다.
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
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
  static const _headerRow = <String>[
    '予定タイトル',
    '会社名',
    '担当者名',
    '開始日時',
    '終了日時',
    '場所',
    '要約',
    '詳細メモ',
    '次のアクション',
    'ユーザーID',
    'GoogleイベントID',
    'レコードID',
  ];
  static final _dateTimeFormatter = DateFormat('yyyy/MM/dd HH:mm');

  /// 한 개의 미팅 기록을 시트에 upsert 한다.
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

    await _ensureHeaderRow(headers);
    final rowValues = _buildRowValues(record);
    final matchedRowIndex = await _findRowIndexByRecordId(
      headers,
      record.id,
    );

    if (matchedRowIndex != null) {
      await _updateRow(
        headers,
        rowIndex: matchedRowIndex,
        rowValues: rowValues,
      );
      return;
    }

    await _appendRow(headers, rowValues);
  }

  Future<void> _ensureHeaderRow(Map<String, String> headers) async {
    final headerRange =
        '${AppEnv.googleSheetsSheetName}!A1:L1'.replaceAll(' ', '%20');

    final response = await _dio.get(
      'https://sheets.googleapis.com/v4/spreadsheets/'
      '${AppEnv.googleSheetsSpreadsheetId}/values/$headerRange',
      options: Options(headers: headers),
    );

    final data = response.data as Map<String, dynamic>;
    final values = data['values'] as List<dynamic>?;
    final firstRow = values != null && values.isNotEmpty
        ? List<String>.from(values.first as List<dynamic>)
        : const <String>[];

    if (_hasHeader(firstRow)) {
      return;
    }

    await _dio.put(
      'https://sheets.googleapis.com/v4/spreadsheets/'
      '${AppEnv.googleSheetsSpreadsheetId}/values/$headerRange',
      options: Options(headers: headers),
      queryParameters: const {'valueInputOption': 'RAW'},
      data: {
        'majorDimension': 'ROWS',
        'values': [_headerRow],
      },
    );
  }

  bool _hasHeader(List<String> firstRow) {
    if (firstRow.length < _headerRow.length) {
      return false;
    }

    for (var index = 0; index < _headerRow.length; index++) {
      if (firstRow[index].trim() != _headerRow[index]) {
        return false;
      }
    }
    return true;
  }

  Future<int?> _findRowIndexByRecordId(
    Map<String, String> headers,
    String recordId,
  ) async {
    final bodyRange =
        '${AppEnv.googleSheetsSheetName}!A2:L'.replaceAll(' ', '%20');
    final response = await _dio.get(
      'https://sheets.googleapis.com/v4/spreadsheets/'
      '${AppEnv.googleSheetsSpreadsheetId}/values/$bodyRange',
      options: Options(headers: headers),
    );

    final data = response.data as Map<String, dynamic>;
    final values = data['values'] as List<dynamic>?;
    if (values == null || values.isEmpty) {
      return null;
    }

    for (var index = 0; index < values.length; index++) {
      final row = List<String>.from(values[index] as List<dynamic>);
      if (row.length >= _headerRow.length && row.last.trim() == recordId) {
        return index + 2;
      }
    }

    return null;
  }

  Future<void> _updateRow(
    Map<String, String> headers, {
    required int rowIndex,
    required List<String> rowValues,
  }) async {
    final rowRange =
        '${AppEnv.googleSheetsSheetName}!A$rowIndex:L$rowIndex'.replaceAll(
          ' ',
          '%20',
        );

    await _dio.put(
      'https://sheets.googleapis.com/v4/spreadsheets/'
      '${AppEnv.googleSheetsSpreadsheetId}/values/$rowRange',
      options: Options(headers: headers),
      queryParameters: const {'valueInputOption': 'USER_ENTERED'},
      data: {
        'majorDimension': 'ROWS',
        'values': [rowValues],
      },
    );
  }

  Future<void> _appendRow(
    Map<String, String> headers,
    List<String> rowValues,
  ) async {
    final appendRange =
        '${AppEnv.googleSheetsSheetName}!A:L'.replaceAll(' ', '%20');

    await _dio.post(
      'https://sheets.googleapis.com/v4/spreadsheets/'
      '${AppEnv.googleSheetsSpreadsheetId}/values/$appendRange:append',
      options: Options(headers: headers),
      queryParameters: const {
        'valueInputOption': 'USER_ENTERED',
        'insertDataOption': 'INSERT_ROWS',
      },
      data: {
        'majorDimension': 'ROWS',
        'values': [rowValues],
      },
    );
  }

  List<String> _buildRowValues(MeetingRecordEntity record) {
    return [
      record.title,
      record.companyName ?? '',
      record.contactName ?? '',
      _formatDateTime(record.scheduledStartAt),
      _formatDateTime(record.scheduledEndAt),
      record.locationName ?? '',
      record.summary,
      record.notes ?? '',
      record.nextAction ?? '',
      record.userId,
      record.googleEventId,
      record.id,
    ];
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    return _dateTimeFormatter.format(value.toLocal());
  }
}
