import SwiftUI
import SwiftData

/// 登録済みメモの一覧。タップで地図上の該当ピンへ移動できる。
struct MemoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoreMemo.createdAt, order: .reverse) private var memos: [StoreMemo]

    /// 行を選択したときに呼ばれる（地図側でフォーカスするために使用）
    var onSelect: (StoreMemo) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if memos.isEmpty {
                    ContentUnavailableView(
                        "メモがありません",
                        systemImage: "mappin.slash",
                        description: Text("地図をタップするか「現在地にメモ」からお店のメモを追加できます。")
                    )
                } else {
                    List {
                        ForEach(memos) { memo in
                            Button {
                                onSelect(memo)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(memo.storeName)
                                        .font(.headline)
                                    Text(memo.memo)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .tint(.primary)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("メモ一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(memos[index])
        }
    }
}
