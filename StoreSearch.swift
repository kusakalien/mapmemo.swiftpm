import Foundation
import MapKit
import Observation

/// 地図上に表示する実在のお店。
struct Store: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D

    init?(mapItem: MKMapItem) {
        guard let name = mapItem.name else { return nil }
        let coordinate = mapItem.placemark.coordinate
        self.name = name
        self.coordinate = coordinate
        // 検索のたびに同じお店が安定した id を持つようにする
        self.id = "\(name)|\(coordinate.latitude),\(coordinate.longitude)"
    }

    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let here = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return here.distance(from: target)
    }

    static func == (lhs: Store, rhs: Store) -> Bool { lhs.id == rhs.id }
}

/// 表示中の地図領域から、実在のお店（コンビニ・スーパー等）を検索するサービス。
@MainActor
@Observable
final class StoreSearch {
    /// 直近の検索で見つかったお店
    var stores: [Store] = []

    @ObservationIgnored
    private var searchTask: Task<Void, Never>?

    /// 検索対象とするお店のカテゴリ
    private static let categories: [MKPointOfInterestCategory] = [
        .store, .foodMarket, .gasStation, .pharmacy, .restaurant, .cafe, .bakery
    ]

    /// 指定された地図領域内のお店を検索する（短いデバウンス付き）。
    func search(in region: MKCoordinateRegion) {
        // 広域すぎる（ズームアウトしすぎ）場合は検索しない。
        // MKLocalPointsOfInterestRequest は span が大きすぎると例外になるため。
        guard region.span.latitudeDelta <= 0.4, region.span.longitudeDelta <= 0.4 else {
            stores = []
            return
        }

        searchTask?.cancel()
        searchTask = Task { [region] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: Self.categories)

            let search = MKLocalSearch(request: request)
            guard let response = try? await search.start(), !Task.isCancelled else { return }

            // 同名・同座標の重複を除いて反映する
            var seen = Set<String>()
            stores = response.mapItems.compactMap { Store(mapItem: $0) }.filter { seen.insert($0.id).inserted }
        }
    }
}
