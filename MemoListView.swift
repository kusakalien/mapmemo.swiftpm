import SwiftUI
import SwiftData

/// 登録済みメモ（ブランド単位）の一覧。タップで編集できる。
struct MemoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store
    @Query(sort: \StoreMemo.updatedAt, order: .reverse) private var memos: [StoreMemo]

    @State private var editingMemo: StoreMemo?
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if memos.isEmpty {
                    ContentUnavailableView(
                        "メモがありません",
                        systemImage: "mappin.slash",
                        description: Text("地図上のお店のピンをタップして、お得な決済方法などをメモできます。")
                    )
                } else {
                    List {
                        planSection

                        Section {
                            ForEach(memos) { memo in
                                Button {
                                    editingMemo = memo
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
            }
            .navigationTitle("メモ一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(item: $editingMemo) { memo in
                StoreMemoEditorView(storeTitle: memo.storeName, existingMemo: memo)
                    .environment(store)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environment(store)
            }
        }
    }

    /// 課金プランの状態を表示するセクション
    @ViewBuilder
    private var planSection: some View {
        if store.isUnlimitedUnlocked {
            Section {
                Label("メモ無制限プラン", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
        } else {
            Section {
                LabeledContent("無料プラン", value: "\(memos.count) / \(StoreManager.freeMemoLimit) 件")
                Button("メモを無制限にする") {
                    showingPaywall = true
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(memos[index])
        }
        try? modelContext.save()
    }
}
