import Foundation
import SwiftData
import CoreLocation

/// 店舗ごとのメモを表す永続化モデル。
///
/// 例: 「ローソン」で「○○クレカが還元率最大」など、
/// 場所に紐づくお得情報をユーザーが自由に記録できる。
@Model
final class StoreMemo {
    /// 店舗名（例: ローソン △△店）
    var storeName: String
    /// メモ本文（例: 三井住友カードのタッチ決済で最大7%還元）
    var memo: String
    /// 位置情報（緯度）。CLLocationCoordinate2D は直接保存できないため分割して保持する。
    var latitude: Double
    /// 位置情報（経度）
    var longitude: Double
    /// 作成日時
    var createdAt: Date

    init(
        storeName: String,
        memo: String,
        latitude: Double,
        longitude: Double,
        createdAt: Date = .now
    ) {
        self.storeName = storeName
        self.memo = memo
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }

    /// 地図表示用の座標
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 指定座標からの距離（メートル）を返す
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let here = CLLocation(latitude: latitude, longitude: longitude)
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return here.distance(from: target)
    }
}
