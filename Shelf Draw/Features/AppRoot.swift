import SwiftData
import SwiftUI

struct AppRoot: View {
    var storeOpened: Bool
    var retry: () -> Void

    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("activeShelf") private var activeShelfName = ""

    private var phase: LaunchPhase {
        guard storeOpened else { return .unavailable }
        return hasCompletedOnboarding ? .ready : .intro
    }

    var body: some View {
        LaunchGate(
            phase: phase,
            unavailableTitle: "Shelf log didn't open",
            unavailableMessage: "Your figures and placements are still on this phone. Try opening the storage again.",
            retry: retry,
            intro: {
                OnboardingScreen { shelf in
                    let existing = (try? context.fetchCount(FetchDescriptor<ChanceSetup>())) ?? 0
                    if existing == 0 {
                        SeedData.install(into: context)
                    }
                    activeShelfName = shelf
                    hasCompletedOnboarding = true
                }
            },
            ready: {
                NavRoot(
                    roles: ["draw", "shelves", "log"],
                    titles: ["Draw", "Shelves", "Log"],
                    symbols: ["circle.dashed.inset.filled", "books.vertical", "clock.arrow.circlepath"]
                ) {
                    DrawScreen()
                } second: {
                    ShelvesScreen()
                } third: {
                    LogScreen()
                } settings: {
                    SettingsScreen {
                        SeedData.wipe(context)
                        activeShelfName = ""
                        hasCompletedOnboarding = false
                    }
                }
            }
        )
    }
}
