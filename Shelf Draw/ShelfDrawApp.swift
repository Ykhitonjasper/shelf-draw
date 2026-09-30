import SwiftData
import SwiftUI

@main
struct ShelfDrawApp: App {
    @State private var container: ModelContainer? = ShelfDrawApp.openStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    AppRoot(storeOpened: true, retry: {})
                        .modelContainer(container)
                } else {
                    AppRoot(storeOpened: false, retry: { container = ShelfDrawApp.openStore() })
                }
            }
            .background(AppBackground())
            .preferredColorScheme(.light)
            .tint(AppTheme.accent)
        }
    }

    private static func openStore() -> ModelContainer? {
        try? ModelContainer(for: Toy.self, ChanceSetup.self, SpinResult.self)
    }
}
