import SwiftUI
import SwiftData

@main
struct MapMemoApp: App {
    /// アプリ内課金の状態を管理する
    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
        }
        // SwiftData の永続化コンテナをアプリ全体に提供する
        .modelContainer(for: StoreMemo.self)
    }
}
