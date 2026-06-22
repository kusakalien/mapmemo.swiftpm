import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// アプリのメイン画面。
///
/// - 地図上に実在のお店のピンを表示する
/// - お店のピンをタップすると、そのお店（ブランド）のメモを表示・編集できる
/// - メモはブランド名でマッチングするため、同じブランドのお店すべてに反映される
/// - 現在地を取得し、近くのお店にメモがあれば画面上部のバナーで知らせる
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var memos: [StoreMemo]

    @State private var locationManager = LocationManager()
    @State private var storeSearch = StoreSearch()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    /// タップされたお店（非 nil でメモ編集シートを表示）
    @State private var tappedStore: Store?
    /// メモ一覧シートの表示状態
    @State private var showingList = false

    /// 「近くにいる」とみなす距離（メートル）
    private let nearbyThreshold: CLLocationDistance = 80

    var body: some View {
        NavigationStack {
            mapView
                .overlay(alignment: .top) { nearbyBanner }
                .overlay(alignment: .bottomTrailing) { recenterHint }
                .navigationTitle("MapMemo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingList = true
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
                // メモ編集シート（お店のピンをタップして表示）
                .sheet(item: $tappedStore) { store in
                    StoreMemoEditorView(storeTitle: store.name, existingMemo: memo(for: store.name))
                }
                // メモ一覧シート
                .sheet(isPresented: $showingList) {
                    MemoListView()
                }
                .task {
                    locationManager.requestPermission()
                    locationManager.startUpdating()
                }
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: $cameraPosition) {
            // 現在地
            UserAnnotation()

            // 検索で見つかった実在のお店
            ForEach(storeSearch.stores) { store in
                Annotation(store.name, coordinate: store.coordinate) {
                    Button {
                        tappedStore = store
                    } label: {
                        StorePin(hasMemo: memo(for: store.name) != nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        // 自前のピンを使うため、地図標準の POI ラベルは消す
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        // 表示領域が変わるたびに、その範囲のお店を検索する
        .onMapCameraChange(frequency: .onEnd) { context in
            storeSearch.search(in: context.region)
        }
    }

    // MARK: - Nearby banner

    @ViewBuilder
    private var nearbyBanner: some View {
        if let match = nearestMemoStore {
            Button {
                tappedStore = match.store
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("近くのお店: \(match.store.name)")
                            .font(.headline)
                        Text(match.memo.memo)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    // MARK: - Hint

    private var recenterHint: some View {
        Text("お店のピンをタップしてメモ")
            .font(.footnote)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.thinMaterial, in: Capsule())
            .padding()
    }

    // MARK: - Helpers

    /// 指定したお店の名前に該当するメモを返す（ブランド名でマッチング）。
    private func memo(for storeName: String) -> StoreMemo? {
        memos.first { $0.matches(storeName: storeName) }
    }

    /// 現在地の近くにあり、かつメモが登録されているお店のうち最も近いもの。
    private var nearestMemoStore: (store: Store, memo: StoreMemo)? {
        guard let current = locationManager.currentLocation else { return nil }
        return storeSearch.stores
            .filter { $0.distance(from: current) <= nearbyThreshold }
            .compactMap { store -> (store: Store, memo: StoreMemo)? in
                guard let memo = memo(for: store.name) else { return nil }
                return (store, memo)
            }
            .min { $0.store.distance(from: current) < $1.store.distance(from: current) }
    }
}

/// 地図上のお店を表すピン。メモがあるお店は赤、なければ灰色で表示する。
private struct StorePin: View {
    let hasMemo: Bool

    var body: some View {
        Image(systemName: hasMemo ? "mappin.circle.fill" : "mappin.circle")
            .font(.title)
            .foregroundStyle(hasMemo ? .red : .gray)
            .background(Circle().fill(.white).padding(5))
            .shadow(radius: 2)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StoreMemo.self, inMemory: true)
}
