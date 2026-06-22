import SwiftUI
import SwiftData
import MapKit

/// 既存のメモを表示・編集・削除する画面。
struct MemoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var memo: StoreMemo

    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("お店") {
                    TextField("店舗名", text: $memo.storeName)
                }

                Section("メモ") {
                    TextField("メモ", text: $memo.memo, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("場所") {
                    Map(
                        initialPosition: .region(
                            MKCoordinateRegion(
                                center: memo.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                            )
                        ),
                        interactionModes: []
                    ) {
                        Marker(memo.storeName, coordinate: memo.coordinate)
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("このメモを削除", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(memo.storeName.isEmpty ? "メモ" : memo.storeName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .confirmationDialog(
                "このメモを削除しますか？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    modelContext.delete(memo)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}
