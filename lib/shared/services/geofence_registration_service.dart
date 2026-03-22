import 'package:jg_business/features/meeting/data/models/meeting_status_entity.dart';
import 'package:jg_business/shared/constants/reminder_constants.dart';
import 'package:jg_business/shared/services/ios_geofence_channel_service.dart';

/// 현재 `meeting_status` 목록을 기준으로 iOS geofence 등록 상태를 맞춘다.
class GeofenceRegistrationService {
  GeofenceRegistrationService({
    required IosGeofenceChannelService iosGeofenceChannelService,
  }) : _iosGeofenceChannelService = iosGeofenceChannelService;

  final IosGeofenceChannelService _iosGeofenceChannelService;

  Future<void> syncMeetingGeofences(List<MeetingStatusEntity> statuses) async {
    if (!_iosGeofenceChannelService.isSupported) {
      return;
    }

    final now = DateTime.now();
    final desired = <_GeofenceRegistration>[];

    for (final status in statuses) {
      if (status.locationLatitude == null || status.locationLongitude == null) {
        continue;
      }

      final arrival = _buildArrivalRegistration(status, now);
      if (arrival != null) {
        desired.add(arrival);
      }

      final leave = _buildLeaveRegistration(status, now);
      if (leave != null) {
        desired.add(leave);
      }
    }

    desired.sort((a, b) => a.referenceAt.compareTo(b.referenceAt));
    final limitedDesired =
        desired.take(ReminderConstants.maxActiveGeofences).toList();
    final desiredIds = limitedDesired.map((item) => item.identifier).toSet();

    final existingIds =
        await _iosGeofenceChannelService.monitoredRegionIdentifiers();

    for (final identifier in existingIds) {
      // 다른 기능이나 테스트용으로 등록된 geofence 는 건드리지 않고,
      // 이 앱이 만든 identifier prefix 만 정리 대상으로 본다.
      if (!identifier.startsWith(_identifierPrefix)) {
        continue;
      }
      // 이번 계산 결과에서 더 이상 유지할 필요가 없는 geofence 는 기기에서 제거한다.
      if (!desiredIds.contains(identifier)) {
        await _iosGeofenceChannelService.unregisterRegion(identifier);
      }
    }

    // 반경/설정 변경도 반영되게 원하는 geofence 는 항상 한 번 갱신 등록한다.
    for (final registration in limitedDesired) {
      // 같은 identifier 가 이미 있어도 이전 반경/옵션이 남아 있을 수 있으므로
      // 먼저 제거한 뒤 최신 설정으로 다시 등록한다.
      await _iosGeofenceChannelService.unregisterRegion(
        registration.identifier,
      );
      // 현재 규칙 기준으로 entry/exit 옵션과 반경을 다시 등록한다.
      await _iosGeofenceChannelService.registerRegion(
        identifier: registration.identifier,
        latitude: registration.latitude,
        longitude: registration.longitude,
        radius: registration.radiusMeters,
        notifyOnEntry: registration.notifyOnEntry,
        notifyOnExit: registration.notifyOnExit,
      );
    }
  }

  _GeofenceRegistration? _buildArrivalRegistration(
    MeetingStatusEntity status,
    DateTime now,
  ) {
    final start = status.scheduledStartAt;
    if (start == null || !start.isAfter(now)) {
      return null;
    }

    final monitoringStart = start.subtract(
      const Duration(minutes: ReminderConstants.arrivalMonitoringLeadMinutes),
    );
    if (now.isBefore(monitoringStart)) {
      return null;
    }

    return _GeofenceRegistration(
      identifier: '$_identifierPrefix-arrival-${status.googleEventId}',
      latitude: status.locationLatitude!,
      longitude: status.locationLongitude!,
      radiusMeters: ReminderConstants.arrivalRadiusMeters,
      notifyOnEntry: true,
      notifyOnExit: false,
      referenceAt: start,
    );
  }

  _GeofenceRegistration? _buildLeaveRegistration(
    MeetingStatusEntity status,
    DateTime now,
  ) {
    final end = status.scheduledEndAt;
    if (end == null || status.recordStatus == 'completed') {
      return null;
    }

    final monitoringStart = end.add(
      const Duration(
        minutes: ReminderConstants.primaryAfterMeetingReminderMinute,
      ),
    );
    if (now.isBefore(monitoringStart)) {
      return null;
    }

    return _GeofenceRegistration(
      identifier: '$_identifierPrefix-leave-${status.googleEventId}',
      latitude: status.locationLatitude!,
      longitude: status.locationLongitude!,
      radiusMeters: ReminderConstants.leaveRadiusMeters,
      notifyOnEntry: false,
      notifyOnExit: true,
      referenceAt: end,
    );
  }

  static const _identifierPrefix = 'jg-business';
}

class _GeofenceRegistration {
  const _GeofenceRegistration({
    required this.identifier,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.notifyOnEntry,
    required this.notifyOnExit,
    required this.referenceAt,
  });

  final String identifier;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool notifyOnEntry;
  final bool notifyOnExit;
  // 어떤 시점의 geofence 인지 나타낸다.
  // arrival 은 일정 시작 시각, leave 는 일정 종료 시각을 넣고,
  // 가까운 일정부터 우선 등록하기 위한 정렬 기준으로 사용한다.
  final DateTime referenceAt;
}
