import Foundation
import CoreLocation
import UserNotifications

/// iOS CoreLocation geofence 등록/해제와 진입/이탈 이벤트를 관리한다.
final class LocationGeofenceManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationGeofenceManager()

    // iOS geofence 등록과 권한 상태는 모두 CLLocationManager 를 통해 관리한다.
    private let manager = CLLocationManager()

    private override init() {
        super.init()

        // delegate를 자기 자신으로 두고 geofence 이벤트를 직접 받는다.
        manager.delegate = self

        // 백그라운드에서도 위치 기반 이벤트를 받을 수 있게 한다.
        manager.allowsBackgroundLocationUpdates = true

        // 시스템이 적절히 위치 업데이트를 멈출 수 있게 둔다.
        manager.pausesLocationUpdatesAutomatically = true
    }

    /// 항상 허용 권한을 요청한다.
    func requestAlwaysPermission() {
        manager.requestAlwaysAuthorization()
    }

    /// 사용 중 권한만 먼저 요청할 때 쓴다.
    func requestWhenInUsePermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// 현재 권한 상태를 문자열로 반환한다.
    func currentAuthorizationStatus() -> String {
        switch manager.authorizationStatus {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .authorizedAlways:
            return "authorizedAlways"
        @unknown default:
            return "unknown"
        }
    }

    /// 단일 geofence를 등록한다.
    func registerRegion(
        identifier: String,
        latitude: Double,
        longitude: Double,
        radius: Double,
        notifyOnEntry: Bool,
        notifyOnExit: Bool
    ) {
        // 하나의 미팅 장소를 원형 반경 영역으로 등록한다.
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)

        region.notifyOnEntry = notifyOnEntry
        region.notifyOnExit = notifyOnExit

        // iOS 에게 이 반경의 진입/이탈을 감시하도록 요청한다.
        manager.startMonitoring(for: region)

        // 등록 직후 현재 사용자가 안/밖에 있는지도 확인할 수 있게 요청한다.
        manager.requestState(for: region)
    }

    /// 특정 identifier geofence를 제거한다.
    func unregisterRegion(identifier: String) {
        for region in manager.monitoredRegions {
            if region.identifier == identifier {
                manager.stopMonitoring(for: region)
            }
        }
    }

    /// 모든 geofence를 제거한다.
    func unregisterAllRegions() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
    }

    /// 현재 등록된 geofence identifier 목록을 반환한다.
    func monitoredRegionIdentifiers() -> [String] {
        // 현재 기기에 실제 등록된 geofence identifier 목록만 확인한다.
        manager.monitoredRegions.map { $0.identifier }.sorted()
    }

    /// 사용자가 geofence 안으로 들어왔을 때 호출된다.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // 현재는 테스트 단계라 Flutter 왕복 없이 네이티브에서 바로 로컬 알림을 띄운다.
        sendLocalNotification(
            title: "まもなく面談です",
            body: "面談場所の近くに到着しました。"
        )
        print("didEnterRegion: \(region.identifier)")
    }

    /// 사용자가 geofence 밖으로 나갔을 때 호출된다.
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // 이후에는 identifier 규칙에 따라 "도착 알림 / 기록 알림"을 나눌 수 있다.
        sendLocalNotification(
            title: "面談記録の作成",
            body: "面談場所を離れました。記録を残してください。"
        )
        print("didExitRegion: \(region.identifier)")
    }

    /// geofence 상태를 바로 확인했을 때 현재 안/밖인지 알려준다.
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            print("regionState: inside / \(region.identifier)")
        case .outside:
            print("regionState: outside / \(region.identifier)")
        case .unknown:
            print("regionState: unknown / \(region.identifier)")
        @unknown default:
            print("regionState: unsupported / \(region.identifier)")
        }
    }

    /// 위치 관련 에러를 로그로 남긴다.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    /// 권한 변경 시 상태를 확인하기 위한 로그다.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 권한 팝업 후 실제 상태가 어떻게 바뀌었는지 추적하기 위한 로그다.
        print("Authorization changed: \(currentAuthorizationStatus())")
    }

    /// 로컬 알림을 즉시 발생시킨다.
    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
