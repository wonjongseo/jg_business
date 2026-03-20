import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Flutter 플러그인을 먼저 등록한다.
        GeneratedPluginRegistrant.register(with: self)

        if let controller = window?.rootViewController as? FlutterViewController {
            // Flutter <-> iOS geofence 제어용 MethodChannel 이다.
            let geofenceChannel = FlutterMethodChannel(
                name: "jg_business/geofence",
                binaryMessenger: controller.binaryMessenger
            )

            // Flutter에서 geofence 관련 메서드를 호출하면 여기서 받는다.
            geofenceChannel.setMethodCallHandler { call, result in
                switch call.method {
                case "requestWhenInUsePermission":
                    // foreground 위치 권한 요청
                    LocationGeofenceManager.shared.requestWhenInUsePermission()
                    result(nil)

                case "requestAlwaysPermission":
                    // background geofence 용 항상 허용 권한 요청
                    LocationGeofenceManager.shared.requestAlwaysPermission()
                    result(nil)

                case "currentAuthorizationStatus":
                    // iOS CLLocation 권한 상태를 Flutter 로 돌려준다.
                    result(LocationGeofenceManager.shared.currentAuthorizationStatus())

                case "monitoredRegionIdentifiers":
                    // 현재 등록된 geofence 목록을 디버깅/복구용으로 넘긴다.
                    result(LocationGeofenceManager.shared.monitoredRegionIdentifiers())

                case "registerRegion":
                    guard
                        let args = call.arguments as? [String: Any],
                        let identifier = args["identifier"] as? String,
                        let latitude = args["latitude"] as? Double,
                        let longitude = args["longitude"] as? Double,
                        let radius = args["radius"] as? Double,
                        let notifyOnEntry = args["notifyOnEntry"] as? Bool,
                        let notifyOnExit = args["notifyOnExit"] as? Bool
                    else {
                        result(
                            FlutterError(
                                code: "bad_args",
                                message: "registerRegion 인자가 잘못되었습니다.",
                                details: nil
                            )
                        )
                        return
                    }

                    LocationGeofenceManager.shared.registerRegion(
                        identifier: identifier,
                        latitude: latitude,
                        longitude: longitude,
                        radius: radius,
                        notifyOnEntry: notifyOnEntry,
                        notifyOnExit: notifyOnExit
                    )
                    result(nil)

                case "unregisterRegion":
                    guard
                        let args = call.arguments as? [String: Any],
                        let identifier = args["identifier"] as? String
                    else {
                        result(
                            FlutterError(
                                code: "bad_args",
                                message: "unregisterRegion 인자가 잘못되었습니다.",
                                details: nil
                            )
                        )
                        return
                    }

                    LocationGeofenceManager.shared.unregisterRegion(identifier: identifier)
                    result(nil)

                case "unregisterAllRegions":
                    // 재등록 전에 모든 geofence를 비울 때 사용한다.
                    LocationGeofenceManager.shared.unregisterAllRegions()
                    result(nil)

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
