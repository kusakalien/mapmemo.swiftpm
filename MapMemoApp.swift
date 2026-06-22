import SwiftUI
import SwiftData

@main
struct MapMemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // SwiftData の永続化コンテナをアプリ全体に提供する
        .modelContainer(for: StoreMemo.self)
    }
}
