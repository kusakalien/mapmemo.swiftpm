import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// アプリのメイン画面。
///
/// - 地図上にユーザーが作成したお店のメモをピンで表示する
/// - 現在地を取得し、近くのお店のメモをバナーで知らせる
/// - 地図をタップ、または現在地ボタンからメモを追加できる
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoreMemo.createdAt, order: .reverse) private var memos: [StoreMemo]

    @State private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    /// 新規メモを追加する座標（非 nil でシートを表示）
    @State private var newMemoLocation: MemoLocation?
    /// 詳細表示・編集するメモ
    @State private var selectedMemo: StoreMemo?
    /// メモ一覧シートの表示状態
    @State private var showingList = false

    /// 「近くにいる」とみなす距離（メートル）
    private let nearbyThreshold: CLLocationDistance = 80

    /// 現在地から近い順に並べた、しきい値以内のメモ
    private var nearbyMemos: [StoreMemo] {
        guard let current = locationManager.currentLocation else { return [] }
        return memos
            .filter { $0.distance(from: current) <= nearbyThreshold }
            .sorted { $0.distance(from: current) < $1.distance(from: current) }
    }

    var body: some View {
        NavigationStack {
            mapView
                .overlay(alignment: .top) { nearbyBanner }
                .overlay(alignment: .bottomTrailing) { controlButtons }
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
                // メモ追加シート
                .sheet(item: $newMemoLocation) { location in
                    AddMemoView(coordinate: location.coordinate)
                }
                // メモ詳細・編集シート
                .sheet(item: $selectedMemo) { memo in
                    MemoDetailView(memo: memo)
                }
                // メモ一覧シート
                .sheet(isPresented: $showingList) {
                    MemoListView { memo in
                        showingList = false
                        focus(on: memo)
                    }
                }
                .task {
                    locationManager.requestPermission()
                    locationManager.startUpdating()
                }
        }
    }

    // MARK: - Map

    private var mapView: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                // 現在地
                UserAnnotation()

                // 各メモのピン
                ForEach(memos) { memo in
                    Annotation(memo.storeName, coordinate: memo.coordinate) {
                        Button {
                            selectedMemo = memo
                        } label: {
                            MemoPin(isNearby: nearbyMemos.contains { $0.id == memo.id })
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            // 地図上のタップ位置にメモを追加する
            .onTapGesture(coordinateSpace: .local) { screenPoint in
                if let coordinate = proxy.convert(screenPoint, from: .local) {
                    newMemoLocation = MemoLocation(coordinate: coordinate)
                }
            }
        }
    }

    // MARK: - Nearby banner

    @ViewBuilder
    private var nearbyBanner: some View {
        if let memo = nearbyMemos.first {
            Button {
                selectedMemo = memo
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("近くのお店: \(memo.storeName)")
                            .font(.headline)
                        Text(memo.memo)
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
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Buttons

    private var controlButtons: some View {
        Button {
            addMemoAtCurrentLocation()
        } label: {
            Label("現在地にメモ", systemImage: "plus")
                .font(.headline)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.blue, in: Capsule())
                .foregroundStyle(.white)
                .shadow(radius: 4)
        }
        .padding()
    }

    // MARK: - Actions

    private func addMemoAtCurrentLocation() {
        // 現在地が取れていればその座標、なければ地図中心付近にフォールバック
        if let current = locationManager.currentLocation {
            newMemoLocation = MemoLocation(coordinate: current)
        } else if let region = cameraPosition.region {
            newMemoLocation = MemoLocation(coordinate: region.center)
        } else {
            newMemoLocation = MemoLocation(
                coordinate: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
            )
        }
    }

    private func focus(on memo: StoreMemo) {
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: memo.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
    }
}

/// 地図上のメモを表すピン。近くにいるメモは強調表示する。
private struct MemoPin: View {
    let isNearby: Bool

    var body: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.title)
            .foregroundStyle(isNearby ? .red : .blue)
            .background(Circle().fill(.white).padding(4))
            .shadow(radius: 2)
    }
}

/// sheet(item:) で座標を渡すための Identifiable ラッパー
struct MemoLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    ContentView()
        .modelContainer(for: StoreMemo.self, inMemory: true)
}
