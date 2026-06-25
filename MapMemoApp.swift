import SwiftUI
import SwiftData

@main
struct MapMemoApp: App {
    /// アプリ内課金の状態を管理する
    @State private var storeManager: StoreManager
    /// SwiftData の永続化コンテナ
    private let container: ModelContainer

    init() {
        _storeManager = State(initialValue: StoreManager())
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
        }
        // SwiftData の永続化コンテナをアプリ全体に提供する
        .modelContainer(container)
    }

    /// 永続化コンテナを生成する。
    ///
    /// 既存ストアがスキーマ非互換などで開けない場合は、古いストアを削除して作り直す。
    /// （開発中にモデルを変更した際に保存できなくなる問題を防ぐ）
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([StoreMemo.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // 古いストアファイル（と関連ファイル）を削除して再作成を試みる
            removeStoreFiles(at: configuration.url)
            if let container = try? ModelContainer(for: schema, configurations: configuration) {
                return container
            }
            // それでも失敗する場合はメモリ内ストアで起動する（最低限アプリが動くように）
            let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: memoryConfiguration)
        }
    }

    /// SQLite ストア本体と WAL / SHM などの関連ファイルを削除する。
    private static func removeStoreFiles(at url: URL) {
        let fileManager = FileManager.default
        let suffixes = ["", "-wal", "-shm", "-journal"]
        for suffix in suffixes {
            let target = URL(fileURLWithPath: url.path + suffix)
            try? fileManager.removeItem(at: target)
        }
    }
}
