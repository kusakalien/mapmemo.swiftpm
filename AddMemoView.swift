import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// 新しいお店のメモを追加するための入力画面。
struct AddMemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// メモを紐づける座標
    let coordinate: CLLocationCoordinate2D

    @State private var storeName = ""
    @State private var memoText = ""

    private var canSave: Bool {
        !storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !memoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("お店") {
                    TextField("店舗名（例: ローソン △△店）", text: $storeName)
                }

                Section("メモ") {
                    TextField(
                        "例: 三井住友カードのタッチ決済で最大7%還元",
                        text: $memoText,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section("場所") {
                    LabeledContent("緯度", value: String(format: "%.5f", coordinate.latitude))
                    LabeledContent("経度", value: String(format: "%.5f", coordinate.longitude))
                    locationMap
                }
            }
            .navigationTitle("メモを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var locationMap: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                )
            ),
            interactionModes: []
        ) {
            Marker("ここ", coordinate: coordinate)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .listRowInsets(EdgeInsets())
    }

    private func save() {
        let memo = StoreMemo(
            storeName: storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            memo: memoText.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        modelContext.insert(memo)
        dismiss()
    }
}
