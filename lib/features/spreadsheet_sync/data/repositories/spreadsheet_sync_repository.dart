/// 미팅 기록의 Google Sheets 동기화를 담당한다.
import 'package:jg_business/features/meeting/data/models/meeting_record_entity.dart';
import 'package:jg_business/features/spreadsheet_sync/data/datasources/google_sheets_remote_data_source.dart';

class SpreadsheetSyncRepository {
  SpreadsheetSyncRepository({
    required GoogleSheetsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final GoogleSheetsRemoteDataSource _remoteDataSource;

  Future<void> syncMeetingRecord(MeetingRecordEntity record) {
    return _remoteDataSource.appendMeetingRecord(record);
  }
}
