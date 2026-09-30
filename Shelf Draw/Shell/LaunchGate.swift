import SwiftUI

enum LaunchPhase: Equatable {
    case intro
    case ready
    case unavailable
}

struct LaunchGate<Intro: View, Ready: View>: View {
    var phase: LaunchPhase
    var unavailableTitle: String
    var unavailableMessage: String
    var retryTitle: String = "Try again"
    var retry: () -> Void
    @ViewBuilder var intro: () -> Intro
    @ViewBuilder var ready: () -> Ready

    var body: some View {
        switch phase {
        case .intro:
            intro()
        case .ready:
            ready()
        case .unavailable:
            FailureCard(
                title: unavailableTitle,
                message: unavailableMessage,
                retryTitle: retryTitle,
                retry: retry
            )
        }
    }
}

/// A route that arrived before the tabs exist. Stage it, then take() once phase is .ready.
struct StagedLink<Route: Hashable> {
    var route: Route?

    mutating func stage(_ route: Route) {
        self.route = route
    }

    mutating func take() -> Route? {
        defer { route = nil }
        return route
    }
}

#Preview("Unavailable") {
    LaunchGate(
        phase: .unavailable,
        unavailableTitle: "Library didn't open",
        unavailableMessage: "What you saved is still on this phone.",
        retry: {}
    ) {
        Text("Intro")
    } ready: {
        Text("Ready")
    }
}
