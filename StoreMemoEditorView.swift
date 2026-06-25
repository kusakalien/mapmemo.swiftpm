import SwiftUI
import SwiftData

/// お店のメモを表示・作成・編集・削除する画面。
///
/// 地図でタップしたお店、またはメモ一覧から開かれる。
/// メモは「ブランド名」で管理され、同じブランド名を含むお店すべてに反映される。
struct StoreMemoEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// タップされたお店の名前（表示・初期値用）
    let storeTitle: String
    /// 既存のメモ（あれば編集、なければ新規作成）
    let existingMemo: StoreMemo?

    @State private var brandName: String
    @State private var memoText: String
    @State private var showingDeleteConfirmation = false

    init(storeTitle: String, existingMemo: StoreMemo?) {
        self.storeTitle = storeTitle
        self.existingMemo = existingMemo
        _brandName = State(initialValue: existingMemo?.storeName ?? storeTitle)
        _memoText = State(initialValue: existingMemo?.memo ?? "")
    }

    private var canSave: Bool {
        !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !memoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("タップしたお店", value: storeTitle)
                } footer: {
                    Text("メモは下の「ブランド名」で始まる名前のお店すべてに表示されます。例えば「ローソン」にすると全国のローソンに反映されます（「アローソン」など途中に含むだけのお店は対象外）。")
                }

                Section("ブランド名") {
                    TextField("例: ローソン", text: $brandName)
                }

                Section("メモ") {
                    TextField(
                        "例: 三井住友カードのタッチ決済で最大7%還元",
                        text: $memoText,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                if existingMemo != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("このメモを削除", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(existingMemo == nil ? "メモを追加" : "メモを編集")
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
            .confirmationDialog(
                "このメモを削除しますか？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) { delete() }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    private func save() {
        let name = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = memoText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = existingMemo {
            existing.storeName = name
            existing.memo = text
            existing.updatedAt = .now
        } else {
            modelContext.insert(StoreMemo(storeName: name, memo: text))
        }
        // 確実に永続化する
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        if let existing = existingMemo {
            modelContext.delete(existing)
            try? modelContext.save()
        }
        dismiss()
    }
}
