import Foundation
import CoreLocation
import Observation

/// 利用者の現在地を取得するためのラッパー。
///
/// iOS 17 以降の `@Observable` マクロを使い、SwiftUI から
/// `currentLocation` や `authorizationStatus` の変化を監視できるようにする。
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    /// 現在地（取得できていない場合は nil）
    var currentLocation: CLLocationCoordinate2D?
    /// 位置情報の利用許可状態
    var authorizationStatus: CLAuthorizationStatus

    @ObservationIgnored
    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        // 約10m 移動するごとに更新する
        manager.distanceFilter = 10
    }

    /// 位置情報の利用許可をリクエストする
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// 位置情報の更新を開始する
    func startUpdating() {
        manager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        currentLocation = latest.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 位置情報の取得に失敗してもアプリは継続する（ログのみ）
        print("位置情報の取得に失敗しました: \(error.localizedDescription)")
    }
}
