import SwiftData
import SwiftUI

@MainActor
enum PreviewStore {
    static let container: ModelContainer? = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: Toy.self, ChanceSetup.self, SpinResult.self, configurations: config) else {
            return nil
        }
        SeedData.install(into: container.mainContext)
        return container
    }()
}

extension View {
    @MainActor @ViewBuilder
    func previewStore() -> some View {
        if let container = PreviewStore.container {
            modelContainer(container)
        } else {
            self
        }
    }
}
